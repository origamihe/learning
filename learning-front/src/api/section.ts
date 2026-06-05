import { get, post, put, del } from '@/utils/request'
import type { CourseSection, CreateSectionRequest, ReorderSectionsRequest, MessageResponse } from '@/types/api'

/**
 * 获取课程的章节列表
 */
export function getSectionsByCourse(courseId: string) {
  return get<CourseSection[]>(`/api/sections/course/${courseId}`)
}

/**
 * 创建章节
 */
export function createSection(data: CreateSectionRequest) {
  return post<CourseSection>('/api/sections', data)
}

/**
 * 更新章节
 */
export function updateSection(id: string, data: Partial<CourseSection>) {
  return put<MessageResponse>(`/api/sections/${id}`, data)
}

/**
 * 重新排序章节
 */
export function reorderSections(data: ReorderSectionsRequest) {
  return post<MessageResponse>('/api/sections/reorder', data)
}

/**
 * 删除章节
 */
export function deleteSection(id: string) {
  return del<MessageResponse>(`/api/sections/${id}`)
}
