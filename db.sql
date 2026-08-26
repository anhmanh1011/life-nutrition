--
-- PostgreSQL database dump
--

\restrict ZRB9kFQ5Lwk0Szn73JdXQ27NhTdAfiU0n4Deqq5LXo6QIqOZpvEjOCv6sipMM1t

-- Dumped from database version 17.11 (Homebrew)
-- Dumped by pg_dump version 17.11 (Homebrew)

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
2	Copico	可比克	copico		snack khoai tây	f	2
3	Haochidian	好吃点	haochidian		bánh quy	t	3
4	Heqizheng	和其正	heqizheng		trà thảo mộc	t	4
5	Hi-Tiger	乐虎	hi-tiger		nước tăng lực	t	5
6	Doubendou	豆本豆	doubendou		sữa đậu nành	f	6
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

COPY public.catalog_product (id, name, slug, image, image_alt, description, packaging, is_active, sort_order, brand_id, category_id) FROM stdin;
1	Trà trái cây Daliyuan 500ml (3 vị)	tea-trio	products/tea-trio.jpg	Trà trái cây Daliyuan 500ml	果味茶 · đào trắng ô long / nho xanh trà xanh / chanh hồng trà	Chai 500ml · thùng 15 chai	t	1	1	3
2	Trà xanh mơ xanh Daliyuan 500ml	tea-plum	products/tea-plum.jpg	Trà xanh mơ xanh Daliyuan 500ml	青梅绿茶	Chai 500ml · thùng 15 chai	t	2	1	3
3	Nước tăng lực Hi-Tiger 250ml	hitiger	products/hitiger.jpg	Nước tăng lực Hi-Tiger 250ml	乐虎 氨基酸维生素功能饮料	Lon 250ml · thùng 24 lon	t	3	5	3
4	Trà thảo mộc Heqizheng 310ml	heqizheng	products/heqizheng.jpg	Trà thảo mộc Heqizheng 310ml	和其正 凉茶	Lon 310ml · thùng 24 lon	t	4	4	3
5	Cháo Youyican đậu đỏ ý dĩ 360g	porridge-3	products/porridge-3.jpg	Cháo Youyican đậu đỏ ý dĩ 360g	又一餐 红豆薏仁粥	Lon 360g · thùng 12 lon	t	5	1	4
6	Cháo bát bảo long nhãn hạt sen 360g	porridge-4	products/porridge-4.jpg	Cháo bát bảo long nhãn hạt sen 360g	桂圆莲子八宝粥	Lon 360g · thùng 12 lon	t	6	1	4
7	Sữa lạc Milk Peanut 370g	milk-peanut	products/milk-peanut.jpg	Sữa lạc Milk Peanut 370g	牛奶花生	Lon 370g · thùng 12 lon	t	7	1	4
8	Bánh mì ăn sáng 200g (5 cái)	breakfast-bread	products/breakfast-bread.jpg	Bánh mì ăn sáng Daliyuan 200g	早餐包	Gói 200g · thùng [số] gói	t	8	1	1
9	Bánh mì Pháp mini 200g (10 cái)	mini-french	products/mini-french.jpg	Bánh mì Pháp mini Daliyuan 200g	法式小面包 香奶味	Gói 200g · thùng [số] gói	t	9	1	1
10	Bánh mì K17 — dừa / chà bông / rong biển	k17-trio	products/k17-trio.jpg	Bánh mì K17 Daliyuan ba vị	K17 大椰蓉面包 · 肉松芝麻 · 肉松海苔吐司	Gói lẻ · thùng [số] gói	t	10	1	1
11	Bánh mì socola Hei Hei Bao 80g	heiheibao	products/heiheibao.jpg	Bánh mì socola Hei Hei Bao 80g	黑黑包 浓醇巧克力味	Gói 80g · thùng [số] gói	t	11	1	1
12	Croissant vị cam / socola 100g (4 cái)	croissant	products/croissant.jpg	Croissant Daliyuan vị cam và socola 100g	羊角面包 香橙味 · 巧克力味	Gói 100g · thùng [số] gói	t	12	1	1
13	Bánh quy óc chó giòn 108g	biscuit-walnut	products/biscuit-walnut.jpg	Bánh quy óc chó giòn Haochidian 108g	好吃点 香脆核桃饼	Gói 108g · lốc 10 · thùng 800g	t	13	3	2
14	Bánh quy hạt điều giòn 108g	biscuit-pair	products/biscuit-pair.jpg	Bánh quy hạt điều giòn Haochidian 108g	好吃点 香脆腰果饼	Gói 108g · lốc 10 · thùng 800g	t	14	3	2
15	Thùng bánh quy hạt 800g (óc chó / hạt điều)	biscuit-cartons	products/biscuit-cartons.jpg	Thùng bánh quy hạt Haochidian 800g	好吃点 800克 量贩装	Thùng 800g gói lẻ bên trong	t	15	3	2
16	Bánh quy ngũ cốc cao xơ Guye 110g	guye	products/guye.jpg	Bánh quy ngũ cốc cao xơ Guye 110g	谷野 高纤煎麸饼 · 粗粮饼 · 蔬菜饼	Gói 110g · thùng [số] gói	t	16	3	2
17	Bánh quy kẹp mỏng giòn Cookico 90g	cookico	products/cookico.jpg	Bánh quy kẹp mỏng giòn Cookico 90g	Landy Castle 薄脆夹心曲奇 · bơ / chanh	Gói 90g · thùng [số] gói	t	17	1	2
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
1	contenttypes	0001_initial	2026-08-26 14:09:21.563625+07
2	auth	0001_initial	2026-08-26 14:09:21.604473+07
3	admin	0001_initial	2026-08-26 14:09:21.617367+07
4	admin	0002_logentry_remove_auto_add	2026-08-26 14:09:21.622317+07
5	admin	0003_logentry_add_action_flag_choices	2026-08-26 14:09:21.625822+07
6	contenttypes	0002_remove_content_type_name	2026-08-26 14:09:21.634704+07
7	auth	0002_alter_permission_name_max_length	2026-08-26 14:09:21.639195+07
8	auth	0003_alter_user_email_max_length	2026-08-26 14:09:21.643215+07
9	auth	0004_alter_user_username_opts	2026-08-26 14:09:21.646972+07
10	auth	0005_alter_user_last_login_null	2026-08-26 14:09:21.650743+07
11	auth	0006_require_contenttypes_0002	2026-08-26 14:09:21.651272+07
12	auth	0007_alter_validators_add_error_messages	2026-08-26 14:09:21.654415+07
13	auth	0008_alter_user_username_max_length	2026-08-26 14:09:21.660641+07
14	auth	0009_alter_user_last_name_max_length	2026-08-26 14:09:21.664838+07
15	auth	0010_alter_group_name_max_length	2026-08-26 14:09:21.669571+07
16	auth	0011_update_proxy_permissions	2026-08-26 14:09:21.672687+07
17	auth	0012_alter_user_first_name_max_length	2026-08-26 14:09:21.676577+07
18	catalog	0001_initial	2026-08-26 14:09:21.70541+07
19	leads	0001_initial	2026-08-26 14:09:21.717483+07
20	news	0001_initial	2026-08-26 14:09:21.728961+07
21	sessions	0001_initial	2026-08-26 14:09:21.734809+07
22	siteinfo	0001_initial	2026-08-26 14:09:21.746737+07
\.


--
-- Data for Name: news_article; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.news_article (id, title, slug, topic, cover, cover_alt, excerpt, body, published_at, is_published) FROM stdin;
1	Life Nutrition chính thức là nhà phân phối được ủy quyền của Dali Foods tại Việt Nam	life-nutrition-nha-phan-phoi-uy-quyen-dali-foods	Tin công ty	news/breakfast-bread-2.jpg	Life Nutrition nhận ủy quyền phân phối Dali Foods	Giấy chứng nhận do Công ty TNHH Thực phẩm Dali Quảng Tây cấp, hiệu lực đến 30/04/2027 — mở đường đưa bánh, snack và đồ uống Dali chính ngạch phủ khắp kênh bán lẻ Việt Nam.		2026-04-22 16:00:00+07	t
2	Ra mắt croissant Daliyuan vị cam & socola — bổ sung kệ bánh ngọt	ra-mat-croissant-daliyuan-cam-socola	Tin công ty	news/croissant.jpg	Croissant Daliyuan mới			2026-06-15 16:00:00+07	t
4	3 cách nhận biết hàng Dali chính hãng qua nhãn phụ tiếng Việt	3-cach-nhan-biet-hang-dali-chinh-hang	Kiến thức sản phẩm	news/heiheibao.jpg	Nhận biết hàng chính hãng			2026-08-01 16:00:00+07	t
5	Trà trái cây Daliyuan — vì sao thành trend đồ uống hè trên TikTok	tra-trai-cay-daliyuan-trend-mua-he	Kiến thức sản phẩm	news/tea-plum.jpg	Trà trái cây mùa hè			2026-06-01 16:00:00+07	t
6	Hi-Tiger 乐虎 vào kênh HORECA — combo khai trương cho quán café, phòng gym	hi-tiger-vao-kenh-horeca	Chương trình đại lý	news/hitiger.jpg	Hi-Tiger kênh HORECA			2026-05-01 16:00:00+07	t
7	Cháo lon Youyican 又一餐 — bữa sáng 1 phút cho dân văn phòng	chao-lon-youyican-bua-sang-1-phut	Kiến thức sản phẩm	news/porridge-3.jpg	Cháo Youyican bữa sáng			2026-05-01 16:00:00+07	t
3	Chiết khấu quý III cho đơn nguyên thùng Haochidian — đăng ký trước 30/09/2026	chiet-khau-quy-iii-haochidian	Chương trình đại lý	news/biscuit-cartons.jpg	Chương trình chiết khấu thùng			2026-07-01 16:00:00+07	t
\.


--
-- Data for Name: siteinfo_sitesettings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.siteinfo_sitesettings (id, hotline_wholesale, hotline_retail, email, zalo_oa, tax_code, business_license_no, business_license_date, business_license_issuer, head_office_address, warehouse_address, warehouse_area, shopee_url, lazada_url, tiktok_url, moit_notice, founded_year, retail_points, staff_count, coverage, shipping_partner, facility_location) FROM stdin;
1	1900 8386	0938 246 810	kinhdoanh@dalifoods.vn	Life Nutrition – Dali Foods VN	0109729369	0109729369	05/03/2024	Phòng Đăng ký kinh doanh - Sở Kế hoạch và Đầu tư TP Hà Nội	Số 08, ngõ 163/23 đường Phạm Văn Đồng, tổ 2, phường Mai Dịch, quận Cầu Giấy, TP Hà Nội	Số 2, ngõ 75 đường La Phù, xã An Khánh, TP Hà Nội	1.200 m²	https://shopee.vn/lifenutrition_official	https://www.lazada.vn/shop/life-nutrition	https://www.tiktok.com/@lifenutrition.vn	(dữ liệu demo — chưa thông báo tại online.gov.vn)	2024	1.200+	45	38	Giao Hàng Nhanh & Viettel Post	Hà Nội
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

SELECT pg_catalog.setval('public.auth_user_groups_id_seq', 1, false);


--
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auth_user_id_seq', 1, true);


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

SELECT pg_catalog.setval('public.catalog_product_id_seq', 17, true);


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

SELECT pg_catalog.setval('public.django_migrations_id_seq', 22, true);


--
-- Name: leads_contactmessage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.leads_contactmessage_id_seq', 1, true);


--
-- Name: leads_dealerapplication_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.leads_dealerapplication_id_seq', 1, true);


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

\unrestrict ZRB9kFQ5Lwk0Szn73JdXQ27NhTdAfiU0n4Deqq5LXo6QIqOZpvEjOCv6sipMM1t

