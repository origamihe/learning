<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { listCourses } from '@/api/course'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const stats = ref({ courseCount: 0, userCount: 0 })

async function loadStats() {
  try {
    const res = await listCourses({ page: 1, size: 1 })
    stats.value.courseCount = res.total
  } catch { stats.value.courseCount = 0 }
}

onMounted(() => { loadStats() })
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">管理后台</h1>
      <p class="page-subtitle">欢迎回来，{{ authStore.user?.nickname || authStore.user?.username }}</p>
    </div>
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon" style="background: #e8f5e9;">
          <svg viewBox="0 0 24 24" fill="none" stroke="#34c759" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
        </div>
        <div class="stat-info"><span class="stat-value">{{ stats.courseCount }}</span><span class="stat-label">课程总数</span></div>
      </div>
      <div class="stat-card">
        <div class="stat-icon" style="background: #e3f2fd;">
          <svg viewBox="0 0 24 24" fill="none" stroke="#0071e3" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        </div>
        <div class="stat-info"><span class="stat-value">{{ stats.userCount }}</span><span class="stat-label">用户总数</span></div>
      </div>
    </div>
    <div class="quick-actions">
      <h2 class="section-title">快捷操作</h2>
      <div class="action-grid">
        <button class="action-card" @click="router.push('/admin/users')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          <span>用户管理</span>
        </button>
        <button class="action-card" @click="router.push('/admin/courses')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
          <span>课程管理</span>
        </button>
        <button class="action-card" @click="router.push('/admin/sections')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
          <span>章节管理</span>
        </button>
        <button class="action-card" @click="router.push('/admin/questions')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
          <span>题目管理</span>
        </button>
        <button class="action-card" @click="router.push('/admin/exams')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/><line x1="12" y1="11" x2="12" y2="17"/><line x1="9" y1="14" x2="15" y2="14"/></svg>
          <span>考试管理</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container { max-width: 1200px; margin: 0 auto; padding: 32px 24px; }
.page-header { margin-bottom: 28px; }
.page-title { font-size: 28px; font-weight: 700; color: #1d1d1f; margin-bottom: 6px; }
.page-subtitle { font-size: 15px; color: #86868b; }
.stats-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 16px; margin-bottom: 36px; }
.stat-card { background: #fff; border-radius: 16px; padding: 24px; display: flex; align-items: center; gap: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
.stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-icon svg { width: 24px; height: 24px; }
.stat-info { display: flex; flex-direction: column; }
.stat-value { font-size: 28px; font-weight: 700; color: #1d1d1f; }
.stat-label { font-size: 14px; color: #86868b; margin-top: 2px; }
.section-title { font-size: 20px; font-weight: 600; color: #1d1d1f; margin-bottom: 16px; }
.action-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 16px; }
.action-card { background: #fff; border: 1.5px solid #f1f1f3; border-radius: 16px; padding: 24px; display: flex; flex-direction: column; align-items: center; gap: 12px; cursor: pointer; transition: all 0.3s; color: #1d1d1f; font-size: 15px; font-weight: 500; }
.action-card:hover { border-color: #0071e3; box-shadow: 0 4px 12px rgba(0,113,227,0.1); transform: translateY(-2px); }
.action-card svg { width: 32px; height: 32px; color: #0071e3; }
</style>
