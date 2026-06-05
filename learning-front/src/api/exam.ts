import { get, post, put, del } from '@/utils/request'
import type { Exam, CreateExamRequest, MessageResponse } from '@/types/api'

/**
 * 获取课程的考试列表
 */
export function getExamsByCourse(courseId: string) {
  return get<Exam[]>(`/api/exams/course/${courseId}`)
}

/**
 * 获取考试详情
 */
export function getExamDetail(id: string) {
  return get<Exam>(`/api/exams/${id}`)
}

/**
 * 创建考试
 */
export function createExam(data: CreateExamRequest) {
  return post<Exam>('/api/exams', data)
}

/**
 * 更新考试
 */
export function updateExam(id: string, data: Partial<Exam>) {
  return put<MessageResponse>(`/api/exams/${id}`, data)
}

/**
 * 发布考试
 */
export function publishExam(id: string) {
  return post<MessageResponse>(`/api/exams/${id}/publish`)
}

/**
 * 删除考试
 */
export function deleteExam(id: string) {
  return del<MessageResponse>(`/api/exams/${id}`)
}
