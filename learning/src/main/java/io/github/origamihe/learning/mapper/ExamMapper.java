package io.github.origamihe.learning.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import io.github.origamihe.learning.entity.Exam;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ExamMapper extends BaseMapper<Exam> {
}