INSERT INTO actual_day_meal (adm_date, adm_usr_id)
SELECT
    DATE '2024-01-01' + (random() * 180)::integer * INTERVAL '1 day',
    (random() * 49 + 1)::integer
FROM generate_series(1,200);