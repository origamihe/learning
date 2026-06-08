<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getUserById } from '@/api/user'
import type { User } from '@/types/api'

const users = ref<User[]>([])
const loading = ref(true)
const keyword = ref('')

async function loadUsers() {
  loading.value = true
  try {
    // 用户管理 API 暂用占位数据演示
    users.value = []
  } catch {
    users.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => { loadUsers() })
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">用户管理</h1>
      <p class="page-subtitle">管理系统中的所有用户</p>
    </div>
    <div class="toolbar">
      <div class="search-box">
        <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input v-model="keyword" type="text" class="search-input" placeholder="搜索用户名或邮箱..."/>
      </div>
    </div>
    <div v-if="loading" class="loading-state"><div class="spinner"></div><p>加载中...</p></div>
    <div v-else-if="users.length === 0" class="empty-state">
      <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      <p>暂无用户数据</p>
    </div>
    <div v-else class="table-wrapper">
      <table class="data-table">
        <thead><tr><th>用户名</th><th>邮箱</th><th>角色</th><th>状态</th><th>积分</th><th>注册时间</th><th>操作</th></tr></thead>
        <tbody>
          <tr v-for="user in users" :key="user.id">
            <td><span class="user-name">{{ user.username }}</span></td>
            <td>{{ user.email }}</td>
            <td><span class="role-badge" :class="user.role.toLowerCase()">{{ user.role }}</span></td>
            <td><span class="status-dot" :class="user.status.toLowerCase()"></span>{{ user.status === 'ACTIVE' ? '正常' : user.status === 'BANNED' ? '封禁' : '未激活' }}</td>
            <td>{{ user.points }}</td>
            <td>{{ new Date(user.createdAt).toLocaleDateString() }}</td>
            <td><button class="action-btn">查看</button></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<style scoped>
.page-container { max-width: 1200px; margin: 0 auto; padding: 32px 24px; }
.page-header { margin-bottom: 28px; }
.page-title { font-size: 28px; font-weight: 700; color: #1d1d1f; margin-bottom: 6px; }
.page-subtitle { font-size: 15px; color: #86868b; }
.toolbar { margin-bottom: 20px; }
.search-box { position: relative; max-width: 320px; }
.search-icon { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); width: 18px; height: 18px; color: #86868b; }
.search-input { width: 100%; padding: 10px 14px 10px 40px; border: 1.5px solid #d2d2d7; border-radius: 12px; font-size: 15px; color: #1d1d1f; outline: none; }
.search-input:focus { border-color: #0071e3; }
.loading-state, .empty-state { display: flex; flex-direction: column; align-items: center; padding: 80px 0; color: #86868b; }
.loading-state .spinner { width: 36px; height: 36px; border: 3px solid #f1f1f3; border-top-color: #0071e3; border-radius: 50%; animation: spin 0.6s linear infinite; margin-bottom: 12px; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-icon { width: 64px; height: 64px; margin-bottom: 16px; opacity: 0.4; }
.table-wrapper { background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
.data-table { width: 100%; border-collapse: collapse; }
.data-table th { text-align: left; padding: 14px 20px; font-size: 13px; font-weight: 600; color: #86868b; background: #fafafa; border-bottom: 1px solid #f1f1f3; }
.data-table td { padding: 14px 20px; font-size: 14px; color: #1d1d1f; border-bottom: 1px solid #f5f5f7; }
.data-table tr:hover td { background: #fafafa; }
.user-name { font-weight: 600; }
.role-badge { padding: 4px 10px; border-radius: 9999px; font-size: 12px; font-weight: 500; }
.role-badge.admin { background: #fce4ec; color: #e91e63; }
.role-badge.teacher { background: #e3f2fd; color: #0071e3; }
.role-badge.student { background: #e8f5e9; color: #34c759; }
.status-dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; margin-right: 8px; }
.status-dot.active { background: #34c759; }
.status-dot.banned { background: #ff3b30; }
.status-dot.inactive { background: #ff9500; }
.action-btn { padding: 6px 14px; border: 1.5px solid #d2d2d7; border-radius: 9999px; background: #fff; color: #0071e3; font-size: 13px; cursor: pointer; transition: all 0.3s; }
.action-btn:hover { background: #0071e3; color: #fff; border-color: #0071e3; }
</style>
