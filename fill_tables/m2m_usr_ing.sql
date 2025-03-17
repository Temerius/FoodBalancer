INSERT INTO m2m_usr_ing (mui_usr_id, mui_ing_id, mui_quantity)
SELECT 
    (random() * 49 + 1)::integer,
    (random() * 49 + 1)::integer,
    (random() * 9 + 1)::integer
FROM generate_series(1,250)
ON CONFLICT (mui_usr_id, mui_ing_id) DO NOTHING;