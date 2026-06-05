package io.github.origamihe.learning.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import io.github.origamihe.learning.entity.FileAttachment;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface FileAttachmentMapper extends BaseMapper<FileAttachment> {
}