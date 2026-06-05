package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.FileAttachment;
import io.github.origamihe.learning.dto.UploadResult;
import io.github.origamihe.learning.mapper.FileAttachmentMapper;
import io.github.origamihe.learning.service.FileAttachmentService;
import io.github.origamihe.learning.service.MinioService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FileAttachmentServiceImpl extends ServiceImpl<FileAttachmentMapper, FileAttachment> implements FileAttachmentService {

    private final MinioService minioService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FileAttachment uploadFile(MultipartFile file, UUID userId, String entityType, UUID entityId) {
        UploadResult result = minioService.upload(file, entityType, entityId.toString());

        String category = detectCategory(result.contentType());

        FileAttachment attachment = FileAttachment.builder()
                .userId(userId)
                .originalName(result.originalName())
                .storageKey(result.storageKey())
                .fileUrl(result.fileUrl())
                .fileSize(result.fileSize())
                .mimeType(result.contentType())
                .fileCategory(category)
                .entityType(entityType)
                .entityId(entityId)
                .sortOrder(getNextSortOrder(entityType, entityId))
                .build();

        save(attachment);
        return attachment;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public List<FileAttachment> uploadFiles(List<MultipartFile> files, UUID userId, String entityType, UUID entityId) {
        List<FileAttachment> attachments = new ArrayList<>();
        int baseOrder = getNextSortOrder(entityType, entityId);
        for (int i = 0; i < files.size(); i++) {
            MultipartFile file = files.get(i);
            if (file.isEmpty()) continue;

            UploadResult result = minioService.upload(file, entityType, entityId.toString());
            String category = detectCategory(result.contentType());

            FileAttachment attachment = FileAttachment.builder()
                    .userId(userId)
                    .originalName(result.originalName())
                    .storageKey(result.storageKey())
                    .fileUrl(result.fileUrl())
                    .fileSize(result.fileSize())
                    .mimeType(result.contentType())
                    .fileCategory(category)
                    .entityType(entityType)
                    .entityId(entityId)
                    .sortOrder(baseOrder + i)
                    .build();

            save(attachment);
            attachments.add(attachment);
        }
        return attachments;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void attachToEntity(UUID fileId, String entityType, UUID entityId) {
        FileAttachment attachment = getById(fileId);
        if (attachment == null) {
            throw new RuntimeException("文件不存在");
        }
        attachment.setEntityType(entityType);
        attachment.setEntityId(entityId);
        attachment.setSortOrder(getNextSortOrder(entityType, entityId));
        updateById(attachment);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void attachToEntity(List<UUID> fileIds, String entityType, UUID entityId) {
        int baseOrder = getNextSortOrder(entityType, entityId);
        for (int i = 0; i < fileIds.size(); i++) {
            FileAttachment attachment = getById(fileIds.get(i));
            if (attachment != null) {
                attachment.setEntityType(entityType);
                attachment.setEntityId(entityId);
                attachment.setSortOrder(baseOrder + i);
                updateById(attachment);
            }
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void softDeleteFile(UUID fileId) {
        FileAttachment attachment = getById(fileId);
        if (attachment != null) {
            minioService.delete(attachment.getStorageKey());
            if (attachment.getThumbnailKey() != null) {
                minioService.delete(attachment.getThumbnailKey());
            }
            removeById(fileId);
        }
    }

    @Override
    public List<FileAttachment> getEntityAttachments(String entityType, UUID entityId) {
        return list(new LambdaQueryWrapper<FileAttachment>()
                .eq(FileAttachment::getEntityType, entityType)
                .eq(FileAttachment::getEntityId, entityId)
                .orderByAsc(FileAttachment::getSortOrder));
    }

    @Override
    public String getAccessUrl(UUID fileId) {
        FileAttachment attachment = getById(fileId);
        if (attachment == null) return null;
        return minioService.getPresignedUrl(attachment.getStorageKey());
    }

    private int getNextSortOrder(String entityType, UUID entityId) {
        long count = count(new LambdaQueryWrapper<FileAttachment>()
                .eq(FileAttachment::getEntityType, entityType)
                .eq(FileAttachment::getEntityId, entityId));
        return (int) count;
    }

    private String detectCategory(String mimeType) {
        if (mimeType == null) return "OTHER";
        if (mimeType.startsWith("image/")) return "IMAGE";
        if (mimeType.startsWith("video/")) return "VIDEO";
        if (mimeType.startsWith("application/pdf")
                || mimeType.startsWith("application/msword")
                || mimeType.contains("document")
                || mimeType.contains("sheet")) return "DOCUMENT";
        return "OTHER";
    }
}