package io.github.origamihe.learning.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import io.github.origamihe.learning.entity.Question;
import io.github.origamihe.learning.enums.QuestionType;
import io.github.origamihe.learning.service.QuestionService;
import io.github.origamihe.learning.service.UserWrongQuestionService;
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
@RequestMapping("/api/questions")
@RequiredArgsConstructor
public class QuestionController {

    private final QuestionService questionService;
    private final UserWrongQuestionService wrongQuestionService;

    @Data
    public static class CreateQuestionRequest {
        private UUID courseId;
        private UUID sectionId;
        private QuestionType type;
        @NotBlank(message = "题目内容不能为空")
        private String content;
        private String options;
        private String answer;
        private String explanation;
        private Integer difficulty;
        private String tags;
    }

    @GetMapping
    public ResponseEntity<IPage<Question>> listQuestions(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) UUID courseId,
            @RequestParam(required = false) UUID sectionId,
            @RequestParam(required = false) QuestionType type,
            @RequestParam(required = false) Integer difficulty) {
        IPage<Question> result = questionService.pageQuestions(page, size, courseId, sectionId, type, difficulty);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/course/{courseId}")
    public ResponseEntity<List<Question>> getQuestionsByCourse(@PathVariable UUID courseId) {
        List<Question> questions = questionService.getQuestionsByCourse(courseId);
        return ResponseEntity.ok(questions);
    }

    @GetMapping("/section/{sectionId}")
    public ResponseEntity<List<Question>> getQuestionsBySection(@PathVariable UUID sectionId) {
        List<Question> questions = questionService.getQuestionsBySection(sectionId);
        return ResponseEntity.ok(questions);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Question> getQuestion(@PathVariable UUID id) {
        Question question = questionService.getById(id);
        if (question == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(question);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> createQuestion(@Valid @RequestBody CreateQuestionRequest request) {
        Question question = Question.builder()
                .courseId(request.getCourseId())
                .sectionId(request.getSectionId())
                .type(request.getType())
                .content(request.getContent())
                .options(request.getOptions())
                .answer(request.getAnswer())
                .explanation(request.getExplanation())
                .difficulty(request.getDifficulty())
                .tags(request.getTags())
                .build();
        Question saved = questionService.createQuestion(question);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> updateQuestion(@PathVariable UUID id, @RequestBody Question question) {
        question.setId(id);
        try {
            questionService.updateQuestion(question);
            return ResponseEntity.ok(Map.of("message", "更新成功"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> deleteQuestion(@PathVariable UUID id) {
        questionService.softDeleteQuestion(id);
        return ResponseEntity.ok(Map.of("message", "删除成功"));
    }

    @PostMapping("/{id}/wrong")
    public ResponseEntity<?> addWrongQuestion(@PathVariable UUID id, @RequestParam UUID userId) {
        wrongQuestionService.addWrongQuestion(userId, id);
        return ResponseEntity.ok(Map.of("message", "已加入错题本"));
    }
}