package io.github.origamihe.learning.controller;

import io.github.origamihe.learning.config.JwtProperties;
import io.github.origamihe.learning.dto.LoginRequest;
import io.github.origamihe.learning.dto.LoginResponse;
import io.github.origamihe.learning.dto.RegisterRequest;
import io.github.origamihe.learning.entity.User;
import io.github.origamihe.learning.security.JwtUtil;
import io.github.origamihe.learning.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final JwtProperties jwtProperties;

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        User user = userService.findByUsername(request.getUsername());
        if (user == null) {
            return ResponseEntity.status(401).body(Map.of("message", "用户名或密码错误"));
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            return ResponseEntity.status(401).body(Map.of("message", "用户名或密码错误"));
        }

        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getUsername(), user.getRole().name());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        LoginResponse response = LoginResponse.builder()
                .userId(user.getId())
                .username(user.getUsername())
                .nickname(user.getNickname())
                .accessToken(accessToken)
                .expiresIn(jwtProperties.getExpiration())
                .refreshToken(refreshToken)
                .refreshExpiresIn(jwtProperties.getRefreshExpiration())
                .build();

        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            User user = userService.register(
                    request.getUsername(),
                    request.getEmail(),
                    request.getPassword(),
                    request.getNickname() != null ? request.getNickname() : request.getUsername()
            );

            String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getUsername(), user.getRole().name());
            String refreshToken = jwtUtil.generateRefreshToken(user.getId());

            LoginResponse response = LoginResponse.builder()
                    .userId(user.getId())
                    .username(user.getUsername())
                    .nickname(user.getNickname())
                    .accessToken(accessToken)
                    .expiresIn(jwtProperties.getExpiration())
                    .refreshToken(refreshToken)
                    .refreshExpiresIn(jwtProperties.getRefreshExpiration())
                    .build();

            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}