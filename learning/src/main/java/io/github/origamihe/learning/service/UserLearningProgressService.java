package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.UserLearningProgress;

import java.util.List;
import java.util.UUID;

public interface UserLearningProgressService extends IService<UserLearningProgress> {

    void updateProgress(UUID userId, UUID courseId, UUID sectionId);

    UserLearningProgress getProgress(UUID userId, UUID courseId);

    List<UserLearningProgress> getUserProgresses(UUID userId);

    double getCompletionRate(UUID userId, UUID courseId);
}