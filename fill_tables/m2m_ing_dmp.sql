INSERT INTO m2m_ing_dmp (mid_dmp_id, mid_ing_id, mid_quantity, mid_quantity_type)
SELECT 
    (random() * 49 + 1)::int, 
    (random() * 49 + 1)::int, 
    (random() * 100 + 1)::int,
    (ARRAY['grams','milliliters','pieces','liters'])[(random() * 3 + 1)::int]
FROM generate_series(1, 100);