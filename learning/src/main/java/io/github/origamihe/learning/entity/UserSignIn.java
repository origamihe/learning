package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("user_sign_ins")
public class UserSignIn {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    @TableField("user_id")
    private UUID userId;

    @TableField("sign_in_date")
    private LocalDate signInDate;

    @TableField("points_earned")
    private Integer pointsEarned = 5;

    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private Instant createdAt;
}