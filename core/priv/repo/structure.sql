--
-- PostgreSQL database dump
--

-- Dumped from database version 12.7 (Ubuntu 12.7-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.7 (Ubuntu 12.7-0ubuntu0.20.04.1)

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
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: oban_job_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.oban_job_state AS ENUM (
    'available',
    'scheduled',
    'executing',
    'retryable',
    'completed',
    'discarded',
    'cancelled'
);


--
-- Name: oban_jobs_notify(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.oban_jobs_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  channel text;
  notice json;
BEGIN
  IF NEW.state = 'available' THEN
    channel = 'public.oban_insert';
    notice = json_build_object('queue', NEW.queue);

    PERFORM pg_notify(channel, notice::text);
  END IF;

  RETURN NULL;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: apns_device_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.apns_device_tokens (
    id bigint NOT NULL,
    device_token character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: apns_device_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.apns_device_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: apns_device_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.apns_device_tokens_id_seq OWNED BY public.apns_device_tokens.id;


--
-- Name: authorization_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_nodes (
    id bigint NOT NULL,
    parent_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: authorization_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.authorization_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authorization_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.authorization_nodes_id_seq OWNED BY public.authorization_nodes.id;


--
-- Name: authorization_role_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_role_assignments (
    id bigint NOT NULL,
    node_id bigint,
    role character varying(255),
    principal_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: authorization_role_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.authorization_role_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authorization_role_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.authorization_role_assignments_id_seq OWNED BY public.authorization_role_assignments.id;


--
-- Name: authors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authors (
    id bigint NOT NULL,
    fullname character varying(255),
    displayname character varying(255),
    study_id bigint NOT NULL,
    user_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: authors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.authors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.authors_id_seq OWNED BY public.authors.id;


--
-- Name: client_scripts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_scripts (
    id bigint NOT NULL,
    title character varying(255),
    script text,
    study_id bigint,
    auth_node_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: client_scripts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_scripts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_scripts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_scripts_id_seq OWNED BY public.client_scripts.id;


--
-- Name: content_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_nodes (
    id bigint NOT NULL,
    ready boolean,
    parent_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: content_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_nodes_id_seq OWNED BY public.content_nodes.id;


--
-- Name: data_donation_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_donation_participants (
    id bigint NOT NULL,
    user_id bigint,
    tool_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: data_donation_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_donation_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_donation_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_donation_participants_id_seq OWNED BY public.data_donation_participants.id;


--
-- Name: data_donation_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_donation_tasks (
    id bigint NOT NULL,
    status character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    tool_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: data_donation_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_donation_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_donation_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_donation_tasks_id_seq OWNED BY public.data_donation_tasks.id;


--
-- Name: data_donation_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_donation_tools (
    id bigint NOT NULL,
    script text,
    reward_currency character varying(255),
    reward_value integer,
    subject_count integer,
    promotion_id bigint,
    study_id bigint,
    auth_node_id bigint NOT NULL,
    content_node_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: data_donation_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_donation_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_donation_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_donation_tools_id_seq OWNED BY public.data_donation_tools.id;


--
-- Name: data_donation_user_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_donation_user_data (
    id bigint NOT NULL,
    data bytea,
    tool_id bigint,
    user_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: data_donation_user_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_donation_user_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_donation_user_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_donation_user_data_id_seq OWNED BY public.data_donation_user_data.id;


--
-- Name: google_sign_in_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.google_sign_in_users (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    sub bytea NOT NULL,
    name character varying(255),
    email character varying(255),
    email_verified boolean,
    given_name character varying(255),
    family_name character varying(255),
    picture character varying(255),
    locale character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: google_sign_in_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.google_sign_in_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: google_sign_in_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.google_sign_in_users_id_seq OWNED BY public.google_sign_in_users.id;


--
-- Name: notification_boxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_boxes (
    id bigint NOT NULL,
    auth_node_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: notification_boxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_boxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_boxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_boxes_id_seq OWNED BY public.notification_boxes.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    box_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    action character varying(255),
    status character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: oban_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oban_jobs (
    id bigint NOT NULL,
    state public.oban_job_state DEFAULT 'available'::public.oban_job_state NOT NULL,
    queue text DEFAULT 'default'::text NOT NULL,
    worker text NOT NULL,
    args jsonb DEFAULT '{}'::jsonb NOT NULL,
    errors jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    attempt integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 20 NOT NULL,
    inserted_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    scheduled_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    attempted_at timestamp without time zone,
    completed_at timestamp without time zone,
    attempted_by text[],
    discarded_at timestamp without time zone,
    priority integer DEFAULT 0 NOT NULL,
    tags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    meta jsonb DEFAULT '{}'::jsonb,
    cancelled_at timestamp without time zone,
    CONSTRAINT attempt_range CHECK (((attempt >= 0) AND (attempt <= max_attempts))),
    CONSTRAINT positive_max_attempts CHECK ((max_attempts > 0)),
    CONSTRAINT priority_range CHECK (((priority >= 0) AND (priority <= 3))),
    CONSTRAINT queue_length CHECK (((char_length(queue) > 0) AND (char_length(queue) < 128))),
    CONSTRAINT worker_length CHECK (((char_length(worker) > 0) AND (char_length(worker) < 128)))
);


--
-- Name: TABLE oban_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.oban_jobs IS '10';


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oban_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oban_jobs_id_seq OWNED BY public.oban_jobs.id;


--
-- Name: promotions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotions (
    id bigint NOT NULL,
    title character varying(255),
    subtitle character varying(255),
    expectations text,
    description text,
    published_at timestamp(0) without time zone,
    image_id text,
    themes character varying(255)[],
    marks character varying(255)[],
    banner_photo_url character varying(255),
    banner_title character varying(255),
    banner_subtitle character varying(255),
    banner_url character varying(255),
    plugin character varying(255),
    auth_node_id bigint NOT NULL,
    content_node_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: promotions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.promotions_id_seq OWNED BY public.promotions.id;


--
-- Name: role_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_assignments (
    entity_type character varying(255),
    entity_id bigint,
    principal_id bigint,
    role character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: sign_in_with_apple_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sign_in_with_apple_users (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    sub bytea NOT NULL,
    email character varying(255),
    first_name character varying(255),
    middle_name character varying(255),
    last_name character varying(255),
    is_private_email boolean,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: sign_in_with_apple_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sign_in_with_apple_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sign_in_with_apple_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sign_in_with_apple_users_id_seq OWNED BY public.sign_in_with_apple_users.id;


--
-- Name: studies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.studies (
    id bigint NOT NULL,
    title text,
    description text,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    auth_node_id bigint NOT NULL
);


--
-- Name: studies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.studies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: studies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.studies_id_seq OWNED BY public.studies.id;


--
-- Name: surfconext_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.surfconext_users (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    sub bytea NOT NULL,
    email character varying(255),
    family_name character varying(255),
    given_name character varying(255),
    preferred_username character varying(255),
    schac_home_organization character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: surfconext_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.surfconext_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: surfconext_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.surfconext_users_id_seq OWNED BY public.surfconext_users.id;


--
-- Name: survey_tool_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_tool_participants (
    id bigint NOT NULL,
    user_id bigint,
    survey_tool_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: survey_tool_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.survey_tool_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: survey_tool_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.survey_tool_participants_id_seq OWNED BY public.survey_tool_participants.id;


--
-- Name: survey_tool_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_tool_tasks (
    id bigint NOT NULL,
    status character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    tool_id bigint NOT NULL
);


--
-- Name: survey_tool_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.survey_tool_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: survey_tool_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.survey_tool_tasks_id_seq OWNED BY public.survey_tool_tasks.id;


--
-- Name: survey_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_tools (
    id bigint NOT NULL,
    study_id bigint NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    survey_url character varying(255),
    subject_count integer,
    duration character varying(255),
    auth_node_id bigint NOT NULL,
    reward_currency character varying(255),
    reward_value integer,
    devices character varying(255)[],
    promotion_id bigint,
    content_node_id bigint NOT NULL
);


--
-- Name: survey_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.survey_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: survey_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.survey_tools_id_seq OWNED BY public.survey_tools.id;


--
-- Name: test_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_entities (
    id bigint NOT NULL,
    title character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: test_entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_entities_id_seq OWNED BY public.test_entities.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profiles (
    id bigint NOT NULL,
    fullname character varying(255),
    user_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    photo_url character varying(255),
    title character varying(255),
    url character varying(255)
);


--
-- Name: user_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_profiles_id_seq OWNED BY public.user_profiles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    password_hash character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    hashed_password character varying(255) NOT NULL,
    confirmed_at timestamp(0) without time zone,
    displayname character varying(255),
    researcher boolean
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_tokens_id_seq OWNED BY public.users_tokens.id;


--
-- Name: web_push_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.web_push_subscriptions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    endpoint character varying(255) NOT NULL,
    expiration_time integer,
    auth character varying(255) NOT NULL,
    p256dh character varying(255) NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: web_push_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.web_push_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_push_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.web_push_subscriptions_id_seq OWNED BY public.web_push_subscriptions.id;


--
-- Name: apns_device_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apns_device_tokens ALTER COLUMN id SET DEFAULT nextval('public.apns_device_tokens_id_seq'::regclass);


--
-- Name: authorization_nodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_nodes ALTER COLUMN id SET DEFAULT nextval('public.authorization_nodes_id_seq'::regclass);


--
-- Name: authorization_role_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_assignments ALTER COLUMN id SET DEFAULT nextval('public.authorization_role_assignments_id_seq'::regclass);


--
-- Name: authors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authors ALTER COLUMN id SET DEFAULT nextval('public.authors_id_seq'::regclass);


--
-- Name: client_scripts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_scripts ALTER COLUMN id SET DEFAULT nextval('public.client_scripts_id_seq'::regclass);


--
-- Name: content_nodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_nodes ALTER COLUMN id SET DEFAULT nextval('public.content_nodes_id_seq'::regclass);


--
-- Name: data_donation_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_participants ALTER COLUMN id SET DEFAULT nextval('public.data_donation_participants_id_seq'::regclass);


--
-- Name: data_donation_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tasks ALTER COLUMN id SET DEFAULT nextval('public.data_donation_tasks_id_seq'::regclass);


--
-- Name: data_donation_tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tools ALTER COLUMN id SET DEFAULT nextval('public.data_donation_tools_id_seq'::regclass);


--
-- Name: data_donation_user_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_user_data ALTER COLUMN id SET DEFAULT nextval('public.data_donation_user_data_id_seq'::regclass);


--
-- Name: google_sign_in_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.google_sign_in_users ALTER COLUMN id SET DEFAULT nextval('public.google_sign_in_users_id_seq'::regclass);


--
-- Name: notification_boxes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_boxes ALTER COLUMN id SET DEFAULT nextval('public.notification_boxes_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: oban_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs ALTER COLUMN id SET DEFAULT nextval('public.oban_jobs_id_seq'::regclass);


--
-- Name: promotions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions ALTER COLUMN id SET DEFAULT nextval('public.promotions_id_seq'::regclass);


--
-- Name: sign_in_with_apple_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sign_in_with_apple_users ALTER COLUMN id SET DEFAULT nextval('public.sign_in_with_apple_users_id_seq'::regclass);


--
-- Name: studies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.studies ALTER COLUMN id SET DEFAULT nextval('public.studies_id_seq'::regclass);


--
-- Name: surfconext_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surfconext_users ALTER COLUMN id SET DEFAULT nextval('public.surfconext_users_id_seq'::regclass);


--
-- Name: survey_tool_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tool_participants ALTER COLUMN id SET DEFAULT nextval('public.survey_tool_participants_id_seq'::regclass);


--
-- Name: survey_tool_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tool_tasks ALTER COLUMN id SET DEFAULT nextval('public.survey_tool_tasks_id_seq'::regclass);


--
-- Name: survey_tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tools ALTER COLUMN id SET DEFAULT nextval('public.survey_tools_id_seq'::regclass);


--
-- Name: test_entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_entities ALTER COLUMN id SET DEFAULT nextval('public.test_entities_id_seq'::regclass);


--
-- Name: user_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles ALTER COLUMN id SET DEFAULT nextval('public.user_profiles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: users_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens ALTER COLUMN id SET DEFAULT nextval('public.users_tokens_id_seq'::regclass);


--
-- Name: web_push_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.web_push_subscriptions_id_seq'::regclass);


--
-- Name: apns_device_tokens apns_device_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apns_device_tokens
    ADD CONSTRAINT apns_device_tokens_pkey PRIMARY KEY (id);


--
-- Name: authorization_nodes authorization_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_nodes
    ADD CONSTRAINT authorization_nodes_pkey PRIMARY KEY (id);


--
-- Name: authorization_role_assignments authorization_role_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_assignments
    ADD CONSTRAINT authorization_role_assignments_pkey PRIMARY KEY (id);


--
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (id);


--
-- Name: client_scripts client_scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_scripts
    ADD CONSTRAINT client_scripts_pkey PRIMARY KEY (id);


--
-- Name: content_nodes content_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_nodes
    ADD CONSTRAINT content_nodes_pkey PRIMARY KEY (id);


--
-- Name: data_donation_participants data_donation_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_participants
    ADD CONSTRAINT data_donation_participants_pkey PRIMARY KEY (id);


--
-- Name: data_donation_tasks data_donation_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tasks
    ADD CONSTRAINT data_donation_tasks_pkey PRIMARY KEY (id);


--
-- Name: data_donation_tools data_donation_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tools
    ADD CONSTRAINT data_donation_tools_pkey PRIMARY KEY (id);


--
-- Name: data_donation_user_data data_donation_user_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_user_data
    ADD CONSTRAINT data_donation_user_data_pkey PRIMARY KEY (id);


--
-- Name: google_sign_in_users google_sign_in_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.google_sign_in_users
    ADD CONSTRAINT google_sign_in_users_pkey PRIMARY KEY (id);


--
-- Name: notification_boxes notification_boxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_boxes
    ADD CONSTRAINT notification_boxes_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: oban_jobs oban_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs
    ADD CONSTRAINT oban_jobs_pkey PRIMARY KEY (id);


--
-- Name: promotions promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sign_in_with_apple_users sign_in_with_apple_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sign_in_with_apple_users
    ADD CONSTRAINT sign_in_with_apple_users_pkey PRIMARY KEY (id);


--
-- Name: studies studies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.studies
    ADD CONSTRAINT studies_pkey PRIMARY KEY (id);


--
-- Name: surfconext_users surfconext_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surfconext_users
    ADD CONSTRAINT surfconext_users_pkey PRIMARY KEY (id);


--
-- Name: survey_tool_participants survey_tool_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tool_participants
    ADD CONSTRAINT survey_tool_participants_pkey PRIMARY KEY (id);


--
-- Name: survey_tool_tasks survey_tool_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tool_tasks
    ADD CONSTRAINT survey_tool_tasks_pkey PRIMARY KEY (id);


--
-- Name: survey_tools survey_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tools
    ADD CONSTRAINT survey_tools_pkey PRIMARY KEY (id);


--
-- Name: test_entities test_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_entities
    ADD CONSTRAINT test_entities_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_tokens users_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_pkey PRIMARY KEY (id);


--
-- Name: web_push_subscriptions web_push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions
    ADD CONSTRAINT web_push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: apns_device_tokens_user_id_device_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX apns_device_tokens_user_id_device_token_index ON public.apns_device_tokens USING btree (user_id, device_token);


--
-- Name: authorization_role_assignments_principal_id_role_node_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX authorization_role_assignments_principal_id_role_node_id_index ON public.authorization_role_assignments USING btree (principal_id, role, node_id);


--
-- Name: client_scripts_study_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_scripts_study_id_index ON public.client_scripts USING btree (study_id);


--
-- Name: data_donation_participants_tool_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX data_donation_participants_tool_id_user_id_index ON public.data_donation_participants USING btree (tool_id, user_id);


--
-- Name: data_donation_tasks_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX data_donation_tasks_status_index ON public.data_donation_tasks USING btree (status);


--
-- Name: data_donation_tasks_tool_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX data_donation_tasks_tool_id_index ON public.data_donation_tasks USING btree (tool_id);


--
-- Name: data_donation_tasks_user_id_tool_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX data_donation_tasks_user_id_tool_id_index ON public.data_donation_tasks USING btree (user_id, tool_id);


--
-- Name: data_donation_tools_promotion_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX data_donation_tools_promotion_id_index ON public.data_donation_tools USING btree (promotion_id);


--
-- Name: data_donation_tools_study_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX data_donation_tools_study_id_index ON public.data_donation_tools USING btree (study_id);


--
-- Name: data_donation_user_data_tool_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX data_donation_user_data_tool_id_index ON public.data_donation_user_data USING btree (tool_id);


--
-- Name: google_sign_in_users_sub_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX google_sign_in_users_sub_index ON public.google_sign_in_users USING btree (sub);


--
-- Name: oban_jobs_args_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_args_index ON public.oban_jobs USING gin (args);


--
-- Name: oban_jobs_meta_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_meta_index ON public.oban_jobs USING gin (meta);


--
-- Name: oban_jobs_queue_state_priority_scheduled_at_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_queue_state_priority_scheduled_at_id_index ON public.oban_jobs USING btree (queue, state, priority, scheduled_at, id);


--
-- Name: role_assignments_principal_id_entity_type_entity_id_role_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX role_assignments_principal_id_entity_type_entity_id_role_index ON public.role_assignments USING btree (principal_id, entity_type, entity_id, role);


--
-- Name: sign_in_with_apple_users_sub_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sign_in_with_apple_users_sub_index ON public.sign_in_with_apple_users USING btree (sub);


--
-- Name: surfconext_users_sub_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX surfconext_users_sub_index ON public.surfconext_users USING btree (sub);


--
-- Name: survey_tool_participants_survey_tool_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX survey_tool_participants_survey_tool_id_user_id_index ON public.survey_tool_participants USING btree (survey_tool_id, user_id);


--
-- Name: survey_tool_tasks_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX survey_tool_tasks_status_index ON public.survey_tool_tasks USING btree (status);


--
-- Name: survey_tool_tasks_tool_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX survey_tool_tasks_tool_id_index ON public.survey_tool_tasks USING btree (tool_id);


--
-- Name: survey_tool_tasks_user_id_tool_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX survey_tool_tasks_user_id_tool_id_index ON public.survey_tool_tasks USING btree (user_id, tool_id);


--
-- Name: user_profiles_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_profiles_user_id_index ON public.user_profiles USING btree (user_id);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_tokens_context_token_index ON public.users_tokens USING btree (context, token);


--
-- Name: users_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_tokens_user_id_index ON public.users_tokens USING btree (user_id);


--
-- Name: web_push_subscriptions_endpoint_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX web_push_subscriptions_endpoint_index ON public.web_push_subscriptions USING btree (endpoint);


--
-- Name: web_push_subscriptions_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX web_push_subscriptions_user_id_index ON public.web_push_subscriptions USING btree (user_id);


--
-- Name: oban_jobs oban_notify; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER oban_notify AFTER INSERT ON public.oban_jobs FOR EACH ROW EXECUTE FUNCTION public.oban_jobs_notify();


--
-- Name: apns_device_tokens apns_device_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apns_device_tokens
    ADD CONSTRAINT apns_device_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: authorization_nodes authorization_nodes_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_nodes
    ADD CONSTRAINT authorization_nodes_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.authorization_nodes(id) ON DELETE CASCADE;


--
-- Name: authorization_role_assignments authorization_role_assignments_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_role_assignments
    ADD CONSTRAINT authorization_role_assignments_node_id_fkey FOREIGN KEY (node_id) REFERENCES public.authorization_nodes(id) ON DELETE CASCADE;


--
-- Name: authors authors_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.studies(id) ON DELETE CASCADE;


--
-- Name: authors authors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: client_scripts client_scripts_auth_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_scripts
    ADD CONSTRAINT client_scripts_auth_node_id_fkey FOREIGN KEY (auth_node_id) REFERENCES public.authorization_nodes(id);


--
-- Name: client_scripts client_scripts_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_scripts
    ADD CONSTRAINT client_scripts_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.studies(id);


--
-- Name: content_nodes content_nodes_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_nodes
    ADD CONSTRAINT content_nodes_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.content_nodes(id) ON DELETE CASCADE;


--
-- Name: data_donation_participants data_donation_participants_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_participants
    ADD CONSTRAINT data_donation_participants_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES public.data_donation_tools(id) ON DELETE CASCADE;


--
-- Name: data_donation_participants data_donation_participants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_participants
    ADD CONSTRAINT data_donation_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: data_donation_tasks data_donation_tasks_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tasks
    ADD CONSTRAINT data_donation_tasks_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES public.data_donation_tools(id) ON DELETE CASCADE;


--
-- Name: data_donation_tasks data_donation_tasks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tasks
    ADD CONSTRAINT data_donation_tasks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: data_donation_tools data_donation_tools_auth_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tools
    ADD CONSTRAINT data_donation_tools_auth_node_id_fkey FOREIGN KEY (auth_node_id) REFERENCES public.authorization_nodes(id);


--
-- Name: data_donation_tools data_donation_tools_content_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tools
    ADD CONSTRAINT data_donation_tools_content_node_id_fkey FOREIGN KEY (content_node_id) REFERENCES public.content_nodes(id);


--
-- Name: data_donation_tools data_donation_tools_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tools
    ADD CONSTRAINT data_donation_tools_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(id);


--
-- Name: data_donation_tools data_donation_tools_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_tools
    ADD CONSTRAINT data_donation_tools_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.studies(id) ON DELETE CASCADE;


--
-- Name: data_donation_user_data data_donation_user_data_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_user_data
    ADD CONSTRAINT data_donation_user_data_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES public.data_donation_tools(id);


--
-- Name: data_donation_user_data data_donation_user_data_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_donation_user_data
    ADD CONSTRAINT data_donation_user_data_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: google_sign_in_users google_sign_in_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.google_sign_in_users
    ADD CONSTRAINT google_sign_in_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notification_boxes notification_boxes_auth_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_boxes
    ADD CONSTRAINT notification_boxes_auth_node_id_fkey FOREIGN KEY (auth_node_id) REFERENCES public.authorization_nodes(id);


--
-- Name: notifications notifications_box_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_box_id_fkey FOREIGN KEY (box_id) REFERENCES public.notification_boxes(id);


--
-- Name: promotions promotions_auth_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_auth_node_id_fkey FOREIGN KEY (auth_node_id) REFERENCES public.authorization_nodes(id);


--
-- Name: promotions promotions_content_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_content_node_id_fkey FOREIGN KEY (content_node_id) REFERENCES public.content_nodes(id);


--
-- Name: sign_in_with_apple_users sign_in_with_apple_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sign_in_with_apple_users
    ADD CONSTRAINT sign_in_with_apple_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: studies studies_auth_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.studies
    ADD CONSTRAINT studies_auth_node_id_fkey FOREIGN KEY (auth_node_id) REFERENCES public.authorization_nodes(id);


--
-- Name: surfconext_users surfconext_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.surfconext_users
    ADD CONSTRAINT surfconext_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: survey_tool_participants survey_tool_participants_survey_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tool_participants
    ADD CONSTRAINT survey_tool_participants_survey_tool_id_fkey FOREIGN KEY (survey_tool_id) REFERENCES public.survey_tools(id) ON DELETE CASCADE;


--
-- Name: survey_tool_participants survey_tool_participants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tool_participants
    ADD CONSTRAINT survey_tool_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: survey_tool_tasks survey_tool_tasks_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tool_tasks
    ADD CONSTRAINT survey_tool_tasks_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES public.survey_tools(id) ON DELETE CASCADE;


--
-- Name: survey_tool_tasks survey_tool_tasks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tool_tasks
    ADD CONSTRAINT survey_tool_tasks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: survey_tools survey_tools_auth_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tools
    ADD CONSTRAINT survey_tools_auth_node_id_fkey FOREIGN KEY (auth_node_id) REFERENCES public.authorization_nodes(id);


--
-- Name: survey_tools survey_tools_content_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tools
    ADD CONSTRAINT survey_tools_content_node_id_fkey FOREIGN KEY (content_node_id) REFERENCES public.content_nodes(id);


--
-- Name: survey_tools survey_tools_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tools
    ADD CONSTRAINT survey_tools_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(id);


--
-- Name: survey_tools survey_tools_study_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_tools
    ADD CONSTRAINT survey_tools_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.studies(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users_tokens users_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: web_push_subscriptions web_push_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions
    ADD CONSTRAINT web_push_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20201017121329);
INSERT INTO public."schema_migrations" (version) VALUES (20201020183311);
INSERT INTO public."schema_migrations" (version) VALUES (20201028085310);
INSERT INTO public."schema_migrations" (version) VALUES (20201101134918);
INSERT INTO public."schema_migrations" (version) VALUES (20201102192524);
INSERT INTO public."schema_migrations" (version) VALUES (20201122134413);
INSERT INTO public."schema_migrations" (version) VALUES (20201206155650);
INSERT INTO public."schema_migrations" (version) VALUES (20201212083922);
INSERT INTO public."schema_migrations" (version) VALUES (20201212084431);
INSERT INTO public."schema_migrations" (version) VALUES (20201213065158);
INSERT INTO public."schema_migrations" (version) VALUES (20201213180227);
INSERT INTO public."schema_migrations" (version) VALUES (20201213191000);
INSERT INTO public."schema_migrations" (version) VALUES (20201219120744);
INSERT INTO public."schema_migrations" (version) VALUES (20201221095052);
INSERT INTO public."schema_migrations" (version) VALUES (20201221105503);
INSERT INTO public."schema_migrations" (version) VALUES (20210103112001);
INSERT INTO public."schema_migrations" (version) VALUES (20210103112648);
INSERT INTO public."schema_migrations" (version) VALUES (20210123220535);
INSERT INTO public."schema_migrations" (version) VALUES (20210203133519);
INSERT INTO public."schema_migrations" (version) VALUES (20210205131330);
INSERT INTO public."schema_migrations" (version) VALUES (20210205145655);
INSERT INTO public."schema_migrations" (version) VALUES (20210207104300);
INSERT INTO public."schema_migrations" (version) VALUES (20210212072604);
INSERT INTO public."schema_migrations" (version) VALUES (20210215212648);
INSERT INTO public."schema_migrations" (version) VALUES (20210215213744);
INSERT INTO public."schema_migrations" (version) VALUES (20210219070920);
INSERT INTO public."schema_migrations" (version) VALUES (20210305122226);
INSERT INTO public."schema_migrations" (version) VALUES (20210312101308);
INSERT INTO public."schema_migrations" (version) VALUES (20210318142906);
INSERT INTO public."schema_migrations" (version) VALUES (20210319073253);
INSERT INTO public."schema_migrations" (version) VALUES (20210328112518);
INSERT INTO public."schema_migrations" (version) VALUES (20210417094346);
INSERT INTO public."schema_migrations" (version) VALUES (20210430134220);
INSERT INTO public."schema_migrations" (version) VALUES (20210505183453);
INSERT INTO public."schema_migrations" (version) VALUES (20210513135033);
INSERT INTO public."schema_migrations" (version) VALUES (20210521122136);
INSERT INTO public."schema_migrations" (version) VALUES (20210604083641);
INSERT INTO public."schema_migrations" (version) VALUES (20210605085911);
INSERT INTO public."schema_migrations" (version) VALUES (20210607120324);
INSERT INTO public."schema_migrations" (version) VALUES (20210620092414);
INSERT INTO public."schema_migrations" (version) VALUES (20210630111238);
