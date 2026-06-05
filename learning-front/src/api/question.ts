import { get, post, put, del } from '@/utils/request'
import type { Question, CreateQuestionRequest, PageResponse, QuestionType, MessageResponse } from '@/types/api'

/**
 * 获取题目列表（分页）
 */
export function listQuestions(params: {
  page?: number
  size?: number
  courseId?: string
  sectionId?: string
  type?: QuestionType
  difficulty?: number
}) {
  return get<PageResponse<Question>>('/api/questions', params)
}

/**
 * 获取课程的题目列表
 */
export function getQuestionsByCourse(courseId: string) {
  return get<Question[]>(`/api/questions/course/${courseId}`)
}

/**
 * 获取章节的题目列表
 */
export function getQuestionsBySection(sectionId: string) {
  return get<Question[]>(`/api/questions/section/${sectionId}`)
}

/**
 * 获取题目详情
 */
export function getQuestion(id: string) {
  return get<Question>(`/api/questions/${id}`)
}

/**
 * 创建题目
 */
export function createQuestion(data: CreateQuestionRequest) {
  return post<Question>('/api/questions', data)
}

/**
 * 更新题目
 */
export function updateQuestion(id: string, data: Partial<Question>) {
  return put<MessageResponse>(`/api/questions/${id}`, data)
}

/**
 * 删除题目
 */
export function deleteQuestion(id: string) {
  return del<MessageResponse>(`/api/questions/${id}`)
}
