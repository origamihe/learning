package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.Exam;

import java.util.List;
import java.util.UUID;

public interface ExamService extends IService<Exam> {

    Exam createExam(Exam exam);

    void publishExam(UUID examId);

    List<Exam> getExamsByCourse(UUID courseId);

    Exam getExamDetail(UUID examId);
}