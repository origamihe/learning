package io.github.origamihe.learning.service;

import com.baomidou.mybatisplus.extension.service.IService;
import io.github.origamihe.learning.entity.ExamRecord;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface ExamRecordService extends IService<ExamRecord> {

    ExamRecord startExam(UUID userId, UUID examId);

    ExamRecord submitExam(UUID recordId, Map<String, Object> answers);

    ExamRecord gradeExam(UUID recordId);

    List<ExamRecord> getUserExamRecords(UUID userId);

    ExamRecord getExamRecordDetail(UUID recordId);
}