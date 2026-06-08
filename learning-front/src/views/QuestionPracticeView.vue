<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getCourse } from '@/api/course'
import { getSectionsByCourse } from '@/api/section'
import { listQuestions } from '@/api/question'
import { addWrongQuestion } from '@/api/wrongQuestion'
import type { Course, CourseSection, Question } from '@/types/api'
import { QuestionType } from '@/types/api'

const route = useRoute()
const router = useRouter()
const courseId = route.params.id as string

const course = ref<Course | null>(null)
const sections = ref<CourseSection[]>([])
const questions = ref<Question[]>([])
const loading = ref(true)
const questionsLoading = ref(false)

// 筛选
const selectedSectionId = ref<string>('')
const selectedType = ref<QuestionType | ''>('')

// 答题状态
const userAnswers = ref<Record<string, string>>({})
const submittedQuestions = ref<Set<string>>(new Set())
const correctAnswers = ref<Set<string>>(new Set())

// localStorage 持久化 key
const PRACTICE_STATE_KEY = `practice_state_${courseId}`

// 保存答题状态到 localStorage
function savePracticeState() {
  const state = {
    userAnswers: userAnswers.value,
    submittedQuestions: [...submittedQuestions.value],
    correctAnswers: [...correctAnswers.value],
  }
  localStorage.setItem(PRACTICE_STATE_KEY, JSON.stringify(state))
}

// 从 localStorage 恢复答题状态
function loadPracticeState() {
  try {
    const saved = localStorage.getItem(PRACTICE_STATE_KEY)
    if (saved) {
      const state = JSON.parse(saved)
      userAnswers.value = state.userAnswers || {}
      submittedQuestions.value = new Set(state.submittedQuestions || [])
      correctAnswers.value = new Set(state.correctAnswers || [])
    }
  } catch {
    // 忽略无效数据
  }
}

// 分页
const currentPage = ref(0)
const pageSize = 10
const totalRecords = ref(0)

const typeLabel: Record<string, string> = {
  SINGLE: '单选题',
  MULTIPLE: '多选题',
  JUDGE: '判断题',
  FILL: '填空题',
  PROGRAMMING: '编程题',
}

const typeTagColor: Record<string, string> = {
  SINGLE: '#0071e3',
  MULTIPLE: '#ff9500',
  JUDGE: '#34c759',
  FILL: '#af52de',
  PROGRAMMING: '#ff3b30',
}

// 已提交的题目总数
const submittedCount = computed(() => submittedQuestions.value.size)

// 正确数
const correctCount = computed(() => correctAnswers.value.size)

// 已加载的题目数
const loadedCount = computed(() => questions.value.length)

// 是否还有更多
const hasMore = computed(() => loadedCount.value < totalRecords.value)

const currentQuestions = computed(() => {
  return questions.value
})

function parseOptions(optionsStr?: string): string[] {
  if (!optionsStr) return []
  try {
    const arr: unknown = JSON.parse(optionsStr)
    if (Array.isArray(arr)) {
      return (arr as unknown[]).map((item) => {
        if (typeof item === 'string') return item
        if (typeof item === 'object' && item !== null) {
          const opt = item as Record<string, unknown>
          if (typeof opt.value === 'string') return opt.value
        }
        return String(item)
      })
    }
    return []
  } catch {
    return []
  }
}

function isChoiceType(type: QuestionType): boolean {
  return type === QuestionType.SINGLE || type === QuestionType.MULTIPLE
}

function isJudgeType(type: QuestionType): boolean {
  return type === QuestionType.JUDGE
}

function isFillType(type: QuestionType): boolean {
  return type === QuestionType.FILL
}

function isProgrammingType(type: QuestionType): boolean {
  return type === QuestionType.PROGRAMMING
}

async function fetchCourseInfo() {
  try {
    const [courseRes, sectionsRes] = await Promise.all([
      getCourse(courseId),
      getSectionsByCourse(courseId),
    ])
    course.value = courseRes
    sections.value = sectionsRes.sort((a, b) => a.sortOrder - b.sortOrder)
  } catch {
    course.value = null
    sections.value = []
  }
}

async function fetchQuestions(reset = false) {
  questionsLoading.value = true
  if (reset) {
    currentPage.value = 0
    questions.value = []
  }
  const nextPage = currentPage.value + 1
  try {
    const res = await listQuestions({
      page: nextPage,
      size: pageSize,
      courseId,
      sectionId: selectedSectionId.value || undefined,
      type: selectedType.value || undefined,
    })
    if (reset) {
      questions.value = res.records
    } else {
      questions.value.push(...res.records)
    }
    totalRecords.value = res.total
    currentPage.value = nextPage
  } catch {
    // handled by interceptor
  } finally {
    questionsLoading.value = false
  }
}

function loadMore() {
  fetchQuestions(false)
}

function handleFilterChange() {
  fetchQuestions(true)
}

function getAnswer(questionId: string): string {
  return userAnswers.value[questionId] || ''
}

function setSingleAnswer(questionId: string, value: string) {
  userAnswers.value[questionId] = value
}

function setMultipleAnswer(questionId: string, index: string, checked: boolean) {
  const current = userAnswers.value[questionId] || ''
  const arr = current ? current.split(',').filter(Boolean) : []
  if (checked) {
    if (!arr.includes(index)) arr.push(index)
  } else {
    const idx = arr.indexOf(index)
    if (idx !== -1) arr.splice(idx, 1)
  }
  userAnswers.value[questionId] = arr.join(',')
}

function isMultipleChecked(questionId: string, index: string): boolean {
  const current = userAnswers.value[questionId] || ''
  const arr = current ? current.split(',') : []
  return arr.includes(index)
}

function convertAnswerToIndex(answer: string, type: QuestionType): string {
  // 去除引号和多余空白
  let cleaned = answer.trim().replace(/^["']|["']$/g, '').trim()
  if (type === QuestionType.SINGLE || type === QuestionType.MULTIPLE) {
    const upper = cleaned.toUpperCase()
    if (/^[A-Z]$/.test(upper)) {
      const charCode = upper.charCodeAt(0)
      const index = charCode - 'A'.charCodeAt(0)
      return String(index)
    }
    return cleaned
  }
  return cleaned
}

function parseFillAnswer(answer?: string): string[] {
  if (!answer) return []
  try {
    const parsed = JSON.parse(answer)
    if (Array.isArray(parsed)) {
      return parsed.map((item: unknown) => String(item).trim()).filter(Boolean)
    }
  } catch { /* ignore */ }
  return [answer.trim()]
}

function checkAnswer(question: Question): boolean {
  let userAnswer = (userAnswers.value[question.id] || '').trim()
  let correctAnswer = (question.answer || '').trim()
  if (!userAnswer) return false

  if (question.type === QuestionType.SINGLE || question.type === QuestionType.MULTIPLE) {
    if (question.type === QuestionType.MULTIPLE) {
      const userArr = userAnswer.split(',').filter(Boolean).map(s => convertAnswerToIndex(s, question.type)).sort()
      const correctArr = correctAnswer.split(',').filter(Boolean).map(s => convertAnswerToIndex(s, question.type)).sort()
      return userArr.length === correctArr.length && userArr.every((v, i) => v === correctArr[i])
    } else {
      userAnswer = convertAnswerToIndex(userAnswer, question.type)
      correctAnswer = convertAnswerToIndex(correctAnswer, question.type)
      return userAnswer.toLowerCase() === correctAnswer.toLowerCase()
    }
  }

  if (question.type === QuestionType.FILL) {
    const parsed = parseFillAnswer(question.answer)
    return parsed.some(a => userAnswer.toLowerCase() === a.toLowerCase())
  }

  return userAnswer.toLowerCase() === correctAnswer.toLowerCase()
}

function submitAnswer(questionId: string) {
  const question = questions.value.find((q) => q.id === questionId)
  if (!question) return
  submittedQuestions.value.add(questionId)
  if (checkAnswer(question)) {
    correctAnswers.value.add(questionId)
  } else {
    markWrong(questionId)
  }
}

function hasSubmitted(questionId: string): boolean {
  return submittedQuestions.value.has(questionId)
}

function isCorrect(questionId: string): boolean {
  return correctAnswers.value.has(questionId)
}

function isWrong(questionId: string): boolean {
  return hasSubmitted(questionId) && !isCorrect(questionId)
}

function isCorrectOption(question: Question, idx: number): boolean {
  if (!question.answer) return false
  if (question.type === QuestionType.SINGLE) {
    const correctIdx = convertAnswerToIndex(question.answer, question.type)
    return correctIdx === String(idx)
  }
  if (question.type === QuestionType.MULTIPLE) {
    const correctArr = question.answer.split(',').filter(Boolean).map(s => convertAnswerToIndex(s, question.type))
    return correctArr.includes(String(idx))
  }
  return false
}

function isWrongOption(question: Question, idx: number): boolean {
  const userAnswer = getAnswer(question.id)
  if (!userAnswer) return false
  if (question.type === QuestionType.SINGLE) {
    return userAnswer === String(idx) && !isCorrectOption(question, idx)
  }
  if (question.type === QuestionType.MULTIPLE) {
    const userArr = userAnswer.split(',').map(s => s.trim())
    return userArr.includes(String(idx)) && !isCorrectOption(question, idx)
  }
  return false
}

function formatCorrectAnswer(question: Question): string {
  if (!question.answer) return '—'
  if (question.type === QuestionType.SINGLE) {
    const opts = parseOptions(question.options)
    const idxStr = convertAnswerToIndex(question.answer, question.type)
    const idx = parseInt(idxStr)
    if (!isNaN(idx) && opts[idx]) {
      return `${['A', 'B', 'C', 'D', 'E', 'F'][idx]}. ${opts[idx]}`
    }
    return question.answer
  }
  if (question.type === QuestionType.MULTIPLE) {
    const opts = parseOptions(question.options)
    const indices = question.answer.split(',').filter(Boolean).map(s => parseInt(convertAnswerToIndex(s, question.type)))
    return indices
      .filter(i => !isNaN(i))
      .map(i => {
        const label = ['A', 'B', 'C', 'D', 'E', 'F'][i]
        const text = opts[i] || `选项${i + 1}`
        return `${label}. ${text}`
      })
      .join('、')
  }
  if (question.type === QuestionType.FILL) {
    const parsed = parseFillAnswer(question.answer)
    return parsed.join(' / ')
  }
  if (question.type === QuestionType.JUDGE) {
    return question.answer === 'true' ? '✓ 正确' : '✗ 错误'
  }
  return question.answer
}

async function markWrong(questionId: string) {
  try {
    await addWrongQuestion(questionId)
  } catch {
    // handled by interceptor
  }
}

function goBack() {
  router.push(`/courses/${courseId}`)
}

function resetAll() {
  userAnswers.value = {}
  submittedQuestions.value = new Set()
  correctAnswers.value = new Set()
  localStorage.removeItem(PRACTICE_STATE_KEY)
  fetchQuestions(true)
}

watch([selectedSectionId, selectedType], () => {
  handleFilterChange()
})

// 自动保存答题状态
watch(
  [userAnswers, submittedQuestions, correctAnswers],
  () => {
    savePracticeState()
  },
  { deep: true }
)

onMounted(async () => {
  loading.value = true
  await fetchCourseInfo()
  loadPracticeState()
  await fetchQuestions(true)
  loading.value = false
})
</script>

<template>
  <div class="page-container">
    <!-- 返回按钮 -->
    <button class="back-btn" @click="goBack">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="15 18 9 12 15 6" />
      </svg>
      返回课程详情
    </button>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>加载题目中...</p>
    </div>

    <!-- 课程不存在 -->
    <div v-else-if="!course" class="empty-state">
      <p>课程不存在或已被删除</p>
      <button class="hero-btn" @click="goBack">返回课程详情</button>
    </div>

    <template v-else>
      <!-- 头部信息 -->
      <div class="practice-header">
        <div class="header-top">
          <div class="header-info">
            <h1 class="header-title">章节练习</h1>
            <p class="header-course">{{ course.title }}</p>
          </div>
          <button class="reset-btn" @click="resetAll">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
              <polyline points="23 4 23 10 17 10" />
              <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" />
            </svg>
            重新开始
          </button>
        </div>

        <!-- 统计栏 -->
        <div class="stats-bar">
          <div class="stat-item">
            <span class="stat-num">{{ loadedCount }}</span>
            <span class="stat-label">题目总数</span>
          </div>
          <div class="stat-divider"></div>
          <div class="stat-item">
            <span class="stat-num stat-correct">{{ submittedCount }}</span>
            <span class="stat-label">已作答</span>
          </div>
          <div class="stat-divider"></div>
          <div class="stat-item">
            <span class="stat-num stat-correct">{{ correctCount }}</span>
            <span class="stat-label">正确</span>
          </div>
          <div class="stat-divider"></div>
          <div class="stat-item">
            <span class="stat-num stat-wrong">{{ submittedCount - correctCount }}</span>
            <span class="stat-label">错误</span>
          </div>
        </div>

        <!-- 筛选区 -->
        <div class="filter-bar">
          <select v-model="selectedSectionId" class="filter-select">
            <option value="">全部章节</option>
            <option v-for="section in sections" :key="section.id" :value="section.id">
              {{ section.title }}
            </option>
          </select>
          <select v-model="selectedType" class="filter-select">
            <option value="">全部题型</option>
            <option value="SINGLE">单选题</option>
            <option value="MULTIPLE">多选题</option>
            <option value="JUDGE">判断题</option>
            <option value="FILL">填空题</option>
            <option value="PROGRAMMING">编程题</option>
          </select>
        </div>
      </div>

      <!-- 题目列表 -->
      <div v-if="questionsLoading && questions.length === 0" class="loading-state">
        <div class="spinner"></div>
        <p>加载题目中...</p>
      </div>

      <div v-else-if="questions.length === 0" class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="48" height="48" style="color: #c7c7cc;">
          <path d="M9 11l3 3L22 4" />
          <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
        </svg>
        <p>当前筛选条件下暂无题目</p>
      </div>

      <div v-else class="questions-list">
        <div
          v-for="question in currentQuestions"
          :key="question.id"
          class="question-card"
        >
          <!-- 题目头部 -->
          <div class="question-header">
            <span
              class="type-tag"
              :style="{ background: typeTagColor[question.type] }"
            >
              {{ typeLabel[question.type] || question.type }}
            </span>
            <span v-if="question.sectionId" class="section-tag">
              {{ sections.find(s => s.id === question.sectionId)?.title || '' }}
            </span>
            <span v-if="question.difficulty" class="difficulty-stars">
              {{ '★'.repeat(question.difficulty) }}{{ '☆'.repeat(5 - question.difficulty) }}
            </span>
          </div>

          <!-- 题目内容 -->
          <div class="question-content" v-html="question.content"></div>

          <!-- 单选题 -->
          <div v-if="isChoiceType(question.type) && !isJudgeType(question.type)" class="options-list">
            <label
              v-for="(option, idx) in parseOptions(question.options)"
              :key="idx"
              :class="[
                'option-item',
                {
                  'option-correct': hasSubmitted(question.id) && isCorrect(question.id) && isCorrectOption(question, idx),
                  'option-wrong': hasSubmitted(question.id) && isWrong(question.id) && isWrongOption(question, idx),
                },
              ]"
            >
              <template v-if="question.type === QuestionType.SINGLE">
                <input
                  type="radio"
                  :name="`q-${question.id}`"
                  :value="String(idx)"
                  :checked="getAnswer(question.id) === String(idx)"
                  :disabled="hasSubmitted(question.id)"
                  @change="setSingleAnswer(question.id, String(idx))"
                />
              </template>
              <template v-else>
                <input
                  type="checkbox"
                  :value="String(idx)"
                  :checked="isMultipleChecked(question.id, String(idx))"
                  :disabled="hasSubmitted(question.id)"
                  @change="(e: Event) => {
                    const target = e.target as HTMLInputElement
                    setMultipleAnswer(question.id, String(idx), target.checked)
                  }"
                />
              </template>
              <span class="option-label">{{ ['A', 'B', 'C', 'D', 'E', 'F'][idx] }}.</span>
              <span class="option-text">{{ option }}</span>
            </label>
          </div>

          <!-- 判断题 -->
          <div v-else-if="isJudgeType(question.type)" class="judge-options">
            <label
              :class="['judge-item', { 'option-correct': hasSubmitted(question.id) && isCorrect(question.id) && getAnswer(question.id) === 'true' }]"
            >
              <input
                type="radio"
                :name="`q-${question.id}`"
                value="true"
                :checked="getAnswer(question.id) === 'true'"
                :disabled="hasSubmitted(question.id)"
                @change="setSingleAnswer(question.id, 'true')"
              />
              <span>✓ 正确</span>
            </label>
            <label
              :class="['judge-item', { 'option-correct': hasSubmitted(question.id) && isCorrect(question.id) && getAnswer(question.id) === 'false' }]"
            >
              <input
                type="radio"
                :name="`q-${question.id}`"
                value="false"
                :checked="getAnswer(question.id) === 'false'"
                :disabled="hasSubmitted(question.id)"
                @change="setSingleAnswer(question.id, 'false')"
              />
              <span>✗ 错误</span>
            </label>
          </div>

          <!-- 填空题 -->
          <div v-else-if="isFillType(question.type)" class="fill-input-wrap">
            <input
              v-model="userAnswers[question.id]"
              type="text"
              class="fill-input"
              placeholder="请输入你的答案"
              :disabled="hasSubmitted(question.id)"
            />
          </div>

          <!-- 编程题 -->
          <div v-else-if="isProgrammingType(question.type)" class="programming-input-wrap">
            <textarea
              v-model="userAnswers[question.id]"
              class="programming-input"
              rows="6"
              placeholder="请在此编写你的代码..."
              :disabled="hasSubmitted(question.id)"
            ></textarea>
          </div>

          <!-- 操作按钮 -->
          <div class="question-actions">
            <button
              v-if="!hasSubmitted(question.id)"
              class="submit-btn"
              :disabled="!getAnswer(question.id)?.trim()"
              @click="submitAnswer(question.id)"
            >
              提交答案
            </button>
            <template v-else>
              <span v-if="isCorrect(question.id)" class="result-tag result-correct">
                ✓ 回答正确
              </span>
              <span v-else class="result-tag result-wrong">
                ✗ 回答错误
              </span>
            </template>
          </div>

          <!-- 解析区域 -->
          <div v-if="hasSubmitted(question.id)" class="explanation-box">
            <div class="explanation-header">
              <span class="explanation-title">📖 答案解析</span>
              <button
                v-if="isWrong(question.id)"
                class="wrong-btn"
                @click="markWrong(question.id)"
              >
                加入错题本
              </button>
            </div>
            <div class="explanation-answer">
              <strong>正确答案：</strong>
              <span>{{ formatCorrectAnswer(question) }}</span>
            </div>
            <div v-if="question.explanation" class="explanation-text" v-html="question.explanation"></div>
            <div v-else class="explanation-text explanation-empty">暂无解析</div>
          </div>
        </div>

        <!-- 加载更多 -->
        <div v-if="hasMore" class="load-more-wrap">
          <button
            class="load-more-btn"
            :disabled="questionsLoading"
            @click="loadMore"
          >
            <span v-if="questionsLoading" class="spinner-sm"></span>
            {{ questionsLoading ? '加载中...' : `加载更多（${loadedCount}/${totalRecords}）` }}
          </button>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.page-container {
  max-width: 900px;
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
  gap: 12px;
}

.spinner {
  width: 36px;
  height: 36px;
  border: 3px solid #f1f1f3;
  border-top-color: #0071e3;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

.spinner-sm {
  display: inline-block;
  width: 16px;
  height: 16px;
  border: 2px solid #e8e8ed;
  border-top-color: #0071e3;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
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

/* 头部信息 */
.practice-header {
  background: #fff;
  border-radius: 16px;
  padding: 28px 32px;
  margin-bottom: 24px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}

.header-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 20px;
}

.header-title {
  font-size: 26px;
  font-weight: 700;
  color: #1d1d1f;
  margin: 0 0 4px;
}

.header-course {
  font-size: 15px;
  color: #86868b;
  margin: 0;
}

.reset-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 18px;
  border: 1px solid #d2d2d7;
  border-radius: 10px;
  background: #fff;
  color: #515154;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.reset-btn:hover {
  background: #f5f5f7;
  border-color: #0071e3;
  color: #0071e3;
}

/* 统计栏 */
.stats-bar {
  display: flex;
  align-items: center;
  gap: 0;
  padding: 16px 0;
  border-top: 1px solid #f1f1f3;
  border-bottom: 1px solid #f1f1f3;
  margin-bottom: 16px;
}

.stat-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.stat-num {
  font-size: 22px;
  font-weight: 700;
  color: #1d1d1f;
}

.stat-num.stat-correct {
  color: #34c759;
}

.stat-num.stat-wrong {
  color: #ff3b30;
}

.stat-label {
  font-size: 13px;
  color: #86868b;
}

.stat-divider {
  width: 1px;
  height: 32px;
  background: #e8e8ed;
}

/* 筛选区 */
.filter-bar {
  display: flex;
  gap: 12px;
}

.filter-select {
  flex: 1;
  padding: 10px 14px;
  border: 1px solid #d2d2d7;
  border-radius: 10px;
  font-size: 14px;
  color: #1d1d1f;
  background: #fff;
  outline: none;
  cursor: pointer;
  transition: border-color 0.2s;
}

.filter-select:hover,
.filter-select:focus {
  border-color: #0071e3;
}

/* 题目卡片 */
.questions-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.question-card {
  background: #fff;
  border-radius: 16px;
  padding: 24px 28px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}

.question-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.type-tag {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #fff;
}

.section-tag {
  font-size: 13px;
  color: #86868b;
  background: #f5f5f7;
  padding: 3px 10px;
  border-radius: 6px;
}

.difficulty-stars {
  font-size: 12px;
  color: #ff9500;
  letter-spacing: 1px;
}

.question-content {
  font-size: 16px;
  line-height: 1.7;
  color: #1d1d1f;
  margin-bottom: 20px;
}

/* 选项 */
.options-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 16px;
}

.option-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px 16px;
  border: 1px solid #e8e8ed;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.option-item:hover {
  border-color: #0071e3;
  background: #f5f9ff;
}

.option-item input[type="radio"],
.option-item input[type="checkbox"] {
  margin-top: 2px;
  accent-color: #0071e3;
}

.option-label {
  font-weight: 600;
  color: #0071e3;
  min-width: 24px;
}

.option-text {
  color: #1d1d1f;
  line-height: 1.5;
}

.option-correct {
  border-color: #34c759 !important;
  background: #f0fff4 !important;
}

.option-wrong {
  border-color: #ff3b30 !important;
  background: #fff5f5 !important;
}

/* 判断题 */
.judge-options {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.judge-item {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 16px;
  border: 1px solid #e8e8ed;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 15px;
  font-weight: 500;
}

.judge-item:hover {
  border-color: #0071e3;
  background: #f5f9ff;
}

.judge-item input[type="radio"] {
  accent-color: #0071e3;
}

.judge-item.option-correct {
  border-color: #34c759 !important;
  background: #f0fff4 !important;
}

/* 填空 */
.fill-input-wrap {
  margin-bottom: 16px;
}

.fill-input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #d2d2d7;
  border-radius: 10px;
  font-size: 15px;
  color: #1d1d1f;
  outline: none;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.fill-input:focus {
  border-color: #0071e3;
  box-shadow: 0 0 0 3px rgba(0, 113, 227, 0.1);
}

.fill-input:disabled {
  background: #f5f5f7;
  color: #86868b;
}

/* 编程 */
.programming-input-wrap {
  margin-bottom: 16px;
}

.programming-input {
  width: 100%;
  padding: 14px 16px;
  border: 1px solid #d2d2d7;
  border-radius: 10px;
  font-size: 14px;
  font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
  color: #1d1d1f;
  outline: none;
  resize: vertical;
  transition: border-color 0.2s;
  box-sizing: border-box;
  line-height: 1.6;
}

.programming-input:focus {
  border-color: #0071e3;
  box-shadow: 0 0 0 3px rgba(0, 113, 227, 0.1);
}

.programming-input:disabled {
  background: #f5f5f7;
  color: #86868b;
}

/* 操作按钮 */
.question-actions {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 4px;
}

.submit-btn {
  padding: 8px 22px;
  border: none;
  border-radius: 8px;
  background: #0071e3;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.submit-btn:hover:not(:disabled) {
  background: #0066cc;
}

.submit-btn:disabled {
  background: #a1a1a6;
  cursor: not-allowed;
}

.result-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 6px 14px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
}

.result-correct {
  background: #f0fff4;
  color: #34c759;
}

.result-wrong {
  background: #fff5f5;
  color: #ff3b30;
}

/* 解析区域 */
.explanation-box {
  margin-top: 16px;
  padding: 16px;
  background: #f9f9fb;
  border-radius: 12px;
  border: 1px solid #f1f1f3;
}

.explanation-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.explanation-title {
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
}

.wrong-btn {
  padding: 5px 12px;
  border: 1px solid #ff9500;
  border-radius: 6px;
  background: #fff;
  color: #ff9500;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.wrong-btn:hover {
  background: #ff9500;
  color: #fff;
}

.explanation-answer {
  font-size: 14px;
  color: #1d1d1f;
  margin-bottom: 8px;
}

.explanation-text {
  font-size: 14px;
  line-height: 1.6;
  color: #515154;
}

.explanation-empty {
  color: #c7c7cc;
  font-style: italic;
}

/* 加载更多 */
.load-more-wrap {
  display: flex;
  justify-content: center;
  padding: 16px 0;
}

.load-more-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 28px;
  border: 1px solid #d2d2d7;
  border-radius: 10px;
  background: #fff;
  color: #515154;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.load-more-btn:hover:not(:disabled) {
  border-color: #0071e3;
  color: #0071e3;
}

.load-more-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
