-- One-off migration for an ALREADY RUNNING database (postgres only runs
-- initdb/*.sql on a brand-new, empty volume — an existing deployment needs
-- this run by hand, once, before deploying the new backend/app release):
--
--   docker compose exec -T db psql -U <user> -d bracelet_connecte \
--       < initdb/003-migrate-drop-bracelets.sql
--
-- Drops the "bracelets" table and the appairage/pairing step that went with
-- it: biometrics_measurements now belongs directly to a user, with the
-- device identity kept as plain columns instead of a foreign key.
--
-- Test data, so this keeps it simple: measurements whose bracelet was
-- already paired are carried over to that user, anything else (never
-- paired) is just dropped rather than reassigned by hand.

BEGIN;

ALTER TABLE biometrics_measurements
    ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS device_uid TEXT,
    ADD COLUMN IF NOT EXISTS serial_number TEXT,
    ADD COLUMN IF NOT EXISTS display_name TEXT,
    ADD COLUMN IF NOT EXISTS mac_address TEXT;

UPDATE biometrics_measurements m
SET user_id       = b.user_id,
    device_uid    = b.device_uid::text,
    serial_number = b.serial_number,
    display_name  = b.display_name,
    mac_address   = b.mac_address
FROM bracelets b
WHERE m.bracelet_id = b.id;

DELETE FROM biometrics_measurements WHERE user_id IS NULL;

ALTER TABLE biometrics_measurements
    ALTER COLUMN user_id SET NOT NULL,
    DROP COLUMN IF EXISTS bracelet_id;

CREATE INDEX IF NOT EXISTS idx_biometrics_measurements_user_captured_at ON biometrics_measurements(user_id, captured_at DESC);

DROP TABLE IF EXISTS bracelets;

COMMIT;
