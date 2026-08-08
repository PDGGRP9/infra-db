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
-- Seed bracelets
-- One bracelet per user because user_id is UNIQUE
-- ============================================================

INSERT INTO bracelets (
    user_id,
    device_uid,
    serial_number,
    display_name,
    firmware_version,
    mac_address,
    status,
    paired_at,
    last_seen_at
)
VALUES
    (
        (SELECT id FROM users WHERE email = 'ryad@example.com'),
        '11111111-1111-1111-1111-111111111111',
        'FAKE-BRACELET-001',
        'Bracelet de test Ryad',
        '1.0.3',
        'AA:BB:CC:DD:EE:01',
        'active',
        NOW() - INTERVAL '7 days',
        NOW()
    ),
    (
        (SELECT id FROM users WHERE email = 'alice@example.com'),
        '22222222-2222-2222-2222-222222222222',
        'FAKE-BRACELET-002',
        'Bracelet Alice',
        '1.0.2',
        'AA:BB:CC:DD:EE:02',
        'active',
        NOW() - INTERVAL '14 days',
        NOW() - INTERVAL '5 minutes'
    ),
    (
        (SELECT id FROM users WHERE email = 'thomas@example.com'),
        '33333333-3333-3333-3333-333333333333',
        'FAKE-BRACELET-003',
        'Bracelet Thomas',
        '0.9.8',
        'AA:BB:CC:DD:EE:03',
        'inactive',
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '2 hours'
    )
ON CONFLICT (serial_number) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    device_uid = EXCLUDED.device_uid,
    display_name = EXCLUDED.display_name,
    firmware_version = EXCLUDED.firmware_version,
    mac_address = EXCLUDED.mac_address,
    status = EXCLUDED.status,
    paired_at = EXCLUDED.paired_at,
    last_seen_at = EXCLUDED.last_seen_at,
    updated_at = NOW();

-- ============================================================
-- Optional cleanup of previous seed measurements
-- Useful if you manually rerun this script
-- ============================================================

DELETE FROM biometrics_measurements bm
USING bracelets b
WHERE bm.bracelet_id = b.id
  AND b.serial_number IN (
      'FAKE-BRACELET-001',
      'FAKE-BRACELET-002',
      'FAKE-BRACELET-003'
  )
  AND bm.source_topic LIKE 'seed/%';

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
    bracelet_id,
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
    (SELECT id FROM bracelets WHERE serial_number = 'FAKE-BRACELET-001'),
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
    bracelet_id,
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
    (SELECT id FROM bracelets WHERE serial_number = 'FAKE-BRACELET-002'),
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
    bracelet_id,
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
    (SELECT id FROM bracelets WHERE serial_number = 'FAKE-BRACELET-003'),
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
SELECT 'bracelets' AS table_name, COUNT(*) AS count FROM bracelets
UNION ALL
SELECT 'biometrics_measurements' AS table_name, COUNT(*) AS count FROM biometrics_measurements;

-- ============================================================
-- Detail verification per user
-- ============================================================

SELECT
    u.id AS user_id,
    u.email,
    u.username,
    b.serial_number,
    b.display_name,
    b.status,
    COUNT(m.id) AS measurements_count,
    MIN(m.captured_at) AS first_measurement,
    MAX(m.captured_at) AS last_measurement
FROM users u
LEFT JOIN bracelets b ON b.user_id = u.id
LEFT JOIN biometrics_measurements m ON m.bracelet_id = b.id
GROUP BY
    u.id,
    u.email,
    u.username,
    b.serial_number,
    b.display_name,
    b.status
ORDER BY u.id;