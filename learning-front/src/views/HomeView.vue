<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { listCourses } from '@/api/course'
import type { Course } from '@/types/api'

const router = useRouter()
const authStore = useAuthStore()

const featuredCourses = ref<Course[]>([])
const loading = ref(true)

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

async function loadFeatured() {
  loading.value = true
  try {
    const res = await listCourses({ page: 1, size: 6 })
    featuredCourses.value = res.records
  } catch {
    featuredCourses.value = []
  } finally {
    loading.value = false
  }
}

function goToCourses() {
  router.push('/courses')
}

function goToCourseDetail(id: string) {
  router.push(`/courses/${id}`)
}

onMounted(() => {
  loadFeatured()
})
</script>

<template>
  <div class="home-container">
    <!-- Hero 区域 -->
    <section class="hero">
      <h1 class="hero-title">
        你好，{{ authStore.user?.nickname || authStore.user?.username }} 👋
      </h1>
      <p class="hero-subtitle">
        今天想学点什么？选择一门课程，开启你的学习之旅
      </p>
      <button class="hero-btn" @click="goToCourses">
        浏览全部课程
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="5" y1="12" x2="19" y2="12" />
          <polyline points="12 5 19 12 12 19" />
        </svg>
      </button>
    </section>

    <!-- 推荐课程 -->
    <section class="featured-section">
      <h2 class="section-title">推荐课程</h2>
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>加载中...</p>
      </div>
      <div v-else-if="featuredCourses.length === 0" class="empty-state">
        <p>暂无课程，请稍后再来</p>
      </div>
      <div v-else class="featured-grid">
        <div
          v-for="course in featuredCourses"
          :key="course.id"
          class="featured-card"
          @click="goToCourseDetail(course.id)"
        >
          <div class="card-cover">
            <div class="cover-bg"></div>
            <span class="difficulty-tag" :style="{ background: difficultyColor[course.difficulty] }">
              {{ difficultyLabel[course.difficulty] || course.difficulty }}
            </span>
          </div>
          <div class="card-info">
            <h3 class="card-title">{{ course.title }}</h3>
            <p class="card-desc">{{ course.description || '暂无简介' }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- 统计信息 -->
    <section class="stats-section">
      <div class="stat-item">
        <span class="stat-num">{{ featuredCourses.length }}+</span>
        <span class="stat-label">精品课程</span>
      </div>
      <div class="stat-item">
        <span class="stat-num">3</span>
        <span class="stat-label">难度等级</span>
      </div>
      <div class="stat-item">
        <span class="stat-num">24/7</span>
        <span class="stat-label">随时学习</span>
      </div>
    </section>
  </div>
</template>

<style scoped>
.home-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 24px;
}

/* Hero */
.hero {
  text-align: center;
  padding: 60px 0 48px;
}

.hero-title {
  font-size: 36px;
  font-weight: 700;
  color: #1d1d1f;
  margin-bottom: 12px;
  letter-spacing: -0.5px;
}

.hero-subtitle {
  font-size: 18px;
  color: #86868b;
  margin-bottom: 28px;
  line-height: 1.5;
}

.hero-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 28px;
  border: none;
  border-radius: 9999px;
  background: #0071e3;
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.hero-btn:hover {
  background: #0066cc;
  box-shadow: 0 4px 16px rgba(0, 113, 227, 0.3);
  transform: translateY(-1px);
}

.hero-btn svg {
  width: 18px;
  height: 18px;
}

/* 推荐课程 */
.featured-section {
  padding: 16px 0 48px;
}

.section-title {
  font-size: 24px;
  font-weight: 700;
  color: #1d1d1f;
  margin-bottom: 20px;
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 60px 0;
  color: #86868b;
}

.spinner {
  width: 32px;
  height: 32px;
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

.featured-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 20px;
}

.featured-card {
  background: #fff;
  border-radius: 16px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}

.featured-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
}

.card-cover {
  height: 120px;
  position: relative;
}

.cover-bg {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.difficulty-tag {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 3px 10px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 600;
  color: #fff;
}

.card-info {
  padding: 14px 18px 18px;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
  margin-bottom: 6px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-desc {
  font-size: 13px;
  color: #86868b;
  line-height: 1.4;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

/* 统计 */
.stats-section {
  display: flex;
  justify-content: center;
  gap: 60px;
  padding: 40px 0 60px;
  border-top: 1px solid #f1f1f3;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.stat-num {
  font-size: 28px;
  font-weight: 700;
  color: #1d1d1f;
}

.stat-label {
  font-size: 14px;
  color: #86868b;
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 26px;
  }

  .stats-section {
    gap: 32px;
  }
}
</style>
