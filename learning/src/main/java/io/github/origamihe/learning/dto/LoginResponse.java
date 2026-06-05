package io.github.origamihe.learning.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponse {

    private UUID userId;
    private String username;
    private String nickname;
    private String accessToken;
    private long expiresIn;
    private String refreshToken;
    private long refreshExpiresIn;
}