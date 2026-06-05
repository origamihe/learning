package io.github.origamihe.learning.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import io.github.origamihe.learning.entity.ExamRecord;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ExamRecordMapper extends BaseMapper<ExamRecord> {
}