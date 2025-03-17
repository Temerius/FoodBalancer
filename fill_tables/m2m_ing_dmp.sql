INSERT INTO m2m_ing_dmp (mid_dmp_id, mid_ing_id, mid_quantity)
SELECT
    dmp_id,
    (random() * 49 + 1)::integer, 
    (random() * 450 + 50)::integer 
FROM daily_meal_plan
CROSS JOIN LATERAL (
    SELECT generate_series(1, (random() * 5 + 3)::integer)
) AS ingredients(n)
ON CONFLICT DO NOTHING;