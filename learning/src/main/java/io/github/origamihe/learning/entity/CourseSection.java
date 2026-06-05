package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import io.github.origamihe.learning.common.BaseEntity;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("course_sections")
public class CourseSection extends BaseEntity {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    @TableField("course_id")
    private UUID courseId;

    private String title;

    @TableField("sort_order")
    private Integer sortOrder;

    @TableField(value = "content", typeHandler = JacksonTypeHandler.class)
    private String content;

    private Integer duration;
}