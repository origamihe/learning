package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.Course;
import io.github.origamihe.learning.enums.CourseDifficulty;
import io.github.origamihe.learning.enums.CourseStatus;

import java.util.List;
import java.util.UUID;

public interface CourseService extends IService<Course> {

    Course createCourse(Course course);

    void publishCourse(UUID courseId);

    void archiveCourse(UUID courseId);

    IPage<Course> pageCourses(int page, int size, CourseDifficulty difficulty, CourseStatus status, String keyword);

    List<Course> getCoursesByTeacher(UUID teacherId);
}