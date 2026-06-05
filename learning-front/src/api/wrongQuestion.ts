import { get, post, put, del } from '@/utils/request'
import type { UserWrongQuestion, UpdateWrongQuestionNotesRequest, MessageResponse } from '@/types/api'

/**
 * 添加错题
 */
export function addWrongQuestion(questionId: string) {
  return post<MessageResponse>('/api/wrong-questions', { questionId })
}

/**
 * 获取我的错题列表
 */
export function getMyWrongQuestions() {
  return get<UserWrongQuestion[]>('/api/wrong-questions/me')
}

/**
 * 获取待复习错题
 */
export function getDueForReview() {
  return get<UserWrongQuestion[]>('/api/wrong-questions/review/due')
}

/**
 * 更新掌握程度
 */
export function updateMasteryLevel(id: string, level: number) {
  return put<MessageResponse>(`/api/wrong-questions/${id}/mastery`, { level })
}

/**
 * 更新笔记
 */
export function updateNotes(id: string, notes: string) {
  return put<MessageResponse>(`/api/wrong-questions/${id}/notes`, { notes })
}

/**
 * 移除错题
 */
export function removeWrongQuestion(id: string) {
  return del<MessageResponse>(`/api/wrong-questions/${id}`)
}
