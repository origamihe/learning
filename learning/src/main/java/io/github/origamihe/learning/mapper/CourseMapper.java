package io.github.origamihe.learning.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import io.github.origamihe.learning.entity.Course;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface CourseMapper extends BaseMapper<Course> {
}