CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT,
    first_name TEXT NOT NULL DEFAULT '',
    last_name TEXT NOT NULL DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_staff BOOLEAN NOT NULL DEFAULT FALSE,
    is_superuser BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- No more "bracelets" table, and no pairing/appairage step: a measurement
-- belongs directly to the authenticated user who posted it. The BLE link only
-- ever talks to one bracelet at a time, so device_uid/serial_number/mac_address
-- are kept as plain descriptive columns on the measurement itself (which device
-- produced it), not as a foreign key to a device registry. A user can post
-- measurements from as many different physical bracelets as they want, one
-- session at a time — there is nothing left to "pair" or "unpair".
CREATE TABLE IF NOT EXISTS biometrics_measurements (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_uid TEXT,
    serial_number TEXT,
    display_name TEXT,
    mac_address TEXT,
    captured_at TIMESTAMPTZ NOT NULL,
    heart_rate_bpm INTEGER CHECK (heart_rate_bpm IS NULL OR heart_rate_bpm BETWEEN 0 AND 250),
    spo2_percent NUMERIC(5, 2) CHECK (spo2_percent IS NULL OR spo2_percent BETWEEN 0 AND 100),
    step_count INTEGER NOT NULL DEFAULT 0 CHECK (step_count >= 0),
    motion_level NUMERIC(8, 3),
    signal_quality INTEGER CHECK (signal_quality IS NULL OR signal_quality BETWEEN 0 AND 100),
    raw_payload JSONB,
    source_topic TEXT,
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_biometrics_measurements_user_captured_at ON biometrics_measurements(user_id, captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_biometrics_measurements_captured_at ON biometrics_measurements(captured_at DESC);
