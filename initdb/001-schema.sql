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

CREATE TABLE IF NOT EXISTS bracelets (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    device_uid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    serial_number TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    firmware_version TEXT,
    mac_address TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'lost', 'retired')),
    paired_at TIMESTAMPTZ,
    last_seen_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS biometrics_measurements (
    id BIGSERIAL PRIMARY KEY,
    bracelet_id BIGINT NOT NULL REFERENCES bracelets(id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_bracelets_user_id ON bracelets(user_id);
CREATE INDEX IF NOT EXISTS idx_biometrics_measurements_bracelet_captured_at ON biometrics_measurements(bracelet_id, captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_biometrics_measurements_captured_at ON biometrics_measurements(captured_at DESC);