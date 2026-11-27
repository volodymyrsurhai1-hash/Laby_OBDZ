BEGIN;

DROP TRIGGER clubs_check_max_places ON clubs;
DROP FUNCTION check_club_max_places();

DROP TRIGGER pcs_check_club_capacity ON pcs;
DROP FUNCTION check_pc_capacity();

ALTER TABLE clubs
DROP COLUMN max_places;

COMMIT;