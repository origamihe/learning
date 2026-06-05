package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.service.UserService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import lombok.Data;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @Data
    public static class UpdateProfileRequest {
        @NotBlank(message = "昵称不能为空")
        private String nickname;
        private String avatar;
    }

    @Data
    public static class UpdatePasswordRequest {
        @NotBlank(message = "旧密码不能为空")
        private String oldPassword;
        @NotBlank(message = "新密码不能为空")
        private String newPassword;
    }

    @GetMapping("/me")
    public ResponseEntity<User> getCurrentUser() {
        User user = getAuthenticatedUser();
        return ResponseEntity.ok(user);
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        User user = getAuthenticatedUser();
        try {
            userService.updateProfile(user.getId(), request.getNickname(), request.getAvatar());
            return ResponseEntity.ok(Map.of("message", "更新成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/password")
    public ResponseEntity<?> updatePassword(@Valid @RequestBody UpdatePasswordRequest request) {
        User user = getAuthenticatedUser();
        try {
            userService.updatePassword(user.getId(), request.getOldPassword(), request.getNewPassword());
            return ResponseEntity.ok(Map.of("message", "密码修改成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable UUID id) {
        User user = userService.getById(id);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }
        User safeUser = new User();
        safeUser.setId(user.getId());
        safeUser.setUsername(user.getUsername());
        safeUser.setNickname(user.getNickname());
        safeUser.setAvatar(user.getAvatar());
        safeUser.setRole(user.getRole());
        safeUser.setPoints(user.getPoints());
        return ResponseEntity.ok(safeUser);
    }

    private User getAuthenticatedUser() {
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}