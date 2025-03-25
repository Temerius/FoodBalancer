CREATE OR REPLACE FUNCTION validate_user_age()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usr_age IS NOT NULL AND (NEW.usr_age < 1 OR NEW.usr_age > 150) THEN
        RAISE EXCEPTION 'Invalid age (1-150 years allowed) for user %', NEW.usr_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_check_age
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE FUNCTION validate_user_age();