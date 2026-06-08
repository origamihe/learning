package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.entity.CourseSection;
import io.github.origamihe.learning.service.CourseSectionService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/sections")
@RequiredArgsConstructor
public class CourseSectionController {

    private final CourseSectionService sectionService;

    @Data
    public static class CreateSectionRequest {
        @NotBlank(message = "章节标题不能为空")
        private String title;
        private UUID courseId;
        private String content;
        private Integer duration;
    }

    @GetMapping("/course/{courseId}")
    public ResponseEntity<List<CourseSection>> getSectionsByCourse(@PathVariable UUID courseId) {
        List<CourseSection> sections = sectionService.getSectionsByCourse(courseId);
        return ResponseEntity.ok(sections);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> createSection(@Valid @RequestBody CreateSectionRequest request) {
        CourseSection section = CourseSection.builder()
                .courseId(request.getCourseId())
                .title(request.getTitle())
                .content(request.getContent())
                .duration(request.getDuration())
                .build();
        CourseSection saved = sectionService.createSection(section);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> updateSection(@PathVariable UUID id, @RequestBody CourseSection section) {
        section.setId(id);
        try {
            sectionService.updateSection(section);
            return ResponseEntity.ok(Map.of("message", "更新成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/reorder")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> reorderSections(@RequestBody ReorderRequest request) {
        sectionService.reorderSections(request.getCourseId(), request.getSectionIds());
        return ResponseEntity.ok(Map.of("message", "排序成功"));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> deleteSection(@PathVariable UUID id) {
        sectionService.deleteSection(id);
        return ResponseEntity.ok(Map.of("message", "删除成功"));
    }

    @Data
    public static class ReorderRequest {
        private UUID courseId;
        private List<UUID> sectionIds;
    }
}