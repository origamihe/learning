package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("user_wrong_questions")
public class UserWrongQuestion {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    @TableField("user_id")
    private UUID userId;

    @TableField("question_id")
    private UUID questionId;

    @TableField("wrong_count")
    private Integer wrongCount = 1;

    @TableField("last_wrong_at")
    private Instant lastWrongAt;

    @TableField("next_review_at")
    private Instant nextReviewAt;

    @TableField("mastery_level")
    private Integer masteryLevel = 1;

    private String notes;
}