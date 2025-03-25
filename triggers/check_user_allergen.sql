CREATE OR REPLACE FUNCTION check_user_allergen()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM m2m_usr_alg ua
        JOIN m2m_ing_alg ia ON ua.mua_alg_id = ia.mia_alg_id
        WHERE ua.mua_usr_id = NEW.mui_usr_id 
          AND ia.mia_ing_id = NEW.mui_ing_id
    ) THEN
        RAISE WARNING 'User % has allergy to ingredient %', NEW.mui_usr_id, NEW.mui_ing_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER trg_warn_allergic_ingredient
BEFORE INSERT OR UPDATE ON m2m_usr_ing
FOR EACH ROW EXECUTE FUNCTION check_user_allergen();