INSERT INTO weakly_meal_plan (wmp_start, wmp_end, wmp_usr_id)
SELECT
    start_date,
    start_date + INTERVAL '6 days' AS end_date,
    (random() * 49 + 1)::integer
FROM (
    SELECT DATE '2024-01-01' + (random() * 180)::integer * INTERVAL '1 day' AS start_date
    FROM generate_series(1, 150)
) AS subquery;