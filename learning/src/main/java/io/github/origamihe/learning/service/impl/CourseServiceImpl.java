package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.Course;
import io.github.origamihe.learning.enums.CourseDifficulty;
import io.github.origamihe.learning.enums.CourseStatus;
import io.github.origamihe.learning.mapper.CourseMapper;
import io.github.origamihe.learning.service.CourseService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.UUID;

@Service
public class CourseServiceImpl extends ServiceImpl<CourseMapper, Course> implements CourseService {

    @Override
    @Transactional
    public Course createCourse(Course course) {
        course.setId(UUID.randomUUID());
        course.setStatus(CourseStatus.DRAFT);
        save(course);
        return course;
    }

    @Override
    @Transactional
    public void publishCourse(UUID courseId) {
        Course course = getById(courseId);
        if (course == null) {
            throw new RuntimeException("课程不存在");
        }
        course.setStatus(CourseStatus.PUBLISHED);
        updateById(course);
    }

    @Override
    @Transactional
    public void archiveCourse(UUID courseId) {
        Course course = getById(courseId);
        if (course == null) {
            throw new RuntimeException("课程不存在");
        }
        course.setStatus(CourseStatus.ARCHIVED);
        updateById(course);
    }

    @Override
    public IPage<Course> pageCourses(int page, int size, CourseDifficulty difficulty, CourseStatus status, String keyword) {
        LambdaQueryWrapper<Course> wrapper = new LambdaQueryWrapper<>();
        if (difficulty != null) {
            wrapper.eq(Course::getDifficulty, difficulty);
        }
        if (status != null) {
            wrapper.eq(Course::getStatus, status);
        }
        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w.like(Course::getTitle, keyword).or().like(Course::getDescription, keyword));
        }
        wrapper.orderByDesc(Course::getCreatedAt);
        return page(new Page<>(page, size), wrapper);
    }

    @Override
    public List<Course> getCoursesByTeacher(UUID teacherId) {
        return lambdaQuery()
                .eq(Course::getTeacherId, teacherId)
                .orderByDesc(Course::getCreatedAt)
                .list();
    }
}