CREATE OR REPLACE VIEW user_shopping_list AS
SELECT 
  spl_usr_id AS user_id,
  json_agg(json_build_object(
    'ingredient_type', it.igt_name,
    'quantity', mis.mis_quantity,
    'quantity_type', mis.mis_quantity_type
  )) AS items
FROM shopping_list spl
JOIN m2m_ing_spl mis ON mis.mis_spl_id = spl.spl_id
JOIN ingredient_type it ON it.igt_id = mis.mis_igt_id
GROUP BY spl_usr_id;