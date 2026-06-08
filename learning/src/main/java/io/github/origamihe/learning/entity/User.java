package io.github.origamihe.learning.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import io.github.origamihe.learning.common.BaseEntity;
import io.github.origamihe.learning.enums.UserRole;
import io.github.origamihe.learning.enums.UserStatus;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@TableName("users")
public class User extends BaseEntity {

    @TableId(type = IdType.ASSIGN_UUID)
    private UUID id;

    private String username;

    private String email;

    @TableField("password_hash")
    private String passwordHash;

    private String nickname;

    private String avatar;

    private UserRole role = UserRole.STUDENT;

    private Integer points = 0;

    @TableField("streak_days")
    private Integer streakDays = 0;

    @TableField("last_sign_in")
    private LocalDate lastSignIn;

    private UserStatus status = UserStatus.ACTIVE;

    @TableField(value = "preferences", typeHandler = JacksonTypeHandler.class)
    private String preferences;

    @TableLogic
    @TableField("deleted_at")
    private Instant deletedAt;
}