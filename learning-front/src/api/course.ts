import { get, post, put, del } from '@/utils/request'
import type { Course, CreateCourseRequest, PageResponse, CourseDifficulty, CourseStatus, MessageResponse } from '@/types/api'

/**
 * 获取课程列表（分页）
 */
export function listCourses(params: {
  page?: number
  size?: number
  difficulty?: CourseDifficulty
  status?: CourseStatus
  keyword?: string
}) {
  return get<PageResponse<Course>>('/api/courses', params)
}

/**
 * 获取教师的课程列表
 */
export function getTeacherCourses(teacherId: string) {
  return get<Course[]>(`/api/courses/teacher/${teacherId}`)
}

/**
 * 获取课程详情
 */
export function getCourse(id: string) {
  return get<Course>(`/api/courses/${id}`)
}

/**
 * 创建课程
 */
export function createCourse(data: CreateCourseRequest) {
  return post<Course>('/api/courses', data)
}

/**
 * 更新课程
 */
export function updateCourse(id: string, data: Partial<Course>) {
  return put<MessageResponse>(`/api/courses/${id}`, data)
}

/**
 * 发布课程
 */
export function publishCourse(id: string) {
  return post<MessageResponse>(`/api/courses/${id}/publish`)
}

/**
 * 归档课程
 */
export function archiveCourse(id: string) {
  return post<MessageResponse>(`/api/courses/${id}/archive`)
}

/**
 * 删除课程
 */
export function deleteCourse(id: string) {
  return del<MessageResponse>(`/api/courses/${id}`)
}
