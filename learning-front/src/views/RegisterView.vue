<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { RegisterRequest } from '@/types/api'

const router = useRouter()
const authStore = useAuthStore()

const username = ref('')
const email = ref('')
const nickname = ref('')
const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

const isFormValid = computed(() => {
  return (
    username.value.trim() !== '' &&
    email.value.trim() !== '' &&
    password.value.length >= 6 &&
    password.value === confirmPassword.value
  )
})

const passwordStrength = computed(() => {
  const len = password.value.length
  if (len === 0) return { text: '', color: '', width: '0%' }
  if (len < 6) return { text: '密码太短', color: '#e53e3e', width: '25%' }
  if (len < 8) return { text: '一般', color: '#dd6b20', width: '50%' }
  if (len < 10) return { text: '较好', color: '#38a169', width: '75%' }
  return { text: '很强', color: '#38a169', width: '100%' }
})

const passwordMismatch = computed(() => {
  return confirmPassword.value !== '' && password.value !== confirmPassword.value
})

async function handleRegister() {
  if (!isFormValid.value) return

  loading.value = true
  errorMsg.value = ''
  successMsg.value = ''

  try {
    const data: RegisterRequest = {
      username: username.value.trim(),
      email: email.value.trim(),
      password: password.value,
    }

    if (nickname.value.trim()) {
      data.nickname = nickname.value.trim()
    }

    await authStore.register(data)

    successMsg.value = '注册成功！正在跳转...'
    setTimeout(() => {
      router.push('/courses')
    }, 1500)
  } catch (err: any) {
    const msg = err?.response?.data?.message || err?.message || '注册失败，请稍后重试'
    errorMsg.value = msg
  } finally {
    loading.value = false
  }
}

function goToLogin() {
  router.push('/login')
}
</script>

<template>
  <div class="register-wrapper">
    <div class="register-card">
      <!-- 标题区 -->
      <div class="form-header">
        <div class="header-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
            <circle cx="8.5" cy="7" r="4" />
            <line x1="20" y1="8" x2="20" y2="14" />
            <line x1="23" y1="11" x2="17" y2="11" />
          </svg>
        </div>
        <h2 class="form-title">创建账号</h2>
        <p class="form-desc">注册一个账号，开始你的学习之旅</p>
      </div>

      <!-- 成功提示 -->
      <transition name="fade">
        <div v-if="successMsg" class="success-banner">
          <svg class="success-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
            <polyline points="22 4 12 14.01 9 11.01" />
          </svg>
          {{ successMsg }}
        </div>
      </transition>

      <!-- 错误提示 -->
      <transition name="fade">
        <div v-if="errorMsg" class="error-banner">
          <svg class="error-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          {{ errorMsg }}
        </div>
      </transition>

      <!-- 表单 -->
      <form class="register-form" @submit.prevent="handleRegister">
        <div class="form-group">
          <label class="form-label" for="username">用户名 <span class="required">*</span></label>
          <div class="input-wrapper">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            <input
              id="username"
              v-model="username"
              type="text"
              class="form-input"
              placeholder="请输入用户名"
              autocomplete="username"
            />
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="email">邮箱 <span class="required">*</span></label>
          <div class="input-wrapper">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
              <polyline points="22,6 12,13 2,6" />
            </svg>
            <input
              id="email"
              v-model="email"
              type="email"
              class="form-input"
              placeholder="请输入邮箱"
              autocomplete="email"
            />
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="nickname">昵称 <span class="optional">(选填)</span></label>
          <div class="input-wrapper">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
              <circle cx="12" cy="7" r="4" />
            </svg>
            <input
              id="nickname"
              v-model="nickname"
              type="text"
              class="form-input"
              placeholder="给自己起个名字吧"
            />
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="password">密码 <span class="required">*</span></label>
          <div class="input-wrapper">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <input
              id="password"
              v-model="password"
              type="password"
              class="form-input"
              placeholder="至少 6 位密码"
              autocomplete="new-password"
            />
          </div>
          <!-- 密码强度指示 -->
          <div v-if="password" class="password-strength">
            <div class="strength-bar">
              <div
                class="strength-fill"
                :style="{ width: passwordStrength.width, backgroundColor: passwordStrength.color }"
              ></div>
            </div>
            <span class="strength-text" :style="{ color: passwordStrength.color }">
              {{ passwordStrength.text }}
            </span>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="confirmPassword">确认密码 <span class="required">*</span></label>
          <div class="input-wrapper">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <input
              id="confirmPassword"
              v-model="confirmPassword"
              type="password"
              class="form-input"
              :class="{ 'input-error': passwordMismatch }"
              placeholder="请再次输入密码"
              autocomplete="new-password"
            />
          </div>
          <p v-if="passwordMismatch" class="field-error">两次输入的密码不一致</p>
        </div>

        <button
          type="submit"
          class="submit-btn"
          :disabled="!isFormValid || loading"
        >
          <span v-if="loading" class="spinner"></span>
          <span v-else>注 册</span>
        </button>
      </form>

      <!-- 底部跳转 -->
      <div class="form-footer">
        <span>已有账号？</span>
        <button class="link-btn" @click="goToLogin">立即登录</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.register-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: #f5f5f7;
}

.register-card {
  width: 100%;
  max-width: 440px;
  background: #ffffff;
  border-radius: 16px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
  overflow: hidden;
  animation: slideUp 0.5s ease;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 表单头部 */
.form-header {
  padding: 36px 36px 8px;
  text-align: center;
}

.header-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  border-radius: 16px;
  background: #0071e3;
  color: #ffffff;
  margin-bottom: 16px;
}

.header-icon svg {
  width: 28px;
  height: 28px;
}

.form-title {
  font-size: 24px;
  font-weight: 700;
  color: #1d1d1f;
  margin-bottom: 8px;
}

.form-desc {
  font-size: 14px;
  color: #86868b;
}

/* 消息提示 */
.success-banner,
.error-banner {
  margin: 16px 36px 0;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  border-radius: 12px;
  font-size: 14px;
}

.success-banner {
  background: #f0fff4;
  border: 1px solid #9ae6b4;
  color: #276749;
}

.error-banner {
  background: #fff5f5;
  border: 1px solid #feb2b2;
  color: #c53030;
}

.success-icon,
.error-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 表单 */
.register-form {
  padding: 24px 36px;
}

.form-group {
  margin-bottom: 18px;
}

.form-label {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
  margin-bottom: 8px;
}

.required {
  color: #e53e3e;
}

.optional {
  color: #86868b;
  font-weight: 400;
  font-size: 12px;
}

.input-wrapper {
  position: relative;
}

.input-icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  width: 18px;
  height: 18px;
  color: #86868b;
  pointer-events: none;
}

.form-input {
  width: 100%;
  padding: 12px 14px 12px 42px;
  border: 1.5px solid #d2d2d7;
  border-radius: 12px;
  font-size: 15px;
  color: #1d1d1f;
  background: #ffffff;
  outline: none;
  transition: border-color 0.3s ease, box-shadow 0.3s ease;
}

.form-input:focus {
  border-color: #0071e3;
  box-shadow: 0 0 0 3px rgba(0, 113, 227, 0.12);
}

.form-input::placeholder {
  color: #86868b;
}

.input-error {
  border-color: #feb2b2;
}

.input-error:focus {
  border-color: #e53e3e;
  box-shadow: 0 0 0 3px rgba(229, 62, 62, 0.12);
}

.field-error {
  margin-top: 6px;
  font-size: 12px;
  color: #e53e3e;
}

/* 密码强度 */
.password-strength {
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.strength-bar {
  flex: 1;
  height: 4px;
  background: #f1f1f3;
  border-radius: 2px;
  overflow: hidden;
}

.strength-fill {
  height: 100%;
  border-radius: 2px;
  transition: width 0.3s ease, background-color 0.3s ease;
}

.strength-text {
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}

/* 提交按钮 */
.submit-btn {
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 9999px;
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
  background: #0071e3;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 8px;
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.submit-btn:not(:disabled):hover {
  background: #0066cc;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 113, 227, 0.3);
}

.spinner {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 2.5px solid rgba(255, 255, 255, 0.3);
  border-top-color: #ffffff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* 底部 */
.form-footer {
  padding: 0 36px 32px;
  text-align: center;
  font-size: 14px;
  color: #86868b;
}

.link-btn {
  background: none;
  border: none;
  color: #0071e3;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  margin-left: 4px;
  transition: color 0.3s ease;
}

.link-btn:hover {
  color: #0066cc;
  text-decoration: underline;
}
</style>
