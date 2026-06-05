package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.entity.ExamRecord;
import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.service.ExamRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/exam-records")
@RequiredArgsConstructor
public class ExamRecordController {

    private final ExamRecordService examRecordService;

    @PostMapping("/start")
    public ResponseEntity<?> startExam(@RequestParam UUID examId) {
        User user = getAuthenticatedUser();
        try {
            ExamRecord record = examRecordService.startExam(user.getId(), examId);
            return ResponseEntity.ok(record);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/{id}/submit")
    public ResponseEntity<?> submitExam(@PathVariable UUID id, @RequestBody Map<String, Object> answers) {
        try {
            ExamRecord record = examRecordService.submitExam(id, answers);
            return ResponseEntity.ok(record);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/{id}/grade")
    public ResponseEntity<?> gradeExam(@PathVariable UUID id) {
        try {
            ExamRecord record = examRecordService.gradeExam(id);
            return ResponseEntity.ok(record);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<ExamRecord>> getUserRecords(@PathVariable UUID userId) {
        List<ExamRecord> records = examRecordService.getUserExamRecords(userId);
        return ResponseEntity.ok(records);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ExamRecord> getRecordDetail(@PathVariable UUID id) {
        ExamRecord record = examRecordService.getExamRecordDetail(id);
        if (record == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(record);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteRecord(@PathVariable UUID id) {
        examRecordService.removeById(id);
        return ResponseEntity.ok(Map.of("message", "删除成功"));
    }

    private User getAuthenticatedUser() {
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}