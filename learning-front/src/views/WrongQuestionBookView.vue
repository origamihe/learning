<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getMyWrongQuestions, getDueForReview, updateMasteryLevel, updateNotes, removeWrongQuestion } from '@/api/wrongQuestion'
import { getQuestion } from '@/api/question'
import type { UserWrongQuestion, Question } from '@/types/api'
import { QuestionType } from '@/types/api'

const router = useRouter()

interface WrongQuestionItem {
  wrongRecord: UserWrongQuestion
  question: Question | null
}

const wrongQuestions = ref<WrongQuestionItem[]>([])
const loading = ref(true)
const filterMode = ref<'all' | 'due'>('all')
const editingNotes = ref<string | null>(null)
const editingNotesText = ref('')

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

const masteryLabels = ['', '未掌握', '略懂', '一般', '较熟练', '已掌握']
const masteryColors = ['', '#ff3b30', '#ff9500', '#ffcc00', '#34c759', '#0071e3']

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

function parseOptions(options?: string): string[] {
  if (!options) return []
  try {
    const arr: unknown = JSON.parse(options)
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
    return options.split('\n').filter(Boolean)
  }
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

function formatTime(dateStr: string): string {
  if (!dateStr) return '—'
  const d = new Date(dateStr)
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return '刚刚'
  if (mins < 60) return `${mins} 分钟前`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours} 小时前`
  const days = Math.floor(hours / 24)
  if (days < 30) return `${days} 天前`
  return d.toLocaleDateString('zh-CN')
}

function isDueForReview(item: WrongQuestionItem): boolean {
  if (!item.wrongRecord.nextReviewAt) return false
  return new Date(item.wrongRecord.nextReviewAt) <= new Date()
}

async function fetchData() {
  loading.value = true
  try {
    let records: UserWrongQuestion[]
    if (filterMode.value === 'due') {
      records = await getDueForReview()
    } else {
      records = await getMyWrongQuestions()
    }
    const items: WrongQuestionItem[] = []
    for (const record of records) {
      try {
        const question = await getQuestion(record.questionId)
        items.push({ wrongRecord: record, question })
      } catch {
        items.push({ wrongRecord: record, question: null })
      }
    }
    wrongQuestions.value = items
  } catch {
    wrongQuestions.value = []
  } finally {
    loading.value = false
  }
}

function switchMode(mode: 'all' | 'due') {
  filterMode.value = mode
  fetchData()
}

async function handleMasteryChange(id: string, level: number) {
  try {
    await updateMasteryLevel(id, level)
    const item = wrongQuestions.value.find(w => w.wrongRecord.id === id)
    if (item) item.wrongRecord.masteryLevel = level
  } catch {
    // handled by interceptor
  }
}

function startEditNotes(id: string, currentNotes: string) {
  editingNotes.value = id
  editingNotesText.value = currentNotes || ''
}

async function saveNotes(id: string) {
  try {
    await updateNotes(id, editingNotesText.value)
    const item = wrongQuestions.value.find(w => w.wrongRecord.id === id)
    if (item) item.wrongRecord.notes = editingNotesText.value
    editingNotes.value = null
  } catch {
    // handled by interceptor
  }
}

function cancelEditNotes() {
  editingNotes.value = null
}

async function handleRemove(id: string) {
  if (!confirm('确定要移除这道错题吗？')) return
  try {
    await removeWrongQuestion(id)
    wrongQuestions.value = wrongQuestions.value.filter(w => w.wrongRecord.id !== id)
  } catch {
    // handled by interceptor
  }
}

function goBack() {
  router.push('/home')
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="page-container">
    <!-- 返回按钮 -->
    <button class="back-btn" @click="goBack">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="15 18 9 12 15 6" />
      </svg>
      返回首页
    </button>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>加载错题中...</p>
    </div>

    <template v-else>
      <!-- 头部信息 -->
      <div class="practice-header">
        <div class="header-top">
          <div class="header-info">
            <h1 class="header-title">📖 错题本</h1>
            <p class="header-subtitle">复习错题，巩固知识</p>
          </div>
        </div>

        <!-- 模式切换 Tab -->
        <div class="mode-tabs">
          <button
            :class="['mode-tab', { active: filterMode === 'all' }]"
            @click="switchMode('all')"
          >
            全部错题
          </button>
          <button
            :class="['mode-tab', { active: filterMode === 'due' }]"
            @click="switchMode('due')"
          >
            待复习
          </button>
        </div>
      </div>

      <!-- 空状态 -->
      <div v-if="wrongQuestions.length === 0" class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="56" height="56" style="color: #c7c7cc;">
          <path d="M9 11l3 3L22 4" />
          <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
        </svg>
        <p v-if="filterMode === 'all'">还没有错题记录</p>
        <p v-else>暂无待复习的错题，继续保持！</p>
      </div>

      <!-- 错题列表 -->
      <div v-else class="questions-list">
        <div
          v-for="item in wrongQuestions"
          :key="item.wrongRecord.id"
          class="question-card"
        >
          <!-- 题目头部 -->
          <div class="question-header">
            <span
              v-if="item.question"
              class="type-tag"
              :style="{ background: typeTagColor[item.question.type] }"
            >
              {{ typeLabel[item.question.type] || item.question.type }}
            </span>
            <span class="wrong-count-tag">
              错 {{ item.wrongRecord.wrongCount }} 次
            </span>
            <span v-if="item.question?.difficulty" class="difficulty-stars">
              {{ '★'.repeat(item.question.difficulty) }}{{ '☆'.repeat(5 - item.question.difficulty) }}
            </span>
            <span v-if="isDueForReview(item)" class="due-tag">待复习</span>
          </div>

          <!-- 题目内容 -->
          <div v-if="item.question" class="question-content" v-html="item.question.content"></div>
          <div v-else class="question-content question-deleted">
            该题目已被删除
          </div>

          <!-- 正确答案 -->
          <div v-if="item.question" class="answer-section">
            <span class="answer-label">正确答案：</span>
            <span class="answer-value">{{ formatCorrectAnswer(item.question) }}</span>
          </div>

          <!-- 解析 -->
          <div v-if="item.question?.explanation" class="explanation-box">
            <span class="explanation-title">📖 解析：</span>
            <span class="explanation-text">{{ item.question.explanation }}</span>
          </div>

          <!-- 底部操作区 -->
          <div class="question-footer">
            <!-- 掌握程度 -->
            <div class="mastery-section">
              <span class="footer-label">掌握程度：</span>
              <div class="mastery-stars">
                <button
                  v-for="level in 5"
                  :key="level"
                  :class="['mastery-star', { filled: level <= item.wrongRecord.masteryLevel }]"
                  :style="{ color: level <= item.wrongRecord.masteryLevel ? masteryColors[item.wrongRecord.masteryLevel] : '#d2d2d7' }"
                  :title="masteryLabels[level]"
                  @click="handleMasteryChange(item.wrongRecord.id, level)"
                >
                  ★
                </button>
              </div>
            </div>

            <!-- 时间信息 -->
            <div class="time-info">
              <span class="time-text">上次做错：{{ formatTime(item.wrongRecord.lastWrongAt) }}</span>
            </div>
          </div>

          <!-- 笔记区域 -->
          <div class="notes-section">
            <div class="notes-header">
              <span class="footer-label">📝 笔记：</span>
              <button
                v-if="editingNotes !== item.wrongRecord.id"
                class="notes-edit-btn"
                @click="startEditNotes(item.wrongRecord.id, item.wrongRecord.notes || '')"
              >
                编辑
              </button>
            </div>
            <div v-if="editingNotes === item.wrongRecord.id" class="notes-editor">
              <textarea
                v-model="editingNotesText"
                class="notes-textarea"
                rows="3"
                placeholder="写下你的解题思路或易错点..."
              ></textarea>
              <div class="notes-editor-actions">
                <button class="notes-save-btn" @click="saveNotes(item.wrongRecord.id)">保存</button>
                <button class="notes-cancel-btn" @click="cancelEditNotes">取消</button>
              </div>
            </div>
            <p v-else class="notes-content">
              {{ item.wrongRecord.notes || '暂无笔记，点击编辑添加' }}
            </p>
          </div>

          <!-- 移除按钮 -->
          <div class="remove-section">
            <button class="remove-btn" @click="handleRemove(item.wrongRecord.id)">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16">
                <polyline points="3 6 5 6 21 6" />
                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
              </svg>
              移出错题本
            </button>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.page-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 24px 24px 48px;
}

/* 返回按钮 */
.back-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border: 1px solid #d2d2d7;
  border-radius: 10px;
  background: #fff;
  color: #515154;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 20px;
}

.back-btn:hover {
  border-color: #0071e3;
  color: #0071e3;
}

.back-btn svg {
  width: 18px;
  height: 18px;
}

/* 加载状态 */
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  color: #86868b;
}

.spinner {
  width: 36px;
  height: 36px;
  border: 3px solid #e8e8ed;
  border-top-color: #0071e3;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* 空状态 */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 0;
  color: #86868b;
  font-size: 15px;
}

.empty-state p {
  margin-top: 16px;
}

/* 头部 */
.practice-header {
  margin-bottom: 24px;
}

.header-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 20px;
}

.header-title {
  font-size: 28px;
  font-weight: 700;
  color: #1d1d1f;
  margin: 0 0 4px;
  letter-spacing: -0.5px;
}

.header-subtitle {
  font-size: 15px;
  color: #86868b;
  margin: 0;
}

/* 模式切换 Tab */
.mode-tabs {
  display: flex;
  gap: 0;
  background: #f5f5f7;
  border-radius: 10px;
  padding: 3px;
}

.mode-tab {
  flex: 1;
  padding: 9px 20px;
  border: none;
  border-radius: 8px;
  background: transparent;
  color: #86868b;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.mode-tab.active {
  background: #fff;
  color: #1d1d1f;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.mode-tab:hover:not(.active) {
  color: #515154;
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

.wrong-count-tag {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #fff;
  background: #ff3b30;
}

.due-tag {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  color: #ff9500;
  background: #fff8f0;
  border: 1px solid #ffe0b2;
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
  margin-bottom: 16px;
}

.question-deleted {
  color: #c7c7cc;
  font-style: italic;
}

/* 正确答案 */
.answer-section {
  margin-bottom: 12px;
  padding: 10px 14px;
  background: #f5f9ff;
  border-radius: 8px;
}

.answer-label {
  font-size: 14px;
  font-weight: 600;
  color: #515154;
}

.answer-value {
  font-size: 14px;
  color: #0071e3;
  font-weight: 500;
}

/* 解析 */
.explanation-box {
  margin-bottom: 16px;
  padding: 12px 14px;
  background: #f5f5f7;
  border-radius: 8px;
  line-height: 1.6;
}

.explanation-title {
  font-size: 14px;
  font-weight: 600;
  color: #515154;
}

.explanation-text {
  font-size: 14px;
  color: #515154;
}

/* 底部操作区 */
.question-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  padding-top: 12px;
  border-top: 1px solid #f5f5f7;
  margin-bottom: 12px;
}

.mastery-section {
  display: flex;
  align-items: center;
  gap: 8px;
}

.footer-label {
  font-size: 13px;
  color: #86868b;
  font-weight: 500;
}

.mastery-stars {
  display: flex;
  gap: 4px;
}

.mastery-star {
  background: none;
  border: none;
  font-size: 20px;
  cursor: pointer;
  padding: 0 2px;
  transition: transform 0.15s;
}

.mastery-star:hover {
  transform: scale(1.2);
}

.time-info {
  display: flex;
  gap: 16px;
}

.time-text {
  font-size: 13px;
  color: #aeaeb2;
}

/* 笔记区域 */
.notes-section {
  padding-top: 12px;
  border-top: 1px solid #f5f5f7;
}

.notes-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.notes-edit-btn {
  padding: 4px 12px;
  border: 1px solid #d2d2d7;
  border-radius: 6px;
  background: #fff;
  color: #0071e3;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.notes-edit-btn:hover {
  background: #f5f9ff;
  border-color: #0071e3;
}

.notes-content {
  font-size: 14px;
  color: #515154;
  line-height: 1.5;
  margin: 0;
}

.notes-editor {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.notes-textarea {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #d2d2d7;
  border-radius: 10px;
  font-size: 14px;
  color: #1d1d1f;
  background: #fff;
  outline: none;
  resize: vertical;
  font-family: inherit;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.notes-textarea:focus {
  border-color: #0071e3;
}

.notes-editor-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}

.notes-save-btn {
  padding: 6px 16px;
  border: none;
  border-radius: 8px;
  background: #0071e3;
  color: #fff;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}

.notes-save-btn:hover {
  background: #0077ed;
}

.notes-cancel-btn {
  padding: 6px 16px;
  border: 1px solid #d2d2d7;
  border-radius: 8px;
  background: #fff;
  color: #86868b;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.notes-cancel-btn:hover {
  border-color: #86868b;
  color: #515154;
}

/* 移除按钮 */
.remove-section {
  display: flex;
  justify-content: flex-end;
  padding-top: 12px;
  border-top: 1px solid #f5f5f7;
  margin-top: 12px;
}

.remove-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border: 1px solid #ffd1cf;
  border-radius: 8px;
  background: #fff;
  color: #ff3b30;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.remove-btn:hover {
  background: #fff5f5;
  border-color: #ff3b30;
}
</style>
