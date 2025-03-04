-- Seed script for Clients and Projects tables

-- Delete existing data to ensure clean slate
DELETE FROM projects;
DELETE FROM clients;

-- Insert Clients (separate INSERT statements)
INSERT INTO clients (client_name, contact_email, contact_phone, address) 
VALUES ('Client Alpha', 'alpha@example.com', '+1234567890', '123 Alpha St');

INSERT INTO clients (client_name, contact_email, contact_phone, address) 
VALUES ('Client Beta', 'beta@example.com', '+0987654321', '456 Beta Ave');

INSERT INTO clients (client_name, contact_email, contact_phone, address) 
VALUES ('Client Gamma', 'gamma@example.com', '+1122334455', '789 Gamma Rd');

INSERT INTO clients (client_name, contact_email, contact_phone, address) 
VALUES ('Client Delta', 'delta@example.com', '+5544332211', '321 Delta Blvd');

-- Insert Projects
DECLARE 
    v_alpha_client_id NUMBER;
    v_beta_client_id NUMBER;
    v_gamma_client_id NUMBER;
BEGIN
    -- Get client IDs
    SELECT client_id INTO v_alpha_client_id 
    FROM clients 
    WHERE client_name = 'Client Alpha';

    SELECT client_id INTO v_beta_client_id 
    FROM clients 
    WHERE client_name = 'Client Beta';

    SELECT client_id INTO v_gamma_client_id 
    FROM clients 
    WHERE client_name = 'Client Gamma';

    -- Insert Projects for Alpha client
    INSERT INTO projects (project_name, start_date, end_date, client_id)
    VALUES ('Project X', TO_DATE('2025-02-15', 'YYYY-MM-DD'), NULL, v_alpha_client_id);

    INSERT INTO projects (project_name, start_date, end_date, client_id)
    VALUES ('Project Y', TO_DATE('2025-03-20', 'YYYY-MM-DD'), NULL, v_alpha_client_id);

    -- Insert Project for Beta client
    INSERT INTO projects (project_name, start_date, end_date, client_id)
    VALUES ('Project Z', TO_DATE('2025-04-10', 'YYYY-MM-DD'), NULL, v_beta_client_id);

    -- For nested_select.json (projects for clients starting with 'Client')
    INSERT INTO projects (project_name, start_date, end_date, client_id)
    VALUES ('Nested Project 1', TO_DATE('2024-01-01', 'YYYY-MM-DD'), NULL, v_gamma_client_id);

    -- For exist_select.json (projects with a specific client_id)
    INSERT INTO projects (project_name, start_date, end_date, client_id)
    VALUES ('Exist Project', TO_DATE('2024-06-15', 'YYYY-MM-DD'), NULL, v_alpha_client_id);
END;
/

-- Commit the changes
COMMIT;