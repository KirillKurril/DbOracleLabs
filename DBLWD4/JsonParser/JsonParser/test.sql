
-- Тестовые запросы для демонстрации работы JSON-парсера
-- Тема: База данных аэропорта

-- 1. Простой SELECT-запрос
DECLARE
  v_cursor SYS_REFCURSOR;
BEGIN
  v_cursor := dynamic_sql_pkg.process_json_query(
    '{
      "queryType": "SELECT",
      "columns": ["flight_number", "departure_city", "arrival_city", "status"],
      "tables": ["airport_flights"],
      "where": {
        "conditions": [
          {
            "column": "status",
            "operator": "=",
            "value": "Scheduled",
            "type": "string"
          }
        ]
      }
    }'
  );
  DBMS_SQL.RETURN_RESULT(v_cursor);
END;
/

-- 2. SELECT с JOIN и вложенным подзапросом (IN)
DECLARE
  v_cursor SYS_REFCURSOR;
BEGIN
  v_cursor := dynamic_sql_pkg.process_json_query(
    '{
      "queryType": "SELECT",
      "columns": ["f.flight_number", "a.airline_name", "f.departure_city", "f.arrival_city"],
      "tables": ["airport_flights f"],
      "joins": [
        {
          "type": "INNER JOIN",
          "table": "airport_aircraft ac",
          "condition": "f.aircraft_id = ac.aircraft_id"
        },
        {
          "type": "INNER JOIN",
          "table": "airport_airlines a",
          "condition": "ac.airline_id = a.airline_id"
        }
      ],
      "where": {
        "conditions": [
          {
            "column": "f.flight_id",
            "operator": "IN",
            "subquery": {
              "queryType": "SELECT",
              "columns": ["flight_id"],
              "tables": ["airport_tickets"],
              "where": {
                "conditions": [
                  {
                    "column": "price",
                    "operator": ">",
                    "value": "1000",
                    "type": "number"
                  }
                ]
              }
            }
          }
        ]
      }
    }'
  );
  DBMS_SQL.RETURN_RESULT(v_cursor);
END;
/

-- 3. DML: INSERT с подзапросом
DECLARE
  v_cursor SYS_REFCURSOR;
BEGIN
  v_cursor := dynamic_sql_pkg.process_json_query(
    '{
      "queryType": "INSERT",
      "table": "airport_tickets",
      "columns": ["ticket_id", "flight_id", "passenger_id", "seat_number", "price", "booking_date"],
      "values": ["6", "1", "3", "''15C''", "500.00", "SYSDATE"]
    }'
  );
END;
/

-- 4. DML: UPDATE с условием EXISTS
DECLARE
  v_cursor SYS_REFCURSOR;
BEGIN
  v_cursor := dynamic_sql_pkg.process_json_query(
    '{
      "queryType": "UPDATE",
      "table": "airport_flights",
      "set_clause": "status = ''Delayed''",
      "where": {
        "conditions": [
          {
            "operator": "EXISTS",
            "subquery": {
              "queryType": "SELECT",
              "columns": ["1"],
              "tables": ["airport_tickets t"],
              "where": {
                "conditions": [
                  {
                    "column": "t.flight_id",
                    "operator": "=",
                    "value": "airport_flights.flight_id"
                  },
                  {
                    "logicalOperator": "AND",
                    "column": "t.price",
                    "operator": ">",
                    "value": "1000",
                    "type": "number"
                  }
                ]
              }
            }
          }
        ]
      }
    }'
  );
END;
/

-- 5. DDL: CREATE TABLE с автоинкрементным первичным ключом
DECLARE
  v_cursor SYS_REFCURSOR;
BEGIN
  v_cursor := dynamic_sql_pkg.process_json_query(
    '{
      "queryType": "CREATE TABLE",
      "table": "airport_crew",
      "columns": [
        {
          "name": "crew_id",
          "type": "NUMBER",
          "constraints": ["PRIMARY KEY"]
        },
        {
          "name": "flight_id",
          "type": "NUMBER",
          "constraints": ["REFERENCES airport_flights(flight_id)"]
        },
        {
          "name": "employee_name",
          "type": "VARCHAR2(100)",
          "constraints": ["NOT NULL"]
        },
        {
          "name": "position",
          "type": "VARCHAR2(50)",
          "constraints": ["NOT NULL"]
        }
      ],
      "primaryKey": "crew_id"
    }'
  );
END;
/

-- 6. DDL: DROP TABLE
DECLARE
  v_cursor SYS_REFCURSOR;
BEGIN
  v_cursor := dynamic_sql_pkg.process_json_query(
    '{
      "queryType": "DROP TABLE",
      "table": "airport_crew",
      "removeConstraints": true
    }'
  );
END;
/