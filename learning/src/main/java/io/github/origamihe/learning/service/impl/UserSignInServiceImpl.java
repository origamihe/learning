package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.entity.UserSignIn;
import io.github.origamihe.learning.mapper.UserSignInMapper;
import io.github.origamihe.learning.service.UserService;
import io.github.origamihe.learning.service.UserSignInService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Service
public class UserSignInServiceImpl extends ServiceImpl<UserSignInMapper, UserSignIn> implements UserSignInService {

    private static final int BASE_POINTS = 5;
    private static final int MAX_STREAK_BONUS = 20;

    private final UserService userService;

    public UserSignInServiceImpl(UserService userService) {
        this.userService = userService;
    }

    @Override
    @Transactional
    public UserSignIn signIn(UUID userId) {
        if (hasSignedToday(userId)) {
            throw new RuntimeException("今日已签到");
        }
        User user = userService.getById(userId);
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }
        LocalDate today = LocalDate.now();
        LocalDate yesterday = today.minusDays(1);
        int streakDays = user.getStreakDays();
        if (user.getLastSignIn() != null && user.getLastSignIn().equals(yesterday)) {
            streakDays++;
        } else {
            streakDays = 1;
        }
        int pointsEarned = BASE_POINTS + Math.min(streakDays - 1, MAX_STREAK_BONUS - BASE_POINTS);
        UserSignIn signIn = UserSignIn.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .signInDate(today)
                .pointsEarned(pointsEarned)
                .build();
        save(signIn);
        user.setStreakDays(streakDays);
        user.setLastSignIn(today);
        user.setPoints(user.getPoints() + pointsEarned);
        userService.updateById(user);
        return signIn;
    }

    @Override
    public List<UserSignIn> getSignInRecords(UUID userId, int year, int month) {
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.plusMonths(1).minusDays(1);
        return lambdaQuery()
                .eq(UserSignIn::getUserId, userId)
                .ge(UserSignIn::getSignInDate, start)
                .le(UserSignIn::getSignInDate, end)
                .orderByDesc(UserSignIn::getSignInDate)
                .list();
    }

    @Override
    public boolean hasSignedToday(UUID userId) {
        return lambdaQuery()
                .eq(UserSignIn::getUserId, userId)
                .eq(UserSignIn::getSignInDate, LocalDate.now())
                .exists();
    }

    @Override
    public int getStreakDays(UUID userId) {
        User user = userService.getById(userId);
        return user != null ? user.getStreakDays() : 0;
    }
}