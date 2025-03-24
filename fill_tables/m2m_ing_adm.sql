INSERT INTO m2m_ing_adm (mia_adm_id, mia_ing_id, mia_quantity, mia_quantity_type)
SELECT
    adm_id,
    (random() * 49 + 1)::integer,
    (random() * 450 + 50)::integer,
    (array['grams','milliliters','liters','pieces'])[floor(random() * 4) + 1]
FROM actual_day_meal
CROSS JOIN LATERAL (
    SELECT generate_series(1, (random() * 3 + 2)::integer)
) AS consumed(n)
WHERE random() < 0.8
ON CONFLICT DO NOTHING;