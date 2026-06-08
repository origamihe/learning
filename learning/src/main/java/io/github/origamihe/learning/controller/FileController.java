package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.entity.FileAttachment;
import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.service.FileAttachmentService;
import io.github.origamihe.learning.service.MinioService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
public class FileController {

    private final FileAttachmentService fileAttachmentService;
    private final MinioService minioService;

    // ==================== 上传 ====================

    /**
     * 单文件上传（临时上传，不关联实体）
     * POST /api/files/upload
     */
    @PostMapping("/upload")
    public ResponseEntity<FileAttachment> upload(
            @RequestParam("file") MultipartFile file) {
        User user = getAuthenticatedUser();
        FileAttachment attachment = fileAttachmentService.uploadFile(
                file, user.getId(), "users", user.getId());
        return ResponseEntity.ok(attachment);
    }

    /**
     * 批量上传（最多 10 个文件）
     * POST /api/files/upload/batch
     */
    @PostMapping("/upload/batch")
    public ResponseEntity<List<FileAttachment>> uploadBatch(
            @RequestParam("files") List<MultipartFile> files) {
        if (files.size() > 10) {
            return ResponseEntity.badRequest().build();
        }
        User user = getAuthenticatedUser();
        List<FileAttachment> attachments = fileAttachmentService.uploadFiles(
                files, user.getId(), "users", user.getId());
        return ResponseEntity.ok(attachments);
    }

    /**
     * 上传文件并直接关联到实体
     * POST /api/files/upload/{entityType}/{entityId}
     * 例如: POST /api/files/upload/QUESTION/abc-123
     */
    @PostMapping("/upload/{entityType}/{entityId}")
    public ResponseEntity<List<FileAttachment>> uploadForEntity(
            @PathVariable String entityType,
            @PathVariable UUID entityId,
            @RequestParam("files") List<MultipartFile> files) {
        if (files.size() > 10) {
            return ResponseEntity.badRequest().build();
        }
        User user = getAuthenticatedUser();
        List<FileAttachment> attachments = fileAttachmentService.uploadFiles(
                files, user.getId(), entityType, entityId);
        return ResponseEntity.ok(attachments);
    }

    // ==================== 关联 ====================

    /**
     * 将已有文件关联到实体（用于先上传后保存的场景）
     * POST /api/files/attach
     */
    @Data
    public static class AttachRequest {
        private List<UUID> fileIds;
        private String entityType;
        private UUID entityId;
    }

    @PostMapping("/attach")
    public ResponseEntity<?> attachToEntity(@RequestBody AttachRequest request) {
        fileAttachmentService.attachToEntity(
                request.getFileIds(), request.getEntityType(), request.getEntityId());
        return ResponseEntity.ok(Map.of("message", "关联成功"));
    }

    // ==================== 查询 ====================

    /**
     * 获取实体下的所有附件
     * GET /api/files/entity/{entityType}/{entityId}
     */
    @GetMapping("/entity/{entityType}/{entityId}")
    public ResponseEntity<List<FileAttachment>> getEntityFiles(
            @PathVariable String entityType,
            @PathVariable UUID entityId) {
        List<FileAttachment> files = fileAttachmentService.getEntityAttachments(entityType, entityId);
        return ResponseEntity.ok(files);
    }

    /**
     * 获取单个文件信息
     * GET /api/files/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<FileAttachment> getFileInfo(@PathVariable UUID id) {
        FileAttachment file = fileAttachmentService.getById(id);
        if (file == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(file);
    }

    // ==================== 下载/预览 ====================

    /**
     * 下载/预览文件
     * GET /api/files/{id}/download
     */
    @GetMapping("/{id}/download")
    public ResponseEntity<InputStreamResource> download(@PathVariable UUID id) {
        FileAttachment file = fileAttachmentService.getById(id);
        if (file == null) return ResponseEntity.notFound().build();

        InputStream inputStream = minioService.getObject(file.getStorageKey());

        String encodedName = URLEncoder.encode(file.getOriginalName(), StandardCharsets.UTF_8)
                .replace("+", "%20");

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(
                        file.getMimeType() != null ? file.getMimeType() : "application/octet-stream"))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "inline; filename=\"" + encodedName + "\"")
                .body(new InputStreamResource(inputStream));
    }

    /**
     * 获取预签名 URL（前端直接用 URL 访问）
     * GET /api/files/{id}/url
     */
    @GetMapping("/{id}/url")
    public ResponseEntity<?> getAccessUrl(@PathVariable UUID id) {
        String url = fileAttachmentService.getAccessUrl(id);
        if (url == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(Map.of("url", url));
    }

    // ==================== 删除 ====================

    /**
     * 删除文件
     * DELETE /api/files/{id}
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> delete(@PathVariable UUID id) {
        fileAttachmentService.softDeleteFile(id);
        return ResponseEntity.ok(Map.of("message", "删除成功"));
    }

    // ==================== 工具方法 ====================

    private User getAuthenticatedUser() {
        return (User) SecurityContextHolder.getContext()
                .getAuthentication().getPrincipal();
    }
}