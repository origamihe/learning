package io.github.origamihe.learning.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import io.github.origamihe.learning.entity.Course;
import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.enums.CourseDifficulty;
import io.github.origamihe.learning.enums.CourseStatus;
import io.github.origamihe.learning.service.CourseService;
import io.github.origamihe.learning.service.CourseSectionService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;
    private final CourseSectionService sectionService;

    @Data
    public static class CreateCourseRequest {
        @NotBlank(message = "课程标题不能为空")
        private String title;
        private String description;
        private String coverImage;
        private CourseDifficulty difficulty;
        private String tags;
    }

    @GetMapping
    public ResponseEntity<IPage<Course>> listCourses(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) CourseDifficulty difficulty,
            @RequestParam(required = false) CourseStatus status,
            @RequestParam(required = false) String keyword) {
        IPage<Course> result = courseService.pageCourses(page, size, difficulty, status, keyword);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/teacher/{teacherId}")
    public ResponseEntity<List<Course>> getTeacherCourses(@PathVariable UUID teacherId) {
        List<Course> courses = courseService.getCoursesByTeacher(teacherId);
        return ResponseEntity.ok(courses);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Course> getCourse(@PathVariable UUID id) {
        Course course = courseService.getById(id);
        if (course == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(course);
    }

    @PostMapping
    public ResponseEntity<?> createCourse(@Valid @RequestBody CreateCourseRequest request) {
        User user = getAuthenticatedUser();
        Course course = Course.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .coverImage(request.getCoverImage())
                .teacherId(user.getId())
                .difficulty(request.getDifficulty())
                .tags(request.getTags())
                .build();
        Course saved = courseService.createCourse(course);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateCourse(@PathVariable UUID id, @RequestBody Course course) {
        course.setId(id);
        Course existing = courseService.getById(id);
        if (existing == null) {
            return ResponseEntity.notFound().build();
        }
        courseService.updateById(course);
        return ResponseEntity.ok(Map.of("message", "更新成功"));
    }

    @PostMapping("/{id}/publish")
    public ResponseEntity<?> publishCourse(@PathVariable UUID id) {
        try {
            courseService.publishCourse(id);
            return ResponseEntity.ok(Map.of("message", "发布成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/{id}/archive")
    public ResponseEntity<?> archiveCourse(@PathVariable UUID id) {
        try {
            courseService.archiveCourse(id);
            return ResponseEntity.ok(Map.of("message", "归档成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCourse(@PathVariable UUID id) {
        courseService.removeById(id);
        return ResponseEntity.ok(Map.of("message", "删除成功"));
    }

    private User getAuthenticatedUser() {
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}