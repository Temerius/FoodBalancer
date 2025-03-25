CREATE OR REPLACE FUNCTION validate_user_height()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usr_height IS NOT NULL AND (NEW.usr_height < 50 OR NEW.usr_height > 250) THEN
        RAISE EXCEPTION 'Invalid height (35-255 cm allowed) for user %', NEW.usr_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE or replace TRIGGER trg_check_height
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE FUNCTION validate_user_height();