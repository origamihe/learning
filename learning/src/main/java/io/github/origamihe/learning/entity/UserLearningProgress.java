package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import io.github.origamihe.learning.handler.StringArrayTypeHandler;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("user_learning_progress")
public class UserLearningProgress {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    @TableField("user_id")
    private UUID userId;

    @TableField("course_id")
    private UUID courseId;

    @TableField("last_section_id")
    private UUID lastSectionId;

    private BigDecimal progress = BigDecimal.ZERO;

    @TableField(value = "completed_sections", typeHandler = StringArrayTypeHandler.class)
    private String completedSections;

    @TableField("last_accessed")
    private Instant lastAccessed;
}