INSERT INTO m2m_usr_eqp (mue_usr_id, mue_eqp_id)
SELECT 
    usr_id, 
    (random() * 49 + 1)::integer
FROM generate_series(1, 50) as usr_id;

INSERT INTO m2m_usr_eqp (mue_usr_id, mue_eqp_id)
SELECT
    (random() * 49 + 1)::integer,
    (random() * 49 + 1)::integer
FROM generate_series(1, 100)
ON CONFLICT DO NOTHING;