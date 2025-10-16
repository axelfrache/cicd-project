--
-- PostgreSQL database dump
--

\restrict W45XrUaeAa31D9zTHSkbFqHmHdydjYiqtT1WrQkDQvTydvD38KIfLehdpEyqEvk

-- Dumped from database version 15.14
-- Dumped by pg_dump version 15.14

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

ALTER TABLE IF EXISTS ONLY public.city DROP CONSTRAINT IF EXISTS city_pkey;
ALTER TABLE IF EXISTS public.city ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.city_id_seq;
DROP TABLE IF EXISTS public.city;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: city; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.city (
    id bigint NOT NULL,
    department_code character varying(3) NOT NULL,
    insee_code character varying(5),
    zip_code character varying(5),
    name character varying(100) NOT NULL,
    lat double precision NOT NULL,
    lon double precision NOT NULL
);


--
-- Name: city_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: city_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.city_id_seq OWNED BY public.city.id;


--
-- Name: city id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city ALTER COLUMN id SET DEFAULT nextval('public.city_id_seq'::regclass);


--
-- Data for Name: city; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.city (id, department_code, insee_code, zip_code, name, lat, lon) FROM stdin;
1	01	01001	01400	L'Abergement-Clémenciat	46.15678199203189	4.92469920318725
2	01	01002	01640	L'Abergement-de-Varey	46.01008562499999	5.42875916666667
3	01	01004	01500	Ambérieu-en-Bugey	45.95840939226519	5.3759920441989
\.


--
-- Name: city_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.city_id_seq', 3, true);


--
-- Name: city city_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

\unrestrict W45XrUaeAa31D9zTHSkbFqHmHdydjYiqtT1WrQkDQvTydvD38KIfLehdpEyqEvk

