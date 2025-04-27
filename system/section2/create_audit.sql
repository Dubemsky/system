-- Create audit role
CREATE ROLE auditor WITH NOLOGIN;

-- Create audit tables for position changes
CREATE TABLE position_audit_log (
    audit_id SERIAL PRIMARY KEY,
    operation VARCHAR(10) NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_name VARCHAR(100) NOT NULL,
    position_id INTEGER,
    company_id INTEGER,
    portfolio_id INTEGER,
    old_stock_held INTEGER,
    new_stock_held INTEGER
);

-- Create audit trigger function
CREATE OR REPLACE FUNCTION audit_position_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO position_audit_log(operation, user_name, position_id, company_id, portfolio_id, old_stock_held, new_stock_held)
        VALUES('DELETE', current_user, OLD.position_id, OLD.company_id, OLD.portfolio_id, OLD.stock_held, NULL);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO position_audit_log(operation, user_name, position_id, company_id, portfolio_id, old_stock_held, new_stock_held)
        VALUES('UPDATE', current_user, NEW.position_id, NEW.company_id, NEW.portfolio_id, OLD.stock_held, NEW.stock_held);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO position_audit_log(operation, user_name, position_id, company_id, portfolio_id, old_stock_held, new_stock_held)
        VALUES('INSERT', current_user, NEW.position_id, NEW.company_id, NEW.portfolio_id, NULL, NEW.stock_held);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on positions table
CREATE TRIGGER position_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON positions
FOR EACH ROW EXECUTE FUNCTION audit_position_changes();

-- Grant permissions for the auditor role
GRANT SELECT ON position_audit_log TO auditor;