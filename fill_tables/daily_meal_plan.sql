INSERT INTO daily_meal_plan (dmp_date, dmp_cal_day, dmp_wmp_id)
SELECT
    wmp_start + (n || ' days')::INTERVAL AS day_date,
    1500 + (random() * 1000)::integer,
    wmp_id
FROM weakly_meal_plan
CROSS JOIN LATERAL generate_series(0,6) AS n;