package io.github.origamihe.learning.service.impl;

import io.github.origamihe.learning.config.MinioProperties;
import io.github.origamihe.learning.service.MinioService;
import io.github.origamihe.learning.dto.UploadResult;
import io.minio.*;
import io.minio.http.Method;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class MinioServiceImpl implements MinioService {

    private final MinioClient minioClient;
    private final MinioProperties minioProperties;

    @Override
    public UploadResult upload(MultipartFile file, String entityType, String entityId) {
        try {
            String bucket = minioProperties.getBucketName();
            ensureBucketExists(bucket);

            String originalName = file.getOriginalFilename();
            String extension = getExtension(originalName);
            String objectName = String.format("%s/%s/%s%s",
                    entityType, entityId, UUID.randomUUID(), extension);

            InputStream inputStream = file.getInputStream();
            long fileSize = file.getSize();
            String contentType = file.getContentType();

            minioClient.putObject(
                    PutObjectArgs.builder()
                            .bucket(bucket)
                            .object(objectName)
                            .stream(inputStream, fileSize, -1)
                            .contentType(contentType)
                            .build()
            );

            String fileUrl = minioProperties.getEndpoint() + "/" + bucket + "/" + objectName;

            log.info("文件上传成功: {}", objectName);
            return new UploadResult(objectName, fileUrl, originalName, fileSize, contentType);
        } catch (Exception e) {
            log.error("文件上传失败", e);
            throw new RuntimeException("文件上传失败: " + e.getMessage(), e);
        }
    }

    @Override
    public void delete(String storageKey) {
        try {
            minioClient.removeObject(
                    RemoveObjectArgs.builder()
                            .bucket(minioProperties.getBucketName())
                            .object(storageKey)
                            .build()
            );
            log.info("文件删除成功: {}", storageKey);
        } catch (Exception e) {
            log.error("文件删除失败: {}", storageKey, e);
            throw new RuntimeException("文件删除失败: " + e.getMessage(), e);
        }
    }

    @Override
    public InputStream getObject(String storageKey) {
        try {
            return minioClient.getObject(
                    GetObjectArgs.builder()
                            .bucket(minioProperties.getBucketName())
                            .object(storageKey)
                            .build()
            );
        } catch (Exception e) {
            log.error("获取文件失败: {}", storageKey, e);
            throw new RuntimeException("获取文件失败: " + e.getMessage(), e);
        }
    }

    @Override
    public String getPresignedUrl(String storageKey) {
        try {
            return minioClient.getPresignedObjectUrl(
                    GetPresignedObjectUrlArgs.builder()
                            .bucket(minioProperties.getBucketName())
                            .object(storageKey)
                            .method(Method.GET)
                            .expiry(7, TimeUnit.DAYS)
                            .build()
            );
        } catch (Exception e) {
            log.error("生成预签名URL失败: {}", storageKey, e);
            return null;
        }
    }

    private void ensureBucketExists(String bucket) throws Exception {
        boolean exists = minioClient.bucketExists(
                BucketExistsArgs.builder().bucket(bucket).build());
        if (!exists) {
            minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
            log.info("创建 MinIO 桶: {}", bucket);
        }
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf("."));
    }
}