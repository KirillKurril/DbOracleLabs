
-- Создание и заполнение таблиц для тестирования JSON-парсера
-- Тема: База данных аэропорта

-- Очистка существующих таблиц
BEGIN
   FOR cur_rec IN (SELECT object_name, object_type
                   FROM user_objects
                   WHERE object_type IN ('TABLE','VIEW','PACKAGE','SEQUENCE')
                   AND object_name LIKE 'AIRPORT_%')
   LOOP
      BEGIN
         IF cur_rec.object_type = 'TABLE' THEN
            EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '" CASCADE CONSTRAINTS';
         ELSE
            EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '"';
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
   END LOOP;
END;
/

-- Создание таблиц
CREATE TABLE airport_airlines (
    airline_id NUMBER PRIMARY KEY,
    airline_name VARCHAR2(100),
    country VARCHAR2(50)
);

CREATE TABLE airport_aircraft (
    aircraft_id NUMBER PRIMARY KEY,
    airline_id NUMBER,
    model VARCHAR2(50),
    capacity NUMBER,
    FOREIGN KEY (airline_id) REFERENCES airport_airlines(airline_id)
);

CREATE TABLE airport_flights (
    flight_id NUMBER PRIMARY KEY,
    aircraft_id NUMBER,
    flight_number VARCHAR2(20),
    departure_city VARCHAR2(50),
    arrival_city VARCHAR2(50),
    departure_time TIMESTAMP,
    arrival_time TIMESTAMP,
    status VARCHAR2(20),
    FOREIGN KEY (aircraft_id) REFERENCES airport_aircraft(aircraft_id)
);

CREATE TABLE airport_passengers (
    passenger_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    passport_number VARCHAR2(20),
    nationality VARCHAR2(50)
);

CREATE TABLE airport_tickets (
    ticket_id NUMBER PRIMARY KEY,
    flight_id NUMBER,
    passenger_id NUMBER,
    seat_number VARCHAR2(10),
    price NUMBER(10,2),
    booking_date DATE,
    FOREIGN KEY (flight_id) REFERENCES airport_flights(flight_id),
    FOREIGN KEY (passenger_id) REFERENCES airport_passengers(passenger_id)
);

-- Заполнение таблиц тестовыми данными
-- Авиакомпании
INSERT INTO airport_airlines VALUES (1, 'Aeroflot', 'Russia');
INSERT INTO airport_airlines VALUES (2, 'Lufthansa', 'Germany');
INSERT INTO airport_airlines VALUES (3, 'Emirates', 'UAE');

-- Самолеты
INSERT INTO airport_aircraft VALUES (1, 1, 'Boeing 737', 180);
INSERT INTO airport_aircraft VALUES (2, 1, 'Airbus A320', 150);
INSERT INTO airport_aircraft VALUES (3, 2, 'Boeing 747', 400);
INSERT INTO airport_aircraft VALUES (4, 2, 'Airbus A380', 500);
INSERT INTO airport_aircraft VALUES (5, 3, 'Boeing 777', 350);

-- Рейсы
INSERT INTO airport_flights VALUES (1, 1, 'SU1234', 'Moscow', 'Paris', 
    TIMESTAMP '2024-03-20 10:00:00', TIMESTAMP '2024-03-20 12:00:00', 'Scheduled');
INSERT INTO airport_flights VALUES (2, 3, 'LH5678', 'Berlin', 'London', 
    TIMESTAMP '2024-03-20 11:00:00', TIMESTAMP '2024-03-20 12:30:00', 'Delayed');
INSERT INTO airport_flights VALUES (3, 5, 'EK9012', 'Dubai', 'New York', 
    TIMESTAMP '2024-03-20 15:00:00', TIMESTAMP '2024-03-21 03:00:00', 'Scheduled');

-- Пассажиры
INSERT INTO airport_passengers VALUES (1, 'Ivan', 'Ivanov', 'RU123456', 'Russian');
INSERT INTO airport_passengers VALUES (2, 'John', 'Smith', 'US789012', 'American');
INSERT INTO airport_passengers VALUES (3, 'Hans', 'Mueller', 'DE345678', 'German');
INSERT INTO airport_passengers VALUES (4, 'Mohammed', 'Ahmed', 'AE901234', 'UAE');
INSERT INTO airport_passengers VALUES (5, 'Marie', 'Dubois', 'FR567890', 'French');

-- Билеты
INSERT INTO airport_tickets VALUES (1, 1, 1, '12A', 500.00, DATE '2024-03-15');
INSERT INTO airport_tickets VALUES (2, 1, 2, '12B', 500.00, DATE '2024-03-15');
INSERT INTO airport_tickets VALUES (3, 2, 3, '1A', 750.00, DATE '2024-03-16');
INSERT INTO airport_tickets VALUES (4, 3, 4, '15F', 1200.00, DATE '2024-03-17');
INSERT INTO airport_tickets VALUES (5, 3, 5, '15G', 1200.00, DATE '2024-03-17');

COMMIT;