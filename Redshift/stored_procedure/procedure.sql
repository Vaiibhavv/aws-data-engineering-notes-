-- syntax
create or replace example1() AS
$$
BEGIN
    statements;
EXCEPTION
    WHEN OTHER THEN
    statements;
END;
$$
LANGUAGE plpgsql

--Atomic
/* 
The atomic stored procedure in redshift runs all statement in single transaction,
 if any statment fails, rollback the entire procedure. 
*/ 


CREATE OR REPLACE PROCEDURE update_employee_salary(emp_id INT, increment_amount DECIMAL(10, 2))
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update the salary for the specified employee
    UPDATE employees
    SET salary = salary + increment_amount
    WHERE employee_id = emp_id;

    -- Optional: Log the salary update
    INSERT INTO salary_updates_log (employee_id, updated_salary, update_time)
    VALUES (emp_id, (SELECT salary FROM employees WHERE employee_id = emp_id), SYSDATE);
END;
$$;

-- Non Atomic
/* 
In non atomic procedure the each statement is runs individually, if one fails, it markes as failed
and continue with the next statement.

non-atomic stored procedure allows you to process each 
date in its own transaction, enabling success or failure to be logged individually,
his approach ensures that even if one date fails, the procedure can continue processing subsequent dates without interruption.


*/ 
CREATE OR REPLACE PROCEDURE non_atomic_example()
EXECUTE AS CALLER
LANGUAGE plpgsql
AS $$
DECLARE
    error_message TEXT;
BEGIN
    -- Block 1
    BEGIN
        INSERT INTO table1 VALUES (1);
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
            INSERT INTO logs (message) VALUES ('Error in table1: ' || error_message);
    END;

    -- Block 2
    BEGIN
        INSERT INTO table2 VALUES (2);
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
            INSERT INTO logs (message) VALUES ('Error in table2: ' || error_message);
    END;

    -- Block 3
    BEGIN
        INSERT INTO table3 VALUES (3);
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
            INSERT INTO logs (message) VALUES ('Error in table3: ' || error_message);
    END;
END;
$$;

--advanced

create procedure access_sql_execution()
    language plpgsql
as
$$
BEGIN
    DECLARE
        sql_cmd RECORD;
    BEGIN
        FOR sql_cmd IN EXECUTE
                        'select distinct sql_cmd from table’
            LOOP
                EXECUTE sql_cmd.sql_cmd;
            END LOOP;
    exception
        when others then
            insert into error table;
            VALUES (sql_execution’, 'Error message: ' || SQLERRM);
    END;
END;


-- to run the stored procedure in redshift then  call the stored procedure name 
access_sql_execution();