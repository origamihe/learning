package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.UserWrongQuestion;

import java.util.List;
import java.util.UUID;

public interface UserWrongQuestionService extends IService<UserWrongQuestion> {

    void addWrongQuestion(UUID userId, UUID questionId);

    List<UserWrongQuestion> getUserWrongQuestions(UUID userId);

    void updateMasteryLevel(UUID id, int masteryLevel);

    void updateNotes(UUID id, String notes);

    void removeWrongQuestion(UUID id);

    List<UserWrongQuestion> getDueForReview(UUID userId);
}