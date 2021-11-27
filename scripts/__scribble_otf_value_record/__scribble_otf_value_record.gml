function __scribble_otf_value_record(_buffer, _format, _parent_offset) constructor
{
    __x_placement               = undefined;
    __y_lacement                = undefined;
    __x_advance                 = undefined;
    __y_advance                 = undefined;
    __x_placement_device_offset = undefined;
    __y_placement_device_offset = undefined;
    __x_advance_device_offset   = undefined;
    __y_advance_device_offset   = undefined;
    
    if (_format & 0x0001) __x_placement               = __scribble_otf_buffer_read_s16(_buffer);
    if (_format & 0x0002) __y_lacement                = __scribble_otf_buffer_read_s16(_buffer);
    if (_format & 0x0004) __x_advance                 = __scribble_otf_buffer_read_s16(_buffer);
    if (_format & 0x0008) __y_advance                 = __scribble_otf_buffer_read_s16(_buffer);
    if (_format & 0x0010) __x_placement_device_offset = __scribble_otf_buffer_read_u16(_buffer) + _parent_offset;
    if (_format & 0x0020) __y_placement_device_offset = __scribble_otf_buffer_read_u16(_buffer) + _parent_offset;
    if (_format & 0x0040) __x_advance_device_offset   = __scribble_otf_buffer_read_u16(_buffer) + _parent_offset;
    if (_format & 0x0080) __y_advance_device_offset   = __scribble_otf_buffer_read_u16(_buffer) + _parent_offset;
}