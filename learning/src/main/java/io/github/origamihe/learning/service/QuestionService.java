package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.Question;
import io.github.origamihe.learning.enums.QuestionType;

import java.util.List;
import java.util.UUID;

public interface QuestionService extends IService<Question> {

    IPage<Question> pageQuestions(int page, int size, UUID courseId, UUID sectionId, QuestionType type, Integer difficulty);

    List<Question> getQuestionsByCourse(UUID courseId);

    List<Question> getQuestionsBySection(UUID sectionId);

    Question createQuestion(Question question);

    void updateQuestion(Question question);

    void softDeleteQuestion(UUID questionId);
}