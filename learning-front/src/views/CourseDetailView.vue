<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { getCourse } from '@/api/course'
import { getSectionsByCourse } from '@/api/section'
import { getProgress, updateProgress, getCompletionRate } from '@/api/progress'
import type { Course, CourseSection, UserLearningProgress } from '@/types/api'

const router = useRouter()
const route = useRoute()

const courseId = route.params.id as string

const course = ref<Course | null>(null)
const sections = ref<CourseSection[]>([])
const progress = ref<UserLearningProgress | null>(null)
const completionRate = ref(0)
const loading = ref(true)
const activeSectionId = ref<string | null>(null)

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

const completedSectionIds = computed(() => {
  if (!progress.value?.completedSections) return []
  try {
    return JSON.parse(progress.value.completedSections) as string[]
  } catch {
    return []
  }
})

const activeSection = computed(() => {
  return sections.value.find((s) => s.id === activeSectionId.value) || null
})

function isSectionCompleted(sectionId: string) {
  return completedSectionIds.value.includes(sectionId)
}

async function fetchCourseDetail() {
  loading.value = true
  try {
    const [courseRes, sectionsRes, progressRes, rateRes] = await Promise.all([
      getCourse(courseId),
      getSectionsByCourse(courseId),
      getProgress(courseId).catch(() => null),
      getCompletionRate(courseId).catch(() => ({ completionRate: 0 })),
    ])
    course.value = courseRes
    sections.value = sectionsRes.sort((a, b) => a.sortOrder - b.sortOrder)
    progress.value = progressRes
    completionRate.value = rateRes.completionRate

    if (progressRes?.lastSectionId) {
      activeSectionId.value = progressRes.lastSectionId
    } else if (sectionsRes.length > 0) {
      activeSectionId.value = sectionsRes[0].id
    }
  } catch {
    course.value = null
    sections.value = []
  } finally {
    loading.value = false
  }
}

async function selectSection(sectionId: string) {
  activeSectionId.value = sectionId
  try {
    await updateProgress(courseId, sectionId)
    const rateRes = await getCompletionRate(courseId)
    completionRate.value = rateRes.completionRate
    const progressRes = await getProgress(courseId)
    progress.value = progressRes
  } catch {
    // 静默处理进度更新失败
  }
}

function goToPractice() {
  router.push(`/courses/${courseId}/practice`)
}

function goBack() {
  router.push('/courses')
}

onMounted(() => {
  fetchCourseDetail()
})
</script>

<template>
  <div class="page-container">
    <!-- 返回按钮 -->
    <button class="back-btn" @click="goBack">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="15 18 9 12 15 6" />
      </svg>
      返回课程列表
    </button>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>加载课程信息...</p>
    </div>

    <!-- 课程不存在 -->
    <div v-else-if="!course" class="empty-state">
      <p>课程不存在或已被删除</p>
      <button class="hero-btn" @click="goBack">返回课程列表</button>
    </div>

    <!-- 课程详情主体 -->
    <template v-else>
      <!-- 课程头部信息 -->
      <div class="course-header">
        <div class="header-top">
          <div class="header-info">
            <h1 class="course-title">{{ course.title }}</h1>
            <div class="header-meta">
              <span
                class="difficulty-badge"
                :style="{ background: difficultyColor[course.difficulty] }"
              >
                {{ difficultyLabel[course.difficulty] || course.difficulty }}
              </span>
              <span v-if="course.tags" class="tags-text">{{ course.tags }}</span>
            </div>
            <p class="course-desc">{{ course.description || '暂无课程简介' }}</p>
          </div>
          <button class="practice-btn" @click="goToPractice">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18">
              <path d="M9 11l3 3L22 4" />
              <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
            </svg>
            章节练习
          </button>
        </div>
        <!-- 进度条 -->
        <div class="progress-section">
          <div class="progress-header">
            <span class="progress-label">学习进度</span>
            <span class="progress-percent">{{ Math.round(completionRate) }}%</span>
          </div>
          <div class="progress-bar">
            <div
              class="progress-fill"
              :style="{ width: completionRate + '%' }"
            ></div>
          </div>
        </div>
      </div>

      <!-- 两栏布局 -->
      <div class="content-layout">
        <!-- 左侧章节侧边栏 -->
        <aside class="section-sidebar">
          <div class="sidebar-header">
            <h3>课程章节</h3>
            <span class="chapter-count">共 {{ sections.length }} 章</span>
          </div>
          <div v-if="sections.length === 0" class="sidebar-empty">
            <p>暂无章节内容</p>
          </div>
          <ul v-else class="section-list">
            <li
              v-for="section in sections"
              :key="section.id"
              :class="[
                'section-item',
                { active: activeSectionId === section.id },
              ]"
              @click="selectSection(section.id)"
            >
              <div class="section-index">
                <span v-if="isSectionCompleted(section.id)" class="check-icon">✓</span>
                <span v-else class="index-num">{{ section.sortOrder }}</span>
              </div>
              <div class="section-info">
                <span class="section-title">{{ section.title }}</span>
                <span v-if="section.duration" class="section-duration">
                  {{ section.duration }} 分钟
                </span>
              </div>
            </li>
          </ul>
        </aside>

        <!-- 右侧内容区域 -->
        <main class="content-main">
          <div v-if="!activeSection" class="content-placeholder">
            <h2>{{ course.title }}</h2>
            <p>请从左侧选择一个章节开始学习</p>
          </div>
          <div v-else class="content-body">
            <div class="content-header">
              <h2 class="content-title">{{ activeSection.title }}</h2>
              <span v-if="activeSection.duration" class="content-duration">
                ⏱ {{ activeSection.duration }} 分钟
              </span>
            </div>
            <div class="content-text">
              <div v-if="activeSection.content" v-html="activeSection.content"></div>
              <p v-else class="no-content">该章节暂无内容</p>
            </div>
          </div>
        </main>
      </div>
    </template>
  </div>
</template>

<style scoped>
.page-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px 24px 48px;
}

/* 返回按钮 */
.back-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border: none;
  border-radius: 10px;
  background: #f5f5f7;
  color: #1d1d1f;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
  margin-bottom: 20px;
}

.back-btn:hover {
  background: #e8e8ed;
}

.back-btn svg {
  width: 18px;
  height: 18px;
}

/* 加载 & 空状态 */
.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 80px 0;
  color: #86868b;
  gap: 16px;
}

.spinner {
  width: 36px;
  height: 36px;
  border: 3px solid #f1f1f3;
  border-top-color: #0071e3;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.hero-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 24px;
  border: none;
  border-radius: 9999px;
  background: #0071e3;
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.hero-btn:hover {
  background: #0066cc;
  box-shadow: 0 4px 16px rgba(0, 113, 227, 0.3);
}

/* 课程头部 */
.course-header {
  background: #fff;
  border-radius: 16px;
  padding: 28px 32px;
  margin-bottom: 24px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}

.header-top {
  display: flex;
  align-items: flex-start;
  gap: 24px;
}

.header-info {
  flex: 1;
}

.course-title {
  font-size: 26px;
  font-weight: 700;
  color: #1d1d1f;
  margin: 0 0 12px;
  letter-spacing: -0.3px;
}

.header-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.difficulty-badge {
  display: inline-block;
  padding: 4px 14px;
  border-radius: 9999px;
  font-size: 13px;
  font-weight: 600;
  color: #fff;
}

.tags-text {
  font-size: 13px;
  color: #86868b;
}

.course-desc {
  font-size: 15px;
  color: #515154;
  line-height: 1.6;
  margin: 0;
}

.practice-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 22px;
  border: none;
  border-radius: 9999px;
  background: #0071e3;
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;
  flex-shrink: 0;
}

.practice-btn:hover {
  background: #0066cc;
  box-shadow: 0 4px 16px rgba(0, 113, 227, 0.3);
  transform: translateY(-1px);
}

.practice-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 22px;
  border: none;
  border-radius: 9999px;
  background: #0071e3;
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;
  flex-shrink: 0;
}

.practice-btn:hover {
  background: #0066cc;
  box-shadow: 0 4px 16px rgba(0, 113, 227, 0.3);
  transform: translateY(-1px);
}

/* 进度条 */
.progress-section {
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #f1f1f3;
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.progress-label {
  font-size: 14px;
  font-weight: 500;
  color: #1d1d1f;
}

.progress-percent {
  font-size: 14px;
  font-weight: 600;
  color: #0071e3;
}

.progress-bar {
  width: 100%;
  height: 8px;
  background: #f1f1f3;
  border-radius: 9999px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #0071e3, #34c759);
  border-radius: 9999px;
  transition: width 0.5s ease;
}

/* 两栏布局 */
.content-layout {
  display: flex;
  gap: 24px;
  align-items: flex-start;
}

/* 左侧章节侧边栏 */
.section-sidebar {
  width: 320px;
  flex-shrink: 0;
  background: #fff;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  position: sticky;
  top: 24px;
}

.sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 20px;
  border-bottom: 1px solid #f1f1f3;
}

.sidebar-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.chapter-count {
  font-size: 13px;
  color: #86868b;
}

.sidebar-empty {
  padding: 40px 20px;
  text-align: center;
  color: #86868b;
  font-size: 14px;
}

.section-list {
  list-style: none;
  margin: 0;
  padding: 0;
  max-height: 520px;
  overflow-y: auto;
}

.section-item {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 20px;
  cursor: pointer;
  transition: background 0.2s;
  border-bottom: 1px solid #f5f5f7;
}

.section-item:hover {
  background: #fafafa;
}

.section-item.active {
  background: rgba(0, 113, 227, 0.05);
  border-left: 3px solid #0071e3;
}

.section-index {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #f5f5f7;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.section-item.active .section-index {
  background: #0071e3;
  color: #fff;
}

.index-num {
  font-size: 13px;
  font-weight: 600;
  color: #86868b;
}

.section-item.active .index-num {
  color: #fff;
}

.check-icon {
  font-size: 14px;
  font-weight: 700;
  color: #34c759;
}

.section-item.active .check-icon {
  color: #fff;
}

.section-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.section-title {
  font-size: 14px;
  font-weight: 500;
  color: #1d1d1f;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.section-duration {
  font-size: 12px;
  color: #86868b;
}

/* 右侧内容区域 */
.content-main {
  flex: 1;
  min-width: 0;
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  min-height: 400px;
}

.content-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 40px;
  color: #86868b;
}

.content-placeholder h2 {
  font-size: 22px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0 0 8px;
}

.content-placeholder p {
  font-size: 15px;
  margin: 0;
}

.content-body {
  padding: 28px 32px 40px;
}

.content-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid #f1f1f3;
}

.content-title {
  font-size: 22px;
  font-weight: 700;
  color: #1d1d1f;
  margin: 0;
}

.content-duration {
  font-size: 14px;
  color: #86868b;
}

.content-text {
  font-size: 16px;
  line-height: 1.8;
  color: #1d1d1f;
}

.no-content {
  color: #86868b;
  text-align: center;
  padding: 40px 0;
}

/* 响应式 */
@media (max-width: 768px) {
  .content-layout {
    flex-direction: column;
  }

  .section-sidebar {
    width: 100%;
    position: static;
  }

  .section-list {
    max-height: none;
  }

  .course-header {
    padding: 20px;
  }

  .course-title {
    font-size: 22px;
  }

  .content-body {
    padding: 20px;
  }
}
</style>
