<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { listCourses } from '@/api/course'
import { getExamsByCourse, createExam, updateExam, publishExam, deleteExam } from '@/api/exam'
import type { Course, Exam, CreateExamRequest } from '@/types/api'
import { ExamStatus, ExamType } from '@/types/api'

const courses = ref<Course[]>([])
const exams = ref<Exam[]>([])
const loading = ref(true)
const submitting = ref(false)

const selectedCourseId = ref<string | null>(null)
const selectedStatus = ref<ExamStatus | ''>('')
const selectedType = ref<ExamType | ''>('')

const showModal = ref(false)
const isEditing = ref(false)
const editingId = ref<string | null>(null)

const form = reactive<CreateExamRequest & { type: ExamType }>({
  title: '',
  courseId: '',
  duration: 120,
  totalScore: 100,
  passScore: 60,
  config: '',
  type: ExamType.PRACTICE,
})

const typeOptions: { value: ExamType; label: string }[] = [
  { value: ExamType.PRACTICE, label: '练习考试' },
  { value: ExamType.FORMAL, label: '正式考试' },
  { value: ExamType.MOCK, label: '模拟考试' },
]

const typeLabel: Record<string, string> = {
  PRACTICE: '练习',
  FORMAL: '正式',
  MOCK: '模拟',
}

const typeColor: Record<string, string> = {
  PRACTICE: '#34c759',
  FORMAL: '#0071e3',
  MOCK: '#af52de',
}

const statusLabel: Record<string, string> = {
  DRAFT: '草稿',
  PUBLISHED: '已发布',
}

const statusColor: Record<string, string> = {
  DRAFT: '#86868b',
  PUBLISHED: '#34c759',
}

const statusBgColor: Record<string, string> = {
  DRAFT: 'rgba(134, 134, 139, 0.1)',
  PUBLISHED: 'rgba(52, 199, 89, 0.1)',
}

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

async function fetchExams() {
  if (!selectedCourseId.value) {
    exams.value = []
    return
  }
  try {
    const res = await getExamsByCourse(selectedCourseId.value)
    exams.value = res
  } catch {
    exams.value = []
  }
}

function selectCourse(courseId: string) {
  selectedCourseId.value = courseId
  fetchExams()
}

function openCreateModal() {
  resetForm()
  if (selectedCourseId.value) {
    form.courseId = selectedCourseId.value
  }
  isEditing.value = false
  showModal.value = true
}

function openEditModal(exam: Exam) {
  isEditing.value = true
  editingId.value = exam.id
  form.title = exam.title
  form.courseId = exam.courseId
  form.duration = exam.duration
  form.totalScore = exam.totalScore
  form.passScore = exam.passScore
  form.type = exam.type || ExamType.PRACTICE
  form.config = exam.config || ''
  showModal.value = true
}

function resetForm() {
  form.title = ''
  form.courseId = ''
  form.duration = 120
  form.totalScore = 100
  form.passScore = 60
  form.type = ExamType.PRACTICE
  form.config = ''
  isEditing.value = false
  editingId.value = null
}

function closeModal() {
  showModal.value = false
  resetForm()
}

function getCourseTitle(courseId: string) {
  const course = courses.value.find(c => c.id === courseId)
  return course?.title || '-'
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
}

async function handleSubmit() {
  if (!form.title.trim()) return
  if (!form.courseId) return

  submitting.value = true
  try {
    const data = { ...form }
    if (isEditing.value && editingId.value) {
      await updateExam(editingId.value, data as Partial<Exam>)
    } else {
      await createExam(data)
    }
    closeModal()
    fetchExams()
  } catch {
    // error handled by interceptor
  } finally {
    submitting.value = false
  }
}

async function handlePublish(id: string) {
  if (!confirm('确定要发布该考试吗？发布后学生可以开始考试。')) return
  try {
    await publishExam(id)
    fetchExams()
  } catch { /* handled */ }
}

async function handleDelete(id: string) {
  if (!confirm('确定要删除该考试吗？此操作不可恢复，已有的考试记录也会受影响。')) return
  try {
    await deleteExam(id)
    fetchExams()
  } catch { /* handled */ }
}

onMounted(() => {
  fetchCourses()
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">考试管理</h1>
        <p class="page-subtitle">管理课程考试，共 {{ exams.length }} 个考试</p>
      </div>
      <button class="btn-primary" @click="openCreateModal">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="12" y1="5" x2="12" y2="19"/>
          <line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
        创建考试
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
            <span class="course-status" :class="course.status?.toLowerCase() || 'draft'">
              {{ course.status === 'DRAFT' ? '草稿' : course.status === 'PUBLISHED' ? '已发布' : '已归档' }}
            </span>
          </li>
        </ul>
      </div>

      <div class="main">
        <div v-if="!selectedCourseId" class="empty-state">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="empty-icon">
            <path d="M9 11l3 3L22 4"/>
            <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
          </svg>
          <p>请在左侧选择一门课程查看考试</p>
        </div>

        <template v-else>
          <div class="toolbar">
            <div class="filter-group">
              <select v-model="selectedType" class="filter-select" @change="fetchExams">
                <option value="">全部类型</option>
                <option v-for="t in typeOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
              </select>
              <select v-model="selectedStatus" class="filter-select" @change="fetchExams">
                <option value="">全部状态</option>
                <option value="DRAFT">草稿</option>
                <option value="PUBLISHED">已发布</option>
              </select>
            </div>
          </div>

          <div v-if="exams.length === 0" class="empty-state">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="empty-icon">
              <rect x="9" y="3" width="6" height="4" rx="1"/>
              <path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/>
            </svg>
            <p>暂无考试数据</p>
            <button class="btn-primary" style="margin-top: 16px;" @click="openCreateModal">创建第一个考试</button>
          </div>

          <div v-else class="table-wrapper">
            <table class="data-table">
              <thead>
              <tr>
                <th>考试标题</th>
                <th>类型</th>
                <th>时长</th>
                <th>总分/及格</th>
                <th>状态</th>
                <th>更新时间</th>
                <th style="width: 160px;">操作</th>
              </tr>
              </thead>
              <tbody>
              <tr v-for="exam in exams" :key="exam.id">
                <td>
                  <div class="content-cell">
                    <span class="content-text">{{ exam.title }}</span>
                  </div>
                </td>
                <td>
                  <span class="type-badge" :style="{ background: typeColor[exam.type || 'PRACTICE'] + '1a', color: typeColor[exam.type || 'PRACTICE'] }">
                    {{ typeLabel[exam.type || 'PRACTICE'] }}
                  </span>
                </td>
                <td class="text-muted">{{ exam.duration }} 分钟</td>
                <td class="text-muted">{{ exam.totalScore }} / {{ exam.passScore }}</td>
                <td>
                  <span class="status-badge" :style="{ background: statusBgColor[exam.status], color: statusColor[exam.status] }">
                    {{ statusLabel[exam.status] }}
                  </span>
                </td>
                <td class="text-muted">{{ formatDate(exam.updatedAt) }}</td>
                <td>
                  <div class="action-btns">
                    <button class="action-btn" @click="openEditModal(exam)">编辑</button>
                    <button v-if="exam.status === 'DRAFT'" class="action-btn success" @click="handlePublish(exam.id)">发布</button>
                    <button class="action-btn danger" @click="handleDelete(exam.id)">删除</button>
                  </div>
                </td>
              </tr>
              </tbody>
            </table>
          </div>
        </template>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-header">
            <h3 class="modal-title">{{ isEditing ? '编辑考试' : '创建考试' }}</h3>
            <button class="modal-close" @click="closeModal">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="6" x2="6" y2="18"/>
                <line x1="6" y1="6" x2="18" y2="18"/>
              </svg>
            </button>
          </div>
          <div class="modal-body">
            <div class="form-row">
              <div class="form-group" style="flex: 1;">
                <label class="form-label">所属课程 <span class="required">*</span></label>
                <select v-model="form.courseId" class="form-select">
                  <option value="">请选择课程</option>
                  <option v-for="course in courses" :key="course.id" :value="course.id">{{ course.title }}</option>
                </select>
              </div>
              <div class="form-group" style="flex: 1;">
                <label class="form-label">考试类型</label>
                <select v-model="form.type" class="form-select">
                  <option v-for="t in typeOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
                </select>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">考试标题 <span class="required">*</span></label>
              <input v-model="form.title" type="text" class="form-input" placeholder="请输入考试标题" />
            </div>

            <div class="form-row">
              <div class="form-group" style="flex: 1;">
                <label class="form-label">考试时长（分钟）</label>
                <input v-model.number="form.duration" type="number" class="form-input" min="10" max="300" placeholder="120" />
              </div>
              <div class="form-group" style="flex: 1;">
                <label class="form-label">总分</label>
                <input v-model.number="form.totalScore" type="number" class="form-input" min="10" max="1000" placeholder="100" />
              </div>
              <div class="form-group" style="flex: 1;">
                <label class="form-label">及格分</label>
                <input v-model.number="form.passScore" type="number" class="form-input" min="0" max="1000" placeholder="60" />
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">配置信息（JSON）</label>
              <textarea v-model="form.config" class="form-textarea" placeholder="JSON 格式的额外配置，例如题目抽题规则等（可选）" rows="3"></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" @click="closeModal" :disabled="submitting">取消</button>
            <button class="btn-primary" @click="handleSubmit" :disabled="submitting || !form.title.trim() || !form.courseId">
              {{ submitting ? '保存中...' : (isEditing ? '保存修改' : '创建考试') }}
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

/* Toolbar */
.toolbar { display: flex; align-items: center; gap: 16px; margin-bottom: 20px; flex-wrap: wrap; }
.filter-group { display: flex; gap: 10px; }
.filter-select { padding: 10px 14px; border: 1.5px solid #d2d2d7; border-radius: 12px; font-size: 14px; color: #1d1d1f; background: #fff; outline: none; cursor: pointer; }
.filter-select:focus { border-color: #0071e3; }

/* Empty / Loading */
.empty-state { display: flex; flex-direction: column; align-items: center; padding: 80px 0; color: #86868b; }
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

.type-badge { display: inline-block; padding: 4px 10px; border-radius: 9999px; font-size: 12px; font-weight: 600; }

.status-badge { display: inline-block; padding: 4px 10px; border-radius: 9999px; font-size: 12px; font-weight: 600; }

.text-muted { color: #86868b; font-size: 13px; }

.action-btns { display: flex; gap: 6px; flex-wrap: wrap; }
.action-btn { padding: 5px 12px; border: 1.5px solid #d2d2d7; border-radius: 9999px; background: #fff; color: #0071e3; font-size: 12px; font-weight: 500; cursor: pointer; transition: all 0.3s; white-space: nowrap; }
.action-btn:hover { background: #0071e3; color: #fff; border-color: #0071e3; }
.action-btn.success { color: #34c759; border-color: #34c759; }
.action-btn.success:hover { background: #34c759; color: #fff; }
.action-btn.danger { color: #ff3b30; border-color: #ff3b30; }
.action-btn.danger:hover { background: #ff3b30; color: #fff; }

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
.form-group { display: flex; flex-direction: column; gap: 6px; flex: 1; }
.form-label { font-size: 14px; font-weight: 600; color: #1d1d1f; }
.required { color: #ff3b30; }
.form-input, .form-textarea, .form-select {
  padding: 10px 14px; border: 1.5px solid #d2d2d7; border-radius: 12px;
  font-size: 15px; color: #1d1d1f; outline: none; font-family: inherit;
  transition: border-color 0.3s; box-sizing: border-box;
}
.form-input:focus, .form-textarea:focus, .form-select:focus { border-color: #0071e3; }
.form-textarea { resize: vertical; min-height: 72px; }

@media (max-width: 900px) {
  .content-layout { flex-direction: column; }
  .sidebar { width: 100%; }
  .form-row { flex-direction: column; }
  .toolbar { flex-direction: column; align-items: stretch; }
}
</style>
