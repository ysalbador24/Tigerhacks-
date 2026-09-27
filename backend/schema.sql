-- Snooze You Choose: one row per night played.
-- Runs on Tiger Data (TimescaleDB). The Timescale-only statements below are
-- skipped automatically on plain PostgreSQL.

CREATE TABLE IF NOT EXISTS nights (
    played_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    player_hash   TEXT        NOT NULL,  -- salted hash of the Roblox user id
    display_name  TEXT        NOT NULL,
    phone         SMALLINT    NOT NULL CHECK (phone IN (1, 2)),     -- 1 docked, 2 scrolled
    lighting      SMALLINT    NOT NULL CHECK (lighting IN (1, 2)),  -- 1 dim, 2 big light
    food          SMALLINT    NOT NULL CHECK (food IN (1, 2)),      -- 1 none, 2 late meal
    notifications SMALLINT             CHECK (notifications IN (1, 2)),
    stability     SMALLINT    NOT NULL CHECK (stability BETWEEN 0 AND 100),
    grade         TEXT        NOT NULL,
    points        SMALLINT    NOT NULL,
    sheep         SMALLINT    NOT NULL,
    sheep_total   SMALLINT    NOT NULL,
    stumbles      SMALLINT    NOT NULL,
    seconds_left  SMALLINT    NOT NULL,
    woke_early    BOOLEAN     NOT NULL,
    gemini_used   BOOLEAN     NOT NULL
);

-- optional: every evening activity the player did, e.g. {"Shower": 1, "BrushTeeth": 2, "Activities": 6}.
-- 1 = healthy option, 2 = the other option, missing = skipped.
ALTER TABLE nights ADD COLUMN IF NOT EXISTS routine JSONB;

-- optional: anonymous audience info. Two-letter country/region code from Roblox and device type.
ALTER TABLE nights ADD COLUMN IF NOT EXISTS country TEXT;

-- optional: phone, tablet, computer, or console.
ALTER TABLE nights ADD COLUMN IF NOT EXISTS device TEXT;

CREATE INDEX IF NOT EXISTS nights_points_idx ON nights (played_at DESC, points DESC);

-- timescale: turn nights into a hypertable partitioned by time.
SELECT create_hypertable('nights', 'played_at', if_not_exists => TRUE, migrate_data => TRUE);

-- timescale: hourly rollup for the dashboard, kept fresh automatically.
CREATE MATERIALIZED VIEW IF NOT EXISTS nights_hourly
WITH (timescaledb.continuous, timescaledb.materialized_only = false) AS
SELECT time_bucket(INTERVAL '1 hour', played_at) AS bucket,
       count(*)                     AS nights,
       avg(stability)               AS avg_stability,
       avg((phone = 2)::int)        AS scrolled_rate,
       avg((lighting = 2)::int)     AS big_light_rate,
       avg((food = 2)::int)         AS late_meal_rate
FROM nights
GROUP BY bucket
WITH NO DATA;

-- timescale: refresh the rollup every five minutes.
SELECT add_continuous_aggregate_policy('nights_hourly',
    start_offset => INTERVAL '2 days',
    end_offset => INTERVAL '1 minute',
    schedule_interval => INTERVAL '5 minutes',
    if_not_exists => TRUE);
