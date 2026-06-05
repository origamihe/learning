package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.CourseSection;
import io.github.origamihe.learning.entity.UserLearningProgress;
import io.github.origamihe.learning.mapper.UserLearningProgressMapper;
import io.github.origamihe.learning.service.CourseSectionService;
import io.github.origamihe.learning.service.UserLearningProgressService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class UserLearningProgressServiceImpl extends ServiceImpl<UserLearningProgressMapper, UserLearningProgress> implements UserLearningProgressService {

    private final CourseSectionService sectionService;

    public UserLearningProgressServiceImpl(CourseSectionService sectionService) {
        this.sectionService = sectionService;
    }

    @Override
    @Transactional
    public void updateProgress(UUID userId, UUID courseId, UUID sectionId) {
        UserLearningProgress progress = lambdaQuery()
                .eq(UserLearningProgress::getUserId, userId)
                .eq(UserLearningProgress::getCourseId, courseId)
                .one();
        if (progress == null) {
            progress = UserLearningProgress.builder()
                    .id(UUID.randomUUID())
                    .userId(userId)
                    .courseId(courseId)
                    .lastSectionId(sectionId)
                    .progress(BigDecimal.ZERO)
                    .lastAccessed(Instant.now())
                    .build();
            save(progress);
        } else {
            progress.setLastSectionId(sectionId);
            progress.setLastAccessed(Instant.now());
            updateById(progress);
        }
        recalculateProgress(progress);
    }

    @Override
    public UserLearningProgress getProgress(UUID userId, UUID courseId) {
        return lambdaQuery()
                .eq(UserLearningProgress::getUserId, userId)
                .eq(UserLearningProgress::getCourseId, courseId)
                .one();
    }

    @Override
    public List<UserLearningProgress> getUserProgresses(UUID userId) {
        return lambdaQuery()
                .eq(UserLearningProgress::getUserId, userId)
                .orderByDesc(UserLearningProgress::getLastAccessed)
                .list();
    }

    @Override
    public double getCompletionRate(UUID userId, UUID courseId) {
        UserLearningProgress progress = getProgress(userId, courseId);
        if (progress == null) {
            return 0.0;
        }
        return progress.getProgress().doubleValue();
    }

    private void recalculateProgress(UserLearningProgress progress) {
        List<CourseSection> sections = sectionService.getSectionsByCourse(progress.getCourseId());
        if (sections.isEmpty()) {
            return;
        }
        int lastOrder = sections.stream()
                .filter(s -> s.getId().equals(progress.getLastSectionId()))
                .findFirst()
                .map(CourseSection::getSortOrder)
                .orElse(0);
        if (lastOrder > 0) {
            BigDecimal rate = BigDecimal.valueOf(lastOrder)
                    .divide(BigDecimal.valueOf(sections.size()), 2, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
            progress.setProgress(rate);
            updateById(progress);
        }
    }
}