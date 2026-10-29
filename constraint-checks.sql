-- Перевірки очікуваних обмежень. Виконувати після міграції up.
-- Усі тестові дані відкочуються наприкінці.
BEGIN;

DO $$
DECLARE
    test_tariff_id integer;
    test_client_id integer;
    test_pc_id integer;
    second_pc_id integer;
    test_reservation_id integer;
    saved_price numeric;
    error_text text;
BEGIN
    INSERT INTO tariffs (name, price_per_hour)
    VALUES ('lab-test-pro', 120)
    RETURNING tariff_id INTO test_tariff_id;

    INSERT INTO clients (full_name, phone)
    VALUES ('Тестовий клієнт', '+380000000001')
    RETURNING client_id INTO test_client_id;

    SELECT COALESCE(MAX(pc_id), 0) + 1 INTO test_pc_id FROM pcs;
    second_pc_id := test_pc_id + 1;

    INSERT INTO pcs (pc_id, tariff_id)
    VALUES (test_pc_id, test_tariff_id), (second_pc_id, test_tariff_id);

    BEGIN
        INSERT INTO clients (full_name, phone)
        VALUES (NULL, '+380000000002');
        RAISE EXCEPTION 'NOT NULL: очікувалася помилка';
    EXCEPTION WHEN not_null_violation THEN
        GET STACKED DIAGNOSTICS error_text = MESSAGE_TEXT;
        RAISE NOTICE 'PASS NOT NULL: %', error_text;
    END;

    BEGIN
        INSERT INTO clients (full_name, phone)
        VALUES ('Інший клієнт', '+380000000001');
        RAISE EXCEPTION 'UNIQUE: очікувалася помилка';
    EXCEPTION WHEN unique_violation THEN
        GET STACKED DIAGNOSTICS error_text = MESSAGE_TEXT;
        RAISE NOTICE 'PASS UNIQUE: %', error_text;
    END;

    BEGIN
        INSERT INTO tariffs (name, price_per_hour)
        VALUES ('lab-test-negative', -1);
        RAISE EXCEPTION 'CHECK: очікувалася помилка';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS error_text = MESSAGE_TEXT;
        RAISE NOTICE 'PASS CHECK: %, нуль дозволений', error_text;
    END;

    BEGIN
        INSERT INTO pcs (pc_id, tariff_id)
        VALUES (test_pc_id, test_tariff_id);
        RAISE EXCEPTION 'PRIMARY KEY: очікувалася помилка';
    EXCEPTION WHEN unique_violation THEN
        GET STACKED DIAGNOSTICS error_text = MESSAGE_TEXT;
        RAISE NOTICE 'PASS PRIMARY KEY: %', error_text;
    END;

    BEGIN
        INSERT INTO reservations (
            client_id, pc_id, starts_at, ends_at, agreed_price_per_hour
        )
        VALUES (
            -1, test_pc_id, '2030-01-01 10:00+00', '2030-01-01 11:00+00', 0
        );
        RAISE EXCEPTION 'FOREIGN KEY: очікувалася помилка';
    EXCEPTION WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS error_text = MESSAGE_TEXT;
        RAISE NOTICE 'PASS FOREIGN KEY: %', error_text;
    END;

    BEGIN
        INSERT INTO reservations (
            client_id, pc_id, starts_at, ends_at, agreed_price_per_hour
        )
        VALUES (
            test_client_id, test_pc_id,
            '2030-01-01 11:00+00', '2030-01-01 10:00+00', 0
        );
        RAISE EXCEPTION 'CHECK interval: очікувалася помилка';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS error_text = MESSAGE_TEXT;
        RAISE NOTICE 'PASS CHECK: %', error_text;
    END;

    INSERT INTO reservations (
        client_id, pc_id, starts_at, ends_at, agreed_price_per_hour
    )
    VALUES (
        test_client_id, test_pc_id,
        '2030-01-01 10:00+00', '2030-01-01 12:00+00', 0
    )
    RETURNING reservation_id INTO test_reservation_id;

    BEGIN
        INSERT INTO reservations (
            client_id, pc_id, starts_at, ends_at, agreed_price_per_hour
        )
        VALUES (
            test_client_id, test_pc_id,
            '2030-01-01 11:00+00', '2030-01-01 13:00+00', 0
        );
        RAISE EXCEPTION 'EXCLUDE: очікувалася помилка';
    EXCEPTION WHEN exclusion_violation THEN
        GET STACKED DIAGNOSTICS error_text = MESSAGE_TEXT;
        RAISE NOTICE 'PASS EXCLUDE: %', error_text;
    END;

    -- Початок другої броні дорівнює завершенню першої.
    INSERT INTO reservations (
        client_id, pc_id, starts_at, ends_at, agreed_price_per_hour
    )
    VALUES (
        test_client_id, test_pc_id,
        '2030-01-01 12:00+00', '2030-01-01 13:00+00', 0
    );
    RAISE NOTICE 'PASS ADJACENT: броні, що стикуються, дозволені';

    -- Скасована бронь не займає ПК.
    INSERT INTO reservations (
        client_id, pc_id, starts_at, ends_at, status, agreed_price_per_hour
    )
    VALUES (
        test_client_id, second_pc_id,
        '2030-01-01 10:00+00', '2030-01-01 12:00+00', 'cancelled', 0
    );
    INSERT INTO reservations (
        client_id, pc_id, starts_at, ends_at, agreed_price_per_hour
    )
    VALUES (
        test_client_id, second_pc_id,
        '2030-01-01 10:00+00', '2030-01-01 12:00+00', 0
    );
    RAISE NOTICE 'PASS CANCELLED: скасована бронь не блокує час';

    UPDATE tariffs
    SET price_per_hour = 180
    WHERE tariff_id = test_tariff_id;

    SELECT agreed_price_per_hour
    INTO saved_price
    FROM reservations
    WHERE reservation_id = test_reservation_id;

    IF saved_price <> 120 THEN
        RAISE EXCEPTION 'Очікувалася зафіксована ціна 120, отримано %', saved_price;
    END IF;
    RAISE NOTICE 'PASS PRICE SNAPSHOT: зміна тарифу не змінює стару бронь';

    UPDATE pcs SET is_active = false WHERE pc_id = test_pc_id;

    BEGIN
        INSERT INTO reservations (
            client_id, pc_id, starts_at, ends_at, agreed_price_per_hour
        )
        VALUES (
            test_client_id, test_pc_id,
            '2030-01-02 10:00+00', '2030-01-02 11:00+00', 0
        );
        RAISE EXCEPTION 'INACTIVE PC: очікувалася помилка';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS error_text = MESSAGE_TEXT;
        RAISE NOTICE 'PASS ACTIVE PC: %', error_text;
    END;
END;
$$;

ROLLBACK;
