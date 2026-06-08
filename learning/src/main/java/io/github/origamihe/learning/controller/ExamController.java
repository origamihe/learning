package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.entity.Exam;
import io.github.origamihe.learning.service.ExamService;
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
@RequestMapping("/api/exams")
@RequiredArgsConstructor
public class ExamController {

    private final ExamService examService;

    @Data
    public static class CreateExamRequest {
        @NotBlank(message = "考试标题不能为空")
        private String title;
        private UUID courseId;
        private Integer duration;
        private Integer totalScore;
        private Integer passScore;
        private String config;
    }

    @GetMapping("/course/{courseId}")
    public ResponseEntity<List<Exam>> getExamsByCourse(@PathVariable UUID courseId) {
        List<Exam> exams = examService.getExamsByCourse(courseId);
        return ResponseEntity.ok(exams);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Exam> getExamDetail(@PathVariable UUID id) {
        Exam exam = examService.getExamDetail(id);
        if (exam == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(exam);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> createExam(@Valid @RequestBody CreateExamRequest request) {
        Exam exam = Exam.builder()
                .title(request.getTitle())
                .courseId(request.getCourseId())
                .duration(request.getDuration())
                .totalScore(request.getTotalScore() != null ? request.getTotalScore() : 100)
                .passScore(request.getPassScore() != null ? request.getPassScore() : 60)
                .config(request.getConfig())
                .build();
        Exam saved = examService.createExam(exam);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> updateExam(@PathVariable UUID id, @RequestBody Exam exam) {
        exam.setId(id);
        examService.updateById(exam);
        return ResponseEntity.ok(Map.of("message", "更新成功"));
    }

    @PostMapping("/{id}/publish")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> publishExam(@PathVariable UUID id) {
        try {
            examService.publishExam(id);
            return ResponseEntity.ok(Map.of("message", "发布成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> deleteExam(@PathVariable UUID id) {
        examService.removeById(id);
        return ResponseEntity.ok(Map.of("message", "删除成功"));
    }
}