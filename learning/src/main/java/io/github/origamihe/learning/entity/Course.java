package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import io.github.origamihe.learning.common.BaseEntity;
import io.github.origamihe.learning.enums.CourseDifficulty;
import io.github.origamihe.learning.enums.CourseStatus;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("courses")
public class Course extends BaseEntity {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    private String title;

    private String description;

    @TableField("cover_image")
    private String coverImage;

    @TableField("teacher_id")
    private UUID teacherId;

    private CourseDifficulty difficulty;

    private CourseStatus status = CourseStatus.DRAFT;

    @TableField(value = "tags", typeHandler = JacksonTypeHandler.class)
    private String tags;

    @TableField(value = "meta", typeHandler = JacksonTypeHandler.class)
    private String meta;

    @TableLogic
    @TableField("deleted_at")
    private Instant deletedAt;
}