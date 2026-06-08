<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { updateProfile, updatePassword } from '@/api/user'
import type { UpdateProfileRequest, UpdatePasswordRequest } from '@/types/api'

const authStore = useAuthStore()

// ==================== 状态 ====================
const pageLoading = ref(true)
const profileSaving = ref(false)
const passwordSaving = ref(false)

const successMsg = ref('')
const errorMsg = ref('')
const passwordSuccessMsg = ref('')
const passwordErrorMsg = ref('')

// 编辑昵称
const editNickname = ref('')

// 修改密码
const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: '',
})

// ==================== 初始化 ====================
onMounted(async () => {
  try {
    await authStore.fetchUser()
    editNickname.value = authStore.user?.nickname || ''
  } finally {
    pageLoading.value = false
  }
})

// ==================== 计算属性 ====================
function getAvatarLetter(): string {
  const name = authStore.user?.nickname || authStore.user?.username || 'U'
  return name.charAt(0).toUpperCase()
}

function getRoleLabel(role: string): string {
  const map: Record<string, string> = {
    ADMIN: '管理员',
    TEACHER: '教师',
    STUDENT: '学生',
  }
  return map[role] || role
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    ACTIVE: '正常',
    BANNED: '封禁',
    INACTIVE: '未激活',
  }
  return map[status] || status
}

function formatDate(dateStr: string): string {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

// ==================== 工具函数 ====================
function getErrorMessage(err: unknown, fallback: string): string {
  const e = err as { response?: { data?: { message?: string } }; message?: string }
  return e?.response?.data?.message || e?.message || fallback
}
// ==================== 操作 ====================
async function handleSaveProfile() {
  if (!editNickname.value.trim()) {
    errorMsg.value = '昵称不能为空'
    return
  }
  if (editNickname.value.trim() === (authStore.user?.nickname || '')) {
    errorMsg.value = '昵称未发生变化'
    return
  }

  profileSaving.value = true
  successMsg.value = ''
  errorMsg.value = ''

  try {
    const data: UpdateProfileRequest = {
      nickname: editNickname.value.trim(),
    }
    await updateProfile(data)
    await authStore.fetchUser()
    successMsg.value = '个人资料更新成功'
  } catch (err: unknown) {
    errorMsg.value = getErrorMessage(err, '更新失败，请重试')
  } finally {
    profileSaving.value = false
  }
}

async function handleChangePassword() {
  passwordErrorMsg.value = ''
  passwordSuccessMsg.value = ''

  if (!passwordForm.oldPassword) {
    passwordErrorMsg.value = '请输入旧密码'
    return
  }
  if (!passwordForm.newPassword || passwordForm.newPassword.length < 6) {
    passwordErrorMsg.value = '新密码至少 6 位'
    return
  }
  if (passwordForm.newPassword !== passwordForm.confirmPassword) {
    passwordErrorMsg.value = '两次输入的新密码不一致'
    return
  }
  if (passwordForm.oldPassword === passwordForm.newPassword) {
    passwordErrorMsg.value = '新密码不能与旧密码相同'
    return
  }

  passwordSaving.value = true

  try {
    const data: UpdatePasswordRequest = {
      oldPassword: passwordForm.oldPassword,
      newPassword: passwordForm.newPassword,
    }
    await updatePassword(data)
    passwordSuccessMsg.value = '密码修改成功'
    passwordForm.oldPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
  } catch (err: unknown) {
    passwordErrorMsg.value = getErrorMessage(err, '密码修改失败，请重试')
  } finally {
    passwordSaving.value = false
  }
}
</script>

<template>
  <div class="profile-container">
    <!-- 加载中 -->
    <div v-if="pageLoading" class="loading-state">
      <div class="spinner"></div>
      <p>加载中...</p>
    </div>

    <template v-else-if="authStore.user">
      <!-- ========== 头部信息卡片 ========== -->
      <section class="profile-header">
        <div class="header-card">
          <div class="avatar-section">
            <div class="avatar-circle">
              <span class="avatar-letter">{{ getAvatarLetter() }}</span>
            </div>
            <div class="user-meta">
              <h1 class="user-name">{{ authStore.user.nickname || authStore.user.username }}</h1>
              <p class="user-email">{{ authStore.user.email }}</p>
              <div class="badge-row">
                <span class="role-badge" :class="authStore.user.role.toLowerCase()">
                  {{ getRoleLabel(authStore.user.role) }}
                </span>
                <span class="status-dot" :class="authStore.user.status.toLowerCase()"></span>
                <span class="status-text">{{ getStatusLabel(authStore.user.status) }}</span>
              </div>
            </div>
          </div>
          <div class="stats-row">
            <div class="stat-item">
              <span class="stat-value">{{ authStore.user.points }}</span>
              <span class="stat-label">积分</span>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-item">
              <span class="stat-value">{{ authStore.user.streakDays }}</span>
              <span class="stat-label">连续签到(天)</span>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-item">
              <span class="stat-value">{{ formatDate(authStore.user.createdAt) }}</span>
              <span class="stat-label">注册时间</span>
            </div>
          </div>
        </div>
      </section>

      <!-- ========== 编辑资料卡片 ========== -->
      <section class="profile-section">
        <div class="section-card">
          <div class="section-header">
            <svg class="section-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
              <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
            </svg>
            <h2 class="section-title">编辑资料</h2>
          </div>

          <!-- 成功/错误提示 -->
          <div v-if="successMsg" class="msg-banner success">
            <svg class="msg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
              <polyline points="22 4 12 14.01 9 11.01" />
            </svg>
            {{ successMsg }}
          </div>
          <div v-if="errorMsg" class="msg-banner error">
            <svg class="msg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10" />
              <line x1="15" y1="9" x2="9" y2="15" />
              <line x1="9" y1="9" x2="15" y2="15" />
            </svg>
            {{ errorMsg }}
          </div>

          <div class="form-group">
            <label class="form-label" for="nickname">昵称</label>
            <input
              id="nickname"
              v-model="editNickname"
              type="text"
              class="form-input"
              placeholder="请输入昵称"
            />
          </div>

          <div class="form-group">
            <label class="form-label">用户名</label>
            <input
              type="text"
              class="form-input disabled"
              :value="authStore.user.username"
              disabled
            />
          </div>

          <div class="form-group">
            <label class="form-label">邮箱</label>
            <input
              type="email"
              class="form-input disabled"
              :value="authStore.user.email"
              disabled
            />
          </div>

          <button class="save-btn" :disabled="profileSaving" @click="handleSaveProfile">
            <span v-if="profileSaving" class="btn-spinner"></span>
            {{ profileSaving ? '保存中...' : '保存修改' }}
          </button>
        </div>
      </section>

      <!-- ========== 修改密码卡片 ========== -->
      <section class="profile-section">
        <div class="section-card">
          <div class="section-header">
            <svg class="section-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <h2 class="section-title">修改密码</h2>
          </div>

          <div v-if="passwordSuccessMsg" class="msg-banner success">
            <svg class="msg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
              <polyline points="22 4 12 14.01 9 11.01" />
            </svg>
            {{ passwordSuccessMsg }}
          </div>
          <div v-if="passwordErrorMsg" class="msg-banner error">
            <svg class="msg-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10" />
              <line x1="15" y1="9" x2="9" y2="15" />
              <line x1="9" y1="9" x2="15" y2="15" />
            </svg>
            {{ passwordErrorMsg }}
          </div>

          <div class="form-group">
            <label class="form-label" for="oldPassword">旧密码</label>
            <input
              id="oldPassword"
              v-model="passwordForm.oldPassword"
              type="password"
              class="form-input"
              placeholder="请输入旧密码"
              autocomplete="current-password"
            />
          </div>

          <div class="form-group">
            <label class="form-label" for="newPassword">新密码</label>
            <input
              id="newPassword"
              v-model="passwordForm.newPassword"
              type="password"
              class="form-input"
              placeholder="至少 6 位"
              autocomplete="new-password"
            />
          </div>

          <div class="form-group">
            <label class="form-label" for="confirmPassword">确认新密码</label>
            <input
              id="confirmPassword"
              v-model="passwordForm.confirmPassword"
              type="password"
              class="form-input"
              placeholder="再次输入新密码"
              autocomplete="new-password"
            />
          </div>

          <button class="save-btn" :disabled="passwordSaving" @click="handleChangePassword">
            <span v-if="passwordSaving" class="btn-spinner"></span>
            {{ passwordSaving ? '修改中...' : '修改密码' }}
          </button>
        </div>
      </section>
    </template>

    <!-- 未登录/无用户数据 -->
    <div v-else class="empty-state">
      <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
        <circle cx="12" cy="7" r="4" />
      </svg>
      <p>无法获取用户信息</p>
    </div>
  </div>
</template>

<style scoped>
/* ========== 容器 ========== */
.profile-container {
  max-width: 720px;
  margin: 0 auto;
  padding: 32px 24px 60px;
}

/* ========== 加载状态 ========== */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 100px 0;
  color: #86868b;
}

.loading-state .spinner {
  width: 36px;
  height: 36px;
  border: 3px solid #f1f1f3;
  border-top-color: #0071e3;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
  margin-bottom: 12px;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* ========== 空状态 ========== */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 100px 0;
  color: #86868b;
}

.empty-icon {
  width: 64px;
  height: 64px;
  margin-bottom: 16px;
  opacity: 0.4;
}

/* ========== 头部信息卡 ========== */
.profile-header {
  margin-bottom: 24px;
}

.header-card {
  background: #ffffff;
  border-radius: 20px;
  padding: 32px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}

.avatar-section {
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 28px;
}

.avatar-circle {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  background: linear-gradient(135deg, #0071e3 0%, #5ac8fa 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 4px 12px rgba(0, 113, 227, 0.2);
}

.avatar-letter {
  font-size: 28px;
  font-weight: 700;
  color: #ffffff;
  line-height: 1;
}

.user-meta {
  flex: 1;
  min-width: 0;
}

.user-name {
  font-size: 24px;
  font-weight: 700;
  color: #1d1d1f;
  margin-bottom: 4px;
  line-height: 1.3;
}

.user-email {
  font-size: 15px;
  color: #86868b;
  margin-bottom: 10px;
}

.badge-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.role-badge {
  padding: 3px 12px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 600;
}

.role-badge.admin {
  background: #fce4ec;
  color: #e91e63;
}

.role-badge.teacher {
  background: #e3f2fd;
  color: #0071e3;
}

.role-badge.student {
  background: #e8f5e9;
  color: #34c759;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.status-dot.active {
  background: #34c759;
}

.status-dot.banned {
  background: #ff3b30;
}

.status-dot.inactive {
  background: #ff9500;
}

.status-text {
  font-size: 13px;
  color: #86868b;
}

/* 统计行 */
.stats-row {
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding-top: 24px;
  border-top: 1px solid #f5f5f7;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: #1d1d1f;
}

.stat-label {
  font-size: 13px;
  color: #86868b;
}

.stat-divider {
  width: 1px;
  height: 36px;
  background: #f1f1f3;
}

/* ========== 内容区域卡片 ========== */
.profile-section {
  margin-bottom: 24px;
}

.section-card {
  background: #ffffff;
  border-radius: 20px;
  padding: 28px 32px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}

.section-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 24px;
}

.section-icon {
  width: 22px;
  height: 22px;
  color: #0071e3;
  flex-shrink: 0;
}

.section-title {
  font-size: 18px;
  font-weight: 700;
  color: #1d1d1f;
}

/* ========== 消息提示 ========== */
.msg-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  border-radius: 12px;
  font-size: 14px;
  margin-bottom: 20px;
}

.msg-banner.success {
  background: #f0fff4;
  border: 1px solid #9ae6b4;
  color: #276749;
}

.msg-banner.error {
  background: #fff5f5;
  border: 1px solid #feb2b2;
  color: #c53030;
}

.msg-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

/* ========== 表单 ========== */
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

.form-input {
  width: 100%;
  padding: 12px 16px;
  border: 1.5px solid #d2d2d7;
  border-radius: 12px;
  font-size: 15px;
  color: #1d1d1f;
  background: #ffffff;
  outline: none;
  transition: border-color 0.3s ease, box-shadow 0.3s ease;
  box-sizing: border-box;
}

.form-input:focus {
  border-color: #0071e3;
  box-shadow: 0 0 0 3px rgba(0, 113, 227, 0.12);
}

.form-input::placeholder {
  color: #86868b;
}

.form-input.disabled {
  background: #f5f5f7;
  color: #86868b;
  cursor: not-allowed;
}

/* ========== 保存按钮 ========== */
.save-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 9999px;
  background: #0071e3;
  color: #ffffff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 4px;
}

.save-btn:hover:not(:disabled) {
  background: #0066cc;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 113, 227, 0.3);
}

.save-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-spinner {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 2.5px solid rgba(255, 255, 255, 0.3);
  border-top-color: #ffffff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

/* ========== 响应式 ========== */
@media (max-width: 640px) {
  .profile-container {
    padding: 20px 16px 40px;
  }

  .header-card {
    padding: 24px 20px;
  }

  .section-card {
    padding: 24px 20px;
  }

  .avatar-section {
    flex-direction: column;
    text-align: center;
  }

  .badge-row {
    justify-content: center;
  }

  .stats-row {
    flex-direction: column;
    gap: 16px;
  }

  .stat-divider {
    width: 60px;
    height: 1px;
  }

  .user-name {
    font-size: 20px;
  }
}
</style>
