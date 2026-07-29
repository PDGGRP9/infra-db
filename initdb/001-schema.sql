CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS app_users (
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
    user_id BIGINT REFERENCES app_users(id) ON DELETE SET NULL,
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

CREATE TABLE IF NOT EXISTS bracelet_pairings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    bracelet_id BIGINT NOT NULL REFERENCES bracelets(id) ON DELETE CASCADE,
    pairing_code TEXT,
    consent_given_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    consent_withdrawn_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, bracelet_id)
);

CREATE TABLE IF NOT EXISTS biometric_measurements (
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

CREATE TABLE IF NOT EXISTS biometric_measurement_samples (
    id BIGSERIAL PRIMARY KEY,
    measurement_id BIGINT NOT NULL REFERENCES biometric_measurements(id) ON DELETE CASCADE,
    sample_type TEXT NOT NULL,
    sample_index INTEGER NOT NULL CHECK (sample_index >= 0),
    sample_value NUMERIC(14, 6) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (measurement_id, sample_type, sample_index)
);

CREATE TABLE IF NOT EXISTS data_export_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'done', 'failed')),
    export_format TEXT NOT NULL DEFAULT 'json' CHECK (export_format IN ('json', 'csv', 'parquet')),
    requested_from TIMESTAMPTZ,
    requested_to TIMESTAMPTZ,
    download_path TEXT,
    error_message TEXT
);

CREATE TABLE IF NOT EXISTS consent_events (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    consent_type TEXT NOT NULL,
    granted BOOLEAN NOT NULL,
    context JSONB,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bracelets_user_id ON bracelets(user_id);
CREATE INDEX IF NOT EXISTS idx_bracelet_pairings_user_id ON bracelet_pairings(user_id);
CREATE INDEX IF NOT EXISTS idx_bracelet_pairings_bracelet_id ON bracelet_pairings(bracelet_id);
CREATE INDEX IF NOT EXISTS idx_biometric_measurements_bracelet_captured_at ON biometric_measurements(bracelet_id, captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_biometric_measurements_captured_at ON biometric_measurements(captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_data_export_requests_user_id ON data_export_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_consent_events_user_id ON consent_events(user_id);