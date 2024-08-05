--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ref_books; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA ref_books;


ALTER SCHEMA ref_books OWNER TO postgres;

--
-- Name: test; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA test;


ALTER SCHEMA test OWNER TO postgres;

--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: list_of_meters_and_readings_t; Type: TYPE; Schema: test; Owner: postgres
--

CREATE TYPE test.list_of_meters_and_readings_t AS (
	serial_number character varying,
	meters_type character varying,
	start_reading numeric,
	end_reading numeric,
	consumption numeric,
	default_readings numeric,
	location_type character varying
);


ALTER TYPE test.list_of_meters_and_readings_t OWNER TO postgres;

--
-- Name: get_meters_and_readings_list(integer, date); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION test.get_meters_and_readings_list(location_type integer, report_month date) RETURNS SETOF test.list_of_meters_and_readings_t
    LANGUAGE plpgsql
    AS $$
DECLARE 
    start_date DATE := date_trunc('month', report_month);
    end_date DATE := (date_trunc('month', report_month) + interval '1 month')::DATE - interval '1 day';
BEGIN 
RETURN QUERY
	SELECT
        m.serial_number,
        rbv_2.name AS meters_type,
        COALESCE((SELECT mr.reading_value
                  FROM test.meters_readings mr
                  WHERE mr.meters_id = m.meters_id
                    AND mr.reading_date = start_date
                    AND mr.is_successful IS TRUE
                  LIMIT 1), 0) AS start_reading,
        COALESCE((SELECT mr.reading_value
                  FROM test.meters_readings mr
                  WHERE mr.meters_id = m.meters_id
                    AND mr.reading_date = end_date
                    AND mr.is_successful IS TRUE
                  LIMIT 1), 0) AS end_reading,
        COALESCE((SELECT mr.reading_value
                  FROM test.meters_readings mr
                  WHERE mr.meters_id = m.meters_id
                    AND mr.reading_date = end_date
                    AND mr.is_successful IS TRUE
                  LIMIT 1), 0) -
        COALESCE((SELECT mr.reading_value
                  FROM test.meters_readings mr
                  WHERE mr.meters_id = m.meters_id
                    AND mr.reading_date = start_date
                    AND mr.is_successful IS TRUE
                  LIMIT 1), 0) AS consumption,
        m.default_readings,
        rbv_1.name AS location_type
    FROM test.meters m
    LEFT JOIN test.meters_readings mr ON mr.meters_id = m.meters_id
    LEFT JOIN test.locations l ON mr.locations_id = l.locations_id
	LEFT JOIN ref_books.ref_book_value rbv_2 ON rbv_2.code = m.meters_type AND rbv_2.id_refb = 2
	LEFT JOIN ref_books.ref_book_value rbv_1 ON rbv_1.code = l.location_type AND rbv_1.id_refb = 1
    WHERE l.location_type = location_type
      AND mr.reading_date BETWEEN start_date AND end_date
      AND mr.is_successful IS TRUE
    GROUP BY m.meters_id, m.serial_number, rbv_2.name, m.default_readings, rbv_1.name;
END;
$$;


ALTER FUNCTION test.get_meters_and_readings_list(location_type integer, report_month date) OWNER TO postgres;

--
-- Name: ref_book_id; Type: SEQUENCE; Schema: ref_books; Owner: postgres
--

CREATE SEQUENCE ref_books.ref_book_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 100000000
    CACHE 1;


ALTER SEQUENCE ref_books.ref_book_id OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ref_book; Type: TABLE; Schema: ref_books; Owner: postgres
--

CREATE TABLE ref_books.ref_book (
    id_refb integer DEFAULT nextval('ref_books.ref_book_id'::regclass) NOT NULL,
    ref_book_name character varying NOT NULL
);


ALTER TABLE ref_books.ref_book OWNER TO postgres;

--
-- Name: ref_book_value; Type: TABLE; Schema: ref_books; Owner: postgres
--

CREATE TABLE ref_books.ref_book_value (
    code integer NOT NULL,
    id_refb integer NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE ref_books.ref_book_value OWNER TO postgres;

--
-- Name: ref_book_value_code; Type: SEQUENCE; Schema: ref_books; Owner: postgres
--

CREATE SEQUENCE ref_books.ref_book_value_code
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 100000000
    CACHE 1;


ALTER SEQUENCE ref_books.ref_book_value_code OWNER TO postgres;

--
-- Name: locations_location_id; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.locations_location_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 100000000
    CACHE 1;


ALTER SEQUENCE test.locations_location_id OWNER TO postgres;

--
-- Name: locations; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.locations (
    locations_id integer DEFAULT nextval('test.locations_location_id'::regclass) NOT NULL,
    location_type smallint NOT NULL
);


ALTER TABLE test.locations OWNER TO postgres;

--
-- Name: TABLE locations; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON TABLE test.locations IS 'Места размещения';


--
-- Name: COLUMN locations.locations_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.locations.locations_id IS 'Уникальный идентификатор записи';


--
-- Name: COLUMN locations.location_type; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.locations.location_type IS 'Тип места размещения';


--
-- Name: meters_meters_id; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.meters_meters_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 100000000
    CACHE 1;


ALTER SEQUENCE test.meters_meters_id OWNER TO postgres;

--
-- Name: meters; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.meters (
    meters_id integer DEFAULT nextval('test.meters_meters_id'::regclass) NOT NULL,
    serial_number character varying NOT NULL,
    default_readings numeric NOT NULL,
    meters_type smallint NOT NULL,
    installation_date date NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE test.meters OWNER TO postgres;

--
-- Name: TABLE meters; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON TABLE test.meters IS 'Приборы учёта';


--
-- Name: COLUMN meters.meters_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters.meters_id IS 'Уникальный идентификатор записи';


--
-- Name: COLUMN meters.serial_number; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters.serial_number IS 'Серийный номер';


--
-- Name: COLUMN meters.default_readings; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters.default_readings IS 'Показание по умолчанию (при установке)';


--
-- Name: COLUMN meters.meters_type; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters.meters_type IS ' Тип прибора (id_refb = 2)';


--
-- Name: COLUMN meters.installation_date; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters.installation_date IS 'Дата установки прибора';


--
-- Name: COLUMN meters.is_active; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters.is_active IS 'Статус активности прибора';


--
-- Name: meters_movements_meters_movements_id; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.meters_movements_meters_movements_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 100000000
    CACHE 1;


ALTER SEQUENCE test.meters_movements_meters_movements_id OWNER TO postgres;

--
-- Name: meters_movements; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.meters_movements (
    meters_movements_id integer DEFAULT nextval('test.meters_movements_meters_movements_id'::regclass) NOT NULL,
    meters_id integer,
    from_location_id integer,
    to_location_id integer,
    movement_date date NOT NULL,
    new_meters_type smallint
);


ALTER TABLE test.meters_movements OWNER TO postgres;

--
-- Name: TABLE meters_movements; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON TABLE test.meters_movements IS 'Перемещения приборов учёта';


--
-- Name: COLUMN meters_movements.meters_movements_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_movements.meters_movements_id IS 'Уникальный идентификатор записи';


--
-- Name: COLUMN meters_movements.meters_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_movements.meters_id IS 'Идентификатор прибора учёта';


--
-- Name: COLUMN meters_movements.from_location_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_movements.from_location_id IS 'Идентификатор на исходное место размещения';


--
-- Name: COLUMN meters_movements.to_location_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_movements.to_location_id IS 'Идентификатор на новое место размещения';


--
-- Name: COLUMN meters_movements.movement_date; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_movements.movement_date IS 'Дата перемещения';


--
-- Name: COLUMN meters_movements.new_meters_type; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_movements.new_meters_type IS 'Новый тип прибора';


--
-- Name: meters_readings_meters_readings_id; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.meters_readings_meters_readings_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 100000000
    CACHE 1;


ALTER SEQUENCE test.meters_readings_meters_readings_id OWNER TO postgres;

--
-- Name: meters_readings; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.meters_readings (
    meters_readings_id integer DEFAULT nextval('test.meters_readings_meters_readings_id'::regclass) NOT NULL,
    meters_id integer,
    locations_id integer,
    reading_date date NOT NULL,
    reading_value numeric NOT NULL,
    is_successful boolean DEFAULT true
);


ALTER TABLE test.meters_readings OWNER TO postgres;

--
-- Name: TABLE meters_readings; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON TABLE test.meters_readings IS 'Показания приборов учёта';


--
-- Name: COLUMN meters_readings.meters_readings_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_readings.meters_readings_id IS 'Уникальный идентификатор записи';


--
-- Name: COLUMN meters_readings.meters_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_readings.meters_id IS 'Идентификатор прибора учёта';


--
-- Name: COLUMN meters_readings.locations_id; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_readings.locations_id IS 'Идентификатор места размещения';


--
-- Name: COLUMN meters_readings.reading_date; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_readings.reading_date IS 'Дата снятия показания';


--
-- Name: COLUMN meters_readings.reading_value; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_readings.reading_value IS 'Значение показания';


--
-- Name: COLUMN meters_readings.is_successful; Type: COMMENT; Schema: test; Owner: postgres
--

COMMENT ON COLUMN test.meters_readings.is_successful IS 'Успешность снятия показания';


--
-- Data for Name: ref_book; Type: TABLE DATA; Schema: ref_books; Owner: postgres
--

COPY ref_books.ref_book (id_refb, ref_book_name) FROM stdin;
1	Тип места размещения
2	Тип прибора учёта
\.


--
-- Data for Name: ref_book_value; Type: TABLE DATA; Schema: ref_books; Owner: postgres
--

COPY ref_books.ref_book_value (code, id_refb, name) FROM stdin;
1	2	Электричество
2	2	Холодная вода
3	2	Горячая вода
4	2	Газ
1	1	Квартира в многоквартирном доме
2	1	Частный дом
3	1	Общедомовые счётчики
\.


--
-- Data for Name: locations; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.locations (locations_id, location_type) FROM stdin;
\.


--
-- Data for Name: meters; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.meters (meters_id, serial_number, default_readings, meters_type, installation_date, is_active) FROM stdin;
\.


--
-- Data for Name: meters_movements; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.meters_movements (meters_movements_id, meters_id, from_location_id, to_location_id, movement_date, new_meters_type) FROM stdin;
\.


--
-- Data for Name: meters_readings; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.meters_readings (meters_readings_id, meters_id, locations_id, reading_date, reading_value, is_successful) FROM stdin;
\.


--
-- Name: ref_book_id; Type: SEQUENCE SET; Schema: ref_books; Owner: postgres
--

SELECT pg_catalog.setval('ref_books.ref_book_id', 1, false);


--
-- Name: ref_book_value_code; Type: SEQUENCE SET; Schema: ref_books; Owner: postgres
--

SELECT pg_catalog.setval('ref_books.ref_book_value_code', 1, false);


--
-- Name: locations_location_id; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.locations_location_id', 1, false);


--
-- Name: meters_meters_id; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.meters_meters_id', 1, false);


--
-- Name: meters_movements_meters_movements_id; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.meters_movements_meters_movements_id', 1, false);


--
-- Name: meters_readings_meters_readings_id; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.meters_readings_meters_readings_id', 1, false);


--
-- Name: ref_book ref_book_pkey; Type: CONSTRAINT; Schema: ref_books; Owner: postgres
--

ALTER TABLE ONLY ref_books.ref_book
    ADD CONSTRAINT ref_book_pkey PRIMARY KEY (id_refb);


--
-- Name: ref_book_value ref_book_value_pkey; Type: CONSTRAINT; Schema: ref_books; Owner: postgres
--

ALTER TABLE ONLY ref_books.ref_book_value
    ADD CONSTRAINT ref_book_value_pkey PRIMARY KEY (code, id_refb);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (locations_id);


--
-- Name: meters_movements meters_movements_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.meters_movements
    ADD CONSTRAINT meters_movements_pkey PRIMARY KEY (meters_movements_id);


--
-- Name: meters meters_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.meters
    ADD CONSTRAINT meters_pkey PRIMARY KEY (meters_id);


--
-- Name: meters_readings meters_readings_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.meters_readings
    ADD CONSTRAINT meters_readings_pkey PRIMARY KEY (meters_readings_id);


--
-- Name: meters_movements meters_movements_from_location_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.meters_movements
    ADD CONSTRAINT meters_movements_from_location_id_fkey FOREIGN KEY (from_location_id) REFERENCES test.locations(locations_id);


--
-- Name: meters_movements meters_movements_meters_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.meters_movements
    ADD CONSTRAINT meters_movements_meters_id_fkey FOREIGN KEY (meters_id) REFERENCES test.meters(meters_id);


--
-- Name: meters_movements meters_movements_to_location_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.meters_movements
    ADD CONSTRAINT meters_movements_to_location_id_fkey FOREIGN KEY (to_location_id) REFERENCES test.locations(locations_id);


--
-- Name: meters_readings meters_readings_location_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.meters_readings
    ADD CONSTRAINT meters_readings_location_id_fkey FOREIGN KEY (locations_id) REFERENCES test.locations(locations_id);


--
-- Name: meters_readings meters_readings_meters_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.meters_readings
    ADD CONSTRAINT meters_readings_meters_id_fkey FOREIGN KEY (meters_id) REFERENCES test.meters(meters_id);


--
-- PostgreSQL database dump complete
--

