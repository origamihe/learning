package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.entity.UserSignIn;
import io.github.origamihe.learning.service.UserSignInService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/sign-in")
@RequiredArgsConstructor
public class UserSignInController {

    private final UserSignInService signInService;

    @PostMapping
    public ResponseEntity<?> doSignIn() {
        User user = getAuthenticatedUser();
        try {
            UserSignIn record = signInService.signIn(user.getId());
            return ResponseEntity.ok(Map.of(
                    "message", "签到成功",
                    "pointsEarned", record.getPointsEarned(),
                    "streakDays", signInService.getStreakDays(user.getId()),
                    "record", record
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getSignInStatus() {
        User user = getAuthenticatedUser();
        boolean hasSigned = signInService.hasSignedToday(user.getId());
        int streakDays = signInService.getStreakDays(user.getId());
        return ResponseEntity.ok(Map.of(
                "hasSignedToday", hasSigned,
                "streakDays", streakDays
        ));
    }

    @GetMapping("/records")
    public ResponseEntity<List<UserSignIn>> getSignInRecords(
            @RequestParam int year,
            @RequestParam int month) {
        User user = getAuthenticatedUser();
        List<UserSignIn> records = signInService.getSignInRecords(user.getId(), year, month);
        return ResponseEntity.ok(records);
    }

    private User getAuthenticatedUser() {
        return (User) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}