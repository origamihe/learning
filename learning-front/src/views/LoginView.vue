<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { LoginRequest } from '@/types/api'

const router = useRouter()
const authStore = useAuthStore()

const activeTab = ref<'user' | 'admin'>('user')
const username = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')

const isFormValid = computed(() => username.value.trim() !== '' && password.value.trim() !== '')

const tabLabel = computed(() => (activeTab.value === 'user' ? '普通用户登录' : '管理员登录'))
const tabDescription = computed(() =>
  activeTab.value === 'user'
    ? '欢迎回来，登录以继续学习'
    : '管理员专属入口，请使用管理员账号登录',
)

async function handleLogin() {
  if (!isFormValid.value) return

  loading.value = true
  errorMsg.value = ''

  try {
    authStore.setLoginType(activeTab.value)

    const credentials: LoginRequest = {
      username: username.value.trim(),
      password: password.value,
    }

    await authStore.login(credentials)

    // 根据角色跳转不同页面
    if (authStore.isAdmin) {
      router.push('/admin/dashboard')
    } else {
      router.push('/courses')
    }
  } catch (err: any) {
    // 角色不匹配时 authStore.login() 会清除 token 并抛出 Error，err.message 即为提示
    const msg = err?.response?.data?.message || err?.message || '登录失败，请检查用户名和密码'
    errorMsg.value = msg
  } finally {
    loading.value = false
  }
}

function switchTab(tab: 'user' | 'admin') {
  activeTab.value = tab
  errorMsg.value = ''
}

function goToRegister() {
  router.push('/register')
}
</script>

<template>
  <div class="login-wrapper">
    <div class="login-card">
      <!-- Tab 切换 -->
      <div class="tab-bar">
        <button
          :class="['tab-btn', { active: activeTab === 'user' }]"
          @click="switchTab('user')"
        >
          <svg class="tab-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>
          普通用户
        </button>
        <button
          :class="['tab-btn', { active: activeTab === 'admin' }]"
          @click="switchTab('admin')"
        >
          <svg class="tab-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
          </svg>
          管理员
        </button>
      </div>

      <!-- 标题区 -->
      <div class="form-header">
        <h2 class="form-title">{{ tabLabel }}</h2>
        <p class="form-desc">{{ tabDescription }}</p>
      </div>

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
      <form class="login-form" @submit.prevent="handleLogin">
        <div class="form-group">
          <label class="form-label" for="username">用户名</label>
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
          <label class="form-label" for="password">密码</label>
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
              placeholder="请输入密码"
              autocomplete="current-password"
            />
          </div>
        </div>

        <button
          type="submit"
          class="submit-btn"
          :class="activeTab === 'admin' ? 'submit-btn-admin' : 'submit-btn-user'"
          :disabled="!isFormValid || loading"
        >
          <span v-if="loading" class="spinner"></span>
          <span v-else>{{ activeTab === 'user' ? '登 录' : '管理员登录' }}</span>
        </button>
      </form>

      <!-- 底部跳转 -->
      <div class="form-footer">
        <span>还没有账号？</span>
        <button class="link-btn" @click="goToRegister">立即注册</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.login-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: #f5f5f7;
}

.login-card {
  width: 100%;
  max-width: 420px;
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

/* Tab 切换栏 */
.tab-bar {
  display: flex;
  border-bottom: 1px solid #f1f1f3;
}

.tab-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 16px;
  border: none;
  background: #fafafa;
  color: #86868b;
  font-size: 15px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.tab-btn:hover {
  background: #f5f5f7;
  color: #1d1d1f;
}

.tab-btn.active {
  background: #ffffff;
  color: #0071e3;
  font-weight: 600;
  box-shadow: inset 0 -3px 0 #0071e3;
}

.tab-icon {
  width: 18px;
  height: 18px;
}

/* 表单头部 */
.form-header {
  padding: 32px 36px 8px;
  text-align: center;
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

/* 错误提示 */
.error-banner {
  margin: 16px 36px 0;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  background: #fff5f5;
  border: 1px solid #feb2b2;
  border-radius: 12px;
  color: #c53030;
  font-size: 14px;
}

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
.login-form {
  padding: 24px 36px;
}

.form-group {
  margin-bottom: 20px;
}

.form-label {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
  margin-bottom: 8px;
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

/* 提交按钮 */
.submit-btn {
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 9999px;
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 8px;
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.submit-btn-user {
  background: #0071e3;
}

.submit-btn-user:not(:disabled):hover {
  background: #0066cc;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 113, 227, 0.3);
}

.submit-btn-admin {
  background: #1d1d1f;
}

.submit-btn-admin:not(:disabled):hover {
  background: #333333;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
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
