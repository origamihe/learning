package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.Exam;
import io.github.origamihe.learning.enums.ExamStatus;
import io.github.origamihe.learning.mapper.ExamMapper;
import io.github.origamihe.learning.service.ExamService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class ExamServiceImpl extends ServiceImpl<ExamMapper, Exam> implements ExamService {

    @Override
    @Transactional
    public Exam createExam(Exam exam) {
        exam.setId(UUID.randomUUID());
        exam.setStatus(ExamStatus.DRAFT);
        save(exam);
        return exam;
    }

    @Override
    @Transactional
    public void publishExam(UUID examId) {
        Exam exam = getById(examId);
        if (exam == null) {
            throw new RuntimeException("考试不存在");
        }
        exam.setStatus(ExamStatus.DRAFT);
        updateById(exam);
    }

    @Override
    public List<Exam> getExamsByCourse(UUID courseId) {
        return lambdaQuery()
                .eq(Exam::getCourseId, courseId)
                .orderByDesc(Exam::getCreatedAt)
                .list();
    }

    @Override
    public Exam getExamDetail(UUID examId) {
        return getById(examId);
    }
}