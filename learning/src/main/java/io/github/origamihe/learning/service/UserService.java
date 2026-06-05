package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.User;

import java.util.UUID;

public interface UserService extends IService<User> {

    User register(String username, String email, String password, String nickname);

    User findByUsername(String username);

    User findByEmail(String email);

    void updatePassword(UUID userId, String oldPassword, String newPassword);

    void updateProfile(UUID userId, String nickname, String avatar);

    void updatePoints(UUID userId, int points);
}