--
-- PostgreSQL database dump
--

\restrict 1XHbhsjjKpYrsKerhCFI4HaFCd9nrWfJo7vEdTcl8b8aLeZJJfwIOpWCcZkIdMz

-- Dumped from database version 17.11
-- Dumped by pg_dump version 17.11

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

ALTER TABLE IF EXISTS ONLY public.django_admin_log DROP CONSTRAINT IF EXISTS django_admin_log_user_id_c564eba6_fk_auth_user_id;
ALTER TABLE IF EXISTS ONLY public.django_admin_log DROP CONSTRAINT IF EXISTS django_admin_log_content_type_id_c4bce8eb_fk_django_co;
ALTER TABLE IF EXISTS ONLY public.catalog_product DROP CONSTRAINT IF EXISTS catalog_product_category_id_35bf920b_fk_catalog_category_id;
ALTER TABLE IF EXISTS ONLY public.catalog_product DROP CONSTRAINT IF EXISTS catalog_product_brand_id_bb0c7890_fk_catalog_brand_id;
ALTER TABLE IF EXISTS ONLY public.auth_user_user_permissions DROP CONSTRAINT IF EXISTS auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id;
ALTER TABLE IF EXISTS ONLY public.auth_user_user_permissions DROP CONSTRAINT IF EXISTS auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm;
ALTER TABLE IF EXISTS ONLY public.auth_user_groups DROP CONSTRAINT IF EXISTS auth_user_groups_user_id_6a12ed8b_fk_auth_user_id;
ALTER TABLE IF EXISTS ONLY public.auth_user_groups DROP CONSTRAINT IF EXISTS auth_user_groups_group_id_97559544_fk_auth_group_id;
ALTER TABLE IF EXISTS ONLY public.auth_permission DROP CONSTRAINT IF EXISTS auth_permission_content_type_id_2f476e4b_fk_django_co;
ALTER TABLE IF EXISTS ONLY public.auth_group_permissions DROP CONSTRAINT IF EXISTS auth_group_permissions_group_id_b120cbf9_fk_auth_group_id;
ALTER TABLE IF EXISTS ONLY public.auth_group_permissions DROP CONSTRAINT IF EXISTS auth_group_permissio_permission_id_84c5c92e_fk_auth_perm;
DROP INDEX IF EXISTS public.news_article_slug_5328fdc5_like;
DROP INDEX IF EXISTS public.news_articl_is_publ_0ea520_idx;
DROP INDEX IF EXISTS public.leads_dealerapplication_sdt_27dd4e73_like;
DROP INDEX IF EXISTS public.leads_dealerapplication_sdt_27dd4e73;
DROP INDEX IF EXISTS public.leads_contactmessage_sdt_ddccec72_like;
DROP INDEX IF EXISTS public.leads_contactmessage_sdt_ddccec72;
DROP INDEX IF EXISTS public.django_session_session_key_c0390e0f_like;
DROP INDEX IF EXISTS public.django_session_expire_date_a5c62663;
DROP INDEX IF EXISTS public.django_admin_log_user_id_c564eba6;
DROP INDEX IF EXISTS public.django_admin_log_content_type_id_c4bce8eb;
DROP INDEX IF EXISTS public.catalog_product_slug_f37848b0_like;
DROP INDEX IF EXISTS public.catalog_product_category_id_35bf920b;
DROP INDEX IF EXISTS public.catalog_product_brand_id_bb0c7890;
DROP INDEX IF EXISTS public.catalog_pro_is_acti_903fcc_idx;
DROP INDEX IF EXISTS public.catalog_category_slug_dbf63ad0_like;
DROP INDEX IF EXISTS public.catalog_brand_slug_988c8dbc_like;
DROP INDEX IF EXISTS public.catalog_brand_name_ea62c47f_like;
DROP INDEX IF EXISTS public.auth_user_username_6821ab7c_like;
DROP INDEX IF EXISTS public.auth_user_user_permissions_user_id_a95ead1b;
DROP INDEX IF EXISTS public.auth_user_user_permissions_permission_id_1fbb5f2c;
DROP INDEX IF EXISTS public.auth_user_groups_user_id_6a12ed8b;
DROP INDEX IF EXISTS public.auth_user_groups_group_id_97559544;
DROP INDEX IF EXISTS public.auth_permission_content_type_id_2f476e4b;
DROP INDEX IF EXISTS public.auth_group_permissions_permission_id_84c5c92e;
DROP INDEX IF EXISTS public.auth_group_permissions_group_id_b120cbf9;
DROP INDEX IF EXISTS public.auth_group_name_a6ea08ec_like;
ALTER TABLE IF EXISTS ONLY public.siteinfo_sitesettings DROP CONSTRAINT IF EXISTS siteinfo_sitesettings_pkey;
ALTER TABLE IF EXISTS ONLY public.news_article DROP CONSTRAINT IF EXISTS news_article_slug_key;
ALTER TABLE IF EXISTS ONLY public.news_article DROP CONSTRAINT IF EXISTS news_article_pkey;
ALTER TABLE IF EXISTS ONLY public.leads_dealerapplication DROP CONSTRAINT IF EXISTS leads_dealerapplication_pkey;
ALTER TABLE IF EXISTS ONLY public.leads_dealerapplication DROP CONSTRAINT IF EXISTS leads_dealerapplication_completion_token_key;
ALTER TABLE IF EXISTS ONLY public.leads_contactmessage DROP CONSTRAINT IF EXISTS leads_contactmessage_pkey;
ALTER TABLE IF EXISTS ONLY public.django_session DROP CONSTRAINT IF EXISTS django_session_pkey;
ALTER TABLE IF EXISTS ONLY public.django_migrations DROP CONSTRAINT IF EXISTS django_migrations_pkey;
ALTER TABLE IF EXISTS ONLY public.django_content_type DROP CONSTRAINT IF EXISTS django_content_type_pkey;
ALTER TABLE IF EXISTS ONLY public.django_content_type DROP CONSTRAINT IF EXISTS django_content_type_app_label_model_76bd3d3b_uniq;
ALTER TABLE IF EXISTS ONLY public.django_admin_log DROP CONSTRAINT IF EXISTS django_admin_log_pkey;
ALTER TABLE IF EXISTS ONLY public.catalog_product DROP CONSTRAINT IF EXISTS catalog_product_slug_key;
ALTER TABLE IF EXISTS ONLY public.catalog_product DROP CONSTRAINT IF EXISTS catalog_product_pkey;
ALTER TABLE IF EXISTS ONLY public.catalog_category DROP CONSTRAINT IF EXISTS catalog_category_slug_key;
ALTER TABLE IF EXISTS ONLY public.catalog_category DROP CONSTRAINT IF EXISTS catalog_category_pkey;
ALTER TABLE IF EXISTS ONLY public.catalog_brand DROP CONSTRAINT IF EXISTS catalog_brand_slug_key;
ALTER TABLE IF EXISTS ONLY public.catalog_brand DROP CONSTRAINT IF EXISTS catalog_brand_pkey;
ALTER TABLE IF EXISTS ONLY public.catalog_brand DROP CONSTRAINT IF EXISTS catalog_brand_name_key;
ALTER TABLE IF EXISTS ONLY public.auth_user DROP CONSTRAINT IF EXISTS auth_user_username_key;
ALTER TABLE IF EXISTS ONLY public.auth_user_user_permissions DROP CONSTRAINT IF EXISTS auth_user_user_permissions_user_id_permission_id_14a6b632_uniq;
ALTER TABLE IF EXISTS ONLY public.auth_user_user_permissions DROP CONSTRAINT IF EXISTS auth_user_user_permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.auth_user DROP CONSTRAINT IF EXISTS auth_user_pkey;
ALTER TABLE IF EXISTS ONLY public.auth_user_groups DROP CONSTRAINT IF EXISTS auth_user_groups_user_id_group_id_94350c0c_uniq;
ALTER TABLE IF EXISTS ONLY public.auth_user_groups DROP CONSTRAINT IF EXISTS auth_user_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.auth_permission DROP CONSTRAINT IF EXISTS auth_permission_pkey;
ALTER TABLE IF EXISTS ONLY public.auth_permission DROP CONSTRAINT IF EXISTS auth_permission_content_type_id_codename_01ab375a_uniq;
ALTER TABLE IF EXISTS ONLY public.auth_group DROP CONSTRAINT IF EXISTS auth_group_pkey;
ALTER TABLE IF EXISTS ONLY public.auth_group_permissions DROP CONSTRAINT IF EXISTS auth_group_permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.auth_group_permissions DROP CONSTRAINT IF EXISTS auth_group_permissions_group_id_permission_id_0cd325b0_uniq;
ALTER TABLE IF EXISTS ONLY public.auth_group DROP CONSTRAINT IF EXISTS auth_group_name_key;
DROP TABLE IF EXISTS public.siteinfo_sitesettings;
DROP TABLE IF EXISTS public.news_article;
DROP TABLE IF EXISTS public.leads_dealerapplication;
DROP TABLE IF EXISTS public.leads_contactmessage;
DROP TABLE IF EXISTS public.django_session;
DROP TABLE IF EXISTS public.django_migrations;
DROP TABLE IF EXISTS public.django_content_type;
DROP TABLE IF EXISTS public.django_admin_log;
DROP TABLE IF EXISTS public.catalog_product;
DROP TABLE IF EXISTS public.catalog_category;
DROP TABLE IF EXISTS public.catalog_brand;
DROP TABLE IF EXISTS public.auth_user_user_permissions;
DROP TABLE IF EXISTS public.auth_user_groups;
DROP TABLE IF EXISTS public.auth_user;
DROP TABLE IF EXISTS public.auth_permission;
DROP TABLE IF EXISTS public.auth_group_permissions;
DROP TABLE IF EXISTS public.auth_group;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auth_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);


--
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_group ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_group_permissions (
    id bigint NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_group_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_permission ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(150) NOT NULL,
    first_name character varying(150) NOT NULL,
    last_name character varying(150) NOT NULL,
    email character varying(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


--
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_user_groups (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_user_groups ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_user ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_user_user_permissions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.auth_user_user_permissions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auth_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: catalog_brand; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_brand (
    id bigint NOT NULL,
    name character varying(80) NOT NULL,
    name_cn character varying(80) NOT NULL,
    slug character varying(100) NOT NULL,
    logo character varying(100) NOT NULL,
    description text NOT NULL,
    is_active boolean NOT NULL,
    sort_order integer NOT NULL,
    CONSTRAINT catalog_brand_sort_order_check CHECK ((sort_order >= 0))
);


--
-- Name: catalog_brand_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.catalog_brand ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.catalog_brand_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: catalog_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_category (
    id bigint NOT NULL,
    name character varying(80) NOT NULL,
    short_name character varying(40) NOT NULL,
    slug character varying(40) NOT NULL,
    sort_order integer NOT NULL,
    CONSTRAINT catalog_category_sort_order_check CHECK ((sort_order >= 0))
);


--
-- Name: catalog_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.catalog_category ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.catalog_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: catalog_product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.catalog_product (
    id bigint NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(220) NOT NULL,
    image character varying(100) NOT NULL,
    image_alt character varying(200) NOT NULL,
    description character varying(255) NOT NULL,
    packaging character varying(160) NOT NULL,
    is_active boolean NOT NULL,
    sort_order integer NOT NULL,
    brand_id bigint NOT NULL,
    category_id bigint NOT NULL,
    body text NOT NULL,
    seo_description character varying(160) NOT NULL,
    seo_title character varying(70) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT catalog_product_sort_order_check CHECK ((sort_order >= 0))
);


--
-- Name: catalog_product_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.catalog_product ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.catalog_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_admin_log ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_content_type ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_migrations (
    id bigint NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.django_migrations ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.django_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: django_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


--
-- Name: leads_contactmessage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads_contactmessage (
    id bigint NOT NULL,
    hoten character varying(120) NOT NULL,
    sdt character varying(15) NOT NULL,
    email character varying(254) NOT NULL,
    zalo character varying(40) NOT NULL,
    previous_count integer NOT NULL,
    utm_source character varying(200) NOT NULL,
    utm_medium character varying(200) NOT NULL,
    utm_campaign character varying(200) NOT NULL,
    referrer character varying(500) NOT NULL,
    landing_page character varying(500) NOT NULL,
    status character varying(12) NOT NULL,
    internal_note text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    telegram_sent boolean NOT NULL,
    telegram_error text NOT NULL,
    telegram_message_id bigint,
    chude character varying(40) NOT NULL,
    noidung text NOT NULL,
    CONSTRAINT leads_contactmessage_previous_count_check CHECK ((previous_count >= 0))
);


--
-- Name: leads_contactmessage_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.leads_contactmessage ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.leads_contactmessage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: leads_dealerapplication; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads_dealerapplication (
    id bigint NOT NULL,
    hoten character varying(120) NOT NULL,
    sdt character varying(15) NOT NULL,
    email character varying(254) NOT NULL,
    zalo character varying(40) NOT NULL,
    previous_count integer NOT NULL,
    utm_source character varying(200) NOT NULL,
    utm_medium character varying(200) NOT NULL,
    utm_campaign character varying(200) NOT NULL,
    referrer character varying(500) NOT NULL,
    landing_page character varying(500) NOT NULL,
    status character varying(12) NOT NULL,
    internal_note text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    telegram_sent boolean NOT NULL,
    telegram_error text NOT NULL,
    telegram_message_id bigint,
    donvi character varying(200) NOT NULL,
    khuvuc character varying(40) NOT NULL,
    loaihinh character varying(60) NOT NULL,
    sanluong character varying(20) NOT NULL,
    completion_token uuid NOT NULL,
    is_complete boolean NOT NULL,
    CONSTRAINT leads_dealerapplication_previous_count_check CHECK ((previous_count >= 0))
);


--
-- Name: leads_dealerapplication_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.leads_dealerapplication ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.leads_dealerapplication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: news_article; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.news_article (
    id bigint NOT NULL,
    title character varying(200) NOT NULL,
    slug character varying(220) NOT NULL,
    topic character varying(40) NOT NULL,
    cover character varying(100) NOT NULL,
    cover_alt character varying(200) NOT NULL,
    excerpt text NOT NULL,
    body text NOT NULL,
    published_at timestamp with time zone NOT NULL,
    is_published boolean NOT NULL
);


--
-- Name: news_article_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.news_article ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.news_article_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: siteinfo_sitesettings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.siteinfo_sitesettings (
    id bigint NOT NULL,
    hotline_wholesale character varying(60) NOT NULL,
    hotline_retail character varying(60) NOT NULL,
    email character varying(120) NOT NULL,
    zalo_oa character varying(120) NOT NULL,
    tax_code character varying(60) NOT NULL,
    business_license_no character varying(60) NOT NULL,
    business_license_date character varying(60) NOT NULL,
    business_license_issuer character varying(120) NOT NULL,
    head_office_address character varying(255) NOT NULL,
    warehouse_address character varying(255) NOT NULL,
    warehouse_area character varying(60) NOT NULL,
    shopee_url character varying(255) NOT NULL,
    lazada_url character varying(255) NOT NULL,
    tiktok_url character varying(255) NOT NULL,
    moit_notice character varying(255) NOT NULL,
    founded_year character varying(60) NOT NULL,
    retail_points character varying(60) NOT NULL,
    staff_count character varying(60) NOT NULL,
    coverage character varying(120) NOT NULL,
    shipping_partner character varying(120) NOT NULL,
    facility_location character varying(120) NOT NULL
);


--
-- Name: siteinfo_sitesettings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.siteinfo_sitesettings ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.siteinfo_sitesettings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_group (id, name) FROM stdin;
1	Quản trị
2	Biên tập
\.


--
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
1	1	5
2	1	6
3	1	7
4	1	8
5	1	9
6	1	10
7	1	11
8	1	12
9	1	13
10	1	14
11	1	15
12	1	16
13	1	26
14	1	27
15	1	28
16	1	29
17	1	30
18	1	31
19	1	32
20	1	33
21	1	34
22	1	35
23	1	36
24	1	37
25	1	38
26	1	39
27	1	40
28	1	41
29	1	42
30	1	43
31	1	44
32	1	45
33	1	46
34	1	47
35	1	48
36	1	49
37	1	50
38	1	51
39	1	52
40	2	32
41	2	33
42	2	34
43	2	36
44	2	37
45	2	38
46	2	40
47	2	41
48	2	42
49	2	44
50	2	26
51	2	28
52	2	29
53	2	30
\.


--
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
1	Can add log entry	1	add_logentry
2	Can change log entry	1	change_logentry
3	Can delete log entry	1	delete_logentry
4	Can view log entry	1	view_logentry
5	Can add permission	3	add_permission
6	Can change permission	3	change_permission
7	Can delete permission	3	delete_permission
8	Can view permission	3	view_permission
9	Can add group	2	add_group
10	Can change group	2	change_group
11	Can delete group	2	delete_group
12	Can view group	2	view_group
13	Can add user	4	add_user
14	Can change user	4	change_user
15	Can delete user	4	delete_user
16	Can view user	4	view_user
17	Can add content type	5	add_contenttype
18	Can change content type	5	change_contenttype
19	Can delete content type	5	delete_contenttype
20	Can view content type	5	view_contenttype
21	Can add session	6	add_session
22	Can change session	6	change_session
23	Can delete session	6	delete_session
24	Can view session	6	view_session
25	Can add Thông tin doanh nghiệp	7	add_sitesettings
26	Can change Thông tin doanh nghiệp	7	change_sitesettings
27	Can delete Thông tin doanh nghiệp	7	delete_sitesettings
28	Can view Thông tin doanh nghiệp	7	view_sitesettings
29	Can add Thương hiệu	8	add_brand
30	Can change Thương hiệu	8	change_brand
31	Can delete Thương hiệu	8	delete_brand
32	Can view Thương hiệu	8	view_brand
33	Can add Ngành hàng	9	add_category
34	Can change Ngành hàng	9	change_category
35	Can delete Ngành hàng	9	delete_category
36	Can view Ngành hàng	9	view_category
37	Can add Sản phẩm	10	add_product
38	Can change Sản phẩm	10	change_product
39	Can delete Sản phẩm	10	delete_product
40	Can view Sản phẩm	10	view_product
41	Can add Bài viết	11	add_article
42	Can change Bài viết	11	change_article
43	Can delete Bài viết	11	delete_article
44	Can view Bài viết	11	view_article
45	Can add Lời nhắn liên hệ	12	add_contactmessage
46	Can change Lời nhắn liên hệ	12	change_contactmessage
47	Can delete Lời nhắn liên hệ	12	delete_contactmessage
48	Can view Lời nhắn liên hệ	12	view_contactmessage
49	Can add Đăng ký đại lý	13	add_dealerapplication
50	Can change Đăng ký đại lý	13	change_dealerapplication
51	Can delete Đăng ký đại lý	13	delete_dealerapplication
52	Can view Đăng ký đại lý	13	view_dealerapplication
\.


--
-- Data for Name: catalog_brand; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.catalog_brand (id, name, name_cn, slug, logo, description, is_active, sort_order) FROM stdin;
1	Daliyuan	达利园	daliyuan		bánh & bánh ngọt	t	1
3	Haochidian	好吃点	haochidian		bánh quy	t	3
4	Heqizheng	和其正	heqizheng		trà thảo mộc	t	4
5	Hi-Tiger	乐虎	hi-tiger		nước tăng lực	t	5
6	Doubendou	豆本豆	doubendou		sữa đậu nành	f	6
2	Copico	可比克	copico		snack khoai tây	t	2
\.


--
-- Data for Name: catalog_category; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.catalog_category (id, name, short_name, slug, sort_order) FROM stdin;
1	Bánh mì & bánh ngọt	Bánh	banh	1
2	Bánh quy & snack	Bánh quy	quy	2
3	Đồ uống	Đồ uống	uong	3
4	Cháo & sữa hạt	Cháo & sữa	chao	4
\.


--
-- Data for Name: catalog_product; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.catalog_product (id, name, slug, image, image_alt, description, packaging, is_active, sort_order, brand_id, category_id, body, seo_description, seo_title, updated_at) FROM stdin;
2	Trà xanh mơ xanh Daliyuan 500ml	tea-plum	products/tea-plum.jpg	Trà xanh mơ xanh Daliyuan 500ml	青梅绿茶	Chai 500ml · thùng 15 chai	t	2	1	3	<h2>Giới thiệu</h2><p>青梅绿茶 là vị bán chạy lâu năm của Daliyuan: nền trà xanh kết hợp thanh mai cho vị chua thanh, ít gắt, hợp khẩu vị người Việt và đặc biệt chạy tốt vào mùa nóng.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Chai PET 500ml, nhãn phụ tiếng Việt dán sẵn khi xuất kho.</li><li>Thùng 15 chai.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi thoáng mát; ngon hơn khi uống lạnh.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Vị đơn, dễ giới thiệu — khách mua lại nhiều.</li><li>Giá vốn thấp, biên lợi nhuận ổn ở kênh tạp hóa.</li><li>Đi kèm được với dòng trà trái cây ba vị để làm đầy kệ đồ uống.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Trà xanh thanh mai 青梅绿茶 Daliyuan chai 500ml, thùng 15 chai. Vị chua thanh dễ uống, nhập sỉ chính hãng qua Dali Foods Việt Nam.	Trà xanh Thanh mai Daliyuan 500ml — giá sỉ nguyên thùng	2026-09-08 09:46:51.864287+00
12	Croissant vị cam / socola 100g (4 cái)	croissant	products/croissant.jpg	Croissant Daliyuan vị cam và socola 100g	羊角面包 香橙味 · 巧克力味	Gói 100g (25g × 4 bánh) · thùng 32 gói	t	14	1	1	<h2>Giới thiệu</h2><p>羊角面包 của Daliyuan làm theo kiểu croissant nhiều lớp, nhân kem cam 香橙味 hoặc kem socola 巧克力味, tỷ lệ nhân trên 19%. Mỗi gói 100g có 4 bánh nhỏ 25g, thích hợp làm đồ ăn nhẹ giữa buổi.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Gói 100g gồm 4 bánh 25g, mỗi bánh bọc riêng.</li><li>Thùng 32 gói, hai vị đặt riêng hoặc trộn thùng.</li><li>Hạn dùng 6 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Mã mới ra mắt, đang được đẩy truyền thông — thời điểm tốt để lên kệ.</li><li>Hai vị cam và socola bổ sung cho nhau, dễ chốt combo.</li><li>Kết cấu nhiều lớp tạo khác biệt so với bánh mì ngọt thông thường.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh sừng bò 羊角面包 Daliyuan vị cam và socola, gói 100g gồm 4 bánh 25g, thùng 32 gói. Nhập sỉ chính hãng qua Dali Foods Việt Nam.	Bánh sừng bò Daliyuan vị cam / socola 100g — giá sỉ	2026-09-08 09:46:52.059062+00
5	Cháo Youyican đậu đỏ ý dĩ 360g	porridge-3	products/porridge-3.jpg	Cháo Youyican đậu đỏ ý dĩ 360g	又一餐 红豆薏仁粥	Lon 360g · thùng 12 lon	t	5	1	4	<h2>Giới thiệu</h2><p>又一餐 红豆薏仁粥 nấu sẵn trong lon, mở nắp là ăn được, hâm nóng một phút là có bữa sáng đủ ấm. Đậu đỏ và ý dĩ cho vị bùi nhẹ, ít ngọt — nhóm khách văn phòng và sinh viên mua lại đều.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Lon 360g, nắp giật, không cần dụng cụ mở.</li><li>Thùng 12 lon.</li><li>Hạn dùng 18 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Ngành hàng cháo lon còn mới ở Việt Nam, ít cạnh tranh trực tiếp.</li><li>Bán tốt ở kênh cửa hàng tiện lợi, ký túc xá và văn phòng.</li><li>Hạn dùng dài 18 tháng — rủi ro cận date thấp.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Cháo ăn liền Youyican 又一餐 đậu đỏ ý dĩ, lon 360g, thùng 12 lon. Bữa sáng 1 phút, giá sỉ từ Dali Foods Việt Nam.	Cháo Youyican đậu đỏ 360g — nhập sỉ thùng 12 lon	2026-09-08 09:46:51.89823+00
4	Trà thảo mộc Heqizheng 310ml	heqizheng	products/heqizheng.jpg	Trà thảo mộc Heqizheng 310ml	和其正 凉茶	Lon 310ml · thùng 24 lon	t	4	4	3	<h2>Giới thiệu</h2><p>和其正 凉茶 là dòng trà thảo mộc đóng lon quen thuộc của Dali Foods Group, nấu từ công thức thảo mộc truyền thống, vị ngọt thanh, uống mát. Đây là lựa chọn thay thế nước ngọt có ga cho nhóm khách quan tâm đồ uống nhẹ.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Lon 310ml.</li><li>Thùng 24 lon.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi thoáng mát; ngon hơn khi uống lạnh.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Ngách trà thảo mộc ít đối thủ ở kênh tạp hóa miền Bắc.</li><li>Bán tốt kèm đồ ăn nhiều dầu mỡ — hợp quán ăn và lẩu nướng.</li><li>Bao bì lon dễ trưng bày theo tháp tại quầy.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Trà thảo mộc Heqizheng 和其正 lon 310ml, thùng 24 lon. Vị thanh mát truyền thống, nhập sỉ chính hãng qua Dali Foods Việt Nam.	Trà thảo mộc Heqizheng 和其正 310ml — sỉ 24 lon/thùng	2026-09-08 09:46:51.887055+00
6	Cháo bát bảo long nhãn hạt sen 360g	porridge-4	products/porridge-4.jpg	Cháo bát bảo long nhãn hạt sen 360g	桂圆莲子八宝粥	Lon 360g · thùng 12 lon	t	6	1	4	<h2>Giới thiệu</h2><p>桂圆莲子八宝粥 là công thức cháo bát bảo cổ điển với long nhãn và hạt sen, hạt còn nguyên, nước cháo sánh. Ăn nóng hay lạnh đều được nên bán được quanh năm.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Lon 360g, nắp giật.</li><li>Thùng 12 lon.</li><li>Hạn dùng 18 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Vị quen thuộc với người Việt — không cần giáo dục thị trường.</li><li>Hay được mua làm quà biếu theo thùng vào dịp lễ Tết.</li><li>Đi cặp với cháo đậu đỏ để làm đủ dải cháo lon trên kệ.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Cháo bát bảo 桂圆莲子八宝粥 long nhãn hạt sen, lon 360g, thùng 12 lon. Nhập sỉ chính hãng qua Dali Foods Việt Nam.	Cháo bát bảo long nhãn hạt sen 360g — sỉ 12 lon/thùng	2026-09-08 09:46:51.909965+00
7	Sữa lạc Milk Peanut 370g	milk-peanut	products/milk-peanut.jpg	Sữa lạc Milk Peanut 370g	牛奶花生	Lon 370g · thùng 12 lon	t	9	1	4	<h2>Giới thiệu</h2><p>牛奶花生 là sữa lạc đóng lon — đậu phộng xay mịn hòa với sữa, vị béo bùi, không quá ngọt. Đây là dòng đồ uống dinh dưỡng bán tốt ở kênh trường học và các quán ăn sáng.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Lon 370g.</li><li>Thùng 12 lon.</li><li>Hạn dùng 18 tháng kể từ ngày sản xuất.</li><li>Lắc đều trước khi uống; ngon hơn khi uống lạnh.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Đồ uống dinh dưỡng, dễ bán kèm bánh mì và cháo lon.</li><li>Lon 370g định lượng lớn hơn mặt bằng chung cùng tầm giá.</li><li>Hạn dùng dài, phù hợp đại lý gom hàng theo quý.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Sữa lạc Daliyuan 牛奶花生 lon 370g, thùng 12 lon. Sữa đậu phộng vị béo bùi, giá sỉ và chính sách đại lý từ Dali Foods Việt Nam.	Sữa lạc Milk Peanut 牛奶花生 370g — nhập sỉ	2026-09-08 09:46:51.972272+00
8	Bánh mì ăn sáng 200g (5 cái)	breakfast-bread	products/breakfast-bread.jpg	Bánh mì ăn sáng Daliyuan 200g	早餐包	Gói 200g (40g × 5 bánh) · thùng 20 túi	t	10	1	1	<h2>Giới thiệu</h2><p>早餐包 là dòng bánh mì mềm ăn sáng bán chạy nhất của Daliyuan. Mỗi túi 200g có 5 bánh 40g bọc riêng, ruột xốp, vị sữa nhẹ — ăn liền hoặc hâm nóng đều được.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Túi 200g gồm 5 bánh 40g, mỗi bánh bọc riêng.</li><li>Thùng 20 túi.</li><li>Hạn dùng 6 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>SKU dẫn dắt cả dòng bánh mì — kéo theo các mã còn lại lên kệ.</li><li>Định lượng 5 bánh mỗi túi hợp túi tiền, quay vòng nhanh ở tạp hóa.</li><li>Đóng gói lẻ từng bánh, tiện bán xé lẻ tại quầy.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh mì ăn sáng Daliyuan 早餐包 gói 200g gồm 5 bánh 40g, thùng 20 túi. Nhập sỉ chính hãng qua Dali Foods Việt Nam.	Bánh mì ăn sáng Daliyuan 早餐包 200g — giá sỉ	2026-09-08 09:46:51.996926+00
11	Bánh mì socola Hei Hei Bao 80g	heiheibao	products/heiheibao.jpg	Bánh mì socola Hei Hei Bao 80g	黑黑包 浓醇巧克力味	Gói 80g · thùng 24 gói	t	13	1	1	<h2>Giới thiệu</h2><p>黑黑包 nổi bật nhờ vỏ bánh màu đen từ bột cacao và nhân socola đậm bên trong. Ngoại hình khác lạ khiến mã này rất dễ lên nội dung mạng xã hội và bán chạy theo trend.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Gói 80g, một chiếc.</li><li>Thùng 24 gói.</li><li>Hạn dùng 6 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Ngoại hình bắt mắt — SKU tốt để chạy nội dung TikTok, Facebook.</li><li>Giá lẻ vừa tầm ăn vặt, khách trẻ mua lại nhiều.</li><li>Cùng thùng 24 gói với dòng K17, gộp đơn bánh mì rất gọn.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh bao socola Hei Hei Bao 黑黑包 K17 gói 80g, thùng 24 gói. Vỏ bánh cacao, nhân socola đậm, giá sỉ từ Dali Foods Việt Nam.	Bánh bao K17 socola Hei Hei Bao 80g — nhập sỉ	2026-09-08 09:46:52.046301+00
13	Bánh quy óc chó giòn 108g	biscuit-walnut	products/biscuit-walnut.jpg	Bánh quy óc chó giòn Haochidian 108g	好吃点 香脆核桃饼	Gói 108g · thùng 40 gói	t	15	3	2	<h2>Giới thiệu</h2><p>香脆核桃饼 là mã bánh quy chủ lực của Haochidian: bánh giòn, thơm mùi óc chó rang, ít ngọt. Đây là dòng bánh quy hạt bán chạy nhất trong danh mục 好吃点.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Gói 108g.</li><li>Thùng 40 gói.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Thương hiệu 好吃点 đã có nhận diện sẵn với khách quen hàng nhập.</li><li>Còn quy cách hộp 800g cho đại lý muốn giá vốn thấp hơn trên mỗi gói.</li><li>Hạn dùng 12 tháng, an toàn cho đại lý trữ hàng theo quý.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh quy óc chó giòn Haochidian 香脆核桃饼 gói 108g, thùng 40 gói. Giá sỉ nguyên thùng từ Dali Foods Việt Nam.	Bánh quy óc chó Haochidian 好吃点 108g — nhập sỉ	2026-09-08 09:46:52.070667+00
14	Bánh quy hạt điều giòn 108g	biscuit-pair	products/biscuit-pair.jpg	Bánh quy hạt điều giòn Haochidian 108g	好吃点 香脆腰果饼	Gói 108g · thùng 40 gói	t	16	3	2	<h2>Giới thiệu</h2><p>香脆腰果饼 dùng hạt điều thay óc chó, vị bùi và ngọt nhẹ hơn. Mã này thường được đặt cùng bánh quy óc chó để khách có hai lựa chọn trên cùng một kệ.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Gói 108g.</li><li>Thùng 40 gói.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Đi cặp với mã óc chó — tăng giá trị mỗi đơn mà không tăng số lần giao.</li><li>Hạt điều là nguyên liệu quen thuộc, dễ bán cho khách Việt.</li><li>Cùng thùng 40 gói với mã óc chó, tính đơn rất gọn.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh quy hạt điều giòn Haochidian 香脆腰果饼 gói 108g, thùng 40 gói. Nhập sỉ chính hãng qua Dali Foods Việt Nam.	Bánh quy hạt điều Haochidian 好吃点 108g — giá sỉ	2026-09-08 09:46:52.081865+00
9	Bánh mì Pháp mini 200g (10 cái)	mini-french	products/mini-french.jpg	Bánh mì Pháp mini Daliyuan 200g	法式小面包 香奶味	Gói 200g (20g × 10 bánh) · thùng 15 túi	t	11	1	1	<h2>Giới thiệu</h2><p>法式小面包 香奶味 — bánh mì Pháp cỡ mini nhân kem sữa, mỗi túi 10 bánh 20g vừa một miếng. Đây là mã bán chạy ở kênh trường học và các cửa hàng bán đồ ăn vặt.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Túi 200g gồm 10 bánh 20g, mỗi bánh bọc riêng.</li><li>Thùng 15 túi.</li><li>Hạn dùng 6 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Cỡ mini hợp khách nhỏ tuổi — bán mạnh quanh khu vực trường học.</li><li>10 bánh mỗi túi, dễ làm combo ăn vặt với sữa lạc và trà trái cây.</li><li>Giá lẻ thấp, khách quyết định mua nhanh.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh mì Pháp mini 法式小面包 vị sữa, túi 200g gồm 10 bánh 20g, thùng 15 túi. Giá sỉ nguyên thùng từ Dali Foods Việt Nam.	Bánh mì Pháp mini Daliyuan 200g — sỉ 15 túi/thùng	2026-09-08 09:46:52.02243+00
15	Hộp bánh quy hạt Haochidian 800g (óc chó / hạt điều)	biscuit-cartons	products/biscuit-cartons.jpg	Thùng bánh quy hạt Haochidian 800g	好吃点 800克 量贩装	Hộp 800g (22g × 36 gói) · thùng 12 hộp	t	17	3	2	<h2>Giới thiệu</h2><p>好吃点 800克 量贩装 là quy cách hộp lượng lớn dành cho đại lý và kênh bán sỉ: 36 gói nhỏ 22g xếp sẵn trong hộp 800g, chọn nguyên vị óc chó hoặc nguyên vị hạt điều tùy nhu cầu điểm bán.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Hộp 800g gồm 36 gói nhỏ 22g.</li><li>Thùng 12 hộp.</li><li>Chọn nguyên vị óc chó hoặc nguyên vị hạt điều khi đặt hàng.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Giá vốn trên mỗi gói thấp nhất trong dải bánh quy Haochidian.</li><li>Gói nhỏ 22g hợp làm hàng khuyến mãi, quà kèm đơn và suất ăn nhẹ văn phòng.</li><li>Quy cách chuẩn cho đơn mở đại lý và các chương trình xả hàng.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Hộp bánh quy Haochidian 800g 量贩装 gồm 36 gói nhỏ 22g, thùng 12 hộp, vị óc chó hoặc hạt điều. Giá sỉ từ Dali Foods Việt Nam.	Hộp bánh quy hạt Haochidian 800g — sỉ 12 hộp/thùng	2026-09-08 09:46:52.091862+00
16	Bánh quy ngũ cốc cao xơ Guye 110g (3 vị)	guye	products/guye.jpg	Bánh quy ngũ cốc cao xơ Guye 110g	谷野 高纤煎麸饼 · 高纤粗粮饼 · 高纤蔬菜饼	Gói 110g · thùng 40 gói	t	18	3	2	<h2>Giới thiệu</h2><p>谷野 là dòng bánh quy cao xơ của Haochidian, gồm 高纤煎麸饼 ngũ cốc canxi yến mạch, 高纤粗粮饼 ngũ cốc canxi và 高纤蔬菜饼 rau củ hành cà chua. Ít ngọt, nhiều chất xơ — nhắm vào nhóm khách ăn kiêng và dân văn phòng.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Gói 110g.</li><li>Thùng 40 gói, ba vị đặt riêng hoặc trộn thùng.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Ngách bánh quy healthy đang tăng, ít hàng nhập cạnh tranh trực tiếp.</li><li>Ba vị cho phép điểm bán thử phản ứng thị trường trong một lần đặt.</li><li>Bán tốt kèm trà thảo mộc và sữa lạc ở kênh văn phòng.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh quy cao xơ Guye 谷野 110g ba vị: canxi yến mạch, ngũ cốc canxi, rau củ hành cà chua. Thùng 40 gói, giá sỉ từ Dali Foods Việt Nam.	Bánh quy ngũ cốc cao xơ Guye 谷野 110g — nhập sỉ	2026-09-08 09:46:52.102362+00
17	Bánh quy kẹp mỏng giòn Cookico 90g	cookico	products/cookico.jpg	Bánh quy kẹp mỏng giòn Cookico 90g	Landy Castle 薄脆夹心曲奇 · bơ / chanh	Gói 90g · thùng 32 gói	t	20	1	2	<h2>Giới thiệu</h2><p>Landy Castle 薄脆夹心曲奇 — bánh quy mỏng 3mm kẹp kem, giòn tan, ít đường, có hai vị bơ và chanh. Bao bì nhỏ gọn, định vị đồ ăn vặt tiện mang theo.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Gói 90g.</li><li>Thùng 32 gói, hai vị đặt riêng hoặc trộn thùng.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Bao bì trẻ trung, hợp kệ đồ ăn vặt ở cửa hàng tiện lợi.</li><li>Định vị ít đường — bán được cho nhóm khách ngại bánh ngọt.</li><li>Giá lẻ thấp, phù hợp làm hàng dùng thử kèm đơn lớn.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh quy kẹp mỏng giòn Cookico Landy Castle 90g, vị bơ và chanh. Thùng 32 gói, nhập sỉ chính hãng qua Dali Foods Việt Nam.	Bánh quy kẹp Cookico 90g vị bơ / chanh — giá sỉ	2026-09-08 09:46:52.142029+00
1	Trà trái cây Daliyuan 500ml (3 vị)	tea-trio	products/tea-trio.jpg	Trà trái cây Daliyuan 500ml	果味茶 · đào trắng ô long / nho xanh trà xanh / chanh hồng trà	Chai 500ml · thùng 15 chai	t	1	1	3	<h2>Giới thiệu</h2><p>Dòng trà trái cây 果味茶 của Daliyuan pha nền trà thật với nước ép cô đặc, vị ngọt vừa và hậu trà rõ nên uống được cả ngày. Catalogue 2026 gồm ba vị: ô long đào trắng (白桃乌龙茶), nho xanh trà xanh (青提绿茶) và trà đen vị chanh (柠檬红茶) — chia đều trong cùng một thùng để điểm bán mới thử thị trường trước khi chốt vị bán chạy.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Chai PET 500ml, nhãn tiếng Trung kèm nhãn phụ tiếng Việt.</li><li>Thùng 15 chai, chia đều ba vị theo yêu cầu đặt hàng.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi thoáng mát; ngon hơn khi uống lạnh.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Ba vị trong một SKU — giảm rủi ro tồn kho khi mở điểm bán mới.</li><li>Phân khúc giá phổ thông, xoay vòng nhanh ở kênh trường học và văn phòng.</li><li>Chai 500ml vừa tay, phù hợp cả bán lẻ lẫn combo giao hàng.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Trà trái cây Daliyuan 500ml: ô long đào trắng, nho xanh trà xanh, đen vị chanh. Thùng 15 chai, giá sỉ từ Dali Foods Việt Nam.	Trà trái cây Daliyuan 500ml 3 vị — giá sỉ thùng 15 chai	2026-09-08 09:46:51.833614+00
3	Nước tăng lực Hi-Tiger 250ml	hitiger	products/hitiger.jpg	Nước tăng lực Hi-Tiger 250ml	乐虎 氨基酸维生素功能饮料	Lon 250ml · thùng 24 lon · có chai 380ml	t	3	5	3	<h2>Giới thiệu</h2><p>Hi-Tiger 乐虎 là thương hiệu nước tăng lực chủ lực của Dali Foods Group, công thức bổ sung taurine, axit amin và vitamin nhóm B. Catalogue có hai quy cách: lon thiếc 250ml và chai 380ml — lon chạy mạnh ở kênh HORECA, quán ăn đêm và trạm xăng, chai hợp khách mang theo.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Lon thiếc 250ml, thùng 24 lon.</li><li>Chai 380ml — đặt riêng theo nhu cầu.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Ngành hàng tăng lực quay vòng nhanh, khách mua theo lốc và theo thùng.</li><li>Hai quy cách cho hai kênh bán khác nhau mà chỉ cần làm việc với một nhà cung cấp.</li><li>Định vị giá cạnh tranh so với các thương hiệu tăng lực cùng dung tích.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Hi-Tiger 乐虎 lon 250ml, thùng 24 lon; còn quy cách chai 380ml. Giá sỉ và chính sách đại lý từ Dali Foods Việt Nam.	Nước tăng lực Hi-Tiger 乐虎 250ml — sỉ thùng 24 lon	2026-09-08 09:46:51.875396+00
18	Cháo Youyican gạo lứt khoai tím 360g	porridge-purple	products/porridge-purple.jpg	Cháo Youyican gạo lứt khoai tím 360g	又一餐 燕麦紫薯粥	Lon 360g · thùng 12 lon	t	7	1	4	<h2>Giới thiệu</h2><p>又一餐 燕麦紫薯粥 là vị mới trong dòng cháo lon Youyican: yến mạch nấu cùng khoai tím, màu tím tự nhiên, ít ngọt và nhiều chất xơ hơn các vị cháo truyền thống.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Lon 360g, nắp giật.</li><li>Thùng 12 lon.</li><li>Hạn dùng 18 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Màu sắc và định vị 'ngũ cốc nguyên hạt' hợp nhóm khách trẻ quan tâm ăn uống lành mạnh.</li><li>Vị mới, chưa bị bão hòa ở kênh cửa hàng tiện lợi.</li><li>Cùng quy cách thùng với hai vị cháo còn lại — gộp đơn không phát sinh chuyến giao.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Cháo Youyican 又一餐 燕麦紫薯粥 gạo lứt khoai tím, lon 360g, thùng 12 lon. Nhập sỉ chính hãng qua Dali Foods Việt Nam.	Cháo gạo lứt khoai tím Youyican 360g — nhập sỉ	2026-09-08 09:46:51.932643+00
19	Chè khoai môn yến mạch Ovici 360g	che-khoai-mon	products/che-khoai-mon.jpg	Chè khoai môn yến mạch Ovici 360g	谷吨吨 牛乳香芋燕麦	Lon 360g · thùng 12 lon	t	8	1	4	<h2>Giới thiệu</h2><p>谷吨吨 牛乳香芋燕麦 là món chè đóng lon: khoai môn và yến mạch nấu với sữa, có cả miếng khoai nguyên. Ngọt vừa, ăn lạnh ngon hơn — đây là mã đồ ăn vặt hơn là bữa sáng.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Lon 360g, nắp giật.</li><li>Thùng 12 lon.</li><li>Hạn dùng 18 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo; ngon hơn khi để lạnh trước khi ăn.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Khác biệt với cả kệ cháo lẫn kệ sữa — dễ tạo điểm nhấn trưng bày.</li><li>Vị khoai môn sữa đang là trend đồ uống, kéo theo nhu cầu cho món chè cùng vị.</li><li>Chung thùng 12 lon với dòng cháo, thuận tiện khi gom đơn.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Chè khoai môn yến mạch Ovici 谷吨吨 牛乳香芋燕麦, lon 360g, thùng 12 lon. Nhập sỉ chính hãng qua Dali Foods Việt Nam.	Chè khoai môn yến mạch Ovici 360g — nhập sỉ thùng 12 lon	2026-09-08 09:46:51.957311+00
10	Bánh mì K17 — dừa / chà bông / rong biển	k17-trio	products/k17-trio.jpg	Bánh mì K17 Daliyuan ba vị	K17 大椰蓉面包 · 肉松芝麻 · 肉松海苔吐司	Gói lẻ · thùng 24 gói	t	12	1	1	<h2>Giới thiệu</h2><p>Dòng K17 gồm ba vị mặn — ngọt xen kẽ: 大椰蓉面包 nhân dừa, 肉松芝麻面包 chà bông vừng và 肉松海苔吐司 chà bông rong biển. Bộ ba này phủ được cả nhóm khách thích vị ngọt lẫn nhóm thích vị mặn, nên hiếm khi bị tồn một vị.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Gói lẻ từng chiếc, bán xé lẻ hoặc theo lốc.</li><li>Thùng 24 gói, chia vị theo yêu cầu đặt hàng.</li><li>Hạn dùng 6 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Ba vị trong một dòng — dễ lấp đầy kệ bánh mì chỉ với một mã đặt.</li><li>Vị chà bông hợp khẩu vị Việt, khác biệt so với bánh mì ngọt thông thường.</li><li>Gói lẻ tiện bán tại quầy thu ngân, kích thích mua ngẫu hứng.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh mì K17 Daliyuan ba vị: dừa, chà bông vừng, chà bông rong biển. Gói lẻ, thùng 24 gói, nhập sỉ qua Dali Foods Việt Nam.	Bánh mì K17 dừa / chà bông vừng / rong biển — giá sỉ	2026-09-08 09:46:52.034683+00
20	Bánh quy mặn lá hẹ Daliyuan 130g	banh-la-he	products/banh-la-he.jpg	Bánh quy mặn lá hẹ Daliyuan 130g	达利园 香葱咸饼	Gói 130g · thùng 40 gói	t	19	1	2	<h2>Giới thiệu</h2><p>香葱咸饼 là bánh quy mặn rắc lá hẹ và hành lá, giòn xốp, vị mặn nhẹ. Đây là mã hiếm trong kệ bánh quy Việt vốn thiên về vị ngọt, nên rất dễ tạo khác biệt cho điểm bán.</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Gói 130g dạng thanh dài.</li><li>Thùng 40 gói.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Vị mặn — lấp đúng khoảng trống trên kệ bánh quy vốn toàn vị ngọt.</li><li>Ăn kèm trà và cà phê, dễ bán ở quán nước và văn phòng.</li><li>Cùng thùng 40 gói với dòng Guye, gộp đơn bánh quy rất gọn.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Bánh quy mặn lá hẹ 香葱咸饼 Daliyuan gói 130g, thùng 40 gói. Vị mặn nhẹ thơm hành lá, nhập sỉ qua Dali Foods Việt Nam.	Bánh quy mặn lá hẹ Daliyuan 130g — sỉ 40 gói/thùng	2026-09-08 09:46:52.11972+00
21	Snack khoai tây Copico 45g (5 vị)	snack-copico	products/snack-copico.jpg	Snack khoai tây Copico 45g năm vị	可比克 薯片 · nguyên bản / cà chua / BBQ / cay / dưa leo	Lon 45g · thùng 48 lon	t	21	2	2	<h2>Giới thiệu</h2><p>可比克 薯片 là thương hiệu snack khoai tây của Dali Foods Group, đóng lon giấy giữ bánh nguyên miếng thay vì vụn như bao mềm. Catalogue 2026 có năm vị: nguyên bản (原滋味), cà chua (番茄味), BBQ (烧烤味), cay (香辣味) và dưa leo thanh mát (爽口青瓜味).</p><h2>Quy cách &amp; bảo quản</h2><ul><li>Lon giấy 45g.</li><li>Thùng 48 lon, năm vị đặt riêng hoặc trộn thùng.</li><li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li><li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li></ul><h2>Vì sao nên nhập về bán</h2><ul><li>Lon giấy chống vỡ — tỷ lệ hàng hỏng khi vận chuyển thấp hơn snack bao mềm.</li><li>Năm vị phủ rộng khẩu vị, dễ bày thành một dải màu bắt mắt trên kệ.</li><li>Thùng 48 lon, giá vốn mỗi lon thấp khi nhập nguyên thùng.</li></ul><h2>Hồ sơ kèm theo mỗi lô</h2><p>Mỗi lô xuất kho của Dali Foods Việt Nam đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT — đủ hồ sơ chào hàng vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</p>	Snack khoai tây Copico 可比克 lon 45g, 5 vị: nguyên bản, cà chua, BBQ, cay, dưa leo. Thùng 48 lon, giá sỉ từ Dali Foods Việt Nam.	Snack khoai tây Copico 45g — sỉ thùng 48 lon	2026-09-08 09:46:52.16126+00
\.


--
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_content_type (id, app_label, model) FROM stdin;
1	admin	logentry
2	auth	group
3	auth	permission
4	auth	user
5	contenttypes	contenttype
6	sessions	session
7	siteinfo	sitesettings
8	catalog	brand
9	catalog	category
10	catalog	product
11	news	article
12	leads	contactmessage
13	leads	dealerapplication
\.


--
-- Data for Name: django_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.django_migrations (id, app, name, applied) FROM stdin;
1	contenttypes	0001_initial	2026-08-26 07:09:21.563625+00
2	auth	0001_initial	2026-08-26 07:09:21.604473+00
3	admin	0001_initial	2026-08-26 07:09:21.617367+00
4	admin	0002_logentry_remove_auto_add	2026-08-26 07:09:21.622317+00
5	admin	0003_logentry_add_action_flag_choices	2026-08-26 07:09:21.625822+00
6	contenttypes	0002_remove_content_type_name	2026-08-26 07:09:21.634704+00
7	auth	0002_alter_permission_name_max_length	2026-08-26 07:09:21.639195+00
8	auth	0003_alter_user_email_max_length	2026-08-26 07:09:21.643215+00
9	auth	0004_alter_user_username_opts	2026-08-26 07:09:21.646972+00
10	auth	0005_alter_user_last_login_null	2026-08-26 07:09:21.650743+00
11	auth	0006_require_contenttypes_0002	2026-08-26 07:09:21.651272+00
12	auth	0007_alter_validators_add_error_messages	2026-08-26 07:09:21.654415+00
13	auth	0008_alter_user_username_max_length	2026-08-26 07:09:21.660641+00
14	auth	0009_alter_user_last_name_max_length	2026-08-26 07:09:21.664838+00
15	auth	0010_alter_group_name_max_length	2026-08-26 07:09:21.669571+00
16	auth	0011_update_proxy_permissions	2026-08-26 07:09:21.672687+00
17	auth	0012_alter_user_first_name_max_length	2026-08-26 07:09:21.676577+00
18	catalog	0001_initial	2026-08-26 07:09:21.70541+00
19	leads	0001_initial	2026-08-26 07:09:21.717483+00
20	news	0001_initial	2026-08-26 07:09:21.728961+00
21	sessions	0001_initial	2026-08-26 07:09:21.734809+00
22	siteinfo	0001_initial	2026-08-26 07:09:21.746737+00
23	catalog	0002_alter_brand_is_active	2026-08-31 09:56:27.222706+00
24	catalog	0003_product_body_product_seo_description_and_more	2026-09-08 08:59:47.470448+00
\.


--
-- Data for Name: news_article; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.news_article (id, title, slug, topic, cover, cover_alt, excerpt, body, published_at, is_published) FROM stdin;
1	Dali Foods Việt Nam là đơn vị phân phối chính hãng sản phẩm Dali Foods tại Việt Nam	dali-foods-viet-nam-nha-phan-phoi-chinh-hang	Tin công ty	news/breakfast-bread-2.jpg	Dali Foods Việt Nam phân phối sản phẩm Dali Foods	Hợp đồng phân phối đã ký kết — mở đường đưa bánh, snack và đồ uống Dali chính ngạch phủ khắp kênh bán lẻ Việt Nam.	<h2>Hợp đồng phân phối đã ký kết</h2>\n<p>Dali Foods Việt Nam là đơn vị phân phối chính hãng sản phẩm của Dali Foods Group tại thị trường Việt Nam. Toàn bộ hàng hóa được nhập khẩu chính ngạch; mỗi lô xuất kho đi kèm nhãn phụ tiếng Việt, bản tự công bố sản phẩm và hóa đơn VAT.</p>\n<h2>Danh mục phân phối</h2>\n<p>Catalogue 2026 gồm 21 mã hàng thuộc năm thương hiệu của tập đoàn, chia thành bốn ngành hàng:</p>\n<ul>\n<li><strong>Bánh mì &amp; bánh ngọt</strong> — 5 mã Daliyuan 达利园: bánh mì ăn sáng 早餐包, bánh mì Pháp mini, bộ ba K17, bánh mì socola Hei Hei Bao và croissant hai vị.</li>\n<li><strong>Bánh quy &amp; snack</strong> — 7 mã: bánh quy hạt Haochidian 好吃点, dòng cao xơ Guye 谷野, bánh quy kẹp Cookico, bánh quy mặn lá hẹ và snack khoai tây Copico 可比克.</li>\n<li><strong>Đồ uống</strong> — 4 mã: trà trái cây và trà xanh mơ xanh Daliyuan, trà thảo mộc Heqizheng 和其正, nước tăng lực Hi-Tiger 乐虎.</li>\n<li><strong>Cháo &amp; sữa hạt</strong> — 5 mã: ba vị cháo lon Youyican 又一餐, chè khoai môn yến mạch Ovici và sữa lạc Milk Peanut.</li>\n</ul>\n<h2>Cam kết với đại lý</h2>\n<ul>\n<li>Hàng nhập chính ngạch, đủ chứng từ để chào vào siêu thị, chuỗi cửa hàng tiện lợi và kênh HORECA.</li>\n<li>Nhãn phụ tiếng Việt dán sẵn khi xuất kho, ghi rõ đơn vị nhập khẩu và đơn vị phân phối.</li>\n<li>Giá sỉ thống nhất theo bậc sản lượng, không phá giá giữa các đại lý cùng khu vực.</li>\n<li>Chính sách đổi hàng cận date theo hợp đồng đại lý.</li>\n</ul>\n<h2>Bắt đầu từ đâu</h2>\n<p>Xem toàn bộ <a href="/san-pham/" rel="noopener noreferrer">danh mục sản phẩm</a>, đối chiếu <a href="/hang-chinh-hang/" rel="noopener noreferrer">cách nhận biết hàng chính hãng</a>, hoặc <a href="/hop-tac-dai-ly/" rel="noopener noreferrer">đăng ký hợp tác đại lý</a> để nhận bảng giá sỉ.</p>	2026-04-22 09:00:00+00	t
2	Ra mắt croissant Daliyuan vị cam & socola — bổ sung kệ bánh ngọt	ra-mat-croissant-daliyuan-cam-socola	Tin công ty	news/croissant.jpg	Croissant Daliyuan mới	Croissant Daliyuan 羊角面包 vào danh mục phân phối với hai vị kem cam và kem socola. Gói 100g gồm 4 bánh 25g, thùng 32 gói — mã mới để làm đầy kệ bánh ngọt.	<h2>Mã mới cho kệ bánh ngọt</h2>\n<p>Daliyuan bổ sung croissant 羊角面包 vào danh mục Dali Foods Việt Nam phân phối, với hai vị: kem cam 香橙味 và kem socola 巧克力味. Bánh làm theo kiểu croissant nhiều lớp, tỷ lệ nhân trên 19%, ăn nhẹ giữa buổi hoặc kèm cà phê sáng.</p>\n<h2>Quy cách</h2>\n<ul>\n<li>Gói 100g gồm 4 bánh nhỏ 25g, mỗi bánh bọc riêng.</li>\n<li>Thùng 32 gói; hai vị đặt riêng hoặc trộn thùng.</li>\n<li>Hạn dùng 6 tháng kể từ ngày sản xuất.</li>\n<li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li>\n</ul>\n<h2>Vì sao nên lên kệ sớm</h2>\n<ul>\n<li>Kết cấu nhiều lớp tạo khác biệt rõ so với bánh mì ngọt thông thường đang bày cùng kệ.</li>\n<li>Hai vị bổ sung cho nhau, dễ chốt combo và dễ bán xé lẻ tại quầy thu ngân.</li>\n<li>Mã mới, chưa bão hòa ở kênh tạp hóa và cửa hàng tiện lợi.</li>\n</ul>\n<h2>Đặt hàng</h2>\n<p>Chi tiết mã hàng tại trang <a href="/san-pham/croissant/" rel="noopener noreferrer">Croissant vị cam / socola 100g</a>. Đại lý muốn nhận bảng giá sỉ và ghép đơn cùng các mã bánh mì khác, gửi thông tin qua <a href="/hop-tac-dai-ly/" rel="noopener noreferrer">form hợp tác đại lý</a>.</p>	2026-06-15 09:00:00+00	t
3	Chiết khấu quý III cho đơn nguyên thùng Haochidian — đăng ký trước 30/09/2026	chiet-khau-quy-iii-haochidian	Chương trình đại lý	news/biscuit-cartons.jpg	Chương trình chiết khấu thùng	Đơn nguyên thùng bốn mã bánh quy Haochidian được tính vào bậc chiết khấu theo doanh số quý III, mức 5–12% tùy sản lượng lũy kế. Đăng ký trước 30/09/2026.	<h2>Nội dung chương trình</h2>\n<p>Đến hết ngày 30/09/2026, đơn nguyên thùng các mã bánh quy Haochidian 好吃点 được cộng vào doanh số quý III để xét bậc chiết khấu, mức 5–12% tùy sản lượng lũy kế. Bảng giá và mức chiết khấu của từng bậc được gửi kèm khi đại lý đăng ký.</p>\n<h2>Các mã áp dụng</h2>\n<ul>\n<li><a href="/san-pham/biscuit-walnut/" rel="noopener noreferrer">Bánh quy óc chó giòn 108g</a> 香脆核桃饼 — thùng 40 gói.</li>\n<li><a href="/san-pham/biscuit-pair/" rel="noopener noreferrer">Bánh quy hạt điều giòn 108g</a> 香脆腰果饼 — thùng 40 gói.</li>\n<li><a href="/san-pham/guye/" rel="noopener noreferrer">Bánh quy ngũ cốc cao xơ Guye 110g</a> 谷野, ba vị — thùng 40 gói.</li>\n<li><a href="/san-pham/biscuit-cartons/" rel="noopener noreferrer">Hộp bánh quy hạt 800g</a> gồm 36 gói nhỏ 22g — thùng 12 hộp.</li>\n</ul>\n<h2>Điều kiện</h2>\n<ul>\n<li>Đơn nhập lại tối thiểu 10 thùng mỗi lần giao để tối ưu phí vận chuyển.</li>\n<li>Chiết khấu tính trên doanh số lũy kế trong quý, chốt ngày 30/09/2026.</li>\n<li>Hạn mức công nợ 15–30 ngày được xét từ quý thứ hai, theo lịch sử đơn hàng.</li>\n<li>Đổi tối đa 3% giá trị đơn với SKU còn dưới 90 ngày hạn dùng.</li>\n</ul>\n<h2>Vì sao nên gom đơn ở dòng bánh quy</h2>\n<ul>\n<li>Hạn dùng 12 tháng kể từ ngày sản xuất — trữ hàng theo quý ít rủi ro cận date.</li>\n<li>Hộp 800g cho giá vốn trên mỗi gói thấp nhất trong dải Haochidian, hợp làm hàng khuyến mãi và quà kèm đơn.</li>\n<li>Thương hiệu 好吃点 đã có nhận diện sẵn với nhóm khách quen hàng nhập, không phải giáo dục thị trường từ đầu.</li>\n</ul>\n<h2>Đăng ký</h2>\n<p>Gửi thông tin qua <a href="/hop-tac-dai-ly/" rel="noopener noreferrer">form hợp tác đại lý</a> hoặc gọi hotline sỉ. Chúng tôi phản hồi kèm bảng giá sỉ trong 24 giờ làm việc.</p>	2026-07-01 09:00:00+00	t
5	Trà trái cây Daliyuan — vì sao thành trend đồ uống hè trên TikTok	tra-trai-cay-daliyuan-trend-mua-he	Kiến thức sản phẩm	news/tea-plum.jpg	Trà trái cây mùa hè	Ba vị trà trái cây 果味茶 trong cùng một thùng, chai PET 500ml, giá phổ thông. Vì sao dòng này chạy mạnh vào mùa nóng và hợp với nội dung mạng xã hội.	<h2>Ba vị trong một thùng</h2>\n<p>Dòng trà trái cây 果味茶 của Daliyuan pha nền trà thật với nước ép cô đặc, vị ngọt vừa và hậu trà rõ. Catalogue 2026 gồm ba vị — ô long đào trắng 白桃乌龙茶, nho xanh trà xanh 青提绿茶 và trà đen vị chanh 柠檬红茶 — chia đều trong cùng một thùng, nên điểm bán mới thử được cả ba trước khi chốt vị bán chạy.</p>\n<h2>Vì sao dòng này chạy vào mùa nóng</h2>\n<ul>\n<li>Vị ngọt vừa, uống lạnh hợp khẩu vị người Việt và uống được cả ngày.</li>\n<li>Chai PET 500ml vừa tay, phù hợp cả bán lẻ tại quầy lẫn combo giao hàng.</li>\n<li>Phân khúc giá phổ thông, xoay vòng nhanh ở kênh trường học và văn phòng.</li>\n<li>Ba màu nhãn khác nhau xếp cạnh nhau tạo dải màu bắt mắt trên kệ và trong khung hình — lợi thế khi điểm bán tự quay nội dung giới thiệu.</li>\n</ul>\n<h2>Quy cách</h2>\n<ul>\n<li>Chai PET 500ml, nhãn tiếng Trung kèm nhãn phụ tiếng Việt.</li>\n<li>Thùng 15 chai, chia đều ba vị theo yêu cầu đặt hàng.</li>\n<li>Hạn dùng 12 tháng kể từ ngày sản xuất.</li>\n<li>Bảo quản nơi thoáng mát; ngon hơn khi uống lạnh.</li>\n</ul>\n<h2>Gợi ý làm đầy kệ đồ uống</h2>\n<p>Đi kèm dòng ba vị là <a href="/san-pham/tea-plum/" rel="noopener noreferrer">trà xanh mơ xanh 青梅绿茶</a> — vị đơn, bán chạy lâu năm, dễ giới thiệu và khách mua lại nhiều. Hai mã này phủ được cả nhóm khách thích thử vị mới lẫn nhóm mua quen một vị.</p>\n<p>Chi tiết mã hàng tại <a href="/san-pham/tea-trio/" rel="noopener noreferrer">Trà trái cây Daliyuan 500ml (3 vị)</a>. Đại lý nhận bảng giá sỉ qua <a href="/hop-tac-dai-ly/" rel="noopener noreferrer">form hợp tác đại lý</a>.</p>	2026-06-01 09:00:00+00	t
4	3 cách nhận biết hàng Dali chính hãng qua nhãn phụ tiếng Việt	3-cach-nhan-biet-hang-dali-chinh-hang	Kiến thức sản phẩm	news/heiheibao.jpg	Nhận biết hàng chính hãng	Sản phẩm Dali trên thị trường có cả hàng xách tay và hàng trôi nổi không nhãn phụ. Ba dấu hiệu để nhận ra hàng do Dali Foods Việt Nam nhập khẩu chính ngạch và phân phối.	<p>Hàng do Dali Foods Việt Nam phân phối luôn nhập khẩu chính ngạch và nhận biết được bằng ba dấu hiệu dưới đây.</p>\n<h2>1. Nhãn phụ tiếng Việt đầy đủ thông tin</h2>\n<p>Mỗi sản phẩm đều có nhãn phụ tiếng Việt dán sẵn khi xuất kho, ghi rõ:</p>\n<ul>\n<li>Tên sản phẩm bằng tiếng Việt kèm tên gốc tiếng Trung.</li>\n<li>Nhà sản xuất thuộc Dali Foods Group.</li>\n<li>Đơn vị nhập khẩu và đơn vị phân phối tại Việt Nam.</li>\n<li>Địa chỉ, hotline, ngày sản xuất / hạn sử dụng và số tự công bố sản phẩm.</li>\n</ul>\n<p>Không có nhãn phụ, hoặc nhãn ghi một đơn vị nhập khẩu không xác minh được — đó không phải hàng do chúng tôi phân phối.</p>\n<h2>2. Tem phân phối trên thùng và lốc</h2>\n<p>Thùng và lốc hàng xuất kho được dán tem Dali Foods Việt Nam kèm mã lô. Mã lô cho phép truy ngược lô hàng khi cần đối chiếu date hoặc xử lý khiếu nại. Hệ thống tra cứu mã lô trực tuyến đang được chuẩn bị; trong thời gian này, đại lý đối chiếu mã lô trực tiếp với bộ phận kinh doanh.</p>\n<h2>3. Mua đúng kênh chính hãng</h2>\n<ul>\n<li>Đại lý ủy quyền và siêu thị đối tác.</li>\n<li>Gian hàng chính hãng trên Shopee Mall, LazMall và TikTok Shop.</li>\n<li>Chưa rõ một điểm bán có phải đại lý ủy quyền hay không: liên hệ để xác minh trước khi lấy hàng.</li>\n</ul>\n<h2>Dấu hiệu hàng trôi nổi</h2>\n<ul>\n<li>Giá rẻ bất thường so với mặt bằng chung.</li>\n<li>Không có nhãn phụ tiếng Việt, không xuất được hóa đơn VAT.</li>\n<li>Date ngắn nhưng không báo trước, không có chính sách đổi trả.</li>\n<li>Bao bì móp cũ do vận chuyển tiểu ngạch.</li>\n</ul>\n<p>Dali Foods Việt Nam chỉ chịu trách nhiệm chất lượng và hậu mãi với sản phẩm do công ty phân phối. Chi tiết và bảng đối chiếu đầy đủ tại trang <a href="/hang-chinh-hang/" rel="noopener noreferrer">Hàng chính hãng</a>.</p>	2026-08-01 09:00:00+00	t
6	Hi-Tiger 乐虎 vào kênh HORECA — combo khai trương cho quán café, phòng gym	hi-tiger-vao-kenh-horeca	Chương trình đại lý	news/hitiger.jpg	Hi-Tiger kênh HORECA	Hi-Tiger 乐虎 có hai quy cách — lon 250ml thùng 24 và chai 380ml — cho hai kiểu điểm bán khác nhau. Gợi ý combo khai trương cho quán café, quán ăn đêm và phòng gym.	<h2>Hai quy cách cho hai kiểu điểm bán</h2>\n<p>Hi-Tiger 乐虎 là thương hiệu nước tăng lực chủ lực của Dali Foods Group, công thức bổ sung taurine, axit amin và vitamin nhóm B. Catalogue có hai quy cách: lon thiếc 250ml đóng thùng 24 lon, và chai 380ml đặt riêng theo nhu cầu. Lon chạy mạnh ở quán ăn đêm, trạm xăng và tủ mát quầy thu ngân; chai hợp khách mang theo, phù hợp phòng gym và cửa hàng thể thao.</p>\n<h2>Combo khai trương cho điểm bán mới</h2>\n<p>Ba cấu hình đang được đại lý dùng nhiều nhất khi mở điểm bán:</p>\n<ul>\n<li><strong>Quán café, quán ăn</strong> — Hi-Tiger lon 250ml ghép cùng <a href="/san-pham/heqizheng/" rel="noopener noreferrer">trà thảo mộc Heqizheng 310ml</a>: một mã cho khách cần tỉnh táo, một mã cho khách ăn đồ nhiều dầu mỡ. Cả hai đều thùng 24 lon nên gộp đơn không phát sinh chuyến giao.</li>\n<li><strong>Phòng gym, cửa hàng thể thao</strong> — chai 380ml làm mã chính, kèm <a href="/san-pham/milk-peanut/" rel="noopener noreferrer">sữa lạc Milk Peanut 370g</a> cho nhóm khách tìm đồ uống dinh dưỡng sau buổi tập.</li>\n<li><strong>Trạm xăng, quán ăn đêm</strong> — lon 250ml nguyên thùng, bày tháp tại quầy; bổ sung <a href="/san-pham/snack-copico/" rel="noopener noreferrer">snack Copico lon 45g</a> để bán kèm.</li>\n</ul>\n<h2>Điều kiện áp dụng</h2>\n<ul>\n<li>Bậc chiết khấu 5–12% theo doanh số quý, cộng thưởng cho đơn nguyên thùng.</li>\n<li>Đơn nhập lại tối thiểu 10 thùng mỗi lần giao.</li>\n<li>Đổi tối đa 3% giá trị đơn với SKU còn dưới 90 ngày hạn dùng.</li>\n<li>Đủ hóa đơn VAT và bản tự công bố sản phẩm cho điểm bán cần chứng từ đầu vào.</li>\n</ul>\n<h2>Đăng ký</h2>\n<p>Xem chi tiết <a href="/san-pham/hitiger/" rel="noopener noreferrer">Nước tăng lực Hi-Tiger 250ml</a>, hoặc ghi khu vực kinh doanh vào <a href="/hop-tac-dai-ly/" rel="noopener noreferrer">form hợp tác đại lý</a> để nhận bảng giá sỉ và phương án combo cho đúng loại điểm bán.</p>	2026-05-01 09:00:00+00	t
7	Cháo lon Youyican 又一餐 — bữa sáng 1 phút cho dân văn phòng	chao-lon-youyican-bua-sang-1-phut	Kiến thức sản phẩm	news/porridge-3.jpg	Cháo Youyican bữa sáng	Cháo lon Youyican 又一餐 nấu sẵn, nắp giật, hâm một phút là xong bữa sáng. Ba vị cháo cùng chè khoai môn Ovici — lon 360g, thùng 12, hạn dùng 18 tháng.	<h2>Bữa sáng một phút</h2>\n<p>Cháo 又一餐 nấu sẵn trong lon, nắp giật nên không cần dụng cụ mở: ăn nguội được ngay, hâm nóng một phút là có bữa sáng đủ ấm. Đây là ngành hàng còn mới ở Việt Nam, ít cạnh tranh trực tiếp, và bán tốt ở kênh cửa hàng tiện lợi, ký túc xá và văn phòng.</p>\n<h2>Các vị trên kệ</h2>\n<ul>\n<li><a href="/san-pham/porridge-3/" rel="noopener noreferrer">Cháo đậu đỏ ý dĩ</a> 红豆薏仁粥 — vị bùi nhẹ, ít ngọt; nhóm khách văn phòng và sinh viên mua lại đều.</li>\n<li><a href="/san-pham/porridge-4/" rel="noopener noreferrer">Cháo bát bảo long nhãn hạt sen</a> 桂圆莲子八宝粥 — công thức cổ điển, hạt còn nguyên, ăn nóng hay lạnh đều được; hay được mua theo thùng làm quà dịp lễ Tết.</li>\n<li><a href="/san-pham/porridge-purple/" rel="noopener noreferrer">Cháo gạo lứt khoai tím</a> 燕麦紫薯粥 — yến mạch nấu cùng khoai tím, ít ngọt và nhiều chất xơ hơn, hợp nhóm khách trẻ quan tâm ăn uống lành mạnh.</li>\n<li><a href="/san-pham/che-khoai-mon/" rel="noopener noreferrer">Chè khoai môn yến mạch Ovici</a> 牛乳香芋燕麦 — món ăn vặt hơn là bữa sáng, ăn lạnh ngon hơn, tạo điểm nhấn trưng bày cạnh dải cháo.</li>\n</ul>\n<h2>Quy cách chung</h2>\n<ul>\n<li>Lon 360g, nắp giật.</li>\n<li>Thùng 12 lon — cùng quy cách cho cả bốn mã, gộp đơn không phát sinh chuyến giao.</li>\n<li>Hạn dùng 18 tháng kể từ ngày sản xuất; rủi ro cận date thấp.</li>\n<li>Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng trực tiếp.</li>\n</ul>\n<h2>Bán kèm gì</h2>\n<p>Kệ bữa sáng đầy đủ thường ghép cháo lon với <a href="/san-pham/breakfast-bread/" rel="noopener noreferrer">bánh mì ăn sáng 200g</a> và <a href="/san-pham/milk-peanut/" rel="noopener noreferrer">sữa lạc Milk Peanut 370g</a>: một mã no bụng, một mã cầm tay, một mã đồ uống — khách mua sáng thường lấy đủ bộ.</p>\n<p>Đại lý nhận bảng giá sỉ qua <a href="/hop-tac-dai-ly/" rel="noopener noreferrer">form hợp tác đại lý</a>.</p>	2026-05-01 09:00:00+00	t
\.


--
-- Data for Name: siteinfo_sitesettings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.siteinfo_sitesettings (id, hotline_wholesale, hotline_retail, email, zalo_oa, tax_code, business_license_no, business_license_date, business_license_issuer, head_office_address, warehouse_address, warehouse_area, shopee_url, lazada_url, tiktok_url, moit_notice, founded_year, retail_points, staff_count, coverage, shipping_partner, facility_location) FROM stdin;
1	0845880000	0845880000	kinhdoanh@dalifoods.vn	Dali Foods Việt Nam	[MST]	[số]	[ngày]	[nơi cấp]	Số 27, ngõ 84 đường Trần Thái Tông, phường Dịch Vọng Hậu, quận Cầu Giấy, TP Hà Nội	Lô B4, Cụm công nghiệp An Khánh, xã An Khánh, huyện Hoài Đức, TP Hà Nội	1.200 m²	https://shopee.vn/dalifoods_vn	https://www.lazada.vn/shop/dali-foods-viet-nam	https://www.tiktok.com/@dalifoods.vn	(dữ liệu demo — chưa thông báo tại online.gov.vn)	2024	1.200+	45	38	Giao Hàng Nhanh & Viettel Post	Hà Nội
\.


--
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_group_id_seq', 2, true);


--
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 53, true);


--
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_permission_id_seq', 52, true);


--
-- Name: auth_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_user_groups_id_seq', 1, true);


--
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 2, true);


--
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_user_user_permissions_id_seq', 1, false);


--
-- Name: catalog_brand_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.catalog_brand_id_seq', 6, true);


--
-- Name: catalog_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.catalog_category_id_seq', 4, true);


--
-- Name: catalog_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.catalog_product_id_seq', 21, true);


--
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_admin_log_id_seq', 1, false);


--
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_content_type_id_seq', 13, true);


--
-- Name: django_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.django_migrations_id_seq', 24, true);


--
-- Name: leads_contactmessage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.leads_contactmessage_id_seq', 5, true);


--
-- Name: leads_dealerapplication_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.leads_dealerapplication_id_seq', 4, true);


--
-- Name: news_article_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.news_article_id_seq', 7, true);


--
-- Name: siteinfo_sitesettings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.siteinfo_sitesettings_id_seq', 1, false);


--
-- Name: auth_group auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- Name: auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);


--
-- Name: auth_group_permissions auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_group auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- Name: auth_permission auth_permission_content_type_id_codename_01ab375a_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);


--
-- Name: auth_permission auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_pkey PRIMARY KEY (id);


--
-- Name: auth_user_groups auth_user_groups_user_id_group_id_94350c0c_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_group_id_94350c0c_uniq UNIQUE (user_id, group_id);


--
-- Name: auth_user auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_permission_id_14a6b632_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_permission_id_14a6b632_uniq UNIQUE (user_id, permission_id);


--
-- Name: auth_user auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- Name: catalog_brand catalog_brand_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_brand
    ADD CONSTRAINT catalog_brand_name_key UNIQUE (name);


--
-- Name: catalog_brand catalog_brand_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_brand
    ADD CONSTRAINT catalog_brand_pkey PRIMARY KEY (id);


--
-- Name: catalog_brand catalog_brand_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_brand
    ADD CONSTRAINT catalog_brand_slug_key UNIQUE (slug);


--
-- Name: catalog_category catalog_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_category
    ADD CONSTRAINT catalog_category_pkey PRIMARY KEY (id);


--
-- Name: catalog_category catalog_category_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_category
    ADD CONSTRAINT catalog_category_slug_key UNIQUE (slug);


--
-- Name: catalog_product catalog_product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_product
    ADD CONSTRAINT catalog_product_pkey PRIMARY KEY (id);


--
-- Name: catalog_product catalog_product_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_product
    ADD CONSTRAINT catalog_product_slug_key UNIQUE (slug);


--
-- Name: django_admin_log django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- Name: django_content_type django_content_type_app_label_model_76bd3d3b_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);


--
-- Name: django_content_type django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- Name: django_migrations django_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);


--
-- Name: django_session django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- Name: leads_contactmessage leads_contactmessage_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads_contactmessage
    ADD CONSTRAINT leads_contactmessage_pkey PRIMARY KEY (id);


--
-- Name: leads_dealerapplication leads_dealerapplication_completion_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads_dealerapplication
    ADD CONSTRAINT leads_dealerapplication_completion_token_key UNIQUE (completion_token);


--
-- Name: leads_dealerapplication leads_dealerapplication_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads_dealerapplication
    ADD CONSTRAINT leads_dealerapplication_pkey PRIMARY KEY (id);


--
-- Name: news_article news_article_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_article
    ADD CONSTRAINT news_article_pkey PRIMARY KEY (id);


--
-- Name: news_article news_article_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_article
    ADD CONSTRAINT news_article_slug_key UNIQUE (slug);


--
-- Name: siteinfo_sitesettings siteinfo_sitesettings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.siteinfo_sitesettings
    ADD CONSTRAINT siteinfo_sitesettings_pkey PRIMARY KEY (id);


--
-- Name: auth_group_name_a6ea08ec_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);


--
-- Name: auth_group_permissions_group_id_b120cbf9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);


--
-- Name: auth_group_permissions_permission_id_84c5c92e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);


--
-- Name: auth_permission_content_type_id_2f476e4b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);


--
-- Name: auth_user_groups_group_id_97559544; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_groups_group_id_97559544 ON public.auth_user_groups USING btree (group_id);


--
-- Name: auth_user_groups_user_id_6a12ed8b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_groups_user_id_6a12ed8b ON public.auth_user_groups USING btree (user_id);


--
-- Name: auth_user_user_permissions_permission_id_1fbb5f2c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_user_permissions_permission_id_1fbb5f2c ON public.auth_user_user_permissions USING btree (permission_id);


--
-- Name: auth_user_user_permissions_user_id_a95ead1b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_user_permissions_user_id_a95ead1b ON public.auth_user_user_permissions USING btree (user_id);


--
-- Name: auth_user_username_6821ab7c_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_user_username_6821ab7c_like ON public.auth_user USING btree (username varchar_pattern_ops);


--
-- Name: catalog_brand_name_ea62c47f_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_brand_name_ea62c47f_like ON public.catalog_brand USING btree (name varchar_pattern_ops);


--
-- Name: catalog_brand_slug_988c8dbc_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_brand_slug_988c8dbc_like ON public.catalog_brand USING btree (slug varchar_pattern_ops);


--
-- Name: catalog_category_slug_dbf63ad0_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_category_slug_dbf63ad0_like ON public.catalog_category USING btree (slug varchar_pattern_ops);


--
-- Name: catalog_pro_is_acti_903fcc_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_pro_is_acti_903fcc_idx ON public.catalog_product USING btree (is_active, sort_order);


--
-- Name: catalog_product_brand_id_bb0c7890; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_product_brand_id_bb0c7890 ON public.catalog_product USING btree (brand_id);


--
-- Name: catalog_product_category_id_35bf920b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_product_category_id_35bf920b ON public.catalog_product USING btree (category_id);


--
-- Name: catalog_product_slug_f37848b0_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_product_slug_f37848b0_like ON public.catalog_product USING btree (slug varchar_pattern_ops);


--
-- Name: django_admin_log_content_type_id_c4bce8eb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);


--
-- Name: django_admin_log_user_id_c564eba6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);


--
-- Name: django_session_expire_date_a5c62663; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);


--
-- Name: django_session_session_key_c0390e0f_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);


--
-- Name: leads_contactmessage_sdt_ddccec72; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_contactmessage_sdt_ddccec72 ON public.leads_contactmessage USING btree (sdt);


--
-- Name: leads_contactmessage_sdt_ddccec72_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_contactmessage_sdt_ddccec72_like ON public.leads_contactmessage USING btree (sdt varchar_pattern_ops);


--
-- Name: leads_dealerapplication_sdt_27dd4e73; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_dealerapplication_sdt_27dd4e73 ON public.leads_dealerapplication USING btree (sdt);


--
-- Name: leads_dealerapplication_sdt_27dd4e73_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX leads_dealerapplication_sdt_27dd4e73_like ON public.leads_dealerapplication USING btree (sdt varchar_pattern_ops);


--
-- Name: news_articl_is_publ_0ea520_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_articl_is_publ_0ea520_idx ON public.news_article USING btree (is_published, published_at DESC);


--
-- Name: news_article_slug_5328fdc5_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_article_slug_5328fdc5_like ON public.news_article USING btree (slug varchar_pattern_ops);


--
-- Name: auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_group_id_97559544_fk_auth_group_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_group_id_97559544_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_groups auth_user_groups_user_id_6a12ed8b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_6a12ed8b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auth_user_user_permissions auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: catalog_product catalog_product_brand_id_bb0c7890_fk_catalog_brand_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_product
    ADD CONSTRAINT catalog_product_brand_id_bb0c7890_fk_catalog_brand_id FOREIGN KEY (brand_id) REFERENCES public.catalog_brand(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: catalog_product catalog_product_category_id_35bf920b_fk_catalog_category_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_product
    ADD CONSTRAINT catalog_product_category_id_35bf920b_fk_catalog_category_id FOREIGN KEY (category_id) REFERENCES public.catalog_category(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: django_admin_log django_admin_log_user_id_c564eba6_fk_auth_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_auth_user_id FOREIGN KEY (user_id) REFERENCES public.auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- PostgreSQL database dump complete
--

\unrestrict 1XHbhsjjKpYrsKerhCFI4HaFCd9nrWfJo7vEdTcl8b8aLeZJJfwIOpWCcZkIdMz

