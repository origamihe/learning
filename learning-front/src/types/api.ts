// 通用分页响应类型
export interface PageResponse<T> {
  records: T[]
  total: number
  size: number
  current: number
  pages: number
}

// UUID 类型
export type UUID = string

// 用户角色枚举
export enum UserRole {
  STUDENT = 'STUDENT',
  TEACHER = 'TEACHER',
  ADMIN = 'ADMIN',
}

// 用户状态枚举
export enum UserStatus {
  ACTIVE = 'ACTIVE',
  BANNED = 'BANNED',
  INACTIVE = 'INACTIVE',
}

// 课程难度枚举
export enum CourseDifficulty {
  BEGINNER = 'BEGINNER',
  INTERMEDIATE = 'INTERMEDIATE',
  ADVANCED = 'ADVANCED',
}

// 课程状态枚举
export enum CourseStatus {
  DRAFT = 'DRAFT',
  PUBLISHED = 'PUBLISHED',
  ARCHIVED = 'ARCHIVED',
}

// 题目类型枚举
export enum QuestionType {
  SINGLE = 'SINGLE',
  MULTIPLE = 'MULTIPLE',
  JUDGE = 'JUDGE',
  FILL = 'FILL',
  PROGRAMMING = 'PROGRAMMING',
}

// 考试状态枚举
export enum ExamStatus {
  DRAFT = 'DRAFT',
  PUBLISHED = 'PUBLISHED',
}

// 考试记录状态枚举
export enum ExamRecordStatus {
  IN_PROGRESS = 'IN_PROGRESS',
  SUBMITTED = 'SUBMITTED',
  TIMEOUT = 'TIMEOUT',
  GRADED = 'GRADED',
}

// 考试类型枚举
export enum ExamType {
  PRACTICE = 'PRACTICE',
  FORMAL = 'FORMAL',
  MOCK = 'MOCK',
}

// 用户实体
export interface User {
  id: UUID
  username: string
  email: string
  nickname?: string
  avatar?: string
  role: UserRole
  status: UserStatus
  points: number
  streakDays: number
  lastSignIn?: string
  preferences?: string
  createdAt: string
  updatedAt: string
  deletedAt?: string
}

// 课程实体
export interface Course {
  id: UUID
  title: string
  description?: string
  coverImage?: string
  teacherId: UUID
  difficulty: CourseDifficulty
  status: CourseStatus
  tags?: string
  meta?: string
  createdAt: string
  updatedAt: string
  deletedAt?: string
}

// 课程章节实体
export interface CourseSection {
  id: UUID
  courseId: UUID
  title: string
  content?: string
  sortOrder: number
  duration?: number
  createdAt: string
  updatedAt: string
}

// 题目实体
export interface Question {
  id: UUID
  courseId: UUID
  sectionId?: UUID
  type: QuestionType
  content: string
  options?: string
  answer?: string
  explanation?: string
  difficulty?: number
  tags?: string
  meta?: string
  createdAt: string
  updatedAt: string
  deletedAt?: string
}

// 考试实体
export interface Exam {
  id: UUID
  courseId: UUID
  title: string
  duration: number
  totalScore: number
  passScore: number
  type?: ExamType
  status: ExamStatus
  config?: string
  createdAt: string
  updatedAt: string
}

// 考试记录实体
export interface ExamRecord {
  id: UUID
  userId: UUID
  examId: UUID
  startTime: string
  endTime?: string
  durationUsed?: number
  answers?: string
  score?: number
  status: ExamRecordStatus
  createdAt: string
}

// 学习进度实体
export interface UserLearningProgress {
  id: UUID
  userId: UUID
  courseId: UUID
  lastSectionId?: UUID
  progress: number
  completedSections: string // JSON array of sectionIds
  lastAccessed: string
}

// 签到记录实体
export interface UserSignIn {
  id: UUID
  userId: UUID
  signInDate: string
  pointsEarned: number
  createdAt: string
}

// 错题记录实体
export interface UserWrongQuestion {
  id: UUID
  userId: UUID
  questionId: UUID
  wrongCount: number
  lastWrongAt: string
  nextReviewAt: string
  masteryLevel: number
  notes?: string
}

// 登录请求
export interface LoginRequest {
  username: string
  password: string
}

// 登录响应
export interface LoginResponse {
  userId: UUID
  username: string
  nickname?: string
  accessToken: string
  expiresIn: number
  refreshToken: string
  refreshExpiresIn: number
}

// 注册请求
export interface RegisterRequest {
  username: string
  email: string
  password: string
  nickname?: string
}

// 创建课程请求
export interface CreateCourseRequest {
  title: string
  description?: string
  coverImage?: string
  difficulty?: CourseDifficulty
  tags?: string
}

// 创建章节请求
export interface CreateSectionRequest {
  title: string
  courseId: UUID
  content?: string
  duration?: number
}

// 章节排序请求
export interface ReorderSectionsRequest {
  courseId: UUID
  sectionIds: UUID[]
}

// 创建考试请求
export interface CreateExamRequest {
  title: string
  courseId: UUID
  duration?: number
  totalScore?: number
  passScore?: number
  config?: string
}

// 创建题目请求
export interface CreateQuestionRequest {
  courseId: UUID
  sectionId?: UUID
  type?: QuestionType
  content: string
  options?: string
  answer?: string
  explanation?: string
  difficulty?: number
  tags?: string
}

// 更新用户资料请求
export interface UpdateProfileRequest {
  nickname: string
  avatar?: string
}

// 更新密码请求
export interface UpdatePasswordRequest {
  oldPassword: string
  newPassword: string
}

// 更新错题笔记请求
export interface UpdateWrongQuestionNotesRequest {
  notes: string
}

// 文件附件实体（MinIO）
export interface FileAttachment {
  id: UUID
  userId: UUID
  originalName: string
  storageKey: string
  fileUrl: string
  fileSize: number
  mimeType: string
  fileCategory: string
  entityType: string
  entityId: UUID
  sortOrder: number
  width?: number
  height?: number
  duration?: number
  thumbnailKey?: string
  createdAt: string
  updatedAt: string
  deletedAt?: string
}

// 附件关联请求
export interface AttachFilesRequest {
  fileIds: UUID[]
  entityType: string
  entityId: UUID
}

// 通用响应
export interface ApiResponse<T = any> {
  message?: string
  data?: T
}

// 通用消息响应
export interface MessageResponse {
  message: string
}
