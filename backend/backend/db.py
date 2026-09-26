"""Tiger Data (TimescaleDB / PostgreSQL) storage for played nights."""

import hashlib
import os
from pathlib import Path

import psycopg
from psycopg.rows import dict_row
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
                if not is_timescale:
                    raise
                timescale = False
                print("Skipping TimescaleDB feature (plain PostgreSQL?):", error)

    pool = ConnectionPool(DATABASE_URL, min_size=1, max_size=5, kwargs={"row_factory": dict_row}, open=True)
    print("Database ready. TimescaleDB features:", timescale)


def hash_player(player_id: str) -> str:
    return hashlib.sha256(f"{PLAYER_SALT}:{player_id}".encode()).hexdigest()


def save_night(night: dict) -> None:
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
        "stability_phone_docked": rounded(totals["stability_phone_docked"], 1),
        "stability_scrolled": rounded(totals["stability_scrolled"], 1),
        "avg_sheep": rounded(totals["avg_sheep"], 1),
        "avg_stumbles": rounded(totals["avg_stumbles"], 1),
        "grades": {row["grade"]: row["nights"] for row in grades},
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
