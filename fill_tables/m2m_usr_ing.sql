INSERT INTO m2m_usr_ing (mui_usr_id, mui_ing_id, mui_quantity, mui_quantity_type)
SELECT 
    (random() * 49 + 1)::integer,
    ing_id,
    CASE 
        WHEN quantity_type = 'milliliters' THEN (random() * 900 + 100)::integer 
        WHEN quantity_type = 'pieces' THEN (random() * 4 + 1)::integer
        ELSE CASE
            WHEN category = 'spice' THEN (random() * 450 + 50)::integer
            WHEN category = 'grain' THEN (random() * 1950 + 50)::integer
            ELSE (random() * 950 + 50)::integer
        END
    END,
    quantity_type::quantity_enum 
FROM (
    SELECT 
        ing_id,
        CASE 
            WHEN ing_id IN (31,32,33,34,35,36,37,38,42) THEN 'pieces'::quantity_enum
            WHEN ing_id IN (49,50) THEN 'milliliters'::quantity_enum
            WHEN ing_id BETWEEN 39 AND 48 THEN 'grams'::quantity_enum
            ELSE 'grams'::quantity_enum
        END as quantity_type,
        CASE 
            WHEN ing_id = 11 THEN 'grain'
            WHEN ing_id BETWEEN 39 AND 48 THEN 'spice'
            ELSE 'vegetable' 
        END as category
    FROM ingredient
) AS prepared_data
CROSS JOIN generate_series(1,5)
ON CONFLICT DO NOTHING;