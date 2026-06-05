package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import io.github.origamihe.learning.common.BaseEntity;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("file_attachments")
public class FileAttachment extends BaseEntity {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    @TableField("user_id")
    private UUID userId;

    @TableField("original_name")
    private String originalName;

    @TableField("storage_key")
    private String storageKey;

    @TableField("file_url")
    private String fileUrl;

    @TableField("file_size")
    private Long fileSize;

    @TableField("mime_type")
    private String mimeType;

    @TableField("file_category")
    private String fileCategory;

    @TableField("entity_type")
    private String entityType;

    @TableField("entity_id")
    private UUID entityId;

    @TableField("sort_order")
    private Integer sortOrder;

    private Integer width;

    private Integer height;

    private Integer duration;

    @TableField("thumbnail_key")
    private String thumbnailKey;

    @TableLogic
    @TableField("deleted_at")
    private Instant deletedAt;
}