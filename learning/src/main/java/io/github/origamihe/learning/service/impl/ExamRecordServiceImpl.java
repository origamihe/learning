package io.github.origamihe.learning.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import io.github.origamihe.learning.entity.Exam;
import io.github.origamihe.learning.entity.ExamRecord;
import io.github.origamihe.learning.enums.ExamRecordStatus;
import io.github.origamihe.learning.mapper.ExamRecordMapper;
import io.github.origamihe.learning.service.ExamRecordService;
import io.github.origamihe.learning.service.ExamService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ExamRecordServiceImpl extends ServiceImpl<ExamRecordMapper, ExamRecord> implements ExamRecordService {

    private final ExamService examService;

    public ExamRecordServiceImpl(ExamService examService) {
        this.examService = examService;
    }

    @Override
    @Transactional
    public ExamRecord startExam(UUID userId, UUID examId) {
        Exam exam = examService.getById(examId);
        if (exam == null) {
            throw new RuntimeException("考试不存在");
        }
        ExamRecord record = ExamRecord.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .examId(examId)
                .startTime(Instant.now())
                .status(ExamRecordStatus.IN_PROGRESS)
                .build();
        save(record);
        return record;
    }

    @Override
    @Transactional
    public ExamRecord submitExam(UUID recordId, Map<String, Object> answers) {
        ExamRecord record = getById(recordId);
        if (record == null) {
            throw new RuntimeException("考试记录不存在");
        }
        if (record.getStatus() != ExamRecordStatus.IN_PROGRESS) {
            throw new RuntimeException("考试已结束");
        }
        record.setEndTime(Instant.now());
        record.setDurationUsed((int) ChronoUnit.SECONDS.between(record.getStartTime(), record.getEndTime()));
        record.setAnswers(answers.toString());
        record.setStatus(ExamRecordStatus.SUBMITTED);
        updateById(record);
        return record;
    }

    @Override
    @Transactional
    public ExamRecord gradeExam(UUID recordId) {
        ExamRecord record = getById(recordId);
        if (record == null) {
            throw new RuntimeException("考试记录不存在");
        }
        record.setScore(BigDecimal.ZERO);
        record.setStatus(ExamRecordStatus.GRADED);
        updateById(record);
        return record;
    }

    @Override
    public List<ExamRecord> getUserExamRecords(UUID userId) {
        return lambdaQuery()
                .eq(ExamRecord::getUserId, userId)
                .orderByDesc(ExamRecord::getCreatedAt)
                .list();
    }

    @Override
    public ExamRecord getExamRecordDetail(UUID recordId) {
        return getById(recordId);
    }
}