import { get, post } from '@/utils/request'
import type { UserLearningProgress, MessageResponse } from '@/types/api'

/**
 * 更新学习进度
 */
export function updateProgress(courseId: string, sectionId: string) {
  return post<MessageResponse>('/api/progress', { courseId, sectionId })
}

/**
 * 获取课程学习进度
 */
export function getProgress(courseId: string) {
  return get<UserLearningProgress>(`/api/progress/course/${courseId}`)
}

/**
 * 获取我的所有学习进度
 */
export function getMyProgress() {
  return get<UserLearningProgress[]>('/api/progress/me')
}

/**
 * 获取课程完成率
 */
export function getCompletionRate(courseId: string) {
  return get<{ completionRate: number }>(`/api/progress/completion/${courseId}`)
}
