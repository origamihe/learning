--
-- PostgreSQL database dump
--

\restrict Aw4ICcxTGNJIGWltk3l34YVZbRBfabbGApIUCD9eClecoHiLx1sYDVn1MXasGnC

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

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
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: course_sections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_sections (
    id uuid NOT NULL,
    course_id uuid NOT NULL,
    title character varying(150) NOT NULL,
    sort_order integer NOT NULL,
    content jsonb,
    duration integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.course_sections OWNER TO postgres;

--
-- Name: courses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.courses (
    id uuid NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    cover_image text,
    teacher_id uuid,
    difficulty character varying(20),
    status character varying(20) DEFAULT 'DRAFT'::character varying,
    tags text[],
    meta jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    CONSTRAINT courses_difficulty_check CHECK (((difficulty)::text = ANY ((ARRAY['BEGINNER'::character varying, 'INTERMEDIATE'::character varying, 'ADVANCED'::character varying])::text[]))),
    CONSTRAINT courses_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'PUBLISHED'::character varying, 'ARCHIVED'::character varying])::text[])))
);


ALTER TABLE public.courses OWNER TO postgres;

--
-- Name: exam_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_records (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    exam_id uuid,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    duration_used integer,
    score numeric(5,2),
    answers jsonb,
    status character varying(20) DEFAULT 'IN_PROGRESS'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT exam_records_status_check CHECK (((status)::text = ANY ((ARRAY['IN_PROGRESS'::character varying, 'SUBMITTED'::character varying, 'TIMEOUT'::character varying, 'GRADED'::character varying])::text[])))
);


ALTER TABLE public.exam_records OWNER TO postgres;

--
-- Name: exams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exams (
    id uuid NOT NULL,
    title character varying(150) NOT NULL,
    course_id uuid,
    duration integer NOT NULL,
    total_score integer DEFAULT 100,
    pass_score integer DEFAULT 60,
    type character varying(30),
    status character varying(20) DEFAULT 'DRAFT'::character varying,
    config jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT exams_type_check CHECK (((type)::text = ANY ((ARRAY['PRACTICE'::character varying, 'FORMAL'::character varying, 'MOCK'::character varying])::text[])))
);


ALTER TABLE public.exams OWNER TO postgres;

--
-- Name: file_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.file_attachments (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    original_name character varying(500) NOT NULL,
    storage_key character varying(1000) NOT NULL,
    file_url character varying(2000) NOT NULL,
    file_size bigint DEFAULT 0 NOT NULL,
    mime_type character varying(255),
    file_category character varying(20) DEFAULT 'IMAGE'::character varying NOT NULL,
    entity_type character varying(50),
    entity_id uuid,
    sort_order integer DEFAULT 0 NOT NULL,
    width integer,
    height integer,
    duration integer,
    thumbnail_key character varying(1000),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.file_attachments OWNER TO postgres;

--
-- Name: TABLE file_attachments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.file_attachments IS '通用文件附件表，支持题目配图/课程插图/用户上传等';


--
-- Name: questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.questions (
    id uuid NOT NULL,
    course_id uuid,
    section_id uuid,
    type character varying(30) NOT NULL,
    content text NOT NULL,
    options jsonb,
    answer jsonb NOT NULL,
    explanation text,
    difficulty integer NOT NULL,
    tags text[],
    meta jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    content_type character varying(20) DEFAULT 'PLAIN'::character varying,
    CONSTRAINT questions_difficulty_check CHECK (((difficulty >= 1) AND (difficulty <= 5))),
    CONSTRAINT questions_type_check CHECK (((type)::text = ANY ((ARRAY['SINGLE'::character varying, 'MULTIPLE'::character varying, 'JUDGE'::character varying, 'FILL'::character varying, 'PROGRAMMING'::character varying])::text[])))
);


ALTER TABLE public.questions OWNER TO postgres;

--
-- Name: COLUMN questions.content_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.questions.content_type IS '内容格式：PLAIN-纯文本, MARKDOWN-Markdown, RICH_TEXT-富文本';


--
-- Name: user_learning_progress; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_learning_progress (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    course_id uuid NOT NULL,
    last_section_id uuid,
    progress numeric(5,2) DEFAULT 0,
    completed_sections text[],
    last_accessed timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_learning_progress OWNER TO postgres;

--
-- Name: user_sign_ins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_sign_ins (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    sign_in_date date NOT NULL,
    points_earned integer DEFAULT 5,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_sign_ins OWNER TO postgres;

--
-- Name: user_wrong_questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_wrong_questions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    question_id uuid NOT NULL,
    wrong_count integer DEFAULT 1,
    last_wrong_at timestamp with time zone DEFAULT now(),
    next_review_at timestamp with time zone,
    mastery_level integer DEFAULT 1,
    notes text,
    CONSTRAINT user_wrong_questions_mastery_level_check CHECK (((mastery_level >= 1) AND (mastery_level <= 5)))
);


ALTER TABLE public.user_wrong_questions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    nickname character varying(60),
    avatar text,
    role character varying(20) DEFAULT 'STUDENT'::character varying NOT NULL,
    points integer DEFAULT 0,
    streak_days integer DEFAULT 0,
    last_sign_in date,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    deleted_at timestamp with time zone,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['STUDENT'::character varying, 'TEACHER'::character varying, 'ADMIN'::character varying])::text[]))),
    CONSTRAINT users_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'BANNED'::character varying, 'INACTIVE'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: course_sections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course_sections (id, course_id, title, sort_order, content, duration, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courses (id, title, description, cover_image, teacher_id, difficulty, status, tags, meta, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: exam_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_records (id, user_id, exam_id, start_time, end_time, duration_used, score, answers, status, created_at) FROM stdin;
\.


--
-- Data for Name: exams; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exams (id, title, course_id, duration, total_score, pass_score, type, status, config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: file_attachments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.file_attachments (id, user_id, original_name, storage_key, file_url, file_size, mime_type, file_category, entity_type, entity_id, sort_order, width, height, duration, thumbnail_key, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.questions (id, course_id, section_id, type, content, options, answer, explanation, difficulty, tags, meta, created_at, updated_at, deleted_at, content_type) FROM stdin;
\.


--
-- Data for Name: user_learning_progress; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_learning_progress (id, user_id, course_id, last_section_id, progress, completed_sections, last_accessed) FROM stdin;
\.


--
-- Data for Name: user_sign_ins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_sign_ins (id, user_id, sign_in_date, points_earned, created_at) FROM stdin;
\.


--
-- Data for Name: user_wrong_questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_wrong_questions (id, user_id, question_id, wrong_count, last_wrong_at, next_review_at, mastery_level, notes) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, password_hash, nickname, avatar, role, points, streak_days, last_sign_in, status, preferences, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Name: course_sections course_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT course_sections_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: exam_records exam_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_records
    ADD CONSTRAINT exam_records_pkey PRIMARY KEY (id);


--
-- Name: exams exams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_pkey PRIMARY KEY (id);


--
-- Name: file_attachments file_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_attachments
    ADD CONSTRAINT file_attachments_pkey PRIMARY KEY (id);


--
-- Name: file_attachments file_attachments_storage_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_attachments
    ADD CONSTRAINT file_attachments_storage_key_key UNIQUE (storage_key);


--
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: user_learning_progress user_learning_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_learning_progress
    ADD CONSTRAINT user_learning_progress_pkey PRIMARY KEY (id);


--
-- Name: user_learning_progress user_learning_progress_user_id_course_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_learning_progress
    ADD CONSTRAINT user_learning_progress_user_id_course_id_key UNIQUE (user_id, course_id);


--
-- Name: user_sign_ins user_sign_ins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sign_ins
    ADD CONSTRAINT user_sign_ins_pkey PRIMARY KEY (id);


--
-- Name: user_sign_ins user_sign_ins_user_id_sign_in_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sign_ins
    ADD CONSTRAINT user_sign_ins_user_id_sign_in_date_key UNIQUE (user_id, sign_in_date);


--
-- Name: user_wrong_questions user_wrong_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_wrong_questions
    ADD CONSTRAINT user_wrong_questions_pkey PRIMARY KEY (id);


--
-- Name: user_wrong_questions user_wrong_questions_user_id_question_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_wrong_questions
    ADD CONSTRAINT user_wrong_questions_user_id_question_id_key UNIQUE (user_id, question_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_exam_records_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_records_user ON public.exam_records USING btree (user_id);


--
-- Name: idx_file_attachments_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_file_attachments_category ON public.file_attachments USING btree (file_category) WHERE (deleted_at IS NULL);


--
-- Name: idx_file_attachments_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_file_attachments_entity ON public.file_attachments USING btree (entity_type, entity_id, sort_order) WHERE (deleted_at IS NULL);


--
-- Name: idx_file_attachments_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_file_attachments_user ON public.file_attachments USING btree (user_id, created_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_questions_tags; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_tags ON public.questions USING gin (tags);


--
-- Name: idx_signins_user_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_signins_user_date ON public.user_sign_ins USING btree (user_id, sign_in_date);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_wrong_questions_review; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wrong_questions_review ON public.user_wrong_questions USING btree (next_review_at);


--
-- Name: idx_wrong_questions_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wrong_questions_user ON public.user_wrong_questions USING btree (user_id);


--
-- Name: course_sections course_sections_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT course_sections_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: courses courses_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.users(id);


--
-- Name: exam_records exam_records_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_records
    ADD CONSTRAINT exam_records_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id);


--
-- Name: exam_records exam_records_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_records
    ADD CONSTRAINT exam_records_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: exams exams_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: file_attachments file_attachments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.file_attachments
    ADD CONSTRAINT file_attachments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: questions questions_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: questions questions_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.course_sections(id);


--
-- Name: user_learning_progress user_learning_progress_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_learning_progress
    ADD CONSTRAINT user_learning_progress_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: user_learning_progress user_learning_progress_last_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_learning_progress
    ADD CONSTRAINT user_learning_progress_last_section_id_fkey FOREIGN KEY (last_section_id) REFERENCES public.course_sections(id);


--
-- Name: user_learning_progress user_learning_progress_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_learning_progress
    ADD CONSTRAINT user_learning_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sign_ins user_sign_ins_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sign_ins
    ADD CONSTRAINT user_sign_ins_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_wrong_questions user_wrong_questions_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_wrong_questions
    ADD CONSTRAINT user_wrong_questions_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- Name: user_wrong_questions user_wrong_questions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_wrong_questions
    ADD CONSTRAINT user_wrong_questions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict Aw4ICcxTGNJIGWltk3l34YVZbRBfabbGApIUCD9eClecoHiLx1sYDVn1MXasGnC

