<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { listCourses, getCourse } from '@/api/course'
import { getSectionsByCourse, createSection, updateSection, reorderSections, deleteSection } from '@/api/section'
import type { Course, CourseSection, CreateSectionRequest } from '@/types/api'

const courses = ref<Course[]>([])
const sections = ref<CourseSection[]>([])
const loading = ref(true)
const sectionsLoading = ref(false)
const selectedCourseId = ref<string | null>(null)
const keyword = ref('')

const showModal = ref(false)
const isEditing = ref(false)
const editingId = ref<string | null>(null)
const submitting = ref(false)

const form = reactive<CreateSectionRequest>({
  title: '',
  courseId: '',
  content: '',
  duration: undefined,
})

const filteredSections = computed(() => {
  if (!keyword.value.trim()) return sections.value
  const kw = keyword.value.trim().toLowerCase()
  return sections.value.filter(s => s.title.toLowerCase().includes(kw))
})

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

async function fetchSections() {
  if (!selectedCourseId.value) {
    sections.value = []
    return
  }
  sectionsLoading.value = true
  try {
    const res = await getSectionsByCourse(selectedCourseId.value)
    sections.value = res.sort((a, b) => a.sortOrder - b.sortOrder)
  } catch {
    sections.value = []
  } finally {
    sectionsLoading.value = false
  }
}

function selectCourse(courseId: string) {
  selectedCourseId.value = courseId
  fetchSections()
}

function getCourseTitle(id: string) {
  return courses.value.find(c => c.id === id)?.title || '未知课程'
}

function openCreateModal() {
  if (!selectedCourseId.value) {
    alert('请先选择一门课程')
    return
  }
  isEditing.value = false
  editingId.value = null
  form.title = ''
  form.content = ''
  form.duration = undefined
  form.courseId = selectedCourseId.value
  showModal.value = true
}

function openEditModal(section: CourseSection) {
  isEditing.value = true
  editingId.value = section.id
  form.title = section.title
  form.content = section.content || ''
  form.duration = section.duration
  form.courseId = section.courseId
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

async function handleSubmit() {
  if (!form.title.trim()) return
  submitting.value = true
  try {
    if (isEditing.value && editingId.value) {
      await updateSection(editingId.value, {
        title: form.title,
        content: form.content,
        duration: form.duration,
      })
    } else {
      await createSection({ ...form })
    }
    closeModal()
    fetchSections()
  } catch {
    // error handled by interceptor
  } finally {
    submitting.value = false
  }
}

async function handleDelete(id: string) {
  if (!confirm('确定要删除该章节吗？此操作不可恢复。')) return
  try {
    await deleteSection(id)
    fetchSections()
  } catch { /* handled */ }
}

async function moveUp(index: number) {
  if (index === 0) return
  const newSections = [...sections.value]
  const temp = newSections[index]
  newSections[index] = newSections[index - 1]
  newSections[index - 1] = temp
  sections.value = newSections
  await saveOrder()
}

async function moveDown(index: number) {
  if (index === sections.value.length - 1) return
  const newSections = [...sections.value]
  const temp = newSections[index]
  newSections[index] = newSections[index + 1]
  newSections[index + 1] = temp
  sections.value = newSections
  await saveOrder()
}

async function saveOrder() {
  if (!selectedCourseId.value) return
  const sectionIds = sections.value.map(s => s.id)
  try {
    await reorderSections({
      courseId: selectedCourseId.value,
      sectionIds: sectionIds,
    })
  } catch {
    // 出错了重新获取
    fetchSections()
  }
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
}

onMounted(() => {
  fetchCourses()
})
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <div>
        <h1 class="page-title">章节管理</h1>
        <p class="page-subtitle">管理课程章节，支持拖拽排序</p>
      </div>
      <button class="btn-primary" @click="openCreateModal">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        新增章节
      </button>
    </div>

    <div class="content-layout">
      <div class="course-sidebar">
        <div class="sidebar-header">
          <h3>课程列表</h3>
          <input v-model="keyword" type="text" class="search-input" placeholder="搜索课程..." />
        </div>
        <div v-if="loading" class="loading-text">加载中...</div>
        <ul v-else class="course-list">
          <li
            v-for="course in courses.filter(c => !keyword || c.title.toLowerCase().includes(keyword.toLowerCase()))"
            :key="course.id"
            :class="['course-item', { active: selectedCourseId === course.id }]"
            @click="selectCourse(course.id)"
          >
            <span class="course-name">{{ course.title }}</span>
            <span class="course-status" :class="course.status.toLowerCase()">{{
                course.status === 'DRAFT' ? '草稿' : course.status === 'PUBLISHED' ? '已发布' : '已归档'
              }}</span>
          </li>
        </ul>
      </div>

      <div class="section-main">
        <div v-if="!selectedCourseId" class="empty-state">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
          <p>请在左侧选择一门课程查看章节</p>
        </div>
        <div v-else-if="sectionsLoading" class="loading-state"><div class="spinner"></div><p>加载章节中...</p></div>
        <div v-else-if="sections.length === 0" class="empty-state">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
          <p>该课程暂无章节，点击上方按钮创建第一章节</p>
          <button class="btn-primary" style="margin-top: 16px;" @click="openCreateModal">创建章节</button>
        </div>
        <div v-else class="section-list">
          <div
            v-for="(section, index) in filteredSections"
            :key="section.id"
            class="section-item"
          >
            <div class="section-info">
              <div class="section-order">{{ index + 1 }}</div>
              <div class="section-content">
                <div class="section-title">
                  {{ section.title }}
                </div>
                <div class="section-meta">
                  <span v-if="section.duration">{{ section.duration }} 分钟</span>
                  <span v-if="section.duration && section.content" class="divider">•</span>
                  <span v-if="section.content">{{ section.content.length }} 字符</span>
                  <span class="divider">•</span>
                  更新于 {{ formatDate(section.updatedAt) }}
                </div>
              </div>
            </div>
            <div class="section-actions">
              <button class="action-btn" @click="moveUp(index)" :disabled="index === 0" title="上移">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>
              </button>
              <button class="action-btn" @click="moveDown(index)" :disabled="index === filteredSections.length - 1" title="下移">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
              </button>
              <button class="action-btn" @click="openEditModal(section)">编辑</button>
              <button class="action-btn danger" @click="handleDelete(section.id)">删除</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-header">
            <h3 class="modal-title">{{ isEditing ? '编辑章节' : '创建章节' }}</h3>
            <button class="modal-close" @click="closeModal">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label class="form-label">所属课程</label>
              <input type="text" class="form-input" :value="getCourseTitle(form.courseId)" disabled />
            </div>
            <div class="form-group">
              <label class="form-label">章节标题 <span class="required">*</span></label>
              <input v-model="form.title" type="text" class="form-input" placeholder="请输入章节标题" maxlength="200"/>
            </div>
            <div class="form-group">
              <label class="form-label">章节内容</label>
              <textarea v-model="form.content" class="form-textarea" placeholder="请输入章节内容描述" rows="6"></textarea>
            </div>
            <div class="form-group">
              <label class="form-label">预计时长（分钟）</label>
              <input v-model.number="form.duration" type="number" class="form-input" placeholder="预计学习时长" min="1"/>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" @click="closeModal" :disabled="submitting">取消</button>
            <button class="btn-primary" @click="handleSubmit" :disabled="submitting || !form.title.trim()">
              {{ submitting ? '保存中...' : (isEditing ? '保存修改' : '创建章节') }}
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

.content-layout {
  display: flex; gap: 20px; min-height: 600px;
}

.course-sidebar {
  width: 320px; flex-shrink: 0;
  background: #fff; border-radius: 16px; overflow: hidden;
  box-shadow: 0 2px 12px rgba(0,0,0,0.06);
}
.sidebar-header {
  padding: 16px; border-bottom: 1px solid #f1f1f3;
}
.sidebar-header h3 {
  margin: 0 0 12px; font-size: 16px; font-weight: 600; color: #1d1d1f;
}
.search-input {
  width: 100%; padding: 8px 12px; border: 1.5px solid #d2d2d7; border-radius: 10px;
  font-size: 14px; box-sizing: border-box; outline: none;
}
.search-input:focus { border-color: #0071e3; }
.loading-text {
  padding: 24px; text-align: center; color: #86868b; font-size: 14px;
}
.course-list {
  list-style: none; margin: 0; padding: 0; max-height: 600px; overflow-y: auto;
}
.course-item {
  display: flex; flex-direction: column; gap: 4px;
  padding: 14px 16px; cursor: pointer; transition: background 0.2s;
  border-bottom: 1px solid #f5f5f7;
}
.course-item:hover { background: #fafafa; }
.course-item.active { background: rgba(0, 113, 227, 0.05); border-left: 3px solid #0071e3; }
.course-name {
  font-size: 14px; font-weight: 500; color: #1d1d1f;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.course-status {
  display: inline-block;
  font-size: 12px; padding: 2px 8px; border-radius: 9999px;
  align-self: flex-start;
}
.course-status.draft { background: #f5f5f7; color: #86868b; }
.course-status.published { background: rgba(52, 199, 89, 0.1); color: #34c759; }
.course-status.archived { background: rgba(255, 149, 0, 0.1); color: #ff9500; }

.section-main {
  flex: 1;
  background: #fff; border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.06);
  padding: 20px;
}

.loading-state, .empty-state { display: flex; flex-direction: column; align-items: center; padding: 80px 0; color: #86868b; }
.loading-state .spinner { width: 36px; height: 36px; border: 3px solid #f1f1f3; border-top-color: #0071e3; border-radius: 50%; animation: spin 0.6s linear infinite; margin-bottom: 12px; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-state svg { width: 64px; height: 64px; margin-bottom: 16px; opacity: 0.4; }

.section-list {
  display: flex; flex-direction: column; gap: 12px;
}
.section-item {
  display: flex; align-items: center; justify-content: space-between;
  padding: 16px; border: 1px solid #f1f1f3; border-radius: 12px;
  transition: all 0.2s;
}
.section-item:hover { border-color: #0071e3; box-shadow: 0 2px 8px rgba(0,113,227,0.08); }
.section-info {
  display: flex; align-items: center; gap: 12px; flex: 1; min-width: 0;
}
.section-order {
  width: 36px; height: 36px; border-radius: 8px;
  background: #f5f5f7; display: flex; align-items: center; justify-content: center;
  font-size: 14px; font-weight: 600; color: #86868b; flex-shrink: 0;
}
.section-content {
  flex: 1; min-width: 0;
}
.section-title {
  font-size: 15px; font-weight: 600; color: #1d1d1f;
  margin-bottom: 4px;
}
.section-meta {
  font-size: 13px; color: #86868b;
}
.divider { margin: 0 6px; }
.section-actions {
  display: flex; align-items: center; gap: 6px;
}
.action-btn {
  display: inline-flex; align-items: center; justify-content: center;
  padding: 6px 10px; border: 1.5px solid #d2d2d7; border-radius: 8px;
  background: #fff; color: #0071e3; font-size: 13px; font-weight: 500;
  cursor: pointer; transition: all 0.2s;
}
.action-btn:hover:not(:disabled) { background: #0071e3; color: #fff; border-color: #0071e3; }
.action-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.action-btn.danger { color: #ff3b30; border-color: #ff3b30; }
.action-btn.danger:hover { background: #ff3b30; color: #fff; }
.action-btn svg { width: 16px; height: 16px; }

/* Modal */
.modal-overlay {
  position: fixed; inset: 0; z-index: 1000;
  background: rgba(0, 0, 0, 0.35);
  backdrop-filter: blur(4px);
  display: flex; align-items: center; justify-content: center;
  padding: 24px;
}
.modal {
  background: #fff; border-radius: 20px; width: 100%; max-width: 520px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.15);
  animation: modalIn 0.3s ease;
}
@keyframes modalIn { from { opacity: 0; transform: translateY(20px) scale(0.97); } to { opacity: 1; transform: translateY(0) scale(1); } }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 24px 28px 0; }
.modal-title { font-size: 20px; font-weight: 700; color: #1d1d1f; }
.modal-close {
  width: 32px; height: 32px; border-radius: 50%; border: none; background: #f5f5f7;
  display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.3s;
}
.modal-close:hover { background: #e8e8eb; }
.modal-close svg { width: 16px; height: 16px; color: #86868b; }
.modal-body { padding: 24px 28px; display: flex; flex-direction: column; gap: 18px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 12px; padding: 0 28px 24px; }

.form-group { display: flex; flex-direction: column; gap: 6px; }
.form-label { font-size: 14px; font-weight: 600; color: #1d1d1f; }
.required { color: #ff3b30; }
.form-input, .form-textarea, .form-select {
  padding: 10px 14px; border: 1.5px solid #d2d2d7; border-radius: 12px;
  font-size: 15px; color: #1d1d1f; outline: none; font-family: inherit;
  transition: border-color 0.3s; box-sizing: border-box;
}
.form-input:disabled { background: #f5f5f7; color: #86868b; }
.form-input:focus, .form-textarea:focus, .form-select:focus { border-color: #0071e3; }
.form-textarea { resize: vertical; min-height: 120px; }
</style>
