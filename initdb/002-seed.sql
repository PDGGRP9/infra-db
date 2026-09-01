CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- Seed users
-- Password demo used here: demo1234
-- ============================================================

INSERT INTO users (
    email,
    username,
    password_hash,
    first_name,
    last_name,
    is_active,
    is_staff,
    is_superuser
)
VALUES
    (
        'ryad@example.com',
        'ryad',
        crypt('demo1234', gen_salt('bf')),
        'Ryad',
        'Bouzourene',
        TRUE,
        TRUE,
        TRUE
    ),
    (
        'alice@example.com',
        'alice',
        crypt('demo1234', gen_salt('bf')),
        'Alice',
        'Martin',
        TRUE,
        FALSE,
        FALSE
    ),
    (
        'thomas@example.com',
        'thomas',
        crypt('demo1234', gen_salt('bf')),
        'Thomas',
        'Durand',
        TRUE,
        FALSE,
        FALSE
    )
ON CONFLICT (email) DO UPDATE SET
    username = EXCLUDED.username,
    password_hash = EXCLUDED.password_hash,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    is_active = EXCLUDED.is_active,
    is_staff = EXCLUDED.is_staff,
    is_superuser = EXCLUDED.is_superuser,
    updated_at = NOW();

-- ============================================================
-- Optional cleanup of previous seed measurements
-- Useful if you manually rerun this script
-- ============================================================

DELETE FROM biometrics_measurements
WHERE source_topic LIKE 'seed/%';

-- ============================================================
-- Measurements for Ryad
-- Last 24 hours, one point every 15 minutes
-- ============================================================

WITH series AS (
    SELECT
        generate_series(
            NOW() - INTERVAL '24 hours',
            NOW(),
            INTERVAL '15 minutes'
        ) AS captured_at
),
numbered AS (
    SELECT
        captured_at,
        ROW_NUMBER() OVER (ORDER BY captured_at) AS rn
    FROM series
)
INSERT INTO biometrics_measurements (
    user_id,
    device_uid,
    serial_number,
    display_name,
    mac_address,
    captured_at,
    heart_rate_bpm,
    spo2_percent,
    step_count,
    motion_level,
    signal_quality,
    raw_payload,
    source_topic,
    received_at
)
SELECT
    (SELECT id FROM users WHERE email = 'ryad@example.com'),
    '11111111-1111-1111-1111-111111111111',
    'FAKE-BRACELET-001',
    'Bracelet de test Ryad',
    'AA:BB:CC:DD:EE:01',
    captured_at,
    (68 + random() * 28)::INTEGER,
    ROUND((95 + random() * 4)::NUMERIC, 2),
    (rn * 35 + random() * 80)::INTEGER,
    ROUND((random() * 10)::NUMERIC, 3),
    (78 + random() * 20)::INTEGER,
    jsonb_build_object(
        'device_uid', '11111111-1111-1111-1111-111111111111',
        'serial_number', 'FAKE-BRACELET-001',
        'source', 'seed',
        'profile', 'ryad_24h'
    ),
    'seed/bracelet/ryad',
    captured_at + INTERVAL '2 seconds'
FROM numbered;

-- ============================================================
-- Measurements for Alice
-- Last 7 days, one point every hour
-- ============================================================

WITH series AS (
    SELECT
        generate_series(
            NOW() - INTERVAL '7 days',
            NOW(),
            INTERVAL '1 hour'
        ) AS captured_at
),
numbered AS (
    SELECT
        captured_at,
        ROW_NUMBER() OVER (ORDER BY captured_at) AS rn
    FROM series
)
INSERT INTO biometrics_measurements (
    user_id,
    device_uid,
    serial_number,
    display_name,
    mac_address,
    captured_at,
    heart_rate_bpm,
    spo2_percent,
    step_count,
    motion_level,
    signal_quality,
    raw_payload,
    source_topic,
    received_at
)
SELECT
    (SELECT id FROM users WHERE email = 'alice@example.com'),
    '22222222-2222-2222-2222-222222222222',
    'FAKE-BRACELET-002',
    'Bracelet Alice',
    'AA:BB:CC:DD:EE:02',
    captured_at,
    (62 + random() * 32)::INTEGER,
    ROUND((94 + random() * 5)::NUMERIC, 2),
    (rn * 120 + random() * 250)::INTEGER,
    ROUND((random() * 8)::NUMERIC, 3),
    (70 + random() * 25)::INTEGER,
    jsonb_build_object(
        'device_uid', '22222222-2222-2222-2222-222222222222',
        'serial_number', 'FAKE-BRACELET-002',
        'source', 'seed',
        'profile', 'alice_7d'
    ),
    'seed/bracelet/alice',
    captured_at + INTERVAL '3 seconds'
FROM numbered;

-- ============================================================
-- Measurements for Thomas
-- Last 30 days, one point every 6 hours
-- ============================================================

WITH series AS (
    SELECT
        generate_series(
            NOW() - INTERVAL '30 days',
            NOW(),
            INTERVAL '6 hours'
        ) AS captured_at
),
numbered AS (
    SELECT
        captured_at,
        ROW_NUMBER() OVER (ORDER BY captured_at) AS rn
    FROM series
)
INSERT INTO biometrics_measurements (
    user_id,
    device_uid,
    serial_number,
    display_name,
    mac_address,
    captured_at,
    heart_rate_bpm,
    spo2_percent,
    step_count,
    motion_level,
    signal_quality,
    raw_payload,
    source_topic,
    received_at
)
SELECT
    (SELECT id FROM users WHERE email = 'thomas@example.com'),
    '33333333-3333-3333-3333-333333333333',
    'FAKE-BRACELET-003',
    'Bracelet Thomas',
    'AA:BB:CC:DD:EE:03',
    captured_at,
    (58 + random() * 36)::INTEGER,
    ROUND((93 + random() * 6)::NUMERIC, 2),
    (rn * 300 + random() * 600)::INTEGER,
    ROUND((random() * 6)::NUMERIC, 3),
    (60 + random() * 30)::INTEGER,
    jsonb_build_object(
        'device_uid', '33333333-3333-3333-3333-333333333333',
        'serial_number', 'FAKE-BRACELET-003',
        'source', 'seed',
        'profile', 'thomas_30d',
        'heart_rate_bpm', (58 + random() * 36)::INTEGER,
        'spo2_percent', ROUND((93 + random() * 6)::NUMERIC, 2),
        'step_count', (rn * 300 + random() * 600)::INTEGER
    ),
    'seed/bracelet/thomas',
    captured_at + INTERVAL '5 seconds'
FROM numbered;

-- ============================================================
-- Quick verification
-- ============================================================

SELECT 'users' AS table_name, COUNT(*) AS count FROM users
UNION ALL
SELECT 'biometrics_measurements' AS table_name, COUNT(*) AS count FROM biometrics_measurements;

-- ============================================================
-- Detail verification per user
-- ============================================================

SELECT
    u.id AS user_id,
    u.email,
    u.username,
    COUNT(m.id) AS measurements_count,
    MIN(m.captured_at) AS first_measurement,
    MAX(m.captured_at) AS last_measurement
FROM users u
LEFT JOIN biometrics_measurements m ON m.user_id = u.id
GROUP BY u.id, u.email, u.username
ORDER BY u.id;
