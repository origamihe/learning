import { get, post, del } from '@/utils/request'
import type { FileAttachment, AttachFilesRequest, MessageResponse } from '@/types/api'

/**
 * 上传单个文件（临时上传，不关联实体）
 */
export function uploadFile(file: FormData) {
  return post<FileAttachment>('/api/files/upload', file, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  })
}

/**
 * 批量上传文件（最多 10 个文件）
 */
export function uploadFiles(files: FormData) {
  return post<FileAttachment[]>('/api/files/upload/batch', files, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  })
}

/**
 * 上传文件并直接关联到实体
 */
export function uploadFilesForEntity(entityType: string, entityId: string, files: FormData) {
  return post<FileAttachment[]>(`/api/files/upload/${entityType}/${entityId}`, files, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  })
}

/**
 * 将已有文件关联到实体
 */
export function attachFilesToEntity(data: AttachFilesRequest) {
  return post<MessageResponse>('/api/files/attach', data)
}

/**
 * 获取实体下的所有附件
 */
export function getEntityFiles(entityType: string, entityId: string) {
  return get<FileAttachment[]>(`/api/files/entity/${entityType}/${entityId}`)
}

/**
 * 获取单个文件信息
 */
export function getFileInfo(id: string) {
  return get<FileAttachment>(`/api/files/${id}`)
}

/**
 * 获取预签名访问 URL
 */
export function getFileAccessUrl(id: string) {
  return get<{ url: string }>(`/api/files/${id}/url`)
}

/**
 * 删除文件
 */
export function deleteFile(id: string) {
  return del<MessageResponse>(`/api/files/${id}`)
}
