CREATE EXTENSION IF NOT EXISTS pg_trgm;        -- 模糊搜索

CREATE EXTENSION IF NOT EXISTS hstore;         -- 可选


-- 1. 用户表

CREATE TABLE users (

    id              UUID PRIMARY KEY,                    -- 去掉 DEFAULT，由应用层赋值

    username        VARCHAR(50) UNIQUE NOT NULL,

    email           VARCHAR(100) UNIQUE NOT NULL,

    password_hash   VARCHAR(255) NOT NULL,

    nickname        VARCHAR(60),

    avatar          TEXT,

    role            VARCHAR(20) NOT NULL DEFAULT 'STUDENT'

        CHECK (role IN ('STUDENT', 'TEACHER', 'ADMIN')),

    points          INTEGER DEFAULT 0,

    streak_days     INTEGER DEFAULT 0,

    last_sign_in    DATE,

    status          VARCHAR(20) DEFAULT 'ACTIVE'

        CHECK (status IN ('ACTIVE', 'BANNED', 'INACTIVE')),

    preferences     JSONB DEFAULT '{}',

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    deleted_at      TIMESTAMPTZ

);


-- 2. 签到记录表

CREATE TABLE user_sign_ins (

    id              UUID PRIMARY KEY,                    -- 去掉 DEFAULT

    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    sign_in_date    DATE NOT NULL,

    points_earned   INTEGER DEFAULT 5,

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, sign_in_date)

);


-- 3. 课程表

CREATE TABLE courses (

    id              UUID PRIMARY KEY,                    -- 去掉 DEFAULT

    title           VARCHAR(200) NOT NULL,

    description     TEXT,

    cover_image     TEXT,

    teacher_id      UUID REFERENCES users(id),

    difficulty      VARCHAR(20) CHECK (difficulty IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED')),

    status          VARCHAR(20) DEFAULT 'DRAFT'

        CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),

    tags            TEXT[],

    meta            JSONB DEFAULT '{}',

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    deleted_at      TIMESTAMPTZ

);


-- 4. 课程章节

CREATE TABLE course_sections (

    id              UUID PRIMARY KEY,                    -- 去掉 DEFAULT

    course_id       UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,

    title           VARCHAR(150) NOT NULL,

    sort_order      INTEGER NOT NULL,

    content         JSONB,

    duration        INTEGER,

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    updated_at      TIMESTAMPTZ DEFAULT NOW()

);


-- 5. 题库表

CREATE TABLE questions (

    id              UUID PRIMARY KEY,                    -- 去掉 DEFAULT

    course_id       UUID REFERENCES courses(id),

    section_id      UUID REFERENCES course_sections(id),

    type            VARCHAR(30) NOT NULL

        CHECK (type IN ('SINGLE', 'MULTIPLE', 'JUDGE', 'FILL', 'PROGRAMMING')),

    content         TEXT NOT NULL,

    options         JSONB,

    answer          JSONB NOT NULL,

    explanation     TEXT,

    difficulty      INTEGER NOT NULL CHECK (difficulty BETWEEN 1 AND 5),

    tags            TEXT[],

    meta            JSONB DEFAULT '{}',

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    updated_at      TIMESTAMPTZ DEFAULT NOW(),

    deleted_at      TIMESTAMPTZ

);


-- 6. 用户错题本

CREATE TABLE user_wrong_questions (

    id                  UUID PRIMARY KEY,                -- 去掉 DEFAULT

    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    question_id         UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,

    wrong_count         INTEGER DEFAULT 1,

    last_wrong_at       TIMESTAMPTZ DEFAULT NOW(),

    next_review_at      TIMESTAMPTZ,

    mastery_level       INTEGER DEFAULT 1 CHECK (mastery_level BETWEEN 1 AND 5),

    notes               TEXT,

    UNIQUE(user_id, question_id)

);


-- 7. 考试表

CREATE TABLE exams (

    id              UUID PRIMARY KEY,                    -- 去掉 DEFAULT

    title           VARCHAR(150) NOT NULL,

    course_id       UUID REFERENCES courses(id),

    duration        INTEGER NOT NULL,

    total_score     INTEGER DEFAULT 100,

    pass_score      INTEGER DEFAULT 60,

    type            VARCHAR(30) CHECK (type IN ('PRACTICE', 'FORMAL', 'MOCK')),

    status          VARCHAR(20) DEFAULT 'DRAFT',

    config          JSONB DEFAULT '{}',

    created_at      TIMESTAMPTZ DEFAULT NOW(),

    updated_at      TIMESTAMPTZ DEFAULT NOW()

);


-- 8. 考试记录

CREATE TABLE exam_records (

    id              UUID PRIMARY KEY,                    -- 去掉 DEFAULT

    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    exam_id         UUID REFERENCES exams(id),

    start_time      TIMESTAMPTZ NOT NULL,

    end_time        TIMESTAMPTZ,

    duration_used   INTEGER,

    score           NUMERIC(5,2),

    answers         JSONB,

    status          VARCHAR(20) DEFAULT 'IN_PROGRESS'

        CHECK (status IN ('IN_PROGRESS', 'SUBMITTED', 'TIMEOUT', 'GRADED')),

    created_at      TIMESTAMPTZ DEFAULT NOW()

);


-- 9. 学习进度表

CREATE TABLE user_learning_progress (

    id              UUID PRIMARY KEY,                    -- 去掉 DEFAULT

    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    course_id       UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,

    last_section_id UUID REFERENCES course_sections(id),

    progress        NUMERIC(5,2) DEFAULT 0,

    completed_sections TEXT[],

    last_accessed   TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, course_id)

);


-- 10. 索引（非常重要！）

CREATE INDEX idx_users_email ON users(email);

CREATE INDEX idx_users_role ON users(role);

CREATE INDEX idx_signins_user_date ON user_sign_ins(user_id, sign_in_date);

CREATE INDEX idx_questions_tags ON questions USING GIN(tags);

CREATE INDEX idx_wrong_questions_user ON user_wrong_questions(user_id);

CREATE INDEX idx_wrong_questions_review ON user_wrong_questions(next_review_at);

CREATE INDEX idx_exam_records_user ON exam_records(user_id);