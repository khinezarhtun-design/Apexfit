--
-- PostgreSQL database dump
--

\restrict L98I0n1tSiQTggBRM7Gb6GV6rE8eVL0EXTFqvksK6irkVfnKlFJYgk0cCJUUqf6

-- Dumped from database version 17.10 (Homebrew)
-- Dumped by pg_dump version 17.10 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: apexuser
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO apexuser;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: admin_update_updated_at(); Type: FUNCTION; Schema: public; Owner: apexuser
--

CREATE FUNCTION public.admin_update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;


ALTER FUNCTION public.admin_update_updated_at() OWNER TO apexuser;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: apexuser
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO apexuser;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: apexuser
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    actor_id uuid NOT NULL,
    actor_email character varying(255),
    action character varying(100) NOT NULL,
    entity_type character varying(50),
    entity_id character varying(100),
    metadata jsonb DEFAULT '{}'::jsonb,
    ip_address character varying(45),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO apexuser;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: apexuser
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.refresh_tokens OWNER TO apexuser;

--
-- Name: staff; Type: TABLE; Schema: public; Owner: apexuser
--

CREATE TABLE public.staff (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    email character varying(255) NOT NULL,
    full_name character varying(200) NOT NULL,
    role character varying(20) DEFAULT 'staff'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT staff_role_check CHECK (((role)::text = ANY ((ARRAY['staff'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.staff OWNER TO apexuser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: apexuser
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    username character varying(50) NOT NULL,
    password_hash text NOT NULL,
    phone character varying(20),
    role character varying(20) DEFAULT 'member'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['member'::character varying, 'staff'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO apexuser;

--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: apexuser
--

COPY public.audit_logs (id, actor_id, actor_email, action, entity_type, entity_id, metadata, ip_address, created_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: apexuser
--

COPY public.refresh_tokens (id, user_id, token, expires_at, created_at) FROM stdin;
058958d9-e3df-450b-bcb0-3edbc08f4502	b2c26da6-dd10-4ab3-ae04-d266cdb835bd	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiMmMyNmRhNi1kZDEwLTRhYjMtYWUwNC1kMjY2Y2RiODM1YmQiLCJyb2xlIjoiYWRtaW4iLCJpYXQiOjE3ODU3NDAxMDksImV4cCI6MTc4ODMzMjEwOSwiaXNzIjoiYXBleGZpdC11c2VyLXNlcnZpY2UifQ.DUG_spBOqjDQ8tQfrI4IsFDAfiBqgeh4jEDd435WRyY	2026-09-02 13:25:09.663+06:30	2026-08-03 13:25:09.663831+06:30
\.


--
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: apexuser
--

COPY public.staff (id, user_id, email, full_name, role, is_active, created_at, updated_at) FROM stdin;
07290844-0b35-451b-870e-6a4b756d33d4	550e8400-e29b-41d4-a716-446655440000	admin@example.com	Administrator	admin	t	2026-08-03 12:17:36.030569+06:30	2026-08-03 12:17:36.030569+06:30
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: apexuser
--

COPY public.users (id, email, username, password_hash, phone, role, is_active, created_at, updated_at) FROM stdin;
b2c26da6-dd10-4ab3-ae04-d266cdb835bd	khinezar@gmail.com	Khine	$2a$12$c7u6wY6AA4K2rvwXV37BVu2E3HrtB1zfl9716XRIOstENaL84vGJW	\N	admin	t	2026-08-03 12:09:19.059241+06:30	2026-08-03 13:12:42.746117+06:30
\.


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_user_id_key; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_key UNIQUE (user_id);


--
-- Name: staff staff_email_key; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_email_key UNIQUE (email);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- Name: staff staff_user_id_key; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_user_id_key UNIQUE (user_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_audit_action; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_audit_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_actor; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_audit_actor ON public.audit_logs USING btree (actor_id);


--
-- Name: idx_audit_created; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_audit_created ON public.audit_logs USING btree (created_at DESC);


--
-- Name: idx_refresh_token; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_refresh_token ON public.refresh_tokens USING btree (token);


--
-- Name: idx_refresh_user_id; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_refresh_user_id ON public.refresh_tokens USING btree (user_id);


--
-- Name: idx_staff_user_id; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_staff_user_id ON public.staff USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: apexuser
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: staff set_staff_updated_at; Type: TRIGGER; Schema: public; Owner: apexuser
--

CREATE TRIGGER set_staff_updated_at BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION public.admin_update_updated_at();


--
-- Name: users set_users_updated_at; Type: TRIGGER; Schema: public; Owner: apexuser
--

CREATE TRIGGER set_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apexuser
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict L98I0n1tSiQTggBRM7Gb6GV6rE8eVL0EXTFqvksK6irkVfnKlFJYgk0cCJUUqf6

