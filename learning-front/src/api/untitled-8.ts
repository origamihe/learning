import { get, post } from '@/utils/request'
import type { UserSignIn } from '@/types/api'

/**
 * 签到
 */
export function doSignIn() {
  return post<{
    message: string
    pointsEarned: number
    streakDays: number
    record: UserSignIn
  }>('/api/sign-in')
}

/**
 * 获取签到状态
 */
export function getSignInStatus() {
  return get<{
    hasSignedToday: boolean
    streakDays: number
  }>('/api/sign-in/status')
}

/**
 * 获取月度签到记录
 */
export function getSignInRecords(year: number, month: number) {
  return get<UserSignIn[]>('/api/sign-in/records', { year, month })
}
