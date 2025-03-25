CREATE OR REPLACE FUNCTION validate_user_email()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usr_mail IS NOT NULL AND NEW.usr_mail !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
        RAISE EXCEPTION 'Invalid email format for user %', NEW.usr_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create or replace TRIGGER trg_check_email
BEFORE INSERT OR UPDATE ON "user"
FOR EACH ROW EXECUTE FUNCTION validate_user_email();