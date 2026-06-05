package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import io.github.origamihe.learning.enums.ExamRecordStatus;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("exam_records")
public class ExamRecord {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    @TableField("user_id")
    private UUID userId;

    @TableField("exam_id")
    private UUID examId;

    @TableField("start_time")
    private Instant startTime;

    @TableField("end_time")
    private Instant endTime;

    @TableField("duration_used")
    private Integer durationUsed;

    private BigDecimal score;

    @TableField(value = "answers", typeHandler = JacksonTypeHandler.class)
    private String answers;

    private ExamRecordStatus status = ExamRecordStatus.IN_PROGRESS;

    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private Instant createdAt;
}