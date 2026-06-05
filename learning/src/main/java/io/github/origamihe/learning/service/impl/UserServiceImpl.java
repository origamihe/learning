package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.enums.UserRole;
import io.github.origamihe.learning.enums.UserStatus;
import io.github.origamihe.learning.mapper.UserMapper;
import io.github.origamihe.learning.service.UserService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private final PasswordEncoder passwordEncoder;

    public UserServiceImpl(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public User register(String username, String email, String password, String nickname) {
        if (findByUsername(username) != null) {
            throw new RuntimeException("用户名已存在");
        }
        if (findByEmail(email) != null) {
            throw new RuntimeException("邮箱已注册");
        }
        User user = User.builder()
                .id(UUID.randomUUID())
                .username(username)
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .nickname(nickname)
                .role(UserRole.STUDENT)
                .status(UserStatus.ACTIVE)
                .points(0)
                .streakDays(0)
                .build();
        save(user);
        return user;
    }

    @Override
    public User findByUsername(String username) {
        return lambdaQuery().eq(User::getUsername, username).one();
    }

    @Override
    public User findByEmail(String email) {
        return lambdaQuery().eq(User::getEmail, email).one();
    }

    @Override
    @Transactional
    public void updatePassword(UUID userId, String oldPassword, String newPassword) {
        User user = getById(userId);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        if (!passwordEncoder.matches(oldPassword, user.getPasswordHash())) {
            throw new RuntimeException("原密码错误");
        }
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        updateById(user);
    }

    @Override
    @Transactional
    public void updateProfile(UUID userId, String nickname, String avatar) {
        User user = getById(userId);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        if (nickname != null) {
            user.setNickname(nickname);
        }
        if (avatar != null) {
            user.setAvatar(avatar);
        }
        updateById(user);
    }

    @Override
    @Transactional
    public void updatePoints(UUID userId, int points) {
        User user = getById(userId);
        if (user != null) {
            user.setPoints(user.getPoints() + points);
            if (user.getPoints() < 0) {
                user.setPoints(0);
            }
            updateById(user);
        }
    }
}