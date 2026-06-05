import { post } from '@/utils/request'
import type { LoginRequest, LoginResponse, RegisterRequest } from '@/types/api'

/**
 * 用户登录
 */
export function login(data: LoginRequest) {
  return post<LoginResponse>('/api/auth/login', data)
}

/**
 * 用户注册
 */
export function register(data: RegisterRequest) {
  return post<LoginResponse>('/api/auth/register', data)
}
