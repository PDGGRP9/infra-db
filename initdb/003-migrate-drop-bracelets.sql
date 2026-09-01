-- Migration from the old schema (separate "bracelets" table + pairing) to the
-- new one (a measurement belongs directly to a user).
--
-- This file ships in the image and sits in /docker-entrypoint-initdb.d/, so it
-- also runs on a brand-new database — but 001-schema.sql already creates the new
-- shape there, so the whole thing is guarded on "does the bracelets table still
-- exist" and is a no-op on a fresh install.
--
-- On an ALREADY RUNNING deployment (initdb/*.sql does NOT re-run on an existing
-- volume) run it by hand once, before deploying the new backend/app release:
--
--   docker compose exec -T db psql -U <user> -d bracelet_connecte \
--       -f /docker-entrypoint-initdb.d/003-migrate-drop-bracelets.sql
--
-- Test data, so it keeps things simple: measurements whose bracelet was already
-- paired are carried over to that user, anything else (never paired) is dropped
-- rather than reassigned by hand.

BEGIN;

DO $migrate$
BEGIN
    IF to_regclass('public.bracelets') IS NULL THEN
        RAISE NOTICE 'no bracelets table — nothing to migrate';
        RETURN;
    END IF;

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

    CREATE INDEX IF NOT EXISTS idx_biometrics_measurements_user_captured_at
        ON biometrics_measurements(user_id, captured_at DESC);

    DROP TABLE bracelets;
END
$migrate$;

COMMIT;
