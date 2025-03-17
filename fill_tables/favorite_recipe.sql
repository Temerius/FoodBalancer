INSERT INTO favorite_recipe (fvr_usr_id, fvr_rcp_id)
SELECT 
    usr_id,
    (random() * 49 + 1)::integer
FROM generate_series(1,50) AS usr_id;

INSERT INTO favorite_recipe (fvr_usr_id, fvr_rcp_id)
SELECT
    (random() * 49 + 1)::integer,
    (random() * 49 + 1)::integer
FROM generate_series(1,100);