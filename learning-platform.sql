--
-- PostgreSQL database dump
--

\restrict AJyu1ot4QPvJZZmHRFq1YbAgv4HzFhfE5xcKLWLdVNUm9uCtrB2KdEkm3YmgvEa

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
c94e43ac-564b-468f-a63f-e4738e1f2260	1add72f4-1ae2-44a4-8df5-7e2db23fafac	第1章 Java基础语法与面向对象	1	["变量与数据类型", "流程控制", "类与对象", "构造方法", "this与static"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
b328c74b-36c3-49f2-a636-f819e2c2ae78	1add72f4-1ae2-44a4-8df5-7e2db23fafac	第2章 集合、异常与常用API	2	["List/Set/Map", "Iterator与增强for", "异常分类与处理", "String与包装类", "常见面试题"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
b5332693-0f54-498f-9c4b-6620ae525b57	1add72f4-1ae2-44a4-8df5-7e2db23fafac	第3章 代码实战与面试题训练	3	["手写链表", "字符串处理", "反转与排序题", "基础题答案解析", "高频面试题总结"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
ad1ef213-8b0d-47e9-9156-d3def2f802e4	48a057cf-89a9-4de9-b568-8dc484c593a5	第1章 JVM与垃圾回收	1	["JVM内存结构", "对象创建过程", "垃圾回收算法", "常见GC器", "内存溢出排查"]	16	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
e8f1c64a-e18c-460e-9dd5-72dd3e4c9170	48a057cf-89a9-4de9-b568-8dc484c593a5	第2章 并发编程与线程池	2	["线程生命周期", "synchronized与Lock", "线程池参数", "并发容器", "死锁与线程安全"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
55c3ac3a-39cf-4b72-8389-350e21c5638c	48a057cf-89a9-4de9-b568-8dc484c593a5	第3章 Spring基础与数据库面试	3	["IoC与AOP", "Bean生命周期", "事务传播机制", "MySQL索引与事务", "面试高频题"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
dcf57acf-4a86-4bb2-ae6f-239fd24fca09	29d51edd-37e0-4268-bf1e-6435c9bef575	第1章 Spring Boot与分层架构	1	["自动配置原理", "Starter机制", "配置管理", "日志与异常统一处理", "项目分层设计"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
ce227075-b0b8-470e-bbf1-cc0afab96c4d	29d51edd-37e0-4268-bf1e-6435c9bef575	第2章 微服务、Redis与消息中间件	2	["服务注册与发现", "OpenFeign与网关", "Redis缓存策略", "MQ削峰填谷", "分布式事务"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
4b7f2604-17c0-4872-a858-3c81bde9f78d	29d51edd-37e0-4268-bf1e-6435c9bef575	第3章 系统设计与高级面试	3	["高并发设计", "限流熔断", "数据库拆分", "接口设计原则", "架构面试实战"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
59626d30-244f-4060-b5ff-ec7e0a197ef9	f53e6f89-699a-411e-a49b-34439e9ac969	第1章 计算机组成与操作系统	1	["CPU与存储结构", "进程与线程", "内存管理", "文件系统", "调度算法"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
d8d661a0-4106-49c2-aa54-d80a518621bf	f53e6f89-699a-411e-a49b-34439e9ac969	第2章 计算机网络与数据库基础	2	["OSI与TCP/IP", "IP与子网划分", "关系数据库基础", "SQL基本操作", "事务概念"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
84cd5956-1b8e-42b3-bc24-09241ebe4c87	f53e6f89-699a-411e-a49b-34439e9ac969	第3章 选择题高频考点	3	["历年高频考点", "易错知识点", "速记口诀", "模拟选择题", "错题整理"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
54474ebe-221d-4bac-9b9e-424f3b68492d	2088f6c3-640a-4ae3-9e4c-aa7733f0ae9d	第1章 软件工程与UML	1	["需求分析", "软件生命周期", "UML图形", "面向对象分析", "设计原则"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
30458926-597b-4cf8-9cc2-4abda7199946	2088f6c3-640a-4ae3-9e4c-aa7733f0ae9d	第2章 设计模式与数据库设计	2	["单例与工厂模式", "观察者模式", "E-R模型", "范式理论", "索引与优化"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
71b6bf1e-1935-499f-9625-5d008b60bc9e	2088f6c3-640a-4ae3-9e4c-aa7733f0ae9d	第3章 案例分析与综合题	3	["系统架构案例", "数据库设计题", "算法分析题", "答题步骤", "真题训练"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
5c5f4a4d-31bb-4164-868c-f80511aa952f	fac174fe-43a9-4d62-be8f-51375745cd59	第1章 历年真题精讲	1	["真题结构", "常考题型", "题目拆解", "标准答案分析", "错题归纳"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
36cdb7ae-78b6-45b4-9deb-e27c8aa602fc	fac174fe-43a9-4d62-be8f-51375745cd59	第2章 案例分析强化	2	["案例题读题方法", "数据库设计案例", "UML案例", "程序设计案例", "答题模板"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
05a8a80a-b8d3-4741-aef1-bd65073ea877	fac174fe-43a9-4d62-be8f-51375745cd59	第3章 论文与考前冲刺	3	["论文选题思路", "论文结构模板", "考前复盘", "时间分配", "临场技巧"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
953a7ad0-4144-4280-8735-b968abbfa8a9	f684a0d9-a4c0-440c-bf51-5f2695e87396	第1章 Python语法基础	1	["变量与数据类型", "分支与循环", "列表与字典", "函数定义", "输入输出"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
6b26d2b5-b01f-46f6-ae0e-f174c462885c	f684a0d9-a4c0-440c-bf51-5f2695e87396	第2章 函数、模块与面向对象	2	["参数传递", "作用域", "模块导入", "类与对象", "常用标准库"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
1fdf95b3-76b6-4e78-a8dc-f2960720449c	f684a0d9-a4c0-440c-bf51-5f2695e87396	第3章 文件、异常与小项目	3	["文件读写", "异常处理", "JSON处理", "简单脚本", "综合练习"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
9de036a7-39e6-467d-a906-ce9dd074f42e	81fded06-a0ad-436d-99be-50c72e04ea0e	第1章 面向对象与高级特性	1	["继承与多态", "装饰器", "生成器", "迭代器", "上下文管理器"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
aaeb7176-8ac8-4258-bce2-935938225947	81fded06-a0ad-436d-99be-50c72e04ea0e	第2章 网络编程与爬虫入门	2	["HTTP基础", "requests使用", "HTML解析", "反爬基础", "数据保存"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
625059eb-37cf-4acc-ba09-2fb406cdbeea	81fded06-a0ad-436d-99be-50c72e04ea0e	第3章 模块化开发与实战	3	["项目结构", "日志与配置", "测试与调试", "异常设计", "小型项目实战"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
afa59c91-79a5-4510-87b0-4e7f57d6c29c	65e0eddf-91bf-4ad0-b50d-d9ccda04f946	第1章 Web框架开发	1	["FastAPI基础", "Django基础", "Flask路由", "接口设计", "ORM使用"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
6d3009a2-ac4a-4dba-bcce-d1cf34df3491	65e0eddf-91bf-4ad0-b50d-d9ccda04f946	第2章 异步编程与性能优化	2	["asyncio", "协程与任务", "并发模型", "性能瓶颈分析", "缓存策略"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
36f5d89a-e74e-4240-8b02-1e67e9204307	65e0eddf-91bf-4ad0-b50d-d9ccda04f946	第3章 工程化与部署	3	["项目打包", "环境管理", "日志监控", "容器部署", "CI/CD基础"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
6619ecbe-8019-4960-bd10-ccd642ae8750	64127bf6-a804-401c-88d6-74138d9c7ca1	第1章 ndarray与数组创建	1	["数组概念", "dtype与shape", "创建数组", "维度变换", "常用属性"]	8	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
11c178f7-8bd5-494a-aa41-c3d87fe7e2b3	64127bf6-a804-401c-88d6-74138d9c7ca1	第2章 索引、切片与广播	2	["切片规则", "布尔索引", "花式索引", "广播机制", "视图与拷贝"]	8	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
bfbc980e-8ac5-43e6-8efb-c13628f34b0c	64127bf6-a804-401c-88d6-74138d9c7ca1	第3章 数学运算基础	3	["逐元素运算", "统计函数", "排序与去重", "矩阵乘法", "练习题"]	8	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
e2db1b18-2938-4ab4-b6a1-43b7a4f49240	d868c111-8130-4938-99f1-bf4e4bfbc319	第1章 向量化思维	1	["向量化优势", "避免循环", "性能对比", "数组运算模式", "常见陷阱"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
0622ae94-f81e-4aed-8c01-7e850c30187f	d868c111-8130-4938-99f1-bf4e4bfbc319	第2章 统计分析与随机数	2	["随机数生成", "分布采样", "均值方差", "分位数", "相关性"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
4ff17ab7-1a49-41f0-b10d-bcbe321cb61d	d868c111-8130-4938-99f1-bf4e4bfbc319	第3章 矩阵与线性代数	3	["矩阵乘法", "转置与逆矩阵", "特征值概念", "方程组求解", "综合练习"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
161ce939-8453-4506-ae3c-d45505baf197	c96bf0a1-6e13-4f3e-893f-30e8fea70cfd	第1章 线性代数进阶	1	["向量空间", "SVD概念", "矩阵分解", "数值稳定性", "应用场景"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
4a5d7282-574d-414c-a7cc-572ee9394f45	c96bf0a1-6e13-4f3e-893f-30e8fea70cfd	第2章 高性能数值计算	2	["内存连续性", "广播优化", "向量化优化", "避免Python循环", "性能调优"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
5a84a316-230e-4781-8612-3338acec93a7	c96bf0a1-6e13-4f3e-893f-30e8fea70cfd	第3章 机器学习数据预处理	3	["特征标准化", "缺失值处理", "编码与缩放", "训练集划分", "Pipeline思路"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
e217012f-a40b-4831-98f9-1716e1445d9e	66e42903-3c28-4dab-b3f4-a1487a322844	第1章 Series与DataFrame	1	["Series创建", "DataFrame创建", "行列索引", "查看数据", "基本属性"]	8	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
bc82baf6-a375-43dc-a245-53f2574754f7	66e42903-3c28-4dab-b3f4-a1487a322844	第2章 数据读取与导出	2	["CSV读取", "Excel读取", "SQL读取", "导出文件", "编码问题"]	8	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
9ba5f6a5-eacb-42d1-8172-ab70ec6a7704	66e42903-3c28-4dab-b3f4-a1487a322844	第3章 初步数据查看	3	["head与tail", "describe", "info", "简单筛选", "快速统计"]	8	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
ffc29cb4-3da9-4afe-82be-7a8fcb0aa108	a992e9c3-508f-4a16-bf9e-6c833f5ce598	第1章 缺失值与类型转换	1	["缺失值识别", "填充与删除", "类型转换", "字符串处理", "时间类型"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
78e5f091-3d56-4927-82f6-52c6f2332bdc	a992e9c3-508f-4a16-bf9e-6c833f5ce598	第2章 合并、分组与透视	2	["merge/join", "concat", "groupby", "pivot_table", "聚合统计"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
f09610c7-4f19-4605-8fd5-8d1e374ce2a5	a992e9c3-508f-4a16-bf9e-6c833f5ce598	第3章 清洗实战	3	["异常值处理", "重复值处理", "字段拆分", "数据规整", "项目练习"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
afd144b6-39cb-4f14-8c81-1db74a46fcb7	4ecbb28b-a400-441e-8b41-8b28a4b35878	第1章 时间序列分析	1	["日期索引", "重采样", "滑动窗口", "时间偏移", "周期分析"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
793fa891-9eea-44fd-a695-113591083341	4ecbb28b-a400-441e-8b41-8b28a4b35878	第2章 业务指标分析	2	["留存分析", "转化漏斗", "同比环比", "分组报表", "指标解释"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
7b8c750c-15b8-4a92-b1db-12c61cc559bf	4ecbb28b-a400-441e-8b41-8b28a4b35878	第3章 报表与分析项目	3	["多表联查思路", "报表输出", "可视化基础", "自动化分析", "项目实战"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
9b382e61-3760-4b56-bac6-95d856249c6b	aa9879bb-e374-4d49-8500-b31a5b4072e2	第1章 SQL基础语法	1	["SELECT", "WHERE", "ORDER BY", "LIMIT", "常见运算符"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
c9c70691-77d9-45b2-83b8-50ec4e6c629c	aa9879bb-e374-4d49-8500-b31a5b4072e2	第2章 表、约束与DDL	2	["建表语句", "主键外键", "非空唯一", "默认值", "修改表结构"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
9ab7e7c4-4d3a-4511-bfdd-b85da791a7fe	aa9879bb-e374-4d49-8500-b31a5b4072e2	第3章 单表查询训练	3	["聚合函数", "分组统计", "简单子查询", "排序分页", "练习题"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
146465bc-24c4-4a8e-835d-1a289bd2024b	f02b723e-a8ef-454a-9b09-465220cbb68b	第1章 多表查询	1	["内连接", "左连接", "右连接", "子查询", "联合查询"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
cba2b319-6b72-43b0-85d9-b850f0c615d6	f02b723e-a8ef-454a-9b09-465220cbb68b	第2章 事务与索引	2	["ACID", "隔离级别", "索引类型", "执行计划", "索引失效"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
f55d93c3-fce6-4b72-a669-281996300a76	f02b723e-a8ef-454a-9b09-465220cbb68b	第3章 存储过程与优化	3	["存储过程", "视图", "慢查询", "SQL优化", "实战题"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
c2cfc625-2940-4e5a-95c7-fa4a002c3a36	2c798eae-9a89-4d5f-9742-61c95af7fcd3	第1章 执行计划与调优	1	["EXPLAIN", "索引选择", "回表", "覆盖索引", "SQL重写"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
2d1f0f65-79c3-4683-9a4c-a39a45b577bd	2c798eae-9a89-4d5f-9742-61c95af7fcd3	第2章 锁机制与复制	2	["行锁表锁", "死锁分析", "主从复制", "延迟问题", "读写分离"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
887afc41-d620-4c19-ab9e-98a02c4fd79e	2c798eae-9a89-4d5f-9742-61c95af7fcd3	第3章 分库分表与高并发	3	["分片策略", "中间件思路", "热点数据", "容量规划", "压测与优化"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
09e8d83b-1149-4067-83c8-514a4ea041ab	84b24879-d818-4e6c-b597-059cb40d4089	第1章 PostgreSQL基础语法	1	["SELECT", "INSERT", "UPDATE", "DELETE", "LIMIT"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
88e72973-4c68-4e56-a1de-f8af01ec90f9	84b24879-d818-4e6c-b597-059cb40d4089	第2章 数据类型与约束	2	["字符串与数值类型", "日期类型", "主键唯一", "默认值", "检查约束"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
bc76ca76-dcd1-44cb-b736-c209466ab0e9	84b24879-d818-4e6c-b597-059cb40d4089	第3章 表设计与CRUD	3	["建表实战", "基础查询", "条件过滤", "排序分组", "简单案例"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
a3f2060b-7903-43e9-864a-2cf8d6cf2c8a	bd1734d7-9b61-4838-90fb-2173f22474bd	第1章 事务与索引	1	["事务控制", "隔离级别", "B-Tree索引", "复合索引", "索引失效"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
fc42a948-f9ad-4c31-986e-433f79dbd18b	bd1734d7-9b61-4838-90fb-2173f22474bd	第2章 JSONB、函数与触发器	2	["JSONB操作", "函数创建", "触发器基础", "PL/pgSQL", "常见场景"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
2eebfef2-761f-45f2-8c32-2f5d7d960453	bd1734d7-9b61-4838-90fb-2173f22474bd	第3章 开发场景实战	3	["分页查询", "统计报表", "数据迁移", "批量更新", "调优入门"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
1d8bdf50-8add-4558-a502-8f276abee5ac	d022992d-fb47-4c0a-a4ac-986fe570c3a4	第1章 分区表与复制	1	["范围分区", "列表分区", "逻辑复制", "流复制", "分区维护"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
50be2b4c-7eda-41c3-aaed-03e88bb90b90	d022992d-fb47-4c0a-a4ac-986fe570c3a4	第2章 高可用与备份恢复	2	["备份策略", "恢复流程", "故障切换", "监控告警", "容灾思路"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
0331a1dc-b353-49b0-88db-25f92e272fa1	d022992d-fb47-4c0a-a4ac-986fe570c3a4	第3章 性能调优与运维	3	["执行计划分析", "VACUUM", "ANALYZE", "参数调优", "运维实战"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
89295fe5-606e-479c-b5d2-52c0b065bbe5	74e03a3b-4aa3-4f5a-b894-d0a8b3867988	第1章 C++语法与STL基础	1	["输入输出", "引用与指针", "vector与string", "pair与tuple", "常用STL"]	12	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
68be9783-0cc1-4777-bdf0-524438f3aea3	74e03a3b-4aa3-4f5a-b894-d0a8b3867988	第2章 线性数据结构	2	["数组", "链表", "栈", "队列", "哈希表"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
193ff834-b57b-4df1-916d-44c89d150be2	74e03a3b-4aa3-4f5a-b894-d0a8b3867988	第3章 基础刷题训练	3	["模拟题", "字符串题", "排序题", "简单递归", "错题总结"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
b5170c93-8858-410b-b1da-aa1955896dc4	08710145-1e58-475c-8abc-7cf00f5c52a5	第1章 树与图基础	1	["二叉树遍历", "BST", "图的存储", "最短路径入门", "拓扑排序"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
5a0e703c-9cb2-4ced-ad0e-13e5652578ce	08710145-1e58-475c-8abc-7cf00f5c52a5	第2章 DFS与BFS	2	["递归搜索", "回溯", "剪枝", "广度优先", "经典题型"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
b2e9593a-5ee8-4673-bb26-a7ea732ed1f3	08710145-1e58-475c-8abc-7cf00f5c52a5	第3章 动态规划入门	3	["状态定义", "转移方程", "背包问题", "线性DP", "练习题"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
87bf3726-4670-4f1f-955a-071aff8a5830	3353ee87-1744-4049-b9ad-6cddd3e2f01f	第1章 动态规划进阶	1	["区间DP", "树形DP", "状态压缩DP", "记忆化搜索", "DP优化"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
ba0a982a-a251-451a-901b-a46141fbe672	3353ee87-1744-4049-b9ad-6cddd3e2f01f	第2章 进阶数据结构	2	["线段树", "树状数组", "并查集", "堆与优先队列", "离线算法"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
f4b178a2-26d3-4fdb-8acf-284a21f578c6	3353ee87-1744-4049-b9ad-6cddd3e2f01f	第3章 综合刷题与竞赛技巧	3	["图论综合题", "最短路进阶", "网络流", "赛时策略", "高频模板"]	22	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
5f3ae1a2-262e-4ce1-a340-5a8be1830b6c	3a262091-b97f-43ce-9c08-8cc09e2962c1	第1章 行测基础	1	["言语理解", "数量关系", "判断推理", "资料分析", "常识判断"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
31e55edb-398e-487a-ace1-6779f5ad83e4	3a262091-b97f-43ce-9c08-8cc09e2962c1	第2章 申论写作入门	2	["审题立意", "概括题", "对策题", "议论文结构", "表达训练"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
aaaa9f16-bedc-46e2-ae91-eb6fe71a3227	3a262091-b97f-43ce-9c08-8cc09e2962c1	第3章 计算机基础	3	["数据结构入门", "数据库概念", "网络基础", "操作系统概念", "常考题"]	10	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
1cf57b01-a417-4271-a484-1b16837c756e	61de896f-f51e-4b17-a4f7-0b4788464b24	第1章 数据结构复习	1	["数组链表", "栈队列", "树与图", "查找排序", "复杂度分析"]	14	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
6081857b-6891-4bd4-9f4d-3a3694829966	61de896f-f51e-4b17-a4f7-0b4788464b24	第2章 数据库与操作系统	2	["SQL基础", "事务与索引", "进程线程", "内存管理", "文件系统"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
a5bac867-6f1a-4691-b3fa-3f82ef9421d0	61de896f-f51e-4b17-a4f7-0b4788464b24	第3章 网络与软件工程	3	["TCP/IP", "HTTP", "软件工程", "需求分析", "编码规范"]	18	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
928ad9fa-5e61-4f03-b41b-eaa684d50b2e	33de31d0-351f-46d4-865a-aaa6ba40a822	第1章 真题训练	1	["真题分类", "选择题技巧", "大题答题节奏", "错题本", "模考复盘"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
cb9be9b2-9b99-4811-be5e-4e32e85c4aa3	33de31d0-351f-46d4-865a-aaa6ba40a822	第2章 综合案例分析	2	["系统设计题", "数据库设计题", "程序题分析", "思路拆解", "答题模板"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
b953f2df-232d-4ed4-9316-081b0f2ff929	33de31d0-351f-46d4-865a-aaa6ba40a822	第3章 面试与冲刺	3	["自我介绍", "项目经历表达", "岗位认知", "临场发挥", "考前计划"]	20	2026-06-06 12:22:39.045149+08	2026-06-06 12:22:39.045149+08
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courses (id, title, description, cover_image, teacher_id, difficulty, status, tags, meta, created_at, updated_at, deleted_at) FROM stdin;
1add72f4-1ae2-44a4-8df5-7e2db23fafac	Java面试-初级	Java基础语法、面向对象、集合与异常处理，适合零基础入门和面试基础铺垫.	\N	\N	BEGINNER	PUBLISHED	{Java,面试,基础,OOP,集合}	{"hours": 40, "weeks": 4, "target": "Java初级面试基础"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
48a057cf-89a9-4de9-b568-8dc484c593a5	Java面试-中级	聚焦JVM、并发、反射、泛型、Spring基础与MySQL基础优化，适合中级面试准备.	\N	\N	INTERMEDIATE	PUBLISHED	{Java,JVM,并发,Spring,面试}	{"hours": 72, "weeks": 8, "target": "Java中级开发面试"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
29d51edd-37e0-4268-bf1e-6435c9bef575	Java面试-高级	覆盖Spring Boot、Spring Cloud、Redis、MQ、微服务、分布式事务与系统设计.	\N	\N	ADVANCED	PUBLISHED	{Java,架构,微服务,Redis,系统设计}	{"hours": 120, "weeks": 12, "target": "Java高级架构面试"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
f53e6f89-699a-411e-a49b-34439e9ac969	软考中级-初级基础	计算机基础入门课程，覆盖数据结构、操作系统、计算机网络与数据库基础.	\N	\N	BEGINNER	PUBLISHED	{软考,计算机基础,数据结构,网络,数据库}	{"hours": 36, "weeks": 4, "target": "软考中级打基础"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
2088f6c3-640a-4ae3-9e4c-aa7733f0ae9d	软考中级-软件设计师核心	覆盖UML、软件工程、设计模式、面向对象设计、数据库设计与算法分析.	\N	\N	INTERMEDIATE	PUBLISHED	{软考,软件设计师,UML,软件工程,设计模式}	{"hours": 80, "weeks": 10, "target": "软考中级软件设计师"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
fac174fe-43a9-4d62-be8f-51375745cd59	软考中级-冲刺与真题	历年真题、案例分析、论文写作和考前冲刺训练，帮助快速提分.	\N	\N	ADVANCED	PUBLISHED	{软考,真题,案例分析,论文,冲刺}	{"hours": 60, "weeks": 6, "target": "软考中级冲刺"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
f684a0d9-a4c0-440c-bf51-5f2695e87396	Python开发-初级	Python语法、变量、函数、文件操作、异常处理与常用数据结构.	\N	\N	BEGINNER	PUBLISHED	{Python,基础,语法,函数,文件}	{"hours": 36, "weeks": 4, "target": "Python入门"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
81fded06-a0ad-436d-99be-50c72e04ea0e	Python开发-中级	面向对象、装饰器、生成器、模块化开发、网络编程与爬虫入门.	\N	\N	INTERMEDIATE	PUBLISHED	{Python,面向对象,装饰器,爬虫,模块化}	{"hours": 72, "weeks": 8, "target": "Python工程开发"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
65e0eddf-91bf-4ad0-b50d-d9ccda04f946	Python开发-高级	FastAPI、Django、Flask、异步编程、性能优化与工程化实践.	\N	\N	ADVANCED	PUBLISHED	{Python,FastAPI,Django,Flask,异步}	{"hours": 100, "weeks": 10, "target": "Python高级开发"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
64127bf6-a804-401c-88d6-74138d9c7ca1	NumPy-初级	ndarray、数组创建、索引切片、基本数学运算与广播概念入门.	\N	\N	BEGINNER	PUBLISHED	{NumPy,数组,ndarray,基础}	{"hours": 24, "weeks": 2, "target": "NumPy入门"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
d868c111-8130-4938-99f1-bf4e4bfbc319	NumPy-中级	广播机制、向量化运算、随机数、统计分析与常用矩阵操作.	\N	\N	INTERMEDIATE	PUBLISHED	{NumPy,广播,向量化,统计,矩阵}	{"hours": 36, "weeks": 4, "target": "NumPy数据计算"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
c96bf0a1-6e13-4f3e-893f-30e8fea70cfd	NumPy-高级	线性代数、矩阵分解、高性能数值计算与机器学习数据预处理.	\N	\N	ADVANCED	PUBLISHED	{NumPy,线性代数,高性能,机器学习}	{"hours": 60, "weeks": 6, "target": "NumPy高级计算"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
66e42903-3c28-4dab-b3f4-a1487a322844	Pandas-初级	Series、DataFrame、CSV/Excel读取与基础数据查看操作.	\N	\N	BEGINNER	PUBLISHED	{Pandas,Series,DataFrame,Excel,CSV}	{"hours": 24, "weeks": 2, "target": "Pandas入门"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
a992e9c3-508f-4a16-bf9e-6c833f5ce598	Pandas-中级	缺失值处理、数据清洗、Merge、Join、GroupBy与透视表实战.	\N	\N	INTERMEDIATE	PUBLISHED	{Pandas,清洗,Merge,GroupBy,透视表}	{"hours": 48, "weeks": 5, "target": "Pandas数据清洗分析"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
4ecbb28b-a400-441e-8b41-8b28a4b35878	Pandas-高级	时间序列、复杂数据分析、报表分析与业务指标统计建模.	\N	\N	ADVANCED	PUBLISHED	{Pandas,时间序列,分析,报表,建模}	{"hours": 72, "weeks": 8, "target": "Pandas实战分析"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
aa9879bb-e374-4d49-8500-b31a5b4072e2	MySQL-初级	DDL、DML、约束、单表查询与基础数据库设计.	\N	\N	BEGINNER	PUBLISHED	{MySQL,数据库,SQL,基础}	{"hours": 36, "weeks": 4, "target": "MySQL入门"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
f02b723e-a8ef-454a-9b09-465220cbb68b	MySQL-中级	多表查询、事务、索引、视图、存储过程与基础性能优化.	\N	\N	INTERMEDIATE	PUBLISHED	{MySQL,事务,索引,多表查询,优化}	{"hours": 60, "weeks": 6, "target": "MySQL开发进阶"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
2c798eae-9a89-4d5f-9742-61c95af7fcd3	MySQL-高级	执行计划、锁机制、主从复制、分库分表与高并发优化.	\N	\N	ADVANCED	PUBLISHED	{MySQL,执行计划,复制,分库分表,高并发}	{"hours": 96, "weeks": 10, "target": "MySQL DBA与优化"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
84b24879-d818-4e6c-b597-059cb40d4089	PostgreSQL-初级	PostgreSQL基础语法、数据类型、约束、增删改查与表设计.	\N	\N	BEGINNER	PUBLISHED	{PostgreSQL,数据库,SQL,基础}	{"hours": 36, "weeks": 4, "target": "PostgreSQL入门"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
bd1734d7-9b61-4838-90fb-2173f22474bd	PostgreSQL-中级	事务、索引、JSONB、函数、触发器与常见开发场景.	\N	\N	INTERMEDIATE	PUBLISHED	{PostgreSQL,事务,索引,JSONB,函数}	{"hours": 60, "weeks": 6, "target": "PostgreSQL开发进阶"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
d022992d-fb47-4c0a-a4ac-986fe570c3a4	PostgreSQL-高级	分区表、逻辑复制、流复制、性能优化与高可用架构.	\N	\N	ADVANCED	PUBLISHED	{PostgreSQL,分区表,复制,高可用,优化}	{"hours": 96, "weeks": 10, "target": "PostgreSQL高级运维与优化"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
74e03a3b-4aa3-4f5a-b894-d0a8b3867988	C++算法-初级	数组、链表、栈、队列、哈希表与基础复杂度分析.	\N	\N	BEGINNER	PUBLISHED	{C++,算法,数据结构,基础}	{"hours": 40, "weeks": 4, "target": "C++算法入门"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
08710145-1e58-475c-8abc-7cf00f5c52a5	C++算法-中级	二叉树、DFS、BFS、动态规划、贪心与递归回溯.	\N	\N	INTERMEDIATE	PUBLISHED	{C++,二叉树,动态规划,贪心,搜索}	{"hours": 80, "weeks": 8, "target": "C++算法提升"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
3353ee87-1744-4049-b9ad-6cddd3e2f01f	C++算法-高级	线段树、树状数组、并查集、最短路、网络流与状态压缩DP.	\N	\N	ADVANCED	PUBLISHED	{C++,线段树,并查集,最短路,网络流}	{"hours": 120, "weeks": 12, "target": "C++算法竞赛训练"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
3a262091-b97f-43ce-9c08-8cc09e2962c1	湖南省考程序员岗-初级	行测基础、申论入门与计算机基础知识铺垫.	\N	\N	BEGINNER	PUBLISHED	{湖南省考,行测,申论,计算机基础}	{"hours": 30, "weeks": 4, "target": "湖南省考程序员岗基础"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
61de896f-f51e-4b17-a4f7-0b4788464b24	湖南省考程序员岗-中级	数据结构、数据库、操作系统、网络与软件工程重点复习.	\N	\N	INTERMEDIATE	PUBLISHED	{湖南省考,数据结构,数据库,操作系统,网络}	{"hours": 60, "weeks": 6, "target": "湖南省考程序员岗笔试"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
33de31d0-351f-46d4-865a-aaa6ba40a822	湖南省考程序员岗-高级	真题训练、案例分析、综合题冲刺与面试技巧.	\N	\N	ADVANCED	PUBLISHED	{湖南省考,真题,案例分析,面试,冲刺}	{"hours": 80, "weeks": 8, "target": "湖南省考程序员岗冲刺"}	2026-06-06 12:17:28.847649+08	2026-06-06 12:17:28.847649+08	\N
1b415619-96c2-4f2c-a188-b76f4c9592ca	test	test		41307fd6-5c25-4ddb-b67a-e4673f633d7e	BEGINNER	DRAFT	{test}	{}	2026-06-06 13:11:13.924931+08	2026-06-06 13:11:17.594537+08	2026-06-06 13:11:17.595657+08
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
3c5a6bfe-5b30-4b12-9b07-bef34acc7f91	1add72f4-1ae2-44a4-8df5-7e2db23fafac	c94e43ac-564b-468f-a63f-e4738e1f2260	SINGLE	12	["12", "12", "12", "12"]	0	12	3	{12}	{}	2026-06-07 00:35:38.372934+08	2026-06-07 00:35:42.404652+08	2026-06-07 00:35:42.405996+08	PLAIN
5c7fd545-246e-4afc-a56e-7fd38d45795d	1add72f4-1ae2-44a4-8df5-7e2db23fafac	c94e43ac-564b-468f-a63f-e4738e1f2260	SINGLE	"·1"	["·1", "1", "1", "1"]	0	1	3	{1}	{}	2026-06-07 00:32:21.762814+08	2026-06-07 00:35:44.180262+08	2026-06-07 00:35:44.18169+08	PLAIN
\.


--
-- Data for Name: user_learning_progress; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_learning_progress (id, user_id, course_id, last_section_id, progress, completed_sections, last_accessed) FROM stdin;
bd1fc8ec-db0e-46e8-b2fb-72c4e72626d1	41307fd6-5c25-4ddb-b67a-e4673f633d7e	48a057cf-89a9-4de9-b568-8dc484c593a5	ad1ef213-8b0d-47e9-9156-d3def2f802e4	33.00	\N	2026-06-07 00:43:03.165337+08
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
1987e413-f946-40cd-900c-d4e13d2940f6	不知所谓	2495444762@qq.com	$2a$10$nJGlT7emGEe9N392vdV1p.sSTJyRcAcZ08dWCWrI38vPrMjw1480K	吉他低手	\N	STUDENT	0	0	\N	ACTIVE	{}	2026-06-06 00:56:39.619449+08	2026-06-06 00:56:39.619449+08	\N
41307fd6-5c25-4ddb-b67a-e4673f633d7e	admin	13467608671@qq.com	$2a$10$BVf5tW.0VCnG.94cv0e9deUmiQ9fflrtTOvVJIqU9PUc0f2UdtEk.	ADMIN	\N	ADMIN	0	0	\N	ACTIVE	{}	2026-06-06 01:01:21.261185+08	2026-06-06 01:01:21.261185+08	\N
960801ac-ad2e-4cd4-9f13-f18915a93cd2	Teacher	2495444333@qq.com	$2a$10$LzQiLYAjCLd.5rF/t91hDu771TaX8nRXW7ATpxD13xqbgJakyu8sy	Teacher	\N	TEACHER	0	0	\N	ACTIVE	{}	2026-06-06 11:48:46.925798+08	2026-06-06 11:48:46.925798+08	\N
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

\unrestrict AJyu1ot4QPvJZZmHRFq1YbAgv4HzFhfE5xcKLWLdVNUm9uCtrB2KdEkm3YmgvEa

