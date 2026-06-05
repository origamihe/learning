package io.github.origamihe.learning.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import io.github.origamihe.learning.entity.UserLearningProgress;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserLearningProgressMapper extends BaseMapper<UserLearningProgress> {
}