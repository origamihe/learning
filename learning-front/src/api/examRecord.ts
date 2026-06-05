import { get, post, del } from '@/utils/request'
import type { ExamRecord, MessageResponse } from '@/types/api'

/**
 * 开始考试
 */
export function startExam(examId: string) {
  return post<ExamRecord>('/api/exam-records/start', null, { params: { examId } })
}

/**
 * 提交考试
 */
export function submitExam(id: string, answers: Record<string, any>) {
  return post<ExamRecord>(`/api/exam-records/${id}/submit`, answers)
}

/**
 * 批改考试
 */
export function gradeExam(id: string) {
  return post<ExamRecord>(`/api/exam-records/${id}/grade`)
}

/**
 * 获取用户的考试记录
 */
export function getUserExamRecords(userId: string) {
  return get<ExamRecord[]>(`/api/exam-records/user/${userId}`)
}

/**
 * 获取考试记录详情
 */
export function getExamRecordDetail(id: string) {
  return get<ExamRecord>(`/api/exam-records/${id}`)
}

/**
 * 删除考试记录
 */
export function deleteExamRecord(id: string) {
  return del<MessageResponse>(`/api/exam-records/${id}`)
}
