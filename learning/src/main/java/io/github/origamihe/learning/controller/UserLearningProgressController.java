package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.entity.UserLearningProgress;
import io.github.origamihe.learning.service.UserLearningProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/progress")
@RequiredArgsConstructor
public class UserLearningProgressController {

    private final UserLearningProgressService progressService;

    @PostMapping
    public ResponseEntity<?> updateProgress(@RequestBody Map<String, UUID> request) {
        User user = getAuthenticatedUser();
        UUID courseId = request.get("courseId");
        UUID sectionId = request.get("sectionId");
        progressService.updateProgress(user.getId(), courseId, sectionId);
        return ResponseEntity.ok(Map.of("message", "进度更新成功"));
    }

    @GetMapping("/course/{courseId}")
    public ResponseEntity<UserLearningProgress> getProgress(@PathVariable UUID courseId) {
        User user = getAuthenticatedUser();
        UserLearningProgress progress = progressService.getProgress(user.getId(), courseId);
        if (progress == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(progress);
    }

    @GetMapping("/me")
    public ResponseEntity<List<UserLearningProgress>> getMyProgress() {
        User user = getAuthenticatedUser();
        List<UserLearningProgress> progressList = progressService.getUserProgresses(user.getId());
        return ResponseEntity.ok(progressList);
    }

    @GetMapping("/completion/{courseId}")
    public ResponseEntity<Map<String, Double>> getCompletionRate(@PathVariable UUID courseId) {
        User user = getAuthenticatedUser();
        double rate = progressService.getCompletionRate(user.getId(), courseId);
        return ResponseEntity.ok(Map.of("completionRate", rate));
    }

    private User getAuthenticatedUser() {
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}