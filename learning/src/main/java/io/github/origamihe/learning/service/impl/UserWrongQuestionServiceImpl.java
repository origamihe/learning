package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.UserWrongQuestion;
import io.github.origamihe.learning.mapper.UserWrongQuestionMapper;
import io.github.origamihe.learning.service.UserWrongQuestionService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Service
public class UserWrongQuestionServiceImpl extends ServiceImpl<UserWrongQuestionMapper, UserWrongQuestion> implements UserWrongQuestionService {

    @Override
    @Transactional
    public void addWrongQuestion(UUID userId, UUID questionId) {
        UserWrongQuestion existing = lambdaQuery()
                .eq(UserWrongQuestion::getUserId, userId)
                .eq(UserWrongQuestion::getQuestionId, questionId)
                .one();
        if (existing != null) {
            existing.setWrongCount(existing.getWrongCount() + 1);
            existing.setLastWrongAt(Instant.now());
            int nextHours = (int) Math.pow(2, existing.getWrongCount() - 1);
            existing.setNextReviewAt(Instant.now().plus(nextHours, ChronoUnit.HOURS));
            updateById(existing);
        } else {
            UserWrongQuestion uwq = UserWrongQuestion.builder()
                    .id(UUID.randomUUID())
                    .userId(userId)
                    .questionId(questionId)
                    .wrongCount(1)
                    .lastWrongAt(Instant.now())
                    .nextReviewAt(Instant.now().plus(2, ChronoUnit.HOURS))
                    .masteryLevel(1)
                    .build();
            save(uwq);
        }
    }

    @Override
    public List<UserWrongQuestion> getUserWrongQuestions(UUID userId) {
        return lambdaQuery()
                .eq(UserWrongQuestion::getUserId, userId)
                .orderByDesc(UserWrongQuestion::getLastWrongAt)
                .list();
    }

    @Override
    @Transactional
    public void updateMasteryLevel(UUID id, int masteryLevel) {
        UserWrongQuestion uwq = getById(id);
        if (uwq != null) {
            uwq.setMasteryLevel(Math.max(1, Math.min(5, masteryLevel)));
            updateById(uwq);
        }
    }

    @Override
    @Transactional
    public void updateNotes(UUID id, String notes) {
        UserWrongQuestion uwq = getById(id);
        if (uwq != null) {
            uwq.setNotes(notes);
            updateById(uwq);
        }
    }

    @Override
    @Transactional
    public void removeWrongQuestion(UUID id) {
        removeById(id);
    }

    @Override
    public List<UserWrongQuestion> getDueForReview(UUID userId) {
        return lambdaQuery()
                .eq(UserWrongQuestion::getUserId, userId)
                .le(UserWrongQuestion::getNextReviewAt, Instant.now())
                .orderByAsc(UserWrongQuestion::getNextReviewAt)
                .list();
    }
}