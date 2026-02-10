--
-- PostgreSQL database dump
--

\restrict S7zqbQ2l9rEXxZoFc7sMl9pxQO6NChqqnOpWLj26ZPbFDorkOgBPgj7mV9dtegW

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    service_id uuid,
    expert_id uuid,
    customer_name character varying(255) NOT NULL,
    customer_phone character varying(20) NOT NULL,
    customer_email character varying(255) NOT NULL,
    appointment_date date NOT NULL,
    appointment_time time without time zone NOT NULL,
    status character varying(20) DEFAULT 'reserved'::character varying,
    payment_status character varying(20) DEFAULT 'unpaid'::character varying,
    payment_method character varying(20),
    total_price numeric(10,2) NOT NULL,
    notes text,
    expires_at timestamp without time zone,
    reminder_sent boolean DEFAULT false,
    cancelled_reason text,
    paid_at timestamp without time zone,
    cancelled_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT appointments_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['online'::character varying, 'cash'::character varying, 'card'::character varying])::text[]))),
    CONSTRAINT appointments_payment_status_check CHECK (((payment_status)::text = ANY ((ARRAY['unpaid'::character varying, 'paid'::character varying, 'refunded'::character varying])::text[]))),
    CONSTRAINT appointments_status_check CHECK (((status)::text = ANY ((ARRAY['reserved'::character varying, 'confirmed'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.appointments OWNER TO postgres;

--
-- Name: course_applications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.course_applications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    course_id uuid,
    status character varying(20) DEFAULT 'pending'::character varying,
    applied_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT course_applications_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.course_applications OWNER TO postgres;

--
-- Name: courses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.courses (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    duration character varying(100),
    price numeric(10,2),
    image_url text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.courses OWNER TO postgres;

--
-- Name: expert_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expert_services (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    expert_id uuid,
    service_id uuid
);


ALTER TABLE public.expert_services OWNER TO postgres;

--
-- Name: experts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.experts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255),
    phone character varying(20),
    specialty text,
    bio text,
    image_url text,
    rating numeric(3,2) DEFAULT 0.00,
    total_reviews integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.experts OWNER TO postgres;

--
-- Name: gallery; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gallery (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255),
    description text,
    image_url text NOT NULL,
    category character varying(100),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.gallery OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    type character varying(50),
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: offers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    discount_percentage numeric(5,2),
    discount_amount numeric(10,2),
    image_url text,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.offers OWNER TO postgres;

--
-- Name: pending_registrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pending_registrations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    address text,
    phone character varying(20),
    gender character varying(20),
    verification_code character varying(6) NOT NULL,
    verification_code_expires_at timestamp with time zone NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.pending_registrations OWNER TO postgres;

--
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    slug character varying(150) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- Name: reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reviews (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    service_id uuid,
    expert_id uuid,
    appointment_id uuid,
    rating integer NOT NULL,
    comment text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO postgres;

--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_permissions (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL
);


ALTER TABLE public.role_permissions OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    is_system_role boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: service_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    image_url text,
    icon character varying(100),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.service_categories OWNER TO postgres;

--
-- Name: services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.services (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    category_id uuid,
    name character varying(255) NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    duration integer NOT NULL,
    image_url text,
    tags text[],
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.services OWNER TO postgres;

--
-- Name: sub_services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sub_services (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    service_id uuid,
    name character varying(255) NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    duration integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sub_services OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    role_id uuid,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    address text,
    phone character varying(20),
    gender character varying(20),
    profile_image_url text,
    email_verified boolean DEFAULT false,
    verification_token text,
    reset_password_token text,
    reset_password_expires timestamp without time zone,
    failed_login_attempts integer DEFAULT 0,
    lockout_until timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp without time zone,
    verification_code character varying(6),
    verification_code_expires_at timestamp with time zone,
    is_guest boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointments (id, user_id, service_id, expert_id, customer_name, customer_phone, customer_email, appointment_date, appointment_time, status, payment_status, payment_method, total_price, notes, expires_at, reminder_sent, cancelled_reason, paid_at, cancelled_at, created_at, updated_at) FROM stdin;
ef38c615-4ed0-48c6-a276-1d6431779e88	455ff159-a3c5-4f80-9328-4ae0915c2979	557cd9fa-bd31-4d92-bfa1-96b397c41ef9	\N	saad	03127000786	abdullahejaz512@gmail.com	2026-02-02	13:00:00	confirmed	paid	\N	6500.00		\N	f	\N	2026-02-02 15:29:48.075	\N	2026-02-02 15:29:48.076532	2026-02-02 15:29:48.076532
fe7e5b5b-2ae1-4d7c-b1c6-bbe602f3363b	455ff159-a3c5-4f80-9328-4ae0915c2979	557cd9fa-bd31-4d92-bfa1-96b397c41ef9	\N	saad	03127000786	abdullahejaz512@gmail.com	2026-02-02	13:00:00	confirmed	paid	\N	6500.00		\N	f	\N	2026-02-02 15:31:21.431	\N	2026-02-02 15:31:21.432472	2026-02-02 15:31:21.432472
\.


--
-- Data for Name: course_applications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.course_applications (id, user_id, course_id, status, applied_at, updated_at) FROM stdin;
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courses (id, title, description, duration, price, image_url, is_active, created_at, updated_at) FROM stdin;
f2ebe854-01a8-4552-94b4-e3a0bc035da8	Advance Level	The Advance Level course is perfect for students who have basic knowledge and want to enhance their expertise. \nThis 6-month program covers advanced Hair techniques, professional Makeup, Waxing, Facial treatments, and Massage. \n\nKey Highlights:\n• Detailed theory and practical sessions for advanced techniques.\n• Learn to handle diverse client requirements and preferences.\n• Tips on managing a small beauty business or freelancing.\n• Training on professional-grade tools and products.\nBy the end of this course, students will gain practical experience and a certificate that showcases their proficiency in multiple beauty treatments.\n\nSubjects Included: Hair, Mehndi, Makeup, Waxing, Facial, Massage	6 Months	120000.00	https://salon-app-assets-saad.s3.amazonaws.com/assets/AdvanceCourse.png	t	2026-01-24 11:04:21.046909	2026-01-27 12:46:16.983982
0075b8a8-a3f3-4360-b6df-b8862b51c71e	Basic Level	The Basic Level course is designed for beginners who want to start their journey in the beauty and wellness industry. \nIn this 3-month program, you will learn essential skills in Hair styling, Mehndi application, and basic Massage techniques. \n\nKey Highlights:\n• Hands-on practical sessions to master foundational skills.\n• Introduction to hygiene, safety, and client care.\n• Step-by-step guidance from experienced beauticians.\n• Opportunity to build confidence before moving to advanced courses.\nUpon completion, you will receive a certificate validating your skills in these basic beauty treatments.\n\nSubjects Included: Hair, Mehndi, Massage	3 Month	75000.00	https://salon-app-assets-saad.s3.amazonaws.com/assets/BasicCourse.png	t	2026-01-24 11:04:21.023163	2026-01-27 12:36:12.661597
c1098d6b-9e86-4e3d-a257-31bd4cbf9771	Professional Level	The Pro Level course is designed for ambitious individuals aiming to become professional beauty experts. \nThis 12-month comprehensive program covers every aspect of Hair, Mehndi, Makeup, Waxing, Facial, and Massage treatments. \n\nKey Highlights:\n• Advanced techniques for all subjects, including high-end beauty treatments.\n• Client management, consultation skills, and personalized service training.\n• Hands-on experience with professional equipment and products.\n• Guidance on starting your own salon or becoming a freelance beauty consultant.\nUpon successful completion, students will receive a Pro-level certificate, preparing them for a rewarding career in the beauty industry.\n\nSubjects Included: Hair, Mehndi, Makeup, Waxing, Facial, Massage	12 Months	180000.00	https://salon-app-assets-saad.s3.amazonaws.com/assets/ProCourse.png	t	2026-01-24 11:04:21.053526	2026-01-27 14:23:21.744801
\.


--
-- Data for Name: expert_services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expert_services (id, expert_id, service_id) FROM stdin;
\.


--
-- Data for Name: experts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.experts (id, name, email, phone, specialty, bio, image_url, rating, total_reviews, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: gallery; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gallery (id, title, description, image_url, category, display_order, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, title, message, type, is_read, created_at) FROM stdin;
\.


--
-- Data for Name: offers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offers (id, title, description, discount_percentage, discount_amount, image_url, start_date, end_date, is_active, created_at, updated_at) FROM stdin;
683b7267-b9f7-46bd-b7b9-7faae5021057	winter sale	enjoy this offer	\N	497.98	\N	2026-01-26	2026-01-30	t	2026-01-27 11:48:13.640096	2026-01-27 14:03:35.609925
\.


--
-- Data for Name: pending_registrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pending_registrations (id, name, email, password_hash, address, phone, gender, verification_code, verification_code_expires_at, role_id, created_at) FROM stdin;
908c9bdd-ee14-4dbe-bb77-7fff671414c3	John Doe	abdullahejaz514@gmail.com	$2a$10$CLc2U8t5kAkU04/4e4ldde3M/.NLnxO6ebEPRGsAOwUAXf0v4dQo.	123 Main St	+11234567890	Male	998152	2026-01-21 16:51:36.978+05	c15a2bec-aebf-43f1-bd16-98dd8f583560	2026-01-21 16:41:36.980623
7168543b-b36c-40b3-937f-acb71306ebbf	saad	usman50475@gmail.com	$2a$10$5.5z5KNgXSDy7AbW3upgK.YzI6CWBT02HFvfQYdGjApfryRrP8gGy	f6/1	03127000786	Male	325906	2026-01-21 17:12:01.049+05	c15a2bec-aebf-43f1-bd16-98dd8f583560	2026-01-21 17:02:01.054862
0964a9c3-2961-4139-84ed-94e2971c357f	saad	saadaztorsys03@gmail.com	$2a$10$/1q0g/XWvWcIYI1lour0KuURihAY1PQ261YOACIez8PsKSATtE/wu	f6	03127000786	Male	385532	2026-01-22 04:08:00.364+05	c15a2bec-aebf-43f1-bd16-98dd8f583560	2026-01-22 03:58:00.366664
0cc3fec5-c617-455c-9b0b-0ccb6b6cd5af	saad	saadaztrosys03@gmail.com	$2a$10$WXzvymREDldJlP0MEP4vdOrdM9t/apTYpv3fJsvwZyUmR.J/oRamO	i8	03127000786	Male	838123	2026-02-02 12:32:06.272+05	fa355676-506c-4015-905c-0181c3d19e55	2026-02-02 12:22:06.289269
97f7294f-ea52-4eb1-9be6-5f8d374cc2a5	saad	zaidullahaztrosys@gmail.com	$2a$10$cWUb3f1NHtkCd9xMMOs0.On2.u8imeWA2DYYP3BA5mchsRrYVsY4S	i8	03127000786	Female	499963	2026-02-02 13:11:19.6+05	fa355676-506c-4015-905c-0181c3d19e55	2026-02-02 13:01:19.602521
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permissions (id, slug, description, created_at, updated_at) FROM stdin;
8b36f5be-62fb-4daa-b055-b555fb94ff6f	users.view	View user profiles	2026-01-21 13:08:02.730023	2026-01-21 13:08:02.730023
8b9e7f84-b082-4ec4-a39a-8957ac05a88e	users.manage	Create/Delete users	2026-01-21 13:08:02.730023	2026-01-21 13:08:02.730023
fde2c0d1-6789-41e9-8f76-3f1b1b0a97da	services.manage	Create/Update services	2026-01-21 13:08:02.730023	2026-01-21 13:08:02.730023
04c0ebd4-698c-4980-a695-25b21daf55c3	appointments.create	Book appointments	2026-01-21 13:08:02.730023	2026-01-21 13:08:02.730023
1b5ab645-3713-46a1-afc6-94331e74021c	appointments.manage_all	View and cancel ANY appointment	2026-01-21 13:08:02.730023	2026-01-21 13:08:02.730023
d1d37cfc-37d4-410b-8490-8f0a0e975f85	dashboard.view	View financial stats	2026-01-21 13:08:02.730023	2026-01-21 13:08:02.730023
770463bd-de1d-4fa9-85d4-7c4440d4ae34	roles.manage	Create roles and assign permissions	2026-01-21 13:08:02.730023	2026-01-21 13:08:02.730023
e9593a71-2be3-4031-994f-d11d6a7afbef	roles.view	View roles and permissions	2026-01-21 13:08:02.730023	2026-01-21 13:08:02.730023
b00fc68b-81b4-43b6-821a-b37172b2e333	auth.login	Login to system	2026-01-24 12:51:37.495941	2026-01-24 12:51:37.495941
6a110911-a63b-443b-bf05-9460ba1a46b1	auth.logout	Logout from system	2026-01-24 12:51:37.517075	2026-01-24 12:51:37.517075
6bb9c8e5-9a7e-46d7-8db8-9f7979c54e2a	auth.change-password	Change own password	2026-01-24 12:51:37.519297	2026-01-24 12:51:37.519297
07878781-f051-45b9-863b-7870da6cd5d8	users.create	Create user accounts	2026-01-24 12:51:37.522963	2026-01-24 12:51:37.522963
2da6bf66-f113-48ef-b67f-ce65a79066b7	users.update	Update user profiles	2026-01-24 12:51:37.525436	2026-01-24 12:51:37.525436
d47f0201-99a5-49de-8878-164b3d994f0c	users.delete	Delete user accounts	2026-01-24 12:51:37.529112	2026-01-24 12:51:37.529112
a652aa15-4092-4775-aa1f-55ec1e5e2c35	users.assign-role	Assign roles to users	2026-01-24 12:51:37.532184	2026-01-24 12:51:37.532184
b1025ca3-1101-4049-b7fc-6726fa4b4c17	roles.create	Create new roles	2026-01-24 12:51:37.538184	2026-01-24 12:51:37.538184
9736d07f-d0ec-4d9f-a9e0-438628c5bbf4	roles.update	Update roles and permissions	2026-01-24 12:51:37.540754	2026-01-24 12:51:37.540754
9e24d68d-fa6f-4df6-8d2f-5bab53514153	roles.delete	Delete roles	2026-01-24 12:51:37.545621	2026-01-24 12:51:37.545621
100c0f6c-6d43-44a9-9d3d-a6e35d8c0c99	services.view	View services	2026-01-24 12:51:37.55044	2026-01-24 12:51:37.55044
7930fa58-de7d-4220-b09f-29ae3fcc5e3c	categories.manage	Manage service categories	2026-01-24 12:51:37.557185	2026-01-24 12:51:37.557185
9369a7da-5a9e-4879-82c5-d861b5d8587f	appointments.view	View appointments	2026-01-24 12:51:37.560759	2026-01-24 12:51:37.560759
528dad50-88ae-42bc-9bbc-fa9994945361	appointments.manage	Manage appointments	2026-01-24 12:51:37.563574	2026-01-24 12:51:37.563574
e83d1a9a-f3a7-4400-8e7f-aa622131872a	appointments.cancel	Cancel appointments	2026-01-24 12:51:37.566622	2026-01-24 12:51:37.566622
d1fae0ea-4759-4de4-bd19-e33de536d94f	offers.view	View offers and promotions	2026-01-24 12:51:37.568762	2026-01-24 12:51:37.568762
40e04f56-6f49-4d1b-bda3-285ffc779472	offers.manage	Create, edit, and delete offers	2026-01-24 12:51:37.571294	2026-01-24 12:51:37.571294
2955b6e1-3bdb-4fa3-953d-5381045bf4a0	courses.view	View training courses	2026-01-24 12:51:37.573957	2026-01-24 12:51:37.573957
81aa1778-001b-420c-9475-15d6c9686585	courses.manage	Create, edit, delete courses	2026-01-24 12:51:37.578738	2026-01-24 12:51:37.578738
ff29918f-7fb5-4d88-932c-ad2a4e88cb40	experts.view	View experts/stylists	2026-01-24 12:51:37.581612	2026-01-24 12:51:37.581612
096e2921-0efb-4822-8b9b-94bd46e4670f	experts.manage	Create, edit, delete experts	2026-01-24 12:51:37.584674	2026-01-24 12:51:37.584674
0ba23d6c-8104-40be-b7ee-fa0cb9ab07b8	gallery.view	View gallery images	2026-01-24 12:51:37.587284	2026-01-24 12:51:37.587284
9e2b81a1-14eb-4fc1-b2f1-33d33217c582	gallery.manage	Upload, edit, delete gallery images	2026-01-24 12:51:37.59239	2026-01-24 12:51:37.59239
68d9e370-b812-4aca-9fd3-df462fc0e108	support.view	View support tickets	2026-01-24 12:51:37.59636	2026-01-24 12:51:37.59636
3383071b-5a19-4785-97e2-df2b2a13061a	support.manage	Manage support tickets	2026-01-24 12:51:37.599256	2026-01-24 12:51:37.599256
9a3d0844-0ff7-4964-a5f6-10f53972f226	reports.view	View detailed reports	2026-01-24 12:51:37.605064	2026-01-24 12:51:37.605064
2789e0b2-92d6-4d8b-a5d1-45c68314a423	notifications.send	Send notifications	2026-01-24 12:51:37.608933	2026-01-24 12:51:37.608933
b0bcdce0-d277-4ca6-b0b0-8bf484278ed9	notifications.manage	Manage notification settings	2026-01-24 12:51:37.612908	2026-01-24 12:51:37.612908
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reviews (id, user_id, service_id, expert_id, appointment_id, rating, comment, created_at) FROM stdin;
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_permissions (role_id, permission_id) FROM stdin;
f055f055-1ca2-404b-8e20-326b0c19e3f4	8b36f5be-62fb-4daa-b055-b555fb94ff6f
f055f055-1ca2-404b-8e20-326b0c19e3f4	8b9e7f84-b082-4ec4-a39a-8957ac05a88e
f055f055-1ca2-404b-8e20-326b0c19e3f4	fde2c0d1-6789-41e9-8f76-3f1b1b0a97da
f055f055-1ca2-404b-8e20-326b0c19e3f4	04c0ebd4-698c-4980-a695-25b21daf55c3
f055f055-1ca2-404b-8e20-326b0c19e3f4	1b5ab645-3713-46a1-afc6-94331e74021c
f055f055-1ca2-404b-8e20-326b0c19e3f4	d1d37cfc-37d4-410b-8490-8f0a0e975f85
f055f055-1ca2-404b-8e20-326b0c19e3f4	770463bd-de1d-4fa9-85d4-7c4440d4ae34
f055f055-1ca2-404b-8e20-326b0c19e3f4	e9593a71-2be3-4031-994f-d11d6a7afbef
f055f055-1ca2-404b-8e20-326b0c19e3f4	b00fc68b-81b4-43b6-821a-b37172b2e333
f055f055-1ca2-404b-8e20-326b0c19e3f4	6a110911-a63b-443b-bf05-9460ba1a46b1
f055f055-1ca2-404b-8e20-326b0c19e3f4	6bb9c8e5-9a7e-46d7-8db8-9f7979c54e2a
f055f055-1ca2-404b-8e20-326b0c19e3f4	07878781-f051-45b9-863b-7870da6cd5d8
f055f055-1ca2-404b-8e20-326b0c19e3f4	2da6bf66-f113-48ef-b67f-ce65a79066b7
f055f055-1ca2-404b-8e20-326b0c19e3f4	d47f0201-99a5-49de-8878-164b3d994f0c
f055f055-1ca2-404b-8e20-326b0c19e3f4	a652aa15-4092-4775-aa1f-55ec1e5e2c35
f055f055-1ca2-404b-8e20-326b0c19e3f4	b1025ca3-1101-4049-b7fc-6726fa4b4c17
f055f055-1ca2-404b-8e20-326b0c19e3f4	9736d07f-d0ec-4d9f-a9e0-438628c5bbf4
f055f055-1ca2-404b-8e20-326b0c19e3f4	9e24d68d-fa6f-4df6-8d2f-5bab53514153
f055f055-1ca2-404b-8e20-326b0c19e3f4	100c0f6c-6d43-44a9-9d3d-a6e35d8c0c99
f055f055-1ca2-404b-8e20-326b0c19e3f4	7930fa58-de7d-4220-b09f-29ae3fcc5e3c
f055f055-1ca2-404b-8e20-326b0c19e3f4	9369a7da-5a9e-4879-82c5-d861b5d8587f
f055f055-1ca2-404b-8e20-326b0c19e3f4	528dad50-88ae-42bc-9bbc-fa9994945361
f055f055-1ca2-404b-8e20-326b0c19e3f4	e83d1a9a-f3a7-4400-8e7f-aa622131872a
f055f055-1ca2-404b-8e20-326b0c19e3f4	d1fae0ea-4759-4de4-bd19-e33de536d94f
f055f055-1ca2-404b-8e20-326b0c19e3f4	40e04f56-6f49-4d1b-bda3-285ffc779472
f055f055-1ca2-404b-8e20-326b0c19e3f4	2955b6e1-3bdb-4fa3-953d-5381045bf4a0
f055f055-1ca2-404b-8e20-326b0c19e3f4	81aa1778-001b-420c-9475-15d6c9686585
f055f055-1ca2-404b-8e20-326b0c19e3f4	ff29918f-7fb5-4d88-932c-ad2a4e88cb40
f055f055-1ca2-404b-8e20-326b0c19e3f4	096e2921-0efb-4822-8b9b-94bd46e4670f
fa805b7b-555c-4794-a668-dc4bfc341b0d	100c0f6c-6d43-44a9-9d3d-a6e35d8c0c99
fa805b7b-555c-4794-a668-dc4bfc341b0d	d1fae0ea-4759-4de4-bd19-e33de536d94f
fa805b7b-555c-4794-a668-dc4bfc341b0d	2955b6e1-3bdb-4fa3-953d-5381045bf4a0
fa805b7b-555c-4794-a668-dc4bfc341b0d	ff29918f-7fb5-4d88-932c-ad2a4e88cb40
fa355676-506c-4015-905c-0181c3d19e55	04c0ebd4-698c-4980-a695-25b21daf55c3
fa355676-506c-4015-905c-0181c3d19e55	100c0f6c-6d43-44a9-9d3d-a6e35d8c0c99
fa355676-506c-4015-905c-0181c3d19e55	d1fae0ea-4759-4de4-bd19-e33de536d94f
fa355676-506c-4015-905c-0181c3d19e55	2955b6e1-3bdb-4fa3-953d-5381045bf4a0
fa355676-506c-4015-905c-0181c3d19e55	ff29918f-7fb5-4d88-932c-ad2a4e88cb40
fa355676-506c-4015-905c-0181c3d19e55	b00fc68b-81b4-43b6-821a-b37172b2e333
fa355676-506c-4015-905c-0181c3d19e55	6a110911-a63b-443b-bf05-9460ba1a46b1
fa355676-506c-4015-905c-0181c3d19e55	6bb9c8e5-9a7e-46d7-8db8-9f7979c54e2a
fa355676-506c-4015-905c-0181c3d19e55	9369a7da-5a9e-4879-82c5-d861b5d8587f
f055f055-1ca2-404b-8e20-326b0c19e3f4	0ba23d6c-8104-40be-b7ee-fa0cb9ab07b8
f055f055-1ca2-404b-8e20-326b0c19e3f4	9e2b81a1-14eb-4fc1-b2f1-33d33217c582
f055f055-1ca2-404b-8e20-326b0c19e3f4	68d9e370-b812-4aca-9fd3-df462fc0e108
f055f055-1ca2-404b-8e20-326b0c19e3f4	3383071b-5a19-4785-97e2-df2b2a13061a
f055f055-1ca2-404b-8e20-326b0c19e3f4	9a3d0844-0ff7-4964-a5f6-10f53972f226
f055f055-1ca2-404b-8e20-326b0c19e3f4	2789e0b2-92d6-4d8b-a5d1-45c68314a423
f055f055-1ca2-404b-8e20-326b0c19e3f4	b0bcdce0-d277-4ca6-b0b0-8bf484278ed9
b51de082-f56c-4b24-8a23-1318ae0f663f	8b36f5be-62fb-4daa-b055-b555fb94ff6f
b51de082-f56c-4b24-8a23-1318ae0f663f	fde2c0d1-6789-41e9-8f76-3f1b1b0a97da
b51de082-f56c-4b24-8a23-1318ae0f663f	04c0ebd4-698c-4980-a695-25b21daf55c3
b51de082-f56c-4b24-8a23-1318ae0f663f	1b5ab645-3713-46a1-afc6-94331e74021c
b51de082-f56c-4b24-8a23-1318ae0f663f	d1d37cfc-37d4-410b-8490-8f0a0e975f85
b51de082-f56c-4b24-8a23-1318ae0f663f	b00fc68b-81b4-43b6-821a-b37172b2e333
b51de082-f56c-4b24-8a23-1318ae0f663f	6a110911-a63b-443b-bf05-9460ba1a46b1
b51de082-f56c-4b24-8a23-1318ae0f663f	6bb9c8e5-9a7e-46d7-8db8-9f7979c54e2a
b51de082-f56c-4b24-8a23-1318ae0f663f	07878781-f051-45b9-863b-7870da6cd5d8
b51de082-f56c-4b24-8a23-1318ae0f663f	2da6bf66-f113-48ef-b67f-ce65a79066b7
b51de082-f56c-4b24-8a23-1318ae0f663f	100c0f6c-6d43-44a9-9d3d-a6e35d8c0c99
b51de082-f56c-4b24-8a23-1318ae0f663f	7930fa58-de7d-4220-b09f-29ae3fcc5e3c
b51de082-f56c-4b24-8a23-1318ae0f663f	9369a7da-5a9e-4879-82c5-d861b5d8587f
b51de082-f56c-4b24-8a23-1318ae0f663f	528dad50-88ae-42bc-9bbc-fa9994945361
b51de082-f56c-4b24-8a23-1318ae0f663f	e83d1a9a-f3a7-4400-8e7f-aa622131872a
b51de082-f56c-4b24-8a23-1318ae0f663f	d1fae0ea-4759-4de4-bd19-e33de536d94f
b51de082-f56c-4b24-8a23-1318ae0f663f	40e04f56-6f49-4d1b-bda3-285ffc779472
b51de082-f56c-4b24-8a23-1318ae0f663f	2955b6e1-3bdb-4fa3-953d-5381045bf4a0
b51de082-f56c-4b24-8a23-1318ae0f663f	81aa1778-001b-420c-9475-15d6c9686585
b51de082-f56c-4b24-8a23-1318ae0f663f	ff29918f-7fb5-4d88-932c-ad2a4e88cb40
b51de082-f56c-4b24-8a23-1318ae0f663f	096e2921-0efb-4822-8b9b-94bd46e4670f
b51de082-f56c-4b24-8a23-1318ae0f663f	0ba23d6c-8104-40be-b7ee-fa0cb9ab07b8
b51de082-f56c-4b24-8a23-1318ae0f663f	9e2b81a1-14eb-4fc1-b2f1-33d33217c582
b51de082-f56c-4b24-8a23-1318ae0f663f	68d9e370-b812-4aca-9fd3-df462fc0e108
b51de082-f56c-4b24-8a23-1318ae0f663f	3383071b-5a19-4785-97e2-df2b2a13061a
b51de082-f56c-4b24-8a23-1318ae0f663f	9a3d0844-0ff7-4964-a5f6-10f53972f226
b51de082-f56c-4b24-8a23-1318ae0f663f	2789e0b2-92d6-4d8b-a5d1-45c68314a423
b51de082-f56c-4b24-8a23-1318ae0f663f	b0bcdce0-d277-4ca6-b0b0-8bf484278ed9
ca8e4304-892c-4da0-b335-3dd2d858560e	8b36f5be-62fb-4daa-b055-b555fb94ff6f
ca8e4304-892c-4da0-b335-3dd2d858560e	04c0ebd4-698c-4980-a695-25b21daf55c3
ca8e4304-892c-4da0-b335-3dd2d858560e	d1d37cfc-37d4-410b-8490-8f0a0e975f85
ca8e4304-892c-4da0-b335-3dd2d858560e	b00fc68b-81b4-43b6-821a-b37172b2e333
ca8e4304-892c-4da0-b335-3dd2d858560e	6a110911-a63b-443b-bf05-9460ba1a46b1
ca8e4304-892c-4da0-b335-3dd2d858560e	6bb9c8e5-9a7e-46d7-8db8-9f7979c54e2a
ca8e4304-892c-4da0-b335-3dd2d858560e	100c0f6c-6d43-44a9-9d3d-a6e35d8c0c99
ca8e4304-892c-4da0-b335-3dd2d858560e	9369a7da-5a9e-4879-82c5-d861b5d8587f
ca8e4304-892c-4da0-b335-3dd2d858560e	528dad50-88ae-42bc-9bbc-fa9994945361
ca8e4304-892c-4da0-b335-3dd2d858560e	e83d1a9a-f3a7-4400-8e7f-aa622131872a
ca8e4304-892c-4da0-b335-3dd2d858560e	2955b6e1-3bdb-4fa3-953d-5381045bf4a0
ca8e4304-892c-4da0-b335-3dd2d858560e	81aa1778-001b-420c-9475-15d6c9686585
ca8e4304-892c-4da0-b335-3dd2d858560e	ff29918f-7fb5-4d88-932c-ad2a4e88cb40
df64b9e3-e40e-473a-9804-ddbfe7baf79f	8b36f5be-62fb-4daa-b055-b555fb94ff6f
df64b9e3-e40e-473a-9804-ddbfe7baf79f	04c0ebd4-698c-4980-a695-25b21daf55c3
df64b9e3-e40e-473a-9804-ddbfe7baf79f	d1d37cfc-37d4-410b-8490-8f0a0e975f85
df64b9e3-e40e-473a-9804-ddbfe7baf79f	b00fc68b-81b4-43b6-821a-b37172b2e333
df64b9e3-e40e-473a-9804-ddbfe7baf79f	6a110911-a63b-443b-bf05-9460ba1a46b1
df64b9e3-e40e-473a-9804-ddbfe7baf79f	6bb9c8e5-9a7e-46d7-8db8-9f7979c54e2a
df64b9e3-e40e-473a-9804-ddbfe7baf79f	2da6bf66-f113-48ef-b67f-ce65a79066b7
df64b9e3-e40e-473a-9804-ddbfe7baf79f	100c0f6c-6d43-44a9-9d3d-a6e35d8c0c99
df64b9e3-e40e-473a-9804-ddbfe7baf79f	9369a7da-5a9e-4879-82c5-d861b5d8587f
df64b9e3-e40e-473a-9804-ddbfe7baf79f	528dad50-88ae-42bc-9bbc-fa9994945361
df64b9e3-e40e-473a-9804-ddbfe7baf79f	d1fae0ea-4759-4de4-bd19-e33de536d94f
df64b9e3-e40e-473a-9804-ddbfe7baf79f	40e04f56-6f49-4d1b-bda3-285ffc779472
df64b9e3-e40e-473a-9804-ddbfe7baf79f	2955b6e1-3bdb-4fa3-953d-5381045bf4a0
df64b9e3-e40e-473a-9804-ddbfe7baf79f	ff29918f-7fb5-4d88-932c-ad2a4e88cb40
df64b9e3-e40e-473a-9804-ddbfe7baf79f	0ba23d6c-8104-40be-b7ee-fa0cb9ab07b8
df64b9e3-e40e-473a-9804-ddbfe7baf79f	9a3d0844-0ff7-4964-a5f6-10f53972f226
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, is_system_role, created_at, updated_at) FROM stdin;
f055f055-1ca2-404b-8e20-326b0c19e3f4	Admin	t	2026-01-21 13:08:02.750605	2026-01-26 13:48:54.735309
ca8e4304-892c-4da0-b335-3dd2d858560e	Expert	f	2026-01-24 12:51:50.676887	2026-01-26 13:48:54.735309
b51de082-f56c-4b24-8a23-1318ae0f663f	Manager	f	2026-01-26 13:48:54.735309	2026-01-26 13:48:54.735309
df64b9e3-e40e-473a-9804-ddbfe7baf79f	Sales	f	2026-01-26 13:48:54.735309	2026-01-26 13:48:54.735309
fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	t	2026-01-30 15:15:14.398972	2026-01-30 15:15:14.398972
fa355676-506c-4015-905c-0181c3d19e55	Customer	f	2026-01-30 15:04:46.432139	2026-02-02 13:36:59.90149
\.


--
-- Data for Name: service_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_categories (id, name, description, image_url, icon, display_order, is_active, created_at, updated_at) FROM stdin;
3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Hair Services	Hair cutting, coloring and treatment services	https://salon-app-assets-saad.s3.amazonaws.com/assets/FeatherCutting.png	\N	1	t	2026-01-23 12:11:38.652904	2026-01-23 15:31:59.460347
a99119ae-288a-430b-8973-1a27447fdce0	Makeup Services	Makeup services	https://salon-app-assets-saad.s3.amazonaws.com/assets/MakeUp.jpg	\N	2	t	2026-01-23 12:11:38.681201	2026-01-23 15:31:59.482242
592e147c-f233-4686-8859-62bd36714354	Facial Services	Facial services and treatments	https://salon-app-assets-saad.s3.amazonaws.com/assets/FruitFacial.jpg	\N	3	t	2026-01-23 12:11:38.68532	2026-01-23 15:31:59.48451
23dcd0db-5d9a-4e83-af38-1e71a9604a20	Massage Services	Massage services	https://salon-app-assets-saad.s3.amazonaws.com/assets/DeepTissueMassage.jpg	\N	4	t	2026-01-23 12:11:38.688799	2026-01-23 15:31:59.487484
73547fdd-155a-4bf4-9afd-af609c715615	Mehndi Services	Mehndi services	https://salon-app-assets-saad.s3.amazonaws.com/assets/Mehndi.jpg	\N	5	t	2026-01-23 12:11:38.691962	2026-01-23 15:31:59.490295
dd4f4dde-94ab-413f-af71-f74af8ba2f68	Waxing Services	Waxing services	https://salon-app-assets-saad.s3.amazonaws.com/assets/Waxing.jpg	\N	6	t	2026-01-23 12:11:38.695928	2026-01-23 15:31:59.492158
d9010f77-82ff-40d9-b204-0f9a40a6efb0	PhotoShoot Services	Photoshoot services	https://salon-app-assets-saad.s3.amazonaws.com/assets/PhotoShoot.jpg	\N	7	t	2026-01-23 12:11:38.70279	2026-01-23 15:31:59.495114
\.


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.services (id, category_id, name, description, price, duration, image_url, tags, is_active, created_at, updated_at) FROM stdin;
e5be0f7d-3d46-4c57-94f2-be5397f4d0b9	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Long Layers Haircut	Classic long layers that add bounce, volume, and natural flow while keeping length intact.	1500.00	45	https://salon-app-assets-saad.s3.amazonaws.com/assets/LongLayerHaircut.png	{"Hair Cutting"}	t	2026-01-23 12:11:38.725103	2026-01-23 15:31:59.512631
724470a3-e44c-4937-8dee-338e8c331be5	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Bob Haircut	A sleek, stylish short haircut that can be worn straight or textured for a modern look.	2000.00	35	https://salon-app-assets-saad.s3.amazonaws.com/assets/BobHaircut.png	{"Hair Cutting"}	t	2026-01-23 12:11:38.728096	2026-01-23 15:31:59.515676
4418799c-07cf-4bef-b1a4-8a603d805a67	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Pixie Haircut	A chic, low-maintenance short cut that enhances your features with bold style.	3000.00	40	https://salon-app-assets-saad.s3.amazonaws.com/assets/PixieHaircut.png	{"Hair Cutting"}	t	2026-01-23 12:11:38.732698	2026-01-23 15:31:59.518224
d1d635ab-908e-4c6b-bd92-f19b5bbc17d5	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Bangs Haircut	Fresh, stylish bangs tailored to your face shape for a youthful and trendy look.	2500.00	25	https://salon-app-assets-saad.s3.amazonaws.com/assets/BangsHaircut.png	{"Hair Cutting"}	t	2026-01-23 12:11:38.736168	2026-01-23 15:31:59.519958
909fa458-4ffd-48a3-ab14-330f3e4ad740	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Wolf Haircut	A bold, edgy cut combining shaggy layers with a mullet-inspired shape for volume and texture.	1500.00	50	https://salon-app-assets-saad.s3.amazonaws.com/assets/WolfHaircut.png	{"Hair Cutting"}	t	2026-01-23 12:11:38.742411	2026-01-23 15:31:59.523315
ff6c706a-a0fa-4bb3-9254-3776e12b048f	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Blunt Haircut	A sharp, even-length haircut that gives a bold, sleek, and modern appearance.	1500.00	30	https://salon-app-assets-saad.s3.amazonaws.com/assets/BluntHaircut.jpg	{"Hair Cutting"}	t	2026-01-23 12:11:38.744877	2026-01-23 15:31:59.525163
d862d194-ac80-4d09-b487-eafe2386be74	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Baby Cutting	Gentle, safe haircutting service for kids, keeping them comfortable and stylish.	1500.00	25	https://salon-app-assets-saad.s3.amazonaws.com/assets/BabyCutting.jpg	{"Hair Cutting"}	t	2026-01-23 12:11:38.753177	2026-01-23 15:31:59.53098
f7f024a8-8f6e-41dd-8f8d-e4ae61fca518	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Feather Haircut	A soft, feathered layering technique that adds shape, volume, and lightness to your hair.	2500.00	45	https://salon-app-assets-saad.s3.amazonaws.com/assets/FeatherCutting.png	{"Hair Cutting"}	t	2026-01-23 12:11:38.75635	2026-01-23 15:31:59.532978
b5dc57bd-f3ef-4b07-a7b1-9e057be57971	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Ironing/Straightening	Temporary straightening with a flat iron to achieve sleek, shiny, and smooth hair.	1000.00	45	https://salon-app-assets-saad.s3.amazonaws.com/assets/HairIroningAndStraightening.jpg	{"Hair Cutting"}	t	2026-01-23 12:11:38.761838	2026-01-23 15:31:59.536963
0136b74d-7897-4945-ac4d-917f50d0b9a2	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Curls/ Waves	Heat-styled curls or waves for a glamorous, voluminous, and party-ready look.	2000.00	45	https://salon-app-assets-saad.s3.amazonaws.com/assets/CurlsAndWaves.jpg	{"Hair Cutting"}	t	2026-01-23 12:11:38.766113	2026-01-23 15:31:59.538684
4f298868-a444-4d44-98a4-134e6775e802	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Root Touch-up	Covers regrowth and restores even hair color, keeping your roots fresh and flawless.	2500.00	40	https://salon-app-assets-saad.s3.amazonaws.com/assets/RootTouchUp.jpg	{"Hair Color"}	t	2026-01-23 12:11:38.770236	2026-01-23 15:31:59.541225
557cd9fa-bd31-4d92-bfa1-96b397c41ef9	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Color Cut Down	Removes or tones down existing hair color safely to prepare for a fresh look.	6500.00	50	https://salon-app-assets-saad.s3.amazonaws.com/assets/ColorCutDown.jpg	{"Hair Color"}	t	2026-01-23 12:11:38.776002	2026-01-23 15:31:59.546004
eb28b40b-69b7-42a3-a8c3-5e076034fee1	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Highlights (Full/Half)	Adds dimension and brightness with partial or full highlights tailored to your style.	8000.00	90	https://salon-app-assets-saad.s3.amazonaws.com/assets/Highlights.jpg	{"Hair Color"}	t	2026-01-23 12:11:38.780297	2026-01-23 15:31:59.548884
8239b8f0-ac06-4774-8408-eff2fa640aa6	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Per Foil Highlights (Full)	Foil highlights for full-length hair to achieve a bright, multi-dimensional look.	12000.00	130	https://salon-app-assets-saad.s3.amazonaws.com/assets/PerFoilFull.jpg	{"Hair Color"}	t	2026-01-23 12:11:38.789763	2026-01-23 15:31:59.554704
2bff9b05-f65d-4add-9fdc-ba1ed45fe459	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Hair Spa	A relaxing spa therapy that deeply nourishes, repairs, and revitalizes dry or damaged hair.	2500.00	60	https://salon-app-assets-saad.s3.amazonaws.com/assets/HairSpa.png	{"Hair Treatment"}	t	2026-01-23 12:11:38.793593	2026-01-23 15:31:59.557963
81b7acae-ca50-4972-bb3d-7e7d327f863c	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Deep Conditioning + Blowdry	An intensive conditioning treatment followed by a professional blow-dry for smooth, silky, and frizz-free hair.	1500.00	45	https://salon-app-assets-saad.s3.amazonaws.com/assets/DeepConditioning.png	{"Hair Treatment"}	t	2026-01-23 12:11:38.797023	2026-01-23 15:31:59.559521
4f6647de-4eb0-4c28-9ed5-14d0d637d7fe	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Protein Treatment	Rebuilds and strengthens weak, brittle, or chemically treated hair by restoring lost proteins.	18000.00	90	https://salon-app-assets-saad.s3.amazonaws.com/assets/ProteinTreatment.png	{"Hair Treatment"}	t	2026-01-23 12:11:38.802871	2026-01-23 15:31:59.565744
6856fbf4-b51b-4727-840d-13ab75e0d1db	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Extenso Treatment (6 Sessions)	A professional hair straightening system that gives smooth, sleek, and manageable hair across multiple sessions.	45000.00	150	https://salon-app-assets-saad.s3.amazonaws.com/assets/ExtensoTreatment.png	{"Hair Treatment"}	t	2026-01-23 12:11:38.805699	2026-01-23 15:31:59.56775
5dd5144a-64ca-46e8-b40f-bee53450dd6f	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Herbal Treatment	An herbal therapy using natural extracts to reduce dandruff, strengthen roots, and improve scalp health.	4000.00	60	https://salon-app-assets-saad.s3.amazonaws.com/assets/HerbalTreatment.jpg	{"Hair Treatment"}	t	2026-01-23 12:11:38.80856	2026-01-23 15:31:59.569457
4a62c358-4122-4e8c-a286-23005b32e9be	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Smoothening / Rebounding	A semi-permanent straightening treatment that smooths frizz and makes hair silky, shiny, and manageable.	3500.00	210	https://salon-app-assets-saad.s3.amazonaws.com/assets/Smoothening.png	{"Hair Treatment"}	t	2026-01-23 12:11:38.811126	2026-01-23 15:31:59.571088
137d9643-1106-4aa8-a673-dc11b69d4cb9	a99119ae-288a-430b-8973-1a27447fdce0	Party Makeup (Pakistani)	A traditional Pakistani party look with soft glam, defined eyes, and flawless base for birthdays, dinners, or casual events.	7000.00	60	https://salon-app-assets-saad.s3.amazonaws.com/assets/PartyMakeup.jpg	{}	t	2026-01-23 12:11:38.820291	2026-01-23 15:31:59.576439
f8e5838a-2abd-4d59-8559-119837b06b84	a99119ae-288a-430b-8973-1a27447fdce0	Turkish Party Look	A natural Turkish-inspired soft glam with subtle tones, glowing skin, and light eye makeup for a fresh look.	5000.00	45	https://salon-app-assets-saad.s3.amazonaws.com/assets/LightPartyLook.jpg	{}	t	2026-01-23 12:11:38.822909	2026-01-23 15:31:59.579374
34bca6dc-956f-4824-9243-09de43d18c84	a99119ae-288a-430b-8973-1a27447fdce0	Smokey & Glam Look	Dramatic smokey eyes paired with bold lips and glowing skin — perfect for night parties, receptions, and red-carpet glam.	15000.00	75	https://salon-app-assets-saad.s3.amazonaws.com/assets/GlamLook.png	{}	t	2026-01-23 12:11:38.825263	2026-01-23 15:31:59.582212
a8ad2ca2-c89a-40c9-a826-7767e41b74de	a99119ae-288a-430b-8973-1a27447fdce0	Engagement Look	A semi-glam, graceful makeup style with soft shimmer and radiant base, tailored for engagement ceremonies.	15000.00	90	https://salon-app-assets-saad.s3.amazonaws.com/assets/EngagementLook.jpg	{}	t	2026-01-23 12:11:38.827632	2026-01-23 15:31:59.583834
22157bd7-07b9-4a9b-a18b-9abb35c83bb4	a99119ae-288a-430b-8973-1a27447fdce0	Nikkah Signature Makeup	A soft yet elegant bridal look with pastel tones, natural glam, and a flawless long-lasting base for Nikkah ceremonies.	20000.00	120	https://salon-app-assets-saad.s3.amazonaws.com/assets/NikkahLook.jpg	{}	t	2026-01-23 12:11:38.831971	2026-01-23 15:31:59.58532
3cd3b20e-5102-4c57-99d2-71cf58f6645e	a99119ae-288a-430b-8973-1a27447fdce0	Full Bridal Package	Complete bridal package including Nikkah, Barat, and Walima looks — ensuring flawless glam for all wedding events.	45000.00	150	https://salon-app-assets-saad.s3.amazonaws.com/assets/BridalPackage.jpg	{}	t	2026-01-23 12:11:38.843716	2026-01-23 15:31:59.58996
3bb84b22-c054-4954-8125-f135d8f7015e	a99119ae-288a-430b-8973-1a27447fdce0	Sangeet Makeup	A colorful, festive look with shimmery eyes and radiant glow, designed to complement vibrant sangeet celebrations.	10000.00	90	https://salon-app-assets-saad.s3.amazonaws.com/assets/Sangeet.png	{}	t	2026-01-23 12:11:38.846409	2026-01-23 15:31:59.591583
a41f0c23-0223-4413-953f-7a1e4cefdfb1	592e147c-f233-4686-8859-62bd36714354	CleanUp	A basic cleansing treatment that removes dirt, excess oil, and impurities to refresh your skin.	1200.00	25	https://salon-app-assets-saad.s3.amazonaws.com/assets/CleanUpFacial.jpg	{Facial}	t	2026-01-23 12:11:38.851258	2026-01-23 15:31:59.595873
d17e9043-d10c-4f77-8522-d37f5f6c4275	592e147c-f233-4686-8859-62bd36714354	Fruit Facial	Infused with natural fruit extracts to deeply nourish, hydrate, and brighten dull skin.	3500.00	40	https://salon-app-assets-saad.s3.amazonaws.com/assets/FruitFacial.jpg	{Facial}	t	2026-01-23 12:11:38.853661	2026-01-23 15:31:59.598763
3d711be5-a8f4-40f1-aafa-1dff983c7426	592e147c-f233-4686-8859-62bd36714354	Gold/Diamond/Pearl Facial	A luxurious facial enriched with gold, diamond, or pearl extracts to rejuvenate and brighten.	4500.00	50	https://salon-app-assets-saad.s3.amazonaws.com/assets/GoldPearlFacial.jpg	{Facial}	t	2026-01-23 12:11:38.858611	2026-01-23 15:31:59.602292
158e9fd5-d675-4e30-8f02-4a50b5ab42e2	592e147c-f233-4686-8859-62bd36714354	Brightening Facial	Targets uneven skin tone, dullness, and dark spots for a visibly brighter complexion.	3500.00	55	https://salon-app-assets-saad.s3.amazonaws.com/assets/BrighteningFacial.jpg	{Facial}	t	2026-01-23 12:11:38.861884	2026-01-23 15:31:59.604285
f32b8e29-bf33-4f4d-9b07-08f8f9e918f0	592e147c-f233-4686-8859-62bd36714354	Skin Whitening / De-tan	Reduces tanning, pigmentation, and sun damage while restoring natural fairness and glow.	4500.00	60	https://salon-app-assets-saad.s3.amazonaws.com/assets/SkinWhitening.jpg	{Facial}	t	2026-01-23 12:11:38.866358	2026-01-23 15:31:59.605812
39dff771-3916-4398-9fc0-b586d80698a4	592e147c-f233-4686-8859-62bd36714354	Hydra Facial	An advanced facial that deeply cleanses, exfoliates, hydrates, and infuses antioxidants for instantly radiant and refreshed skin.	9000.00	70	https://salon-app-assets-saad.s3.amazonaws.com/assets/HydraFacial.jpg	{Treatment}	t	2026-01-23 12:11:38.873121	2026-01-23 15:31:59.609933
a6f60432-90b2-4bf9-a914-7ccb7d39f2b7	592e147c-f233-4686-8859-62bd36714354	Serum Infusion	A quick yet powerful treatment that infuses high-performance serums to nourish, repair, and boost skin glow.	1000.00	40	https://salon-app-assets-saad.s3.amazonaws.com/assets/SerumInfusion.jpg	{Treatment}	t	2026-01-23 12:11:38.876873	2026-01-23 15:31:59.613432
1aa2b812-e8ab-40c5-b78b-1e6ef277dba0	592e147c-f233-4686-8859-62bd36714354	Acne Treatment	Specialized therapy to control breakouts, reduce acne marks, calm irritation, and promote clearer skin.	5500.00	55	https://salon-app-assets-saad.s3.amazonaws.com/assets/AcneTreatment.jpg	{Treatment}	t	2026-01-23 12:11:38.879657	2026-01-23 15:31:59.616176
46cff173-c5f4-41dd-a8b0-3c418798adec	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Body Massage (Full)	A complete relaxation massage using long, flowing strokes to release stress, improve circulation, and ease muscle tension from head to toe.	3500.00	75	https://salon-app-assets-saad.s3.amazonaws.com/assets/FullBodyMassage.jpg	{}	t	2026-01-23 12:11:38.887642	2026-01-23 15:31:59.621466
5bfc2457-15f8-44b5-a9e1-947681cc5553	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Swedish Massage	A classic massage style that uses gentle to medium pressure strokes to improve blood flow, reduce stress, and promote overall relaxation.	6500.00	60	https://salon-app-assets-saad.s3.amazonaws.com/assets/SwedishMassage.png	{}	t	2026-01-23 12:11:38.89026	2026-01-23 15:31:59.623039
50362ea3-1f07-4d0d-9cb9-5d7abecd9544	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Deep Tissue	Targets deeper layers of muscles and connective tissue to relieve stiffness, knots, and chronic muscle pain.	4500.00	60	https://salon-app-assets-saad.s3.amazonaws.com/assets/DeepTissueMassage.jpg	{}	t	2026-01-23 12:11:38.892602	2026-01-23 15:31:59.624309
2220d271-29d8-4721-bf13-406ebf41ab41	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Aromatherapy (Medical Therapy)	A relaxing massage combined with essential oils to calm the mind, reduce stress, and support overall well-being.	9500.00	45	https://salon-app-assets-saad.s3.amazonaws.com/assets/AromatherapyMassage.png	{}	t	2026-01-23 12:11:38.894888	2026-01-23 15:31:59.626023
03fc406e-9cad-43b5-bfce-4d5bc27ca2bd	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Scalp Massage	Gentle massage focusing on the scalp and pressure points to relieve headaches, improve blood flow, and promote hair growth.	1000.00	25	https://salon-app-assets-saad.s3.amazonaws.com/assets/ScalpMassage.png	{}	t	2026-01-23 12:11:38.901387	2026-01-23 15:31:59.632293
ee62a4d8-91f4-41a7-b1c3-79702b6474d0	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Neck & Shoulder Relief	Focused massage on the neck and shoulder area to relieve stiffness, tension, and pain caused by stress or long hours at work.	1500.00	38	https://salon-app-assets-saad.s3.amazonaws.com/assets/NeckAndShoulderRelief.jpg	{}	t	2026-01-23 12:11:38.903989	2026-01-23 15:31:59.634349
59cc3502-57f4-4e8f-8628-30d00d3dfd3e	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Relaxing Foot Massage	A soothing foot massage with pressure point therapy to relieve fatigue, improve circulation, and restore body balance.	1000.00	38	https://salon-app-assets-saad.s3.amazonaws.com/assets/RelaxingFoot.png	{}	t	2026-01-23 12:11:38.906565	2026-01-23 15:31:59.636261
4e424445-fb15-4a27-b530-e96be5586399	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Stress Relief Session	A quick, refreshing session targeting stress points in the body to calm the mind, relax muscles, and boost energy instantly.	2500.00	30	https://salon-app-assets-saad.s3.amazonaws.com/assets/StressRelief.jpg	{}	t	2026-01-23 12:11:38.909533	2026-01-23 15:31:59.637567
5fc0e90e-b030-40fc-879e-85c2bfc40250	73547fdd-155a-4bf4-9afd-af609c715615	Hands	Beautiful traditional mehndi applied on both palms with elegant patterns, perfect for festive occasions.	500.00	38	https://salon-app-assets-saad.s3.amazonaws.com/assets/HandMehndi.png	{}	t	2026-01-23 12:11:38.915129	2026-01-23 15:31:59.63963
278ddc1a-dcaf-4371-bc9f-c43009a83bde	73547fdd-155a-4bf4-9afd-af609c715615	Full Arm	Intricate mehndi designs covering from palms up to the elbow, giving a traditional and graceful bridal look.	1500.00	150	https://salon-app-assets-saad.s3.amazonaws.com/assets/FullArmMehndi.png	{}	t	2026-01-23 12:11:38.921354	2026-01-23 15:31:59.642597
8e461aaa-388b-4b5b-8c9a-66cde50fd519	73547fdd-155a-4bf4-9afd-af609c715615	Foot Mehndi	Delicate and creative mehndi patterns applied on the feet and ankles, enhancing the overall festive look.	500.00	53	https://salon-app-assets-saad.s3.amazonaws.com/assets/FootMehndi.jpg	{}	t	2026-01-23 12:11:38.924473	2026-01-23 15:31:59.643947
5b29695c-9da3-4189-be2d-e4d1ad05eed2	73547fdd-155a-4bf4-9afd-af609c715615	Bridal Mehndi	Customized, detailed bridal mehndi covering full hands and feet with intricate patterns, perfect for the wedding day.	7500.00	300	https://salon-app-assets-saad.s3.amazonaws.com/assets/BridalMehndi.jpg	{}	t	2026-01-23 12:11:38.927066	2026-01-23 15:31:59.647358
af19499d-91e6-4711-bbd5-2a5d3aefc839	dd4f4dde-94ab-413f-af71-f74af8ba2f68	Full Arms	Removes unwanted hair from both arms, leaving the skin smooth and soft.	800.00	23	https://salon-app-assets-saad.s3.amazonaws.com/assets/FullArmWax.jpg	{}	t	2026-01-23 12:11:38.931875	2026-01-23 15:31:59.650678
d4db535b-a8c2-4e60-ad3a-d02b01ad54d8	dd4f4dde-94ab-413f-af71-f74af8ba2f68	Underarms	Quick and gentle waxing for underarms, ensuring freshness and smooth skin.	400.00	13	https://salon-app-assets-saad.s3.amazonaws.com/assets/UnderArmWaxing.jpg	{}	t	2026-01-23 12:11:38.936318	2026-01-23 15:31:59.654487
19598d7f-0834-4241-841c-2f8b8aa7ed98	dd4f4dde-94ab-413f-af71-f74af8ba2f68	Full Body Waxing	Comprehensive waxing for the entire body, removing hair from arms, legs, underarms, and more.	8500.00	105	https://salon-app-assets-saad.s3.amazonaws.com/assets/FullBodyWaxing.jpg	{}	t	2026-01-23 12:11:38.938857	2026-01-23 15:31:59.655966
4b8c6cea-8c31-40e9-acdd-6eef5a2a6e91	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Wispy Haircut	A soft, layered cut with feathered ends that adds lightness, movement, and a feminine frame to your face.	2500.00	40	https://salon-app-assets-saad.s3.amazonaws.com/assets/WispyHaircut.png	{"Hair Cutting"}	t	2026-01-23 12:11:38.712215	2026-01-23 15:31:59.506975
fda31bd9-6c67-4c60-89aa-7b4eba511bfb	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Butterfly Haircut	A layered haircut with face-framing waves that creates volume and a soft, fluttery effect.	2000.00	50	https://salon-app-assets-saad.s3.amazonaws.com/assets/ButterflyHaircut.png	{"Hair Cutting"}	t	2026-01-23 12:11:38.739022	2026-01-23 15:31:59.52178
dedff1de-6597-461b-9266-af0dd8222d4e	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Baby Bangs	Short, edgy bangs cut above the eyebrows for a bold and stylish statement look.	15000.00	20	https://salon-app-assets-saad.s3.amazonaws.com/assets/BabyBangsHaircut.jpg	{"Hair Cutting"}	t	2026-01-23 12:11:38.749116	2026-01-27 13:58:33.928321
e1e4964a-d6ac-44f8-8155-85ee6a4ca86c	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Wash/ Blow dry	Professional wash followed by a smooth blow-dry for silky, bouncy, and styled hair.	1500.00	35	https://salon-app-assets-saad.s3.amazonaws.com/assets/BlowDryAndStraigntening.jpg	{"Hair Cutting"}	t	2026-01-23 12:11:38.759026	2026-01-23 15:31:59.534556
05cfce85-a376-4725-b212-db82967c7457	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	One Tone Dye	Single-shade hair coloring for a rich, uniform, and vibrant look.	5000.00	60	https://salon-app-assets-saad.s3.amazonaws.com/assets/OneToneDye.jpg	{"Hair Color"}	t	2026-01-23 12:11:38.773043	2026-01-23 15:31:59.543172
c792a128-842b-43b3-bf54-0c0d675db0dd	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Per Foil Highlights (Shoulder)	Foil highlights for shoulder-length hair to create contrast, depth, and shine.	8000.00	100	https://salon-app-assets-saad.s3.amazonaws.com/assets/PerFoilShoulder.jpg	{"Hair Color"}	t	2026-01-23 12:11:38.786905	2026-01-23 15:31:59.552912
ab9e0720-f8a3-48ea-81a9-f4277f959d7e	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Keratin Treatment	A smoothing therapy that reduces frizz, strengthens hair, and adds lasting shine with keratin infusion.	12000.00	150	https://salon-app-assets-saad.s3.amazonaws.com/assets/KeratinTreatment.png	{"Hair Treatment"}	t	2026-01-23 12:11:38.799983	2026-01-23 15:31:59.562782
732ea198-c390-4abc-8dc6-25bcaf9c2994	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Scalp Treatment	Targets scalp concerns such as dandruff, dryness, or excess oil while boosting circulation and promoting healthy growth.	6500.00	50	https://salon-app-assets-saad.s3.amazonaws.com/assets/ScalpTreatment.png	{"Hair Treatment"}	t	2026-01-23 12:11:38.815849	2026-01-23 15:31:59.573119
39de7caf-813a-42c5-8a5e-8eee4a752535	a99119ae-288a-430b-8973-1a27447fdce0	Barat Signature Makeup	A bold, vibrant, and full-coverage bridal look for Barat day, complete with detailed eye makeup and traditional glam.	35000.00	180	https://salon-app-assets-saad.s3.amazonaws.com/assets/BaratLook.jpg	{}	t	2026-01-23 12:11:38.836851	2026-01-23 15:31:59.587175
54d9a2e6-88f4-40d4-8016-94233f1970ff	a99119ae-288a-430b-8973-1a27447fdce0	Walima Signature Makeup	A soft glam Walima look with elegant tones, glowing skin, and graceful styling for a dreamy bridal appearance.	30000.00	120	https://salon-app-assets-saad.s3.amazonaws.com/assets/WalimaLook.jpg	{}	t	2026-01-23 12:11:38.839732	2026-01-23 15:31:59.588701
bcc8df15-d7c1-4951-8a7e-ddd98f119ecb	592e147c-f233-4686-8859-62bd36714354	Glow Facial	Gives your skin an instant boost of radiance, leaving it soft, fresh, and luminous.	1500.00	35	https://salon-app-assets-saad.s3.amazonaws.com/assets/GlowFacial.jpg	{Facial}	t	2026-01-23 12:11:38.856157	2026-01-23 15:31:59.600417
b49f88fb-ca53-46b8-ae7a-f94735ffd511	592e147c-f233-4686-8859-62bd36714354	Vitamin C Facial	Packed with Vitamin C to fade dark spots, improve texture, and leave skin visibly radiant.	2500.00	65	https://salon-app-assets-saad.s3.amazonaws.com/assets/VitaminCFacial.jpg	{Facial}	t	2026-01-23 12:11:38.869088	2026-01-23 15:31:59.607248
2a017bf1-8511-4ea0-8abd-100ede5ed88c	592e147c-f233-4686-8859-62bd36714354	Anti-Aging Facial	Designed to fight fine lines and wrinkles while boosting collagen production for firmer, youthful-looking skin.	2500.00	65	https://salon-app-assets-saad.s3.amazonaws.com/assets/AntiAgingFacial.jpg	{Treatment}	t	2026-01-23 12:11:38.883488	2026-01-23 15:31:59.618694
9558eea6-3b65-4665-8e2a-05a93f7c1c64	23dcd0db-5d9a-4e83-af38-1e71a9604a20	Therapeutic Massage (Fat Dissolving)	A specialized massage designed to stimulate circulation and target fat deposits, helping in body shaping and detoxification.	12500.00	53	https://salon-app-assets-saad.s3.amazonaws.com/assets/TherapeuticMassage.jpg	{}	t	2026-01-23 12:11:38.898805	2026-01-23 15:31:59.629285
edf705bb-956a-4b32-b588-2c179bbce81c	73547fdd-155a-4bf4-9afd-af609c715615	Half Arm	Stylish and detailed mehndi extending from palms to mid-arm, suitable for parties, Eid, or casual ceremonies.	1000.00	75	https://salon-app-assets-saad.s3.amazonaws.com/assets/HalfArm.jpg	{}	t	2026-01-23 12:11:38.918351	2026-01-23 15:31:59.641029
675c4b3d-0f34-4fbc-ac9c-ecb4af0865b4	dd4f4dde-94ab-413f-af71-f74af8ba2f68	Full Legs	Complete waxing for both legs, giving a silky and clean finish.	1400.00	35	https://salon-app-assets-saad.s3.amazonaws.com/assets/FullLegsWaxing.jpg	{}	t	2026-01-23 12:11:38.93417	2026-01-23 15:31:59.652541
00c6fefb-874a-46b9-a7ee-0a2e546b2346	dd4f4dde-94ab-413f-af71-f74af8ba2f68	Upper Lips	Removes fine hair from the upper lip area for a neat and clean look.	200.00	8	https://salon-app-assets-saad.s3.amazonaws.com/assets/UpperLips.jpg	{}	t	2026-01-23 12:11:38.941131	2026-01-23 15:31:59.65719
6e6f7f85-2c40-4a99-8136-2177d630d975	dd4f4dde-94ab-413f-af71-f74af8ba2f68	Chin	Targets unwanted hair on the chin area, leaving skin smooth and clear.	150.00	8	https://salon-app-assets-saad.s3.amazonaws.com/assets/ChinWaxing.jpg	{}	t	2026-01-23 12:11:38.943861	2026-01-23 15:31:59.65834
08b0e8f7-53f2-480a-b207-ce5233190318	dd4f4dde-94ab-413f-af71-f74af8ba2f68	Forehead	Removes excess hair from the forehead and hairline for a polished look.	350.00	13	https://salon-app-assets-saad.s3.amazonaws.com/assets/ForeheadWaxing.jpg	{}	t	2026-01-23 12:11:38.946322	2026-01-23 15:31:59.659407
87f90ab1-aac7-44f5-b2ff-8f04237f85a3	dd4f4dde-94ab-413f-af71-f74af8ba2f68	Full Face	Complete face waxing including upper lips, chin, forehead, and sides for a clean finish.	1000.00	28	https://salon-app-assets-saad.s3.amazonaws.com/assets/FullFaceWaxing.jpg	{}	t	2026-01-23 12:11:38.950166	2026-01-23 15:31:59.661747
c2cbd004-120f-4801-b5bf-1f2e20a41089	d9010f77-82ff-40d9-b204-0f9a40a6efb0	Bridal Shoot	A complete bridal photoshoot to capture your special day with professional lighting, poses, and editing.	15000.00	150	https://salon-app-assets-saad.s3.amazonaws.com/assets/BridalShoot.jpg	{}	t	2026-01-23 12:11:38.953978	2026-01-23 15:31:59.666034
0a17101a-6574-42e4-8d60-42575ae39d31	d9010f77-82ff-40d9-b204-0f9a40a6efb0	Couple Shoot	A romantic photoshoot for couples, capturing candid and posed moments indoors or outdoors.	25000.00	210	https://salon-app-assets-saad.s3.amazonaws.com/assets/CoupleShoot.jpg	{}	t	2026-01-23 12:11:38.956382	2026-01-23 15:31:59.66786
3bcc8ea3-c404-4b84-a9ce-60a1429fbfa5	d9010f77-82ff-40d9-b204-0f9a40a6efb0	Outdoor Shoot	A professional outdoor photography session at scenic locations, perfect for weddings, engagements, or portfolios.	40000.00	300	https://salon-app-assets-saad.s3.amazonaws.com/assets/OutdoorShoot.jpg	{}	t	2026-01-23 12:11:38.958959	2026-01-23 15:31:59.669394
c3b5a5b2-155f-4de0-aca9-14b1a10c0dd5	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	Cap Hair Streak	Classic cap technique to add streaks of lighter color for a bold, stylish effect.	12000.00	75	https://salon-app-assets-saad.s3.amazonaws.com/assets/CapHairStreak.jpg	{"Hair Color"}	t	2026-01-23 12:11:38.783909	2026-01-27 14:49:52.477764
06dfcc03-ad02-45e5-ba71-46910524ec26	3cb8f843-31da-4d7f-804f-bb6b2cbb159f	bangshaircutidk	idk	5.00	1	https://salon-app-assets-saad.s3.amazonaws.com/services/f41e91da-03e4-4894-804c-eed9a3117e04.png	{}	f	2026-01-23 16:01:39.737467	2026-01-27 14:58:12.055948
\.


--
-- Data for Name: sub_services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sub_services (id, service_id, name, description, price, duration, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, role_id, name, email, password_hash, address, phone, gender, profile_image_url, email_verified, verification_token, reset_password_token, reset_password_expires, failed_login_attempts, lockout_until, created_at, updated_at, last_login, verification_code, verification_code_expires_at, is_guest) FROM stdin;
809716db-5284-4afa-bf67-66cc66ea1268	fa355676-506c-4015-905c-0181c3d19e55	Guest	guest_809716db-5284-4afa-bf67-66cc66ea1268@salon.guest	$2a$10$XWigjrqD5L3ROcDX7BVZYeuZoSqi36fUgoo5Jmk0n0kgvprHF50fa	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:04:46.581721	2026-01-30 15:04:46.581721	\N	\N	\N	f
1fd6e4e9-e675-4f0f-907b-2fa551eb8b5a	fa355676-506c-4015-905c-0181c3d19e55	Guest	guest_1fd6e4e9-e675-4f0f-907b-2fa551eb8b5a@salon.guest	$2a$10$cagfQXoC0jmqk7Xcn82WcOrvDx4IemFgKalLjMCGLuzQj2a01u9Mm	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:05:58.552122	2026-01-30 15:05:58.552122	\N	\N	\N	f
c3f9bb27-e43b-43cc-ac27-80b0fdc0170a	fa355676-506c-4015-905c-0181c3d19e55	Guest	guest_c3f9bb27-e43b-43cc-ac27-80b0fdc0170a@salon.guest	$2a$10$QweUv7SvzFoFqZDr3ig1DuaNqa8R9ov/1.lvBkrFq8nfAvefo6.tm	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:06:49.78053	2026-01-30 15:06:49.78053	\N	\N	\N	f
c6bea394-aa31-4021-8c3c-da335c9e7ce0	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_c6bea394-aa31-4021-8c3c-da335c9e7ce0@salon.guest	$2a$10$aouSOU/jCRR7HxVBNEYtFukIFd3gqaAsZsYva1h3CtwqsOmmkDbbm	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:18:46.915908	2026-01-30 15:18:46.915908	\N	\N	\N	t
110754be-5d7b-4f55-947c-c4eb3c7ea0f0	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_110754be-5d7b-4f55-947c-c4eb3c7ea0f0@salon.guest	246e4f122d1b2567b97294dd6988f9fe1547f3cc6cedfaf7e8446cba86b60423	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:24:16.509781	2026-01-30 15:24:16.509781	\N	\N	\N	t
d7564d63-e705-464e-a21f-d49c5782e97b	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_d7564d63-e705-464e-a21f-d49c5782e97b@salon.guest	a26bdd58bdb124e290eb64cdf46fe1e8b7560147c8696411c484c6e80e4de05d	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:24:31.511244	2026-01-30 15:24:31.511244	\N	\N	\N	t
c1cb1fd7-4038-4320-a5f5-1177229af310	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_c1cb1fd7-4038-4320-a5f5-1177229af310@salon.guest	51d2f2459e01c066bde095831a17cea19d59f40f67f59e53c35dadcc19d16e17	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:39:58.742929	2026-01-30 15:39:58.742929	\N	\N	\N	t
5c918ff5-c184-4294-911a-3aa90872391f	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_5c918ff5-c184-4294-911a-3aa90872391f@salon.guest	e5145c7219a8b5213302c849ea6a8d0f34b1490df690906d07804356e4746e80	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:41:14.477444	2026-01-30 15:41:14.477444	\N	\N	\N	t
24913941-758c-4803-99f2-637d9dc12771	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_24913941-758c-4803-99f2-637d9dc12771@salon.guest	5958e9c68e15419d23ac9c8a8c219f1099d3a00c099effd5b6c1b5b04caf89d3	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:47:06.963718	2026-01-30 15:47:06.963718	\N	\N	\N	t
45d4424e-b40a-4099-8f02-2a57827b623a	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_45d4424e-b40a-4099-8f02-2a57827b623a@salon.guest	9ead39370e22ce54677cd91808c233d1f732edb4125bee189653477994ccd2c3	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 15:58:17.644892	2026-01-30 15:58:17.644892	\N	\N	\N	t
40c0432d-3947-472d-8be1-f1b816c900e9	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_40c0432d-3947-472d-8be1-f1b816c900e9@salon.guest	34a2c35bfb80bd158e6e34d765d00f1cc350f9d2dfd7584b1ae2f2f05c1a9728	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:01:02.596489	2026-01-30 16:01:02.596489	\N	\N	\N	t
a94e5b32-0471-44c7-9240-242f9b09c3b4	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_a94e5b32-0471-44c7-9240-242f9b09c3b4@salon.guest	edb76f900e4b631fa400dc4887d2c211d9be71c37e27b22f8d4168935ef26afe	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:07:31.350218	2026-01-30 16:07:31.350218	\N	\N	\N	t
1b82a6f0-570c-483e-99f5-a618dbfb2c2f	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_1b82a6f0-570c-483e-99f5-a618dbfb2c2f@salon.guest	2a9c41a41d9a9bc744a52dcbae2cd94cf12e6bb227f6ec2f6982c5620ccf6273	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:08:52.714655	2026-01-30 16:08:52.714655	\N	\N	\N	t
7c59c2ab-f02c-4873-9b23-d6b81a378877	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_7c59c2ab-f02c-4873-9b23-d6b81a378877@salon.guest	cd041e19dec1ed51a721c1d4ad104afd563e927e92452c88ed062068a675c946	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:14:26.074998	2026-01-30 16:14:26.074998	\N	\N	\N	t
63923e02-cfe1-4667-bc9a-f618ade23347	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_63923e02-cfe1-4667-bc9a-f618ade23347@salon.guest	04c1f3103f4fb5bff5384cf6ec552a4f43f6ffc200a20a67a29380e8e427da03	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:25:25.738095	2026-01-30 16:25:25.738095	\N	\N	\N	t
d3c38ace-ee55-491e-a82b-103dcf7c502c	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_d3c38ace-ee55-491e-a82b-103dcf7c502c@salon.guest	f04179449f9c7d8f44f9ec599493a6e6d056f18ed2538095c67459bb454852e3	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:30:03.672043	2026-01-30 16:30:03.672043	\N	\N	\N	t
24ae8e7e-5cc2-4627-9c2a-be3aa8574673	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_24ae8e7e-5cc2-4627-9c2a-be3aa8574673@salon.guest	9a83848a8cbbb81271dd455f14788e2ff1b946203e538d949d2f98765260354d	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:32:47.311837	2026-01-30 16:32:47.311837	\N	\N	\N	t
53b898ca-1f02-4829-9903-7659b721bfbd	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_53b898ca-1f02-4829-9903-7659b721bfbd@salon.guest	fd14aa7b9d7c8b518a270d1c166b2dadd4b14b69f4aba7d921c7e68f7c4831aa	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:35:48.760598	2026-01-30 16:35:48.760598	\N	\N	\N	t
2cf9a788-887d-4362-b8fb-ffb7f956dca7	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_2cf9a788-887d-4362-b8fb-ffb7f956dca7@salon.guest	4043dde79839b74247bfafd28f9a05adea763a6b88d2c4dfb5fad6faebfa1269	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:38:18.260885	2026-01-30 16:38:18.260885	\N	\N	\N	t
96729594-3227-492c-b0a6-bc576a934e4d	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_96729594-3227-492c-b0a6-bc576a934e4d@salon.guest	5f73d472251e9318b0aa18456482ab5ac7fced436ef6a01b5ec0a6ba38a14f23	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:42:09.024624	2026-01-30 16:42:09.024624	\N	\N	\N	t
e73230da-af43-402d-9507-8736c70b8204	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_e73230da-af43-402d-9507-8736c70b8204@salon.guest	a8a213704af6bdc21376dd99937641731bd0aa994727105c59b662e55d4bc296	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:46:01.634176	2026-01-30 16:46:01.634176	\N	\N	\N	t
912a4f25-9cc0-4067-aead-d9a8d04e17c9	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_912a4f25-9cc0-4067-aead-d9a8d04e17c9@salon.guest	9481c7ad9f5e8a2518fd9cf7daae7a6be3d561861599265221f9cd685533504f	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:49:27.390405	2026-01-30 16:49:27.390405	\N	\N	\N	t
f0384f9d-d568-49f6-8cdf-8940f730212b	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_f0384f9d-d568-49f6-8cdf-8940f730212b@salon.guest	659cfecf795666d4d6531642a8d243928510a559f9ea578111af714a6a3e69f2	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 16:52:22.594341	2026-01-30 16:52:22.594341	\N	\N	\N	t
33b3ae0c-5d21-4092-8af5-f5f489910cb9	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_33b3ae0c-5d21-4092-8af5-f5f489910cb9@salon.guest	7b6b5a21c4da394b61fcea64eda2887c94298b73e2e816aa734d639187f6fedd	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 17:05:05.008613	2026-01-30 17:05:05.008613	\N	\N	\N	t
ac009ea9-6bb2-4bf8-adab-9bcf8bbf4e33	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_ac009ea9-6bb2-4bf8-adab-9bcf8bbf4e33@salon.guest	d4e3f91cf599b37a8410ca57a2c7a9578a01f61b3bf71a534913431cd76f03a7	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 17:07:41.788573	2026-01-30 17:07:41.788573	\N	\N	\N	t
86664492-cfb5-40cd-b93b-8ebf53c62e0d	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_86664492-cfb5-40cd-b93b-8ebf53c62e0d@salon.guest	e4f4be7e2a1a0d925cc3b4441e4a92ee993879345b427ae87c563fb988b2055f	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 18:02:17.917269	2026-01-30 18:02:17.917269	\N	\N	\N	t
e1002304-1b55-4346-9906-1f6748780b7a	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_e1002304-1b55-4346-9906-1f6748780b7a@salon.guest	4123ec9f70fb6496ddfb1fa23d5b6c2cb0b759496fa641511737b24de16598ec	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 17:32:43.963517	2026-01-30 17:32:43.963517	\N	\N	\N	t
333e2fc6-1403-4e59-ad98-eb75cd5a587c	f055f055-1ca2-404b-8e20-326b0c19e3f4	New User	moulaaikhei@gmail.com	$2a$10$k01PgQelHn3QGiD8LIuoBOTtowoYEbr6V4xI5eRhsBwf/s7i4UBce	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-26 17:43:41.376785	2026-02-06 12:42:29.219408	2026-02-06 12:42:29.219408	\N	\N	f
b1ded342-54af-4ce6-89d4-cba17295044a	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_b1ded342-54af-4ce6-89d4-cba17295044a@salon.guest	d6abceafc8c5d3548c06d26515087b89afa4c91fa2e84efdd32b10fd82ed02d3	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 17:37:49.832297	2026-01-30 17:37:49.832297	\N	\N	\N	t
2adde8d5-3ba1-4d51-ba19-4716d50a769e	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_2adde8d5-3ba1-4d51-ba19-4716d50a769e@salon.guest	f42965c59dfeadeb50301775e4870c9601b46826a5225c09bc463a4d41822dc6	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 17:43:41.247393	2026-01-30 17:43:41.247393	\N	\N	\N	t
1e874ad2-1f58-43ee-b3a4-432cb6a37baf	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_1e874ad2-1f58-43ee-b3a4-432cb6a37baf@salon.guest	b76b024f44d086c97495f3ba6d1a610979748d1fde2177c2fe548924f2ee2985	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 18:14:10.841398	2026-01-30 18:14:10.841398	\N	\N	\N	t
0544f2a0-0670-4472-9548-1d67d8e64e81	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_0544f2a0-0670-4472-9548-1d67d8e64e81@salon.guest	a8e953dfe1677eb326bbd18da2fac0cd9a9a8c66b011b609b31ed6d9697254df	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-30 18:18:08.935334	2026-01-30 18:18:08.935334	\N	\N	\N	t
ca9fc9de-abff-47b5-8af0-45d426b5a280	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_ca9fc9de-abff-47b5-8af0-45d426b5a280@salon.guest	b68360ef470919ec45b8388a0c60a035c36aa635dd6b068ea587f046ee5309e9	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-02-02 10:26:52.85167	2026-02-02 10:26:52.85167	\N	\N	\N	t
d375a3b2-c72f-4fd7-98b1-7cd9e43f356c	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_d375a3b2-c72f-4fd7-98b1-7cd9e43f356c@salon.guest	bead2916f6a39bfe739b3d3a2ca10e2b88755139f0461fcfec93068d31e00b24	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-02-02 10:35:43.112326	2026-02-02 10:35:43.112326	\N	\N	\N	t
b58e59cc-2b49-4413-b595-f7325462c3b9	fa805b7b-555c-4794-a668-dc4bfc341b0d	Guest	guest_b58e59cc-2b49-4413-b595-f7325462c3b9@salon.guest	2bb234111b9929962d30e22159ef9054919f45853e966612ed113d4d898631c4	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-02-02 11:19:01.30361	2026-02-02 11:19:01.30361	\N	\N	\N	t
b2742541-cec9-4e89-97ac-6e6fb070454e	ca8e4304-892c-4da0-b335-3dd2d858560e	New User	usman504757@gmail.com	$2a$10$H7ex0XoPELwEP.Z.KxzZeOo0e4A9IJ0oPPIiLwy52ndxPEsbAgLbO	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-01-26 14:31:26.087343	2026-02-02 12:28:20.431459	2026-02-02 12:28:20.431459	\N	\N	f
64f7e6b1-16b2-41fc-89d2-17d773f692ce	fa355676-506c-4015-905c-0181c3d19e55	Guest	guest_64f7e6b1-16b2-41fc-89d2-17d773f692ce@salon.guest	808020e148902145e998ec010f4aa29c0d66ea36fc672974e863f9d668deb3dc	\N	\N	\N	\N	t	\N	\N	\N	0	\N	2026-02-02 13:39:17.915636	2026-02-02 13:39:17.915636	\N	\N	\N	t
455ff159-a3c5-4f80-9328-4ae0915c2979	fa355676-506c-4015-905c-0181c3d19e55	saad	abdullahejaz512@gmail.com	$2a$10$oslQcZli/BgJ7DnNgr.a9OVkwD7rkQHoTMaB4gjWWXvLZ4eZJmhF.	i8	03127000786	Female	\N	t	\N	\N	\N	0	\N	2026-02-02 13:10:14.659661	2026-02-02 15:26:37.206765	2026-02-02 15:26:37.206765	\N	\N	f
\.


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: course_applications course_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_applications
    ADD CONSTRAINT course_applications_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: expert_services expert_services_expert_id_service_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expert_services
    ADD CONSTRAINT expert_services_expert_id_service_id_key UNIQUE (expert_id, service_id);


--
-- Name: expert_services expert_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expert_services
    ADD CONSTRAINT expert_services_pkey PRIMARY KEY (id);


--
-- Name: experts experts_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experts
    ADD CONSTRAINT experts_email_key UNIQUE (email);


--
-- Name: experts experts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.experts
    ADD CONSTRAINT experts_pkey PRIMARY KEY (id);


--
-- Name: gallery gallery_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gallery
    ADD CONSTRAINT gallery_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: offers offers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offers
    ADD CONSTRAINT offers_pkey PRIMARY KEY (id);


--
-- Name: pending_registrations pending_registrations_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_registrations
    ADD CONSTRAINT pending_registrations_email_key UNIQUE (email);


--
-- Name: pending_registrations pending_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_registrations
    ADD CONSTRAINT pending_registrations_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_slug_key UNIQUE (slug);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: service_categories service_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_categories
    ADD CONSTRAINT service_categories_pkey PRIMARY KEY (id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: sub_services sub_services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sub_services
    ADD CONSTRAINT sub_services_pkey PRIMARY KEY (id);


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
-- Name: idx_appointments_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_date ON public.appointments USING btree (appointment_date);


--
-- Name: idx_appointments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_status ON public.appointments USING btree (status);


--
-- Name: idx_appointments_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_appointments_user ON public.appointments USING btree (user_id);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- Name: idx_pending_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pending_code ON public.pending_registrations USING btree (verification_code) WHERE (verification_code IS NOT NULL);


--
-- Name: idx_pending_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pending_email ON public.pending_registrations USING btree (email);


--
-- Name: idx_reviews_expert; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_expert ON public.reviews USING btree (expert_id);


--
-- Name: idx_reviews_service; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_service ON public.reviews USING btree (service_id);


--
-- Name: idx_services_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_services_active ON public.services USING btree (is_active);


--
-- Name: idx_services_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_services_category ON public.services USING btree (category_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role_id ON public.users USING btree (role_id);


--
-- Name: idx_users_verification_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_verification_code ON public.users USING btree (verification_code) WHERE (verification_code IS NOT NULL);


--
-- Name: appointments update_appointments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: course_applications update_course_applications_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_course_applications_updated_at BEFORE UPDATE ON public.course_applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: courses update_courses_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON public.courses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: experts update_experts_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_experts_updated_at BEFORE UPDATE ON public.experts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: offers update_offers_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON public.offers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: permissions update_permissions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_permissions_updated_at BEFORE UPDATE ON public.permissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: roles update_roles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: service_categories update_service_categories_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_service_categories_updated_at BEFORE UPDATE ON public.service_categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: services update_services_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON public.services FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: appointments appointments_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_expert_id_fkey FOREIGN KEY (expert_id) REFERENCES public.experts(id);


--
-- Name: appointments appointments_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id);


--
-- Name: appointments appointments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: course_applications course_applications_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_applications
    ADD CONSTRAINT course_applications_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_applications course_applications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.course_applications
    ADD CONSTRAINT course_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: expert_services expert_services_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expert_services
    ADD CONSTRAINT expert_services_expert_id_fkey FOREIGN KEY (expert_id) REFERENCES public.experts(id) ON DELETE CASCADE;


--
-- Name: expert_services expert_services_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expert_services
    ADD CONSTRAINT expert_services_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_expert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_expert_id_fkey FOREIGN KEY (expert_id) REFERENCES public.experts(id) ON DELETE SET NULL;


--
-- Name: reviews reviews_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: services services_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.service_categories(id) ON DELETE CASCADE;


--
-- Name: sub_services sub_services_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sub_services
    ADD CONSTRAINT sub_services_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict S7zqbQ2l9rEXxZoFc7sMl9pxQO6NChqqnOpWLj26ZPbFDorkOgBPgj7mV9dtegW

