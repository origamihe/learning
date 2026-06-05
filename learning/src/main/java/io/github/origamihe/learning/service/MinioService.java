package io.github.origamihe.learning.service;

import io.github.origamihe.learning.dto.UploadResult;
import org.springframework.web.multipart.MultipartFile;
import java.io.InputStream;

public interface MinioService {

    /**
     * 上传文件到 MinIO
     * @param file        上传的文件
     * @param entityType  实体类型（questions/course_sections/users/...）
     * @param entityId    实体 ID
     * @return MinIO 存储信息
     */
    UploadResult upload(MultipartFile file, String entityType, String entityId);

    /**
     * 删除文件
     */
    void delete(String storageKey);

    /**
     * 获取文件输入流（用于下载/预览）
     */
    InputStream getObject(String storageKey);

    /**
     * 生成预签名 URL（有效期 7 天，用于前端直接访问私有文件）
     */
    String getPresignedUrl(String storageKey);
}