package io.github.origamihe.learning.dto;

/**
 * MinIO 上传结果
 */
public record UploadResult(
        String storageKey,
        String fileUrl,
        String originalName,
        long fileSize,
        String contentType
) {}