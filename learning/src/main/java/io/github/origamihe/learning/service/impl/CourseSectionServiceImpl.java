package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.CourseSection;
import io.github.origamihe.learning.mapper.CourseSectionMapper;
import io.github.origamihe.learning.service.CourseSectionService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class CourseSectionServiceImpl extends ServiceImpl<CourseSectionMapper, CourseSection> implements CourseSectionService {

    @Override
    public List<CourseSection> getSectionsByCourse(UUID courseId) {
        return lambdaQuery()
                .eq(CourseSection::getCourseId, courseId)
                .orderByAsc(CourseSection::getSortOrder)
                .list();
    }

    @Override
    @Transactional
    public CourseSection createSection(CourseSection section) {
        section.setId(UUID.randomUUID());
        if (section.getSortOrder() == null) {
            long count = lambdaQuery().eq(CourseSection::getCourseId, section.getCourseId()).count();
            section.setSortOrder((int) count + 1);
        }
        save(section);
        return section;
    }

    @Override
    @Transactional
    public void updateSection(CourseSection section) {
        CourseSection existing = getById(section.getId());
        if (existing == null) {
            throw new RuntimeException("章节不存在");
        }
        updateById(section);
    }

    @Override
    @Transactional
    public void reorderSections(UUID courseId, List<UUID> sectionIds) {
        for (int i = 0; i < sectionIds.size(); i++) {
            CourseSection section = getById(sectionIds.get(i));
            if (section != null && section.getCourseId().equals(courseId)) {
                section.setSortOrder(i + 1);
                updateById(section);
            }
        }
    }

    @Override
    @Transactional
    public void deleteSection(UUID sectionId) {
        removeById(sectionId);
    }
}