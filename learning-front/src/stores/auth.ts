import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { login as loginApi, register as registerApi } from '@/api/auth'
import { getCurrentUser } from '@/api/user'
import type { LoginRequest, RegisterRequest, User } from '@/types/api'
import router from '@/router'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string>(localStorage.getItem('accessToken') || '')
  const refreshToken = ref<string>(localStorage.getItem('refreshToken') || '')
  const user = ref<User | null>(null)
  const loginType = ref<'user' | 'admin' | 'teacher'>('user')

  const isLoggedIn = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.role === 'ADMIN')
  const isTeacher = computed(() => user.value?.role === 'TEACHER')
  const isStudent = computed(() => user.value?.role === 'STUDENT')

  function setLoginType(type: 'user' | 'admin' | 'teacher') {
    loginType.value = type
  }

  function setTokens(accessToken: string, refreshTokenStr: string) {
    token.value = accessToken
    refreshToken.value = refreshTokenStr
    localStorage.setItem('accessToken', accessToken)
    localStorage.setItem('refreshToken', refreshTokenStr)
  }

  function clearAuth() {
    token.value = ''
    refreshToken.value = ''
    user.value = null
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
  }

  async function login(credentials: LoginRequest) {
    const response = await loginApi(credentials)
    setTokens(response.accessToken, response.refreshToken)
    const userInfo = await getCurrentUser()
    user.value = userInfo

    // 角色校验：禁止管理员和普通用户/教师互相登录
    if (loginType.value === 'admin' && userInfo.role !== 'ADMIN') {
      clearAuth()
      throw new Error('该账号不是管理员，请使用普通用户入口登录')
    }
    if (loginType.value === 'user' && userInfo.role === 'ADMIN') {
      clearAuth()
      throw new Error('该账号是管理员，请使用管理员入口登录')
    }

    return response
  }

  async function register(data: RegisterRequest) {
    loginType.value = 'user'
    const response = await registerApi(data)
    setTokens(response.accessToken, response.refreshToken)
    const userInfo = await getCurrentUser()
    user.value = userInfo
    return response
  }

  function logout() {
    clearAuth()
    router.push('/login')
  }

  async function fetchUser() {
    if (token.value) {
      try {
        user.value = await getCurrentUser()
      } catch {
        clearAuth()
      }
    }
  }

  return {
    token,
    refreshToken,
    user,
    loginType,
    isLoggedIn,
    isAdmin,
    isTeacher,
    isStudent,
    login,
    register,
    logout,
    fetchUser,
    setLoginType,
  }
})
