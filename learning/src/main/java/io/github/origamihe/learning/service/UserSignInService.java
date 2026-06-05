package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.UserSignIn;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface UserSignInService extends IService<UserSignIn> {

    UserSignIn signIn(UUID userId);

    List<UserSignIn> getSignInRecords(UUID userId, int year, int month);

    boolean hasSignedToday(UUID userId);

    int getStreakDays(UUID userId);
}