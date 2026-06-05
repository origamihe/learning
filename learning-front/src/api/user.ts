import { get, put } from '@/utils/request'
import type { User, UpdateProfileRequest, UpdatePasswordRequest, MessageResponse } from '@/types/api'

/**
 * 获取当前用户信息
 */
export function getCurrentUser() {
  return get<User>('/api/user/me')
}

/**
 * 获取用户信息
 */
export function getUserById(id: string) {
  return get<User>(`/api/user/${id}`)
}

/**
 * 更新用户资料
 */
export function updateProfile(data: UpdateProfileRequest) {
  return put<MessageResponse>('/api/user/profile', data)
}

/**
 * 更新密码
 */
export function updatePassword(data: UpdatePasswordRequest) {
  return put<MessageResponse>('/api/user/password', data)
}
