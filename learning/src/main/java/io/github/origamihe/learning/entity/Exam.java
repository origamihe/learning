package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import io.github.origamihe.learning.common.BaseEntity;
import io.github.origamihe.learning.enums.ExamStatus;
import io.github.origamihe.learning.enums.ExamType;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("exams")
public class Exam extends BaseEntity {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    private String title;

    @TableField("course_id")
    private UUID courseId;

    private Integer duration;

    @TableField("total_score")
    private Integer totalScore = 100;

    @TableField("pass_score")
    private Integer passScore = 60;

    private ExamType type;

    private ExamStatus status = ExamStatus.DRAFT;

    @TableField(value = "config", typeHandler = JacksonTypeHandler.class)
    private String config;
}