package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.Question;
import io.github.origamihe.learning.enums.QuestionType;
import io.github.origamihe.learning.mapper.QuestionMapper;
import io.github.origamihe.learning.service.QuestionService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class QuestionServiceImpl extends ServiceImpl<QuestionMapper, Question> implements QuestionService {

    @Override
    public IPage<Question> pageQuestions(int page, int size, UUID courseId, UUID sectionId, QuestionType type, Integer difficulty) {
        LambdaQueryWrapper<Question> wrapper = new LambdaQueryWrapper<>();
        if (courseId != null) {
            wrapper.eq(Question::getCourseId, courseId);
        }
        if (sectionId != null) {
            wrapper.eq(Question::getSectionId, sectionId);
        }
        if (type != null) {
            wrapper.eq(Question::getType, type);
        }
        if (difficulty != null) {
            wrapper.eq(Question::getDifficulty, difficulty);
        }
        wrapper.orderByDesc(Question::getCreatedAt);
        return page(new Page<>(page, size), wrapper);
    }

    @Override
    public List<Question> getQuestionsByCourse(UUID courseId) {
        return lambdaQuery().eq(Question::getCourseId, courseId).list();
    }

    @Override
    public List<Question> getQuestionsBySection(UUID sectionId) {
        return lambdaQuery().eq(Question::getSectionId, sectionId).list();
    }

    @Override
    @Transactional
    public Question createQuestion(Question question) {
        question.setId(UUID.randomUUID());
        save(question);
        return question;
    }

    @Override
    @Transactional
    public void updateQuestion(Question question) {
        if (getById(question.getId()) == null) {
            throw new RuntimeException("题目不存在");
        }
        updateById(question);
    }

    @Override
    @Transactional
    public void softDeleteQuestion(UUID questionId) {
        removeById(questionId);
    }
}