<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { listCourses, createCourse, updateCourse, publishCourse, archiveCourse, deleteCourse } from '@/api/course'
import { uploadFile, attachFilesToEntity } from '@/api/file'
import type { Course, CreateCourseRequest } from '@/types/api'
import { CourseDifficulty, CourseStatus } from '@/types/api'

const courses = ref<Course[]>([])
const loading = ref(true)
const submitting = ref(false)
const totalPages = ref(1)
const totalRecords = ref(0)
const currentPage = ref(1)
const pageSize = 10

const keyword = ref('')
const selectedDifficulty = ref<CourseDifficulty | ''>('')
const selectedStatus = ref<CourseStatus | ''>('')

const showModal = ref(false)
const isEditing = ref(false)
const editingId = ref<string | null>(null)
const coverFile = ref<File | null>(null)
const coverPreview = ref<string>('')
const coverUploading = ref(false)
const uploadedFileId = ref<string | null>(null)
const form = reactive<CreateCourseRequest>({
  title: '',
  description: '',
  coverImage: '',
  difficulty: CourseDifficulty.BEGINNER,
  tags: '',
})

const difficultyOptions: { value: CourseDifficulty; label: string }[] = [
  { value: CourseDifficulty.BEGINNER, label: '初级' },
  { value: CourseDifficulty.INTERMEDIATE, label: '中级' },
  { value: CourseDifficulty.ADVANCED, label: '高级' },
]

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

const statusLabel: Record<string, string> = {
  DRAFT: '草稿',
  PUBLISHED: '已发布',
  ARCHIVED: '已归档',
}

const statusColor: Record<string, string> = {
  DRAFT: '#86868b',
  PUBLISHED: '#34c759',
  ARCHIVED: '#ff9500',
}

async function fetchCourses() {
  loading.value = true
  try {
    const params: Record<string, unknown> = { page: currentPage.value, size: pageSize }
    if (keyword.value.trim()) params.keyword = keyword.value.trim()
    if (selectedDifficulty.value) params.difficulty = selectedDifficulty.value
    if (selectedStatus.value) params.status = selectedStatus.value
    const res = await listCourses(params as Parameters<typeof listCourses>[0])
    courses.value = res.records
    totalPages.value = res.pages
    totalRecords.value = res.total
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

function goToPage(page: number) {
  currentPage.value = page
  fetchCourses()
}

function openCreateModal() {
  isEditing.value = false
  editingId.value = null
  coverFile.value = null
  coverPreview.value = ''
  coverUploading.value = false
  uploadedFileId.value = null
  form.title = ''
  form.description = ''
  form.coverImage = ''
  form.difficulty = CourseDifficulty.BEGINNER
  form.tags = ''
  showModal.value = true
}

function openEditModal(course: Course) {
  isEditing.value = true
  editingId.value = course.id
  coverFile.value = null
  coverPreview.value = course.coverImage || ''
  coverUploading.value = false
  uploadedFileId.value = null
  form.title = course.title
  form.description = course.description || ''
  form.coverImage = course.coverImage || ''
  form.difficulty = course.difficulty
  form.tags = typeof course.tags === 'string' ? course.tags : ''
  showModal.value = true
}

function handleCoverChange(event: Event) {
  const fileInput = event.target as HTMLInputElement
  const file = fileInput.files?.[0]
  if (!file) return

  if (!file.type.startsWith('image/')) {
    alert('请选择图片文件')
    fileInput.value = ''
    return
  }

  coverFile.value = file
  uploadedFileId.value = null

  const reader = new FileReader()
  reader.onload = (e) => {
    coverPreview.value = e.target?.result as string
  }
  reader.readAsDataURL(file)
}

async function uploadCover() {
  if (!coverFile.value) return

  coverUploading.value = true
  try {
    const formData = new FormData()
    formData.append('file', coverFile.value)
    const result = await uploadFile(formData)

    form.coverImage = result.fileUrl
    uploadedFileId.value = result.id
    coverPreview.value = result.fileUrl
  } catch {
    alert('上传失败，请重试')
  } finally {
    coverUploading.value = false
  }
}

function clearCover() {
  coverFile.value = null
  coverPreview.value = ''
  uploadedFileId.value = null
  form.coverImage = ''
}

function closeModal() {
  showModal.value = false
}

async function handleSubmit() {
  if (!form.title.trim()) return
  submitting.value = true
  try {
    // 如果上传了新文件但尚未关联到课程，并且课程已经存在，则关联
    if (isEditing.value && editingId.value && uploadedFileId.value) {
      await attachFilesToEntity({
        fileIds: [uploadedFileId.value],
        entityType: 'courses',
        entityId: editingId.value
      })
    }

    if (isEditing.value && editingId.value) {
      await updateCourse(editingId.value, {
        title: form.title,
        description: form.description,
        coverImage: form.coverImage,
        difficulty: form.difficulty,
        tags: form.tags,
      } as Partial<Course>)
    } else if (coverFile.value && uploadedFileId.value && form.coverImage) {
      // 新建课程，先创建，再关联文件
      const newCourse = await createCourse({ ...form })
      await attachFilesToEntity({
        fileIds: [uploadedFileId.value],
        entityType: 'courses',
        entityId: newCourse.id
      })
    } else {
      await createCourse({ ...form })
    }
    closeModal()
    fetchCourses()
  } catch {
    // error handled by interceptor
  } finally {
    submitting.value = false
  }
}

async function handlePublish(id: string) {
  if (!confirm('确定要发布该课程吗？发布后学生将可以查看和学习。')) return
  try {
    await publishCourse(id)
    fetchCourses()
  } catch { /* handled */ }
}

async function handleArchive(id: string) {
  if (!confirm('确定要归档该课程吗？归档后学生将无法访问。')) return
  try {
    await archiveCourse(id)
    fetchCourses()
  } catch { /* handled */ }
}

async function handleDelete(id: string) {
  if (!confirm('确定要删除该课程吗？此操作不可恢复。')) return
  try {
    await deleteCourse(id)
    fetchCourses()
  } catch { /* handled */ }
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
        <h1 class="page-title">课程管理</h1>
        <p class="page-subtitle">管理平台所有课程，共 {{ totalRecords }} 门</p>
      </div>
      <button class="btn-primary" @click="openCreateModal">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        创建课程
      </button>
    </div>

    <div class="toolbar">
      <div class="search-box">
        <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input v-model="keyword" type="text" class="search-input" placeholder="搜索课程标题或描述..." @keyup.enter="handleSearch"/>
      </div>
      <div class="filter-group">
        <select v-model="selectedDifficulty" class="filter-select" @change="handleSearch">
          <option value="">全部难度</option>
          <option v-for="d in difficultyOptions" :key="d.value" :value="d.value">{{ d.label }}</option>
        </select>
        <select v-model="selectedStatus" class="filter-select" @change="handleSearch">
          <option value="">全部状态</option>
          <option value="DRAFT">草稿</option>
          <option value="PUBLISHED">已发布</option>
          <option value="ARCHIVED">已归档</option>
        </select>
      </div>
    </div>

    <div v-if="loading" class="loading-state"><div class="spinner"></div><p>加载中...</p></div>

    <div v-else-if="courses.length === 0" class="empty-state">
      <svg class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
      <p>暂无课程数据</p>
      <button class="btn-primary" style="margin-top: 16px;" @click="openCreateModal">创建第一门课程</button>
    </div>

    <div v-else class="table-wrapper">
      <table class="data-table">
        <thead>
        <tr>
          <th style="width: 30%;">课程名称</th>
          <th>难度</th>
          <th>状态</th>
          <th>标签</th>
          <th>创建时间</th>
          <th style="width: 200px;">操作</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="course in courses" :key="course.id">
          <td>
            <div class="course-title-cell">
              <div class="cover-thumb" :style="course.coverImage ? { backgroundImage: `url(${course.coverImage})` } : {}">
                <svg v-if="!course.coverImage" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/></svg>
              </div>
              <div class="course-title-info">
                <span class="course-name">{{ course.title }}</span>
                <span class="course-desc">{{ course.description || '暂无简介' }}</span>
              </div>
            </div>
          </td>
          <td>
              <span class="badge" :style="{ background: difficultyColor[course.difficulty] + '1a', color: difficultyColor[course.difficulty] }">
                {{ difficultyLabel[course.difficulty] || course.difficulty }}
              </span>
          </td>
          <td>
              <span class="status-indicator" :style="{ color: statusColor[course.status] }">
                <span class="status-dot" :style="{ background: statusColor[course.status] }"></span>
                {{ statusLabel[course.status] || course.status }}
              </span>
          </td>
          <td>
            <span v-if="course.tags" class="tag-text">{{ course.tags }}</span>
            <span v-else class="text-muted">—</span>
          </td>
          <td class="text-muted">{{ formatDate(course.createdAt) }}</td>
          <td>
            <div class="action-btns">
              <button class="action-btn" @click="openEditModal(course)">编辑</button>
              <button v-if="course.status === 'DRAFT'" class="action-btn publish" @click="handlePublish(course.id)">发布</button>
              <button v-if="course.status === 'PUBLISHED'" class="action-btn archive" @click="handleArchive(course.id)">归档</button>
              <button class="action-btn danger" @click="handleDelete(course.id)">删除</button>
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

    <Teleport to="body">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-header">
            <h3 class="modal-title">{{ isEditing ? '编辑课程' : '创建课程' }}</h3>
            <button class="modal-close" @click="closeModal">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label class="form-label">课程标题 <span class="required">*</span></label>
              <input v-model="form.title" type="text" class="form-input" placeholder="请输入课程标题" maxlength="200"/>
            </div>
            <div class="form-group">
              <label class="form-label">课程简介</label>
              <textarea v-model="form.description" class="form-textarea" placeholder="请输入课程简介" rows="3"></textarea>
            </div>
            <div class="form-group">
              <label class="form-label">封面图片</label>
              <div class="cover-upload-area">
                <div v-if="coverPreview" class="cover-preview">
                  <img :src="coverPreview" alt="封面预览" />
                  <button class="cover-clear" @click="clearCover" :disabled="coverUploading || submitting">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                  </button>
                </div>
                <div v-else class="cover-placeholder">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
                  <span>点击选择图片上传</span>
                  <input type="file" accept="image/*" class="file-input" @change="handleCoverChange" :disabled="coverUploading || submitting"/>
                </div>
                <button v-if="coverFile && !form.coverImage" class="btn-upload" @click="uploadCover" :disabled="coverUploading || submitting">
                  {{ coverUploading ? '上传中...' : '上传图片' }}
                </button>
              </div>
              <div v-if="form.coverImage" class="url-display">
                <span class="url-label">地址：</span>
                <span class="url-text">{{ form.coverImage }}</span>
              </div>
            </div>
            <div class="form-group">
              <label class="form-label">难度等级</label>
              <select v-model="form.difficulty" class="form-select">
                <option v-for="d in difficultyOptions" :key="d.value" :value="d.value">{{ d.label }}</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">标签</label>
              <input v-model="form.tags" type="text" class="form-input" placeholder="多个标签用逗号分隔，如：Java,Spring,后端"/>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn-secondary" @click="closeModal" :disabled="submitting">取消</button>
            <button class="btn-primary" @click="handleSubmit" :disabled="submitting || !form.title.trim()">
              {{ submitting ? '保存中...' : (isEditing ? '保存修改' : '创建课程') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.page-container { max-width: 1200px; margin: 0 auto; padding: 32px 24px; }
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

/* Toolbar */
.toolbar { display: flex; align-items: center; gap: 16px; margin-bottom: 20px; flex-wrap: wrap; }
.search-box { position: relative; flex: 1; min-width: 200px; max-width: 360px; }
.search-icon { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); width: 18px; height: 18px; color: #86868b; }
.search-input { width: 100%; padding: 10px 14px 10px 40px; border: 1.5px solid #d2d2d7; border-radius: 12px; font-size: 15px; color: #1d1d1f; outline: none; box-sizing: border-box; }
.search-input:focus { border-color: #0071e3; }
.filter-group { display: flex; gap: 10px; }
.filter-select { padding: 10px 14px; border: 1.5px solid #d2d2d7; border-radius: 12px; font-size: 14px; color: #1d1d1f; background: #fff; outline: none; cursor: pointer; }
.filter-select:focus { border-color: #0071e3; }

/* Loading / Empty */
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

.course-title-cell { display: flex; align-items: center; gap: 12px; }
.cover-thumb {
  width: 44px; height: 44px; border-radius: 10px; background: #f5f5f7;
  display: flex; align-items: center; justify-content: center; flex-shrink: 0;
  background-size: cover; background-position: center;
}
.cover-thumb svg { width: 20px; height: 20px; color: #86868b; }
.course-title-info { display: flex; flex-direction: column; min-width: 0; }
.course-name { font-weight: 600; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.course-desc { font-size: 12px; color: #86868b; margin-top: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

.badge { display: inline-block; padding: 4px 10px; border-radius: 9999px; font-size: 12px; font-weight: 600; }

.status-indicator { display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 500; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

.tag-text { font-size: 12px; color: #86868b; }
.text-muted { color: #86868b; font-size: 13px; }

.action-btns { display: flex; gap: 6px; flex-wrap: wrap; }
.action-btn { padding: 5px 12px; border: 1.5px solid #d2d2d7; border-radius: 9999px; background: #fff; color: #0071e3; font-size: 12px; font-weight: 500; cursor: pointer; transition: all 0.3s; white-space: nowrap; }
.action-btn:hover { background: #0071e3; color: #fff; border-color: #0071e3; }
.action-btn.publish { color: #34c759; border-color: #34c759; }
.action-btn.publish:hover { background: #34c759; color: #fff; }
.action-btn.archive { color: #ff9500; border-color: #ff9500; }
.action-btn.archive:hover { background: #ff9500; color: #fff; }
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
.form-input:focus, .form-textarea:focus, .form-select:focus { border-color: #0071e3; }
.form-textarea { resize: vertical; min-height: 72px; }

/* Cover Upload */
.cover-upload-area { display: flex; flex-direction: column; gap: 10px; }
.cover-preview {
  position: relative;
  width: 100%; height: 180px; border-radius: 14px; overflow: hidden;
  background: #f5f5f7;
}
.cover-preview img {
  width: 100%; height: 100%; object-fit: cover;
}
.cover-clear {
  position: absolute; top: 8px; right: 8px;
  width: 28px; height: 28px; border-radius: 50%;
  border: none; background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; transition: all 0.3s;
}
.cover-clear:hover { background: rgba(0,0,0,0.75); }
.cover-clear svg { width: 14px; height: 14px; color: #fff; }
.cover-placeholder {
  position: relative;
  width: 100%; height: 140px; border-radius: 14px;
  border: 2px dashed #d2d2d7;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 8px; color: #86868b; cursor: pointer; transition: all 0.3s;
}
.cover-placeholder:hover { border-color: #0071e3; color: #0071e3; background: rgba(0,113,227,0.03); }
.cover-placeholder svg { width: 32px; height: 32px; }
.cover-placeholder span { font-size: 13px; }
.file-input {
  position: absolute; inset: 0; opacity: 0; cursor: pointer;
}
.btn-upload {
  padding: 8px 16px; background: #0071e3; color: #fff;
  border: none; border-radius: 10px; font-size: 14px; font-weight: 500;
  cursor: pointer; transition: all 0.3s; align-self: flex-start;
}
.btn-upload:hover { background: #0060c0; }
.btn-upload:disabled { opacity: 0.6; cursor: not-allowed; }
.url-display {
  padding: 6px 12px; background: #f5f5f7; border-radius: 8px;
  font-size: 12px; display: flex; gap: 4px; overflow: hidden;
}
.url-label { color: #86868b; flex-shrink: 0; }
.url-text { color: #1d1d1f; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
</style>
