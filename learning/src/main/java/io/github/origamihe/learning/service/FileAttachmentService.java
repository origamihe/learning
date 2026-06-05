package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.FileAttachment;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

public interface FileAttachmentService extends IService<FileAttachment> {

    /**
     * 上传单个文件并保存记录
     */
    FileAttachment uploadFile(MultipartFile file, UUID userId, String entityType, UUID entityId);

    /**
     * 批量上传文件
     */
    List<FileAttachment> uploadFiles(List<MultipartFile> files, UUID userId, String entityType, UUID entityId);

    /**
     * 将已有文件关联到实体
     */
    void attachToEntity(UUID fileId, String entityType, UUID entityId);

    /**
     * 批量关联文件到实体
     */
    void attachToEntity(List<UUID> fileIds, String entityType, UUID entityId);

    /**
     * 软删除文件（同时删除 MinIO 中的文件）
     */
    void softDeleteFile(UUID fileId);

    /**
     * 获取某实体下的所有附件（按排序）
     */
    List<FileAttachment> getEntityAttachments(String entityType, UUID entityId);

    /**
     * 获取预签名 URL（带缓存策略）
     */
    String getAccessUrl(UUID fileId);
}