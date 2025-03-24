INSERT INTO m2m_ing_spl (mis_quantity, mis_spl_id, mis_igt_id, mis_quantity_type)
SELECT 
    (random() * 10 + 1)::int,
    (random() * 49 + 1)::int,   
    (random() * 49 + 1)::int,   
    CASE 
        WHEN mis_igt_id BETWEEN 40 AND 49 THEN 
            (ARRAY['milliliters','liters'])[(random() > 0.5)::int + 1]
        WHEN mis_igt_id IN (41, 17, 35, 36, 37) THEN 'grams'
        ELSE 
            (ARRAY['grams','pieces'])[(random() > 0.5)::int + 1]
    END
FROM generate_series(1, 250);