package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import io.github.origamihe.learning.common.BaseEntity;
import io.github.origamihe.learning.enums.QuestionType;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("questions")
public class Question extends BaseEntity {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    @TableField("course_id")
    private UUID courseId;

    @TableField("section_id")
    private UUID sectionId;

    private QuestionType type;

    private String content;

    @TableField(value = "options", typeHandler = JacksonTypeHandler.class)
    private String options;

    @TableField(value = "answer", typeHandler = JacksonTypeHandler.class)
    private String answer;

    private String explanation;

    private Integer difficulty;

    @TableField(value = "tags", typeHandler = JacksonTypeHandler.class)
    private String tags;

    @TableField(value = "meta", typeHandler = JacksonTypeHandler.class)
    private String meta;

    @TableLogic
    @TableField("deleted_at")
    private Instant deletedAt;
}