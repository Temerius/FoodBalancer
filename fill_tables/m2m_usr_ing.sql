INSERT INTO m2m_usr_ing (mui_usr_id, mui_ing_id, mui_quantity, mui_quantity_type)
SELECT 
    (random() * 49 + 1)::integer,
    (random() * 49 + 1)::integer,
    (random() * 9 + 1)::integer,
    (ARRAY['grams','milliliters','liters','pieces','tablespoons','teaspoons','cups']::quantity_enum[])[floor(random() * 7) + 1]
FROM generate_series(1,250)
ON CONFLICT DO NOTHING;