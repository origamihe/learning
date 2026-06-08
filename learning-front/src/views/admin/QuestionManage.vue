C:\Users\24954\OneDrive\Desktop\learning\learning-front\src\views\admin\QuestionManage.vue
<script setup lang="ts">
import { ref, reactive, onMounted, computed, watch } from 'vue'
import { listCourses } from '@/api/course'
import { getSectionsByCourse } from '@/api/section'
import { listQuestions, createQuestion, updateQuestion, deleteQuestion } from '@/api/question'
import type { Course, CourseSection, Question, CreateQuestionRequest } from '@/types/api'
import { QuestionType } from '@/types/api'

const courses = ref<Course[]>([])
const sections = ref<CourseSection[]>([])
const questions = ref<Question[]>([])
const loading = ref(true)
const questionsLoading = ref(false)
const submitting = ref(false)

const selectedCourseId = ref<string | null>(null)
const selectedSectionId = ref<string | null>(null)
const keyword = ref('')
const selectedType = ref<QuestionType | ''>('')
const selectedDifficulty = ref<number | ''>('')

const totalPages = ref(1)
const totalRecords = ref(0)
const currentPage = ref(1)
const pageSize = 10

const showModal = ref(false)
const isEditing = ref(false)
const editingId = ref<string | null>(null)

const form = reactive<CreateQuestionRequest & { optionsList: string[]; answerSingle: string; answerMultiple: string[]; answerJudge: string; answerFill: string; answerProgramming: string }>({
  courseId: '',
  sectionId: '',
  type: QuestionType.SINGLE,
  content: '',
  options: '',
  answer: '',
  explanation: '',
  difficulty: 3,
  tags: '',
  optionsList: ['', '', '', ''],
  answerSingle: '0',
  answerMultiple: [],
  answerJudge: 'true',
  answerFill: '',
  answerProgramming: '',
})

const typeOptions: { value: QuestionType; label: string }[] = [
  { value: QuestionType.SINGLE, label: '单选题' },
  { value: QuestionType.MULTIPLE, label: '多选题' },
  { value: QuestionType.JUDGE, label: '判断题' },
  { value: QuestionType.FILL, label: '填空题' },
  { value: QuestionType.PROGRAMMING, label: '编程题' },
]

const typeLabel: Record<string, string> = {
  SINGLE: '单选',
  MULTIPLE: '多选',
  JUDGE: '判断',
  FILL: '填空',
  PROGRAMMING: '编程',
}

const typeColor: Record<string, string> = {
  SINGLE: '#0071e3',
  MULTIPLE: '#5856d6',
  JUDGE: '#ff9500',
  FILL: '#34c759',
  PROGRAMMING: '#ff3b30',
}

const difficultyOptions = [1, 2, 3, 4, 5]

const isChoiceType = computed(() => form.type === QuestionType.SINGLE || form.type === QuestionType.MULTIPLE)
const isJudgeType = computed(() => form.type === QuestionType.JUDGE)
const isFillType = computed(() => form.type === QuestionType.FILL)
const isProgrammingType = computed(() => form.type === QuestionType.PROGRAMMING)

async function fetchCourses() {
  loading.value = true
  try {
    const res = await listCourses({ page: 1, size: 1000 })
    courses.value = res.records
  } catch {
    courses.value = []
  } finally {
    loading.value = false
  }
}

async function fetchSections(courseId: string) {
  try {
    const res = await getSectionsByCourse(courseId)
    sections.value = res.sort((a, b) => a.sortOrder - b.sortOrder)
  } catch {
    sections.value = []
  }
}

async function fetchQuestions() {
  questionsLoading.value = true
  try {
    const params: Record<string, unknown> = { page: currentPage.value, size: pageSize }
    if (selectedCourseId.value) params.courseId = selectedCourseId.value
    if (selectedSectionId.value) params.sectionId = selectedSectionId.value
    if (selectedType.value) params.type = selectedType.value
    if (selectedDifficulty.value !== '') params.difficulty = selectedDifficulty.value
    if (keyword.value.trim()) {
      ;(params as Record<string, unknown>).keyword = keyword.value.trim()
    }
    const res = await listQuestions(params as Parameters<typeof listQuestions>[0])
    questions.value = res.records
    totalPages.value = res.pages
    totalRecords.value = res.total
  } catch {
    questions.value = []
  } finally {
    questionsLoading.value = false
  }
}

function selectCourse(courseId: string) {
  selectedCourseId.value = courseId
  selectedSectionId.value = null
  fetchSections(courseId)
  currentPage.value = 1
  fetchQuestions()
}

function selectSection(sectionId: string | null) {
  selectedSectionId.value = sectionId
  currentPage.value = 1
  fetchQuestions()
}

function handleSearch() {
  currentPage.value = 1
  fetchQuestions()
}

function goToPage(page: number) {
  currentPage.value = page
  fetchQuestions()
}

function getCourseTitle(id: string) {
  return courses.value.find(c => c.id === id)?.title || '未知课程'
}

function getSectionTitle(id: string | undefined) {
  if (!id) return '—'
  return sections.value.find(s => s.id === id)?.title || '—'
}

function resolveAnswerIndex(optionsStr: string, answer: string): number {
  try {
    const arr: unknown = JSON.parse(optionsStr || '[]')
    if (!Array.isArray(arr)) return parseInt(answer)
    const idx = (arr as unknown[]).findIndex((item: unknown) => {
      if (typeof item === 'object' && item !== null) {
        const opt = item as Record<string, unknown>
        return typeof opt.key === 'string' && opt.key === answer.trim()
      }
      return false
    })
    if (idx !== -1) return idx
    return parseInt(answer)
  } catch {
    return parseInt(answer)
  }
}

function formatAnswer(question: Question): string {
  if (!question.answer) return '—'
  if (question.type === QuestionType.SINGLE) {
    try {
      const opts: unknown = JSON.parse(question.options || '[]')
      if (!Array.isArray(opts)) return question.answer
      const idx = resolveAnswerIndex(question.options || '', question.answer)
      const item = opts[idx] as unknown
      if (!isNaN(idx) && item) {
        if (typeof item === 'string') return item
        if (typeof item === 'object' && item !== null) {
          const opt = item as Record<string, unknown>
          if (typeof opt.value === 'string') return opt.value
        }
        return String(item)
      }
    } catch { /* ignore */ }
  }
  if (question.type === QuestionType.MULTIPLE) {
    try {
      const opts: unknown = JSON.parse(question.options || '[]')
      if (!Array.isArray(opts)) return question.answer
      const indices = question.answer.split(',').map(s => resolveAnswerIndex(question.options || '', s.trim()))
      return indices.map(i => {
        const item = opts[i] as unknown
        if (!item) return `选项${i + 1}`
        if (typeof item === 'string') return item
        if (typeof item === 'object' && item !== null) {
          const opt = item as Record<string, unknown>
          if (typeof opt.value === 'string') return opt.value
        }
        return String(item)
      }).join('、')
    } catch { /* ignore */ }
  }
  if (question.type === QuestionType.JUDGE) {
    return question.answer === 'true' ? '正确 (√)' : '错误 (×)'
  }
  return question.answer.length > 40 ? question.answer.slice(0, 40) + '...' : question.answer
}

function difficultyStars(level: number | undefined): string {
  if (!level) return '☆'.repeat(5)
  return '★'.repeat(level) + '☆'.repeat(5 - level)
}

function openCreateModal() {
  if (!selectedCourseId.value) {
    alert('请先在左侧选择一门课程')
    return
  }
  isEditing.value = false
  editingId.value = null
  form.courseId = selectedCourseId.value
  form.sectionId = selectedSectionId.value || ''
  form.type = QuestionType.SINGLE
  form.content = ''
  form.options = ''
  form.answer = ''
  form.explanation = ''
  form.difficulty = 3
  form.tags = ''
  form.optionsList = ['', '', '', '']
  form.answerSingle = '0'
  form.answerMultiple = []
  form.answerJudge = 'true'
  form.answerFill = ''
  form.answerProgramming = ''
  showModal.value = true
}

function openEditModal(question: Question) {
  isEditing.value = true
  editingId.value = question.id
  form.courseId = question.courseId
  form.sectionId = question.sectionId || ''
  form.type = question.type
  form.content = question.content
  form.options = question.options || ''
  form.answer = question.answer || ''
  form.explanation = question.explanation || ''
  form.difficulty = question.difficulty || 3
  form.tags = question.tags || ''

  if (question.type === QuestionType.SINGLE || question.type === QuestionType.MULTIPLE) {
    try {
      const raw: unknown = JSON.parse(question.options || '[]')
      if (Array.isArray(raw)) {
        form.optionsList = (raw as unknown[]).map((item) => {
          if (typeof item === 'string') return item
          if (typeof item === 'object' && item !== null) {
            const opt = item as Record<string, unknown>
            if (typeof opt.value === 'string') return opt.value
          }
          return String(item)
        })
      } else {
        form.optionsList = ['', '', '', '']
      }
      if (form.optionsList.length === 0) form.optionsList = ['', '', '', '']
    } catch {
      form.optionsList = ['', '', '', '']
    }
    if (question.type === QuestionType.SINGLE) {
      const idx = resolveAnswerIndex(question.options || '', question.answer || '0')
      form.answerSingle = String(isNaN(idx) ? 0 : idx)
    } else {
      const indices = question.answer
        ? question.answer.split(',').map(s => resolveAnswerIndex(question.options || '', s.trim()))
        : []
      form.answerMultiple = indices.filter(i => !isNaN(i)).map(i => String(i))
    }
  }
  form.answerJudge = question.answer === 'true' || question.answer === 'false' ? question.answer : 'true'
  form.answerFill = (question.type === QuestionType.FILL) ? (question.answer || '') : ''
  form.answerProgramming = (question.type === QuestionType.PROGRAMMING) ? (question.answer || '') : ''

  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function addOption() {
  form.optionsList.push('')
}

function removeOption(index: number) {
  if (form.optionsList.length <= 2) return
  form.optionsList.splice(index, 1)
  if (form.type === QuestionType.SINGLE && parseInt(form.answerSingle) >= form.optionsList.length) {
    form.answerSingle = '0'
  }
  form.answerMultiple = form.answerMultiple.filter(i => parseInt(i) < form.optionsList.length)
}

function toggleMultipleOption(index: string) {
  const idx = form.answerMultiple.indexOf(index)
  if (idx === -1) {
    form.answerMultiple.push(index)
  } else {
    form.answerMultiple.splice(idx, 1)
  }
}

function buildSubmitData(): CreateQuestionRequest | Partial<Question> {
  let options = ''
  let answer = ''

  if (isChoiceType.value) {
    const filtered = form.optionsList.filter(o => o.trim() !== '')
    options = JSON.stringify(filtered.length > 0 ? filtered : form.optionsList)
    if (form.type === QuestionType.SINGLE) {
      answer = form.answerSingle
    } else {
      answer = form.answerMultiple.filter(i => {
        const idx = parseInt(i)
        return idx < form.optionsList.length && (form.optionsList[idx] ?? '').trim() !== ''
      }).join(',')
    }
  } else if (isJudgeType.value) {
    answer = form.answerJudge
  } else if (isFillType.value) {
    answer = form.answerFill
  } else if (isProgrammingType.value) {
    answer = form.answerProgramming
  }

  return {
    courseId: form.courseId,
    sectionId: form.sectionId || undefined,
    type: form.type,
    content: form.content,
    options: options || undefined,
    answer,
    explanation: form.explanation || undefined,
    difficulty: form.difficulty,
    tags: form.tags || undefined,
  }
}

async function handleSubmit() {
  if (!form.content.trim()) return
  submitting.value = true
  try {
    const data = buildSubmitData()
    if (isEditing.value && editingId.value) {
      await updateQuestion(editingId.value, data as Partial<Question>)
    } else {
      await createQuestion(data as CreateQuestionRequest)
    }
    closeModal()
    fetchQuestions()
  } catch {
    // error handled by interceptor
  } finally {
    submitting.value = false
  }
}

async function handleDelete(id: string) {
  if (!confirm('确定要删除该题目吗？此操作不可恢复。')) return
  try {
    await deleteQuestion(id)
    fetchQuestions()
  } catch { /* handled */ }
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
}

watch(() => form.type, () => {
  if (form.type === QuestionType.SINGLE || form.type === QuestionType.MULTIPLE) {
    if (form.optionsList.length === 0) form.optionsList = ['', '', '', '']
    form.answerSingle = form.answerSingle || '0'
  }
})

onMounted(() => {
  fetchCourses()
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">题目管理</h1>
        <p class="page-subtitle">管理平台题库，共 {{ totalRecords }} 道题目</p>
      </div>
      <button class="btn-primary" @click="openCreateModal">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        创建题目
      </button>
    </div>

    <div class="content-layout">
      <div class="sidebar">
        <div class="sidebar-header">
          <h3>课程列表</h3>
        </div>
        <div v-if="loading" class="loading-text">加载中...</div>
        <ul v-else class="course-list">
          <li
            v-for="course in courses"
            :key="course.id"
            :class="['course-item', { active: selectedCourseId === course.id }]"
            @click="selectCourse(course.id)"
          >
            <span class="course-name">{{ course.title }}</span>
            <span class="course-status" :class="course.status.toLowerCase()">
              {{ course.status === 'DRAFT' ? '草稿' : course.status === 'PUBLISHED' ? '已发布' : '已归档' }}
            </span>
          </li>
        </ul>

        <div v-if="selectedCourseId && sections.length > 0" class="section-tree">
          <div class="sidebar-header">
            <h3>章节列表</h3>
          </div>
          <ul class="section-list">
            <li
              :class="['section-item', { active: selectedSectionId === null }]"
              @click="selectSection(null)"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="section-icon"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/></svg>
              <span>全部章节</span>
            </li>
            <li
              v-for="section in sections"
              :key="section.id"
              :class="['section-item', { active: selectedSectionId === section.id }]"
              @click="selectSection(section.id)"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="section-icon"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
              <span>{{ section.title }}</span>
              <span class="section-order-badge">{{ section.sortOrder }}</span>
            </li>
          </ul>
        </div>
      </div>

      <div class="main">
        <div v-if="!selectedCourseId" class="empty-state">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="empty-icon">
            <path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
          </svg>
          <p>请在左侧选择一门课程查看题目</p>
        </div>

        <template v-else>
          <div class="toolbar">
            <div class="search-box">
              <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <input v-model="keyword" type="text" class="search-input" placeholder="搜索题目内容..." @keyup.enter="handleSearch"/>
            </div>
            <div class="filter-group">
              <select v-model="selectedType" class="filter-select" @change="handleSearch">
                <option value="">全部题型</option>
                <option v-for="t in typeOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
              </select>
              <select v-model="selectedDifficulty" class="filter-select" @change="handleSearch">
                <option value="">全部难度</option>
                <option v-for="d in difficultyOptions" :key="d" :value="d">{{ '★'.repeat(d) }} {{ d }}级</option>
              </select>
            </div>
          </div>

          <div v-if="questionsLoading" class="loading-state"><div class="spinner"></div><p>加载题目中...</p></div>

          <div v-else-if="questions.length === 0" class="empty-state">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="empty-icon"><path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/></svg>
            <p>暂无题目数据</p>
            <button class="btn-primary" style="margin-top: 16px;" @click="openCreateModal">创建第一道题目</button>
          </div>

          <div v-else class="table-wrapper">
            <table class="data-table">
              <thead>
              <tr>
                <th style="width: 32%;">题目内容</th>
                <th>题型</th>
                <th>难度</th>
                <th>所属章节</th>
                <th>更新时间</th>
                <th style="width: 120px;">操作</th>
              </tr>
              </thead>
              <tbody>
              <tr v-for="q in questions" :key="q.id">
                <td>
                  <div class="content-cell">
                    <span class="content-text">{{ q.content.length > 60 ? q.content.slice(0, 60) + '...' : q.content }}</span>
                    <div class="answer-preview">
                      <span class="answer-label">答案：</span>
                      <span class="answer-value">{{ formatAnswer(q) }}</span>
                    </div>
                  </div>
                </td>
                <td>
                  <span class="type-badge" :style="{ background: typeColor[q.type] + '1a', color: typeColor[q.type] }">
                    {{ typeLabel[q.type] || q.type }}
                  </span>
                </td>
                <td>
                  <span class="difficulty-stars" :title="'难度 ' + (q.difficulty || 3) + ' 级'">
                    {{ difficultyStars(q.difficulty) }}
                  </span>
                </td>
                <td class="text-muted">{{ getSectionTitle(q.sectionId) }}</td>
                <td class="text-muted">{{ formatDate(q.updatedAt) }}</td>
                <td>
                  <div class="action-btns">
                    <button class="action-btn" @click="openEditModal(q)">编辑</button>
                    <button class="action-btn danger" @click="handleDelete(q.id)">删除</button>
                  </div>
                </td>
              </tr>
              </tbody>
            </table>
          </div>

          <div v-if="totalPages > 1" class="pagination">
            <button class="page-btn" :disabled="currentPage <= 1" @click="goToPage(currentPage - 1)">上一页</button>
            <span class="page-info">{{ currentPage }} / {{ totalPages }}</span>
            <button class="page-btn" :disabled="currentPage >= totalPages" @click="goToPage(currentPage + 1)">下一页</button>
          </div>
        </template>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-header">
            <h3 class="modal-title">{{ isEditing ? '编辑题目' : '创建题目' }}</h3>
            <button class="modal-close" @click="closeModal">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
          <div class="modal-body">
            <div class="form-row">
              <div class="form-group" style="flex: 1;">
                <label class="form-label">所属课程</label>
                <input type="text" class="form-input" :value="getCourseTitle(form.courseId)" disabled />
              </div>
              <div class="form-group" style="flex: 1;">
                <label class="form-label">所属章节</label>
                <select v-model="form.sectionId" class="form-select">
                  <option value="">不指定章节</option>
                  <option v-for="s in sections" :key="s.id" :value="s.id">{{ s.title }}</option>
                </select>
              </div>
            </div>

            <div class="form-row">
              <div class="form-group" style="flex: 1;">
                <label class="form-label">题目类型 <span class="required">*</span></label>
                <select v-model="form.type" class="form-select">
                  <option v-for="t in typeOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
                </select>
              </div>
              <div class="form-group" style="flex: 1;">
                <label class="form-label">难度等级</label>
                <select v-model.number="form.difficulty" class="form-select">
                  <option v-for="d in difficultyOptions" :key="d" :value="d">{{ '★'.repeat(d) }} {{ d }}级</option>
                </select>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">题目内容 <span class="required">*</span></label>
              <textarea v-model="form.content" class="form-textarea" placeholder="请输入题目内容（题干）" rows="3"></textarea>
            </div>

            <div v-if="isChoiceType" class="form-group">
              <label class="form-label">
                选项列表 <span class="required">*</span>
                <span class="label-hint">（{{ form.type === 'SINGLE' ? '单选' : '多选' }}，点击选项前的圆圈标记正确答案）</span>
              </label>
              <div class="options-editor">
                <div v-for="(opt, idx) in form.optionsList" :key="idx" class="option-row">
                  <button
                    v-if="form.type === QuestionType.SINGLE"
                    :class="['option-radio', { selected: form.answerSingle === String(idx) }]"
                    @click="form.answerSingle = String(idx)"
                    type="button"
                  >
                    <span v-if="form.answerSingle === String(idx)" class="radio-dot"></span>
                  </button>
                  <button
                    v-else
                    :class="['option-checkbox', { selected: form.answerMultiple.includes(String(idx)) }]"
                    @click="toggleMultipleOption(String(idx))"
                    type="button"
                  >
                    <svg v-if="form.answerMultiple.includes(String(idx))" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                  </button>
                  <span class="option-label">{{ String.fromCharCode(65 + idx) }}.</span>
                  <input
                    v-model="form.optionsList[idx]"
                    type="text"
                    class="option-input"
                    :placeholder="`选项 ${String.fromCharCode(65 + idx)}`"
                  />
                  <button
                    v-if="form.optionsList.length > 2"
                    class="option-remove"
                    @click="removeOption(idx)"
                    type="button"
                    title="删除选项"
                  >
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                  </button>
                </div>
                <button class="option-add" @click="addOption" type="button">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                  添加选项
                </button>
              </div>
            </div>

            <div v-if="isJudgeType" class="form-group">
              <label class="form-label">正确答案 <span class="required">*</span></label>
              <div class="judge-options">
                <label :class="['judge-btn', { active: form.answerJudge === 'true' }]">
                  <input type="radio" v-model="form.answerJudge" value="true" class="judge-radio" />
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  正确 (√)
                </label>
                <label :class="['judge-btn', { active: form.answerJudge === 'false' }]">
                  <input type="radio" v-model="form.answerJudge" value="false" class="judge-radio" />
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                  错误 (×)
                </label>
              </div>
            </div>

            <div v-if="isFillType" class="form-group">
              <label class="form-label">正确答案 <span class="required">*</span></label>
              <input v-model="form.answerFill" type="text" class="form-input" placeholder="请输入填空的正确答案" />
            </div>

            <div v-if="isProgrammingType" class="form-group">
              <label class="form-label">参考代码 / 答案 <span class="required">*</span></label>
              <textarea v-model="form.answerProgramming" class="form-textarea code-area" placeholder="请输入参考代码或答案..." rows="6"></textarea>
            </div>

            <div class="form-group">
              <label class="form-label">答案解析</label>
              <textarea v-model="form.explanation" class="form-textarea" placeholder="请输入答案解析（可选）" rows="2"></textarea>
            </div>

            <div class="form-group">
              <label class="form-label">标签</label>
              <input v-model="form.tags" type="text" class="form-input" placeholder="多个标签用逗号分隔，如：Java,基础,循环" />
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" @click="closeModal" :disabled="submitting">取消</button>
            <button class="btn-primary" @click="handleSubmit" :disabled="submitting || !form.content.trim()">
              {{ submitting ? '保存中...' : (isEditing ? '保存修改' : '创建题目') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; padding: 32px 24px; }
.page-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 16px; }
.page-title { font-size: 28px; font-weight: 700; color: #1d1d1f; margin-bottom: 6px; }
.page-subtitle { font-size: 15px; color: #86868b; }

.btn-primary {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 10px 20px; background: #0071e3; color: #fff;
  border: none; border-radius: 12px; font-size: 15px; font-weight: 600;
  cursor: pointer; transition: all 0.3s;
}
.btn-primary:hover { background: #0060c0; transform: translateY(-1px); box-shadow: 0 4px 12px rgba(0,113,227,0.3); }
.btn-primary:disabled { opacity: 0.6; cursor: not-allowed; transform: none; box-shadow: none; }
.btn-primary svg { width: 18px; height: 18px; }

.btn-secondary {
  padding: 10px 20px; background: #f5f5f7; color: #1d1d1f;
  border: 1.5px solid #d2d2d7; border-radius: 12px; font-size: 15px; font-weight: 500;
  cursor: pointer; transition: all 0.3s;
}
.btn-secondary:hover { background: #e8e8eb; }

/* Layout */
.content-layout { display: flex; gap: 24px; align-items: flex-start; }
.sidebar { width: 260px; flex-shrink: 0; background: #fff; border-radius: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.06); overflow: hidden; }
.sidebar-header { padding: 18px 20px 10px; }
.sidebar-header h3 { font-size: 14px; font-weight: 700; color: #1d1d1f; }
.main { flex: 1; min-width: 0; }

.loading-text { text-align: center; padding: 24px; color: #86868b; font-size: 14px; }

.course-list { list-style: none; padding: 0 12px 12px; margin: 0; }
.course-item {
  padding: 10px 14px; border-radius: 10px; cursor: pointer;
  display: flex; align-items: center; justify-content: space-between;
  transition: background 0.2s; margin-bottom: 2px;
}
.course-item:hover { background: #f5f5f7; }
.course-item.active { background: #0071e3; }
.course-item.active .course-name { color: #fff; }
.course-item.active .course-status { color: rgba(255,255,255,0.8); }
.course-name { font-size: 14px; font-weight: 500; color: #1d1d1f; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.course-status { font-size: 11px; padding: 2px 8px; border-radius: 9999px; font-weight: 500; }
.course-status.draft { background: #f1f1f3; color: #86868b; }
.course-status.published { background: #e8f8ed; color: #34c759; }
.course-status.archived { background: #fff4e5; color: #ff9500; }

.section-tree { border-top: 1px solid #f1f1f3; }
.section-list { list-style: none; padding: 0 12px 12px; margin: 0; }
.section-item {
  padding: 8px 14px; border-radius: 8px; cursor: pointer;
  display: flex; align-items: center; gap: 8px;
  transition: background 0.2s; margin-bottom: 2px;
  font-size: 13px; color: #1d1d1f;
}
.section-item:hover { background: #f5f5f7; }
.section-item.active { background: rgba(0,113,227,0.08); color: #0071e3; font-weight: 600; }
.section-icon { width: 16px; height: 16px; flex-shrink: 0; color: #86868b; }
.section-item.active .section-icon { color: #0071e3; }
.section-item span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.section-order-badge { font-size: 11px; color: #86868b; margin-left: auto; background: #f5f5f7; padding: 2px 6px; border-radius: 6px; }

/* Toolbar */
.toolbar { display: flex; align-items: center; gap: 16px; margin-bottom: 20px; flex-wrap: wrap; }
.search-box { position: relative; flex: 1; min-width: 180px; max-width: 320px; }
.search-icon { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); width: 18px; height: 18px; color: #86868b; }
.search-input { width: 100%; padding: 10px 14px 10px 40px; border: 1.5px solid #d2d2d7; border-radius: 12px; font-size: 15px; color: #1d1d1f; outline: none; box-sizing: border-box; }
.search-input:focus { border-color: #0071e3; }
.filter-group { display: flex; gap: 10px; }
.filter-select { padding: 10px 14px; border: 1.5px solid #d2d2d7; border-radius: 12px; font-size: 14px; color: #1d1d1f; background: #fff; outline: none; cursor: pointer; }
.filter-select:focus { border-color: #0071e3; }

/* Empty / Loading */
.loading-state, .empty-state { display: flex; flex-direction: column; align-items: center; padding: 80px 0; color: #86868b; }
.loading-state .spinner { width: 36px; height: 36px; border: 3px solid #f1f1f3; border-top-color: #0071e3; border-radius: 50%; animation: spin 0.6s linear infinite; margin-bottom: 12px; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-icon { width: 64px; height: 64px; margin-bottom: 16px; opacity: 0.4; }

/* Table */
.table-wrapper { background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.06); }
.data-table { width: 100%; border-collapse: collapse; }
.data-table th { text-align: left; padding: 14px 20px; font-size: 13px; font-weight: 600; color: #86868b; background: #fafafa; border-bottom: 1px solid #f1f1f3; white-space: nowrap; }
.data-table td { padding: 14px 20px; font-size: 14px; color: #1d1d1f; border-bottom: 1px solid #f5f5f7; }
.data-table tr:hover td { background: #fafafa; }
.data-table tr:last-child td { border-bottom: none; }

.content-cell { display: flex; flex-direction: column; gap: 4px; }
.content-text { font-weight: 500; line-height: 1.5; }
.answer-preview { display: flex; align-items: center; gap: 4px; font-size: 12px; }
.answer-label { color: #86868b; flex-shrink: 0; }
.answer-value { color: #34c759; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 200px; }

.type-badge { display: inline-block; padding: 4px 10px; border-radius: 9999px; font-size: 12px; font-weight: 600; }

.difficulty-stars { font-size: 14px; letter-spacing: 1px; color: #ff9500; white-space: nowrap; }

.text-muted { color: #86868b; font-size: 13px; }

.action-btns { display: flex; gap: 6px; }
.action-btn { padding: 5px 12px; border: 1.5px solid #d2d2d7; border-radius: 9999px; background: #fff; color: #0071e3; font-size: 12px; font-weight: 500; cursor: pointer; transition: all 0.3s; white-space: nowrap; }
.action-btn:hover { background: #0071e3; color: #fff; border-color: #0071e3; }
.action-btn.danger { color: #ff3b30; border-color: #ff3b30; }
.action-btn.danger:hover { background: #ff3b30; color: #fff; }

/* Pagination */
.pagination { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 24px; }
.page-btn { padding: 8px 20px; border: 1.5px solid #d2d2d7; border-radius: 10px; background: #fff; color: #1d1d1f; font-size: 14px; font-weight: 500; cursor: pointer; transition: all 0.3s; }
.page-btn:hover:not(:disabled) { border-color: #0071e3; color: #0071e3; }
.page-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-info { font-size: 14px; color: #86868b; font-weight: 500; }

/* Modal */
.modal-overlay {
  position: fixed; inset: 0; z-index: 1000;
  background: rgba(0, 0, 0, 0.35); backdrop-filter: blur(4px);
  display: flex; align-items: center; justify-content: center;
  padding: 24px;
}
.modal {
  background: #fff; border-radius: 20px; width: 100%; max-width: 640px;
  max-height: 90vh; overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0,0,0,0.15);
  animation: modalIn 0.3s ease;
}
@keyframes modalIn { from { opacity: 0; transform: translateY(20px) scale(0.97); } to { opacity: 1; transform: translateY(0) scale(1); } }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 24px 28px 0; position: sticky; top: 0; background: #fff; z-index: 1; }
.modal-title { font-size: 20px; font-weight: 700; color: #1d1d1f; }
.modal-close {
  width: 32px; height: 32px; border-radius: 50%; border: none; background: #f5f5f7;
  display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.3s;
}
.modal-close:hover { background: #e8e8eb; }
.modal-close svg { width: 16px; height: 16px; color: #86868b; }
.modal-body { padding: 24px 28px; display: flex; flex-direction: column; gap: 18px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 12px; padding: 0 28px 24px; }

.form-row { display: flex; gap: 16px; }
.form-group { display: flex; flex-direction: column; gap: 6px; }
.form-label { font-size: 14px; font-weight: 600; color: #1d1d1f; }
.required { color: #ff3b30; }
.label-hint { font-weight: 400; font-size: 12px; color: #86868b; }
.form-input, .form-textarea, .form-select {
  padding: 10px 14px; border: 1.5px solid #d2d2d7; border-radius: 12px;
  font-size: 15px; color: #1d1d1f; outline: none; font-family: inherit;
  transition: border-color 0.3s; box-sizing: border-box;
}
.form-input:focus, .form-textarea:focus, .form-select:focus { border-color: #0071e3; }
.form-textarea { resize: vertical; min-height: 72px; }
.code-area { font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace; font-size: 13px; }

/* Options Editor */
.options-editor { display: flex; flex-direction: column; gap: 8px; }
.option-row { display: flex; align-items: center; gap: 8px; }
.option-radio, .option-checkbox {
  width: 22px; height: 22px; border-radius: 50%; border: 2px solid #d2d2d7;
  background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center;
  transition: all 0.2s; flex-shrink: 0; padding: 0;
}
.option-radio:hover, .option-checkbox:hover { border-color: #0071e3; }
.option-radio.selected, .option-checkbox.selected { border-color: #34c759; background: #e8f8ed; }
.radio-dot { width: 10px; height: 10px; border-radius: 50%; background: #34c759; }
.option-checkbox { border-radius: 6px; }
.option-checkbox svg { width: 13px; height: 13px; color: #34c759; }
.option-label { font-size: 14px; font-weight: 600; color: #86868b; width: 22px; flex-shrink: 0; }
.option-input {
  flex: 1; padding: 8px 12px; border: 1.5px solid #d2d2d7; border-radius: 10px;
  font-size: 14px; color: #1d1d1f; outline: none; transition: border-color 0.3s;
}
.option-input:focus { border-color: #0071e3; }
.option-remove {
  width: 28px; height: 28px; border-radius: 8px; border: none; background: transparent;
  display: flex; align-items: center; justify-content: center; cursor: pointer;
  color: #86868b; transition: all 0.2s; flex-shrink: 0;
}
.option-remove:hover { background: #ffe5e5; color: #ff3b30; }
.option-remove svg { width: 14px; height: 14px; }
.option-add {
  display: inline-flex; align-items: center; gap: 4px; padding: 8px 14px;
  border: 1.5px dashed #d2d2d7; border-radius: 10px; background: transparent;
  color: #0071e3; font-size: 13px; font-weight: 500; cursor: pointer;
  transition: all 0.2s; align-self: flex-start;
}
.option-add:hover { border-color: #0071e3; background: rgba(0,113,227,0.03); }
.option-add svg { width: 14px; height: 14px; }

/* Judge Options */
.judge-options { display: flex; gap: 12px; }
.judge-btn {
  flex: 1; display: flex; align-items: center; justify-content: center; gap: 8px;
  padding: 14px; border: 2px solid #d2d2d7; border-radius: 14px;
  cursor: pointer; transition: all 0.2s; font-size: 15px; font-weight: 600; color: #1d1d1f;
}
.judge-btn:hover { border-color: #0071e3; }
.judge-btn.active { border-color: #34c759; background: #e8f8ed; color: #34c759; }
.judge-btn svg { width: 20px; height: 20px; }
.judge-radio { display: none; }

@media (max-width: 900px) {
  .content-layout { flex-direction: column; }
  .sidebar { width: 100%; }
  .form-row { flex-direction: column; }
  .toolbar { flex-direction: column; align-items: stretch; }
  .search-box { max-width: none; }
}
</style>
