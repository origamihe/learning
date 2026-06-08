<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { listCourses } from '@/api/course'
import type { Course } from '@/types/api'
import { CourseDifficulty } from '@/types/api'

const router = useRouter()

const courses = ref<Course[]>([])
const loading = ref(true)
const keyword = ref('')
const selectedDifficulty = ref<CourseDifficulty | ''>('')
const currentPage = ref(1)
const totalPages = ref(1)

const difficultyLabel: Record<string, string> = {
  BEGINNER: '初级',
  INTERMEDIATE: '中级',
  ADVANCED: '高级',
}

const difficultyColor: Record<string, string> = {
  BEGINNER: '#34c759',
  INTERMEDIATE: '#0071e3',
  ADVANCED: '#ff9500',
}

async function fetchCourses() {
  loading.value = true
  try {
    const params: any = { page: currentPage.value, size: 12 }
    if (keyword.value.trim()) params.keyword = keyword.value.trim()
    if (selectedDifficulty.value) params.difficulty = selectedDifficulty.value
    const res = await listCourses(params)
    courses.value = res.records
    totalPages.value = res.pages
  } catch {
    courses.value = []
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  currentPage.value = 1
  fetchCourses()
}

function goToCourseDetail(id: string) {
  router.push(`/courses/${id}`)
}

function goToPage(page: number) {
  currentPage.value = page
  fetchCourses()
}

onMounted(() => {
  fetchCourses()
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">课程列表</h1>
      <p class="page-subtitle">选择一门课程，开始你的学习之旅</p>
    </div>
    <div class="filter-bar">
      <div class="search-box">
        <input v-model="keyword" type="text" class="search-input" placeholder="搜索课程..." @keyup.enter="handleSearch"/>
      </div>
      <div class="filter-btns">
        <button v-for="d in ['', 'BEGINNER', 'INTERMEDIATE', 'ADVANCED']" :key="d" :class="['filter-btn', { active: selectedDifficulty === d }]" @click="selectedDifficulty = d as any; handleSearch()">{{ d === '' ? '全部' : difficultyLabel[d] }}</button>
      </div>
    </div>
    <div v-if="loading" class="loading-state"><div class="spinner"></div><p>加载中...</p></div>
    <div v-else-if="courses.length === 0" class="empty-state">
      <p>暂无课程</p>
    </div>
    <div v-else class="course-grid">
      <div v-for="course in courses" :key="course.id" class="course-card" @click="goToCourseDetail(course.id)">
        <div class="card-cover">
          <div class="cover-placeholder"></div>
          <span class="difficulty-badge" :style="{ background: difficultyColor[course.difficulty] }">{{ difficultyLabel[course.difficulty] || course.difficulty }}</span>
        </div>
        <div class="card-body">
          <h3 class="card-title">{{ course.title }}</h3>
          <p class="card-desc">{{ course.description || '暂无简介' }}</p>
        </div>
      </div>
    </div>
    <div v-if="totalPages > 1" class="pagination">
      <button :disabled="currentPage === 1" class="page-btn" @click="goToPage(currentPage - 1)">上一页</button>
      <span class="page-info">{{ currentPage }} / {{ totalPages }}</span>
      <button :disabled="currentPage === totalPages" class="page-btn" @click="goToPage(currentPage + 1)">下一页</button>
    </div>
  </div>
</template>

<style scoped>
.page-container { max-width: 1200px; margin: 0 auto; padding: 32px 24px; }
.page-header { margin-bottom: 28px; }
.page-title { font-size: 28px; font-weight: 700; color: #1d1d1f; margin-bottom: 6px; }
.page-subtitle { font-size: 15px; color: #86868b; }
.filter-bar { display: flex; align-items: center; gap: 16px; margin-bottom: 28px; flex-wrap: wrap; }
.search-box { position: relative; flex: 1; min-width: 200px; max-width: 360px; }
.search-icon { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); width: 18px; height: 18px; color: #86868b; }
.search-input { width: 100%; padding: 10px 14px 10px 40px; border: 1.5px solid #d2d2d7; border-radius: 12px; font-size: 15px; color: #1d1d1f; outline: none; }
.search-input:focus { border-color: #0071e3; }
.filter-btns { display: flex; gap: 8px; }
.filter-btn { padding: 8px 18px; border: 1.5px solid #d2d2d7; border-radius: 9999px; background: #fff; color: #1d1d1f; font-size: 14px; font-weight: 500; cursor: pointer; }
.filter-btn:hover { background: #f5f5f7; }
.filter-btn.active { background: #1d1d1f; color: #fff; border-color: #1d1d1f; }
.loading-state, .empty-state { display: flex; flex-direction: column; align-items: center; padding: 80px 0; color: #86868b; }
.loading-state .spinner { width: 36px; height: 36px; border: 3px solid #f1f1f3; border-top-color: #0071e3; border-radius: 50%; animation: spin 0.6s linear infinite; margin-bottom: 12px; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-icon { width: 64px; height: 64px; margin-bottom: 16px; opacity: 0.4; }
.course-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
.course-card { background: #fff; border-radius: 16px; overflow: hidden; cursor: pointer; transition: all 0.3s; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
.course-card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.1); }
.card-cover { position: relative; height: 160px; }
.cover-placeholder { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
.cover-icon { width: 48px; height: 48px; color: rgba(255,255,255,0.5); }
.difficulty-badge { position: absolute; top: 12px; right: 12px; padding: 4px 12px; border-radius: 9999px; font-size: 12px; font-weight: 600; color: #fff; }
.card-body { padding: 16px 20px 20px; }
.card-title { font-size: 17px; font-weight: 600; color: #1d1d1f; margin-bottom: 8px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.card-desc { font-size: 14px; color: #86868b; line-height: 1.5; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; margin-bottom: 12px; }
.card-footer { display: flex; justify-content: flex-end; }
.card-status { font-size: 12px; padding: 4px 10px; border-radius: 9999px; font-weight: 500; }
.card-status.published { background: #e8f5e9; color: #34c759; }
.card-status.draft { background: #fff3e0; color: #ff9500; }
.card-status.archived { background: #f1f1f3; color: #86868b; }
.pagination { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 32px; }
.page-btn { padding: 8px 20px; border: 1.5px solid #d2d2d7; border-radius: 9999px; background: #fff; color: #1d1d1f; font-size: 14px; cursor: pointer; }
.page-btn:hover:not(:disabled) { background: #f5f5f7; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-info { font-size: 14px; color: #86868b; }
</style>
