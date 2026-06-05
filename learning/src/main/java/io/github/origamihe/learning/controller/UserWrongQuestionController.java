package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.entity.UserWrongQuestion;
import io.github.origamihe.learning.service.UserWrongQuestionService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/wrong-questions")
@RequiredArgsConstructor
public class UserWrongQuestionController {

    private final UserWrongQuestionService wrongQuestionService;

    @Data
    public static class UpdateNotesRequest {
        private String notes;
    }

    @PostMapping
    public ResponseEntity<?> addWrongQuestion(@RequestBody Map<String, UUID> request) {
        User user = getAuthenticatedUser();
        UUID questionId = request.get("questionId");
        wrongQuestionService.addWrongQuestion(user.getId(), questionId);
        return ResponseEntity.ok(Map.of("message", "已添加到错题本"));
    }

    @GetMapping("/me")
    public ResponseEntity<List<UserWrongQuestion>> getMyWrongQuestions() {
        User user = getAuthenticatedUser();
        List<UserWrongQuestion> questions = wrongQuestionService.getUserWrongQuestions(user.getId());
        return ResponseEntity.ok(questions);
    }

    @GetMapping("/review/due")
    public ResponseEntity<List<UserWrongQuestion>> getDueForReview() {
        User user = getAuthenticatedUser();
        List<UserWrongQuestion> questions = wrongQuestionService.getDueForReview(user.getId());
        return ResponseEntity.ok(questions);
    }

    @PutMapping("/{id}/mastery")
    public ResponseEntity<?> updateMastery(@PathVariable UUID id, @RequestBody Map<String, Integer> request) {
        wrongQuestionService.updateMasteryLevel(id, request.get("level"));
        return ResponseEntity.ok(Map.of("message", "更新成功"));
    }

    @PutMapping("/{id}/notes")
    public ResponseEntity<?> updateNotes(@PathVariable UUID id, @RequestBody UpdateNotesRequest request) {
        wrongQuestionService.updateNotes(id, request.getNotes());
        return ResponseEntity.ok(Map.of("message", "更新成功"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> removeWrongQuestion(@PathVariable UUID id) {
        wrongQuestionService.removeWrongQuestion(id);
        return ResponseEntity.ok(Map.of("message", "已移除"));
    }

    private User getAuthenticatedUser() {
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}