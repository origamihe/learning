package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.CourseSection;

import java.util.List;
import java.util.UUID;

public interface CourseSectionService extends IService<CourseSection> {

    List<CourseSection> getSectionsByCourse(UUID courseId);

    CourseSection createSection(CourseSection section);

    void updateSection(CourseSection section);

    void reorderSections(UUID courseId, List<UUID> sectionIds);

    void deleteSection(UUID sectionId);
}