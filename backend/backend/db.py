"""Tiger Data (TimescaleDB / PostgreSQL) storage for played nights."""

import hashlib
import os
from pathlib import Path

import psycopg
from psycopg.rows import dict_row
from psycopg.types.json import Jsonb
from psycopg_pool import ConnectionPool

# Tiger Cloud's downloaded .env calls it TIMESCALE_SERVICE_URL; either name works.
DATABASE_URL = os.getenv("DATABASE_URL") or os.getenv("TIMESCALE_SERVICE_URL")
PLAYER_SALT = os.getenv("PLAYER_SALT", "snooze-you-choose")
SCHEMA_PATH = Path(__file__).with_name("schema.sql")

pool: ConnectionPool | None = None
timescale = False


def enabled() -> bool:
    return pool is not None


def init() -> None:
    """Create the schema (idempotent) and open the connection pool."""
    global pool, timescale
    if not DATABASE_URL:
        print("DATABASE_URL not set: night history and stats are disabled.")
        return

    statements = [s.strip() for s in SCHEMA_PATH.read_text().split(";") if s.strip()]
    with psycopg.connect(DATABASE_URL, autocommit=True) as conn:
        timescale = True
        for statement in statements:
            is_timescale = "-- timescale:" in statement
            try:
                conn.execute(statement)
            except psycopg.Error as error:
                # Upgrades like new columns must never stop the backend from starting.
                if "-- optional:" in statement:
                    print("Skipping optional schema change:", error)
                    continue
                if not is_timescale:
                    raise
                timescale = False
                print("Skipping TimescaleDB feature (plain PostgreSQL?):", error)

    pool = ConnectionPool(DATABASE_URL, min_size=1, max_size=5, kwargs={"row_factory": dict_row}, open=True)
    print("Database ready. TimescaleDB features:", timescale)


def hash_player(player_id: str) -> str:
    return hashlib.sha256(f"{PLAYER_SALT}:{player_id}".encode()).hexdigest()


def save_night(night: dict) -> None:
    if night.get("routine") is not None:
        night["routine"] = Jsonb(night["routine"])
    columns = list(night)
    placeholders = ", ".join(f"%({c})s" for c in columns)
    with pool.connection() as conn:
        conn.execute(f"INSERT INTO nights ({', '.join(columns)}) VALUES ({placeholders})", night)


def community_stats() -> dict:
    with pool.connection() as conn:
        totals = conn.execute(
            """
            SELECT count(*)                                         AS nights,
                   count(DISTINCT player_hash)                      AS players,
                   avg((phone = 2)::int)                            AS scrolled_rate,
                   avg((lighting = 2)::int)                         AS big_light_rate,
                   avg((food = 2)::int)                             AS late_meal_rate,
                   avg((notifications = 2)::int)                    AS notifications_rate,
                   avg(stability) FILTER (WHERE phone = 1)          AS stability_phone_docked,
                   avg(stability) FILTER (WHERE phone = 2)          AS stability_scrolled,
                   avg(sheep)                                       AS avg_sheep,
                   avg(stumbles)                                    AS avg_stumbles
            FROM nights
            """
        ).fetchone()
        grades = conn.execute("SELECT grade, count(*) AS nights FROM nights GROUP BY grade").fetchall()

    def rounded(value, digits=2):
        return None if value is None else round(float(value), digits)

    return {
        "nights": totals["nights"],
        "players": totals["players"],
        "scrolled_rate": rounded(totals["scrolled_rate"]),
        "big_light_rate": rounded(totals["big_light_rate"]),
        "late_meal_rate": rounded(totals["late_meal_rate"]),
        "notifications_rate": rounded(totals["notifications_rate"]),
        "stability_phone_docked": rounded(totals["stability_phone_docked"], 1),
        "stability_scrolled": rounded(totals["stability_scrolled"], 1),
        "avg_sheep": rounded(totals["avg_sheep"], 1),
        "avg_stumbles": rounded(totals["avg_stumbles"], 1),
        "grades": {row["grade"]: row["nights"] for row in grades},
    }


# Evening activities shown on the stats page (keys match the Roblox choices).
ROUTINE_KEYS = ["WindDown", "Lighting", "Food", "Notifications", "Curtains", "Temperature", "Shower", "BrushTeeth", "TV"]


# The four CDC facts in the in-game book (ReadingInteraction.luau), in chapter order.
READING_FACTS = ["ReadingFact1", "ReadingFact2", "ReadingFact3", "ReadingFact4"]


def routine_stats() -> dict:
    """Share of nights that did each activity's healthy option (only nights that sent a routine).
    A skipped activity (missing key) counts as not done."""
    healthy = ",\n".join(
        f"avg(coalesce((routine->>'{key}') = '1', false)::int) AS \"{key}\"" for key in ROUTINE_KEYS
    )
    with pool.connection() as conn:
        row = conn.execute(
            f"""
            SELECT count(*) AS nights,
                   {healthy},
                   avg((routine->>'Activities')::numeric) AS activities,
                   avg(coalesce((routine->>'ReadingFact1') = '1', false)::int)
                       FILTER (WHERE (routine->>'WindDown') = '1') AS "ReadingFact1",
                   avg(coalesce((routine->>'ReadingFact2') = '1', false)::int)
                       FILTER (WHERE (routine->>'WindDown') = '1') AS "ReadingFact2",
                   avg(coalesce((routine->>'ReadingFact3') = '1', false)::int)
                       FILTER (WHERE (routine->>'WindDown') = '1') AS "ReadingFact3",
                   avg(coalesce((routine->>'ReadingFact4') = '1', false)::int)
                       FILTER (WHERE (routine->>'WindDown') = '1') AS "ReadingFact4",
                   count(*) FILTER (WHERE (routine->>'WindDown') = '1') AS readers,
                   avg(((routine->>'ShowerComfortable') = '1')::int)
                       FILTER (WHERE routine ? 'ShowerComfortable') AS shower_comfortable
            FROM nights
            WHERE routine IS NOT NULL
            """
        ).fetchone()

    def rounded(value, digits=2):
        return None if value is None else round(float(value), digits)

    return {
        "nights": row["nights"],
        "healthy": {key: rounded(row[key]) for key in ROUTINE_KEYS},
        "avg_activities": rounded(row["activities"], 1),
        "shower_comfortable": rounded(row["shower_comfortable"]),
        # Among nights where the player chose to read: share who answered each fact correctly.
        "readers": row["readers"],
        "facts_learned": {key: rounded(row[key]) for key in READING_FACTS},
    }


def rank_today(points: int) -> int:
    with pool.connection() as conn:
        row = conn.execute(
            "SELECT count(*) + 1 AS rank FROM nights WHERE played_at > now() - INTERVAL '1 day' AND points > %s",
            (points,),
        ).fetchone()
    return row["rank"]


def leaderboard(limit: int = 10) -> list[dict]:
    with pool.connection() as conn:
        rows = conn.execute(
            """
            SELECT display_name, grade, points, sheep, played_at
            FROM nights
            WHERE played_at > now() - INTERVAL '1 day'
            ORDER BY points DESC, played_at ASC
            LIMIT %s
            """,
            (limit,),
        ).fetchall()
    return [{**row, "played_at": row["played_at"].isoformat()} for row in rows]


def hourly(hours: int = 24) -> list[dict]:
    """Hourly trend from the continuous aggregate (or a plain query without Timescale)."""
    source = (
        "SELECT bucket, nights, avg_stability, scrolled_rate FROM nights_hourly"
        if timescale
        else """SELECT date_trunc('hour', played_at) AS bucket, count(*) AS nights,
                       avg(stability) AS avg_stability, avg((phone = 2)::int) AS scrolled_rate
                FROM nights GROUP BY 1"""
    )
    with pool.connection() as conn:
        rows = conn.execute(
            f"SELECT * FROM ({source}) h WHERE bucket > now() - make_interval(hours => %s) ORDER BY bucket",
            (hours,),
        ).fetchall()
    return [
        {
            "bucket": row["bucket"].isoformat(),
            "nights": row["nights"],
            "avg_stability": round(float(row["avg_stability"]), 1),
            "scrolled_rate": round(float(row["scrolled_rate"]), 2),
        }
        for row in rows
    ]
