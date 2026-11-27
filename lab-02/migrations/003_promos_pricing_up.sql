BEGIN;

ALTER TABLE tariffs
ADD COLUMN evening_price numeric;

-- Сохраняем существующую цену как начальную вечернюю.
UPDATE tariffs
SET evening_price = price_per_hour;

ALTER TABLE tariffs
ALTER COLUMN evening_price SET NOT NULL;

ALTER TABLE tariffs
ADD CONSTRAINT tariffs_evening_price_check
CHECK (evening_price >= 0);


CREATE TABLE promo_codes (
    promo_code_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code text NOT NULL UNIQUE
        CHECK (code <> '' AND code = upper(btrim(code))),
    discount_percent numeric NOT NULL
        CHECK (discount_percent > 0 AND discount_percent <= 100),
    is_active boolean NOT NULL DEFAULT true
);

ALTER TABLE payments
ADD COLUMN promo_code_id integer
    REFERENCES promo_codes (promo_code_id) ON DELETE RESTRICT;

COMMIT;