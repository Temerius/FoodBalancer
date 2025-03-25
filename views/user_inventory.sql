CREATE OR REPLACE VIEW user_inventory AS
SELECT 
  u.usr_id,
  i.ing_name,
  mui.mui_quantity,
  mui.mui_quantity_type
FROM "user" u
JOIN m2m_usr_ing mui ON mui.mui_usr_id = u.usr_id
JOIN ingredient i ON i.ing_id = mui.mui_ing_id;