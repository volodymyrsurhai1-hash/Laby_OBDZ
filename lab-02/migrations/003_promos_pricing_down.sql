BEGIN;

ALTER TABLE payments
DROP COLUMN promo_code_id;

DROP TABLE promo_codes;

ALTER TABLE tariffs
DROP COLUMN evening_price;

COMMIT;