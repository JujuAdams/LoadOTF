function __scribble_otf_buffer_read_array(_buffer, _count, _datatype, _value_offset = undefined)
{
    var _array = array_create(_count);
    var _i = 0;
    repeat(_count)
    {
        var _value = __scribble_otf_buffer_read(_buffer, _datatype); //TODO - Optimise
        if (_value_offset != undefined) _value += _value_offset;
        _array[@ _i] = _value;
        ++_i;
    }
    
    return _array;
}

function __scribble_otf_buffer_read(_buffer, _datatype)
{
    switch(_datatype)
    {
        case buffer_u8:  return __scribble_otf_buffer_read_u8( _buffer); break;
        case buffer_u16: return __scribble_otf_buffer_read_u16(_buffer); break;
        case buffer_s16: return __scribble_otf_buffer_read_s16(_buffer); break;
        case buffer_u32: return __scribble_otf_buffer_read_u32(_buffer); break;
        case buffer_u64: return __scribble_otf_buffer_read_u64(_buffer); break;
        case "tag":      return __scribble_otf_buffer_read_tag(_buffer); break;
    }
}

function __scribble_otf_buffer_read_u8(_buffer)
{
    return buffer_read(_buffer, buffer_u8);
}

function __scribble_otf_buffer_read_u16(_buffer)
{
    var _a = buffer_read(_buffer, buffer_u8);
    var _b = buffer_read(_buffer, buffer_u8);
    return (_b | (_a << 8));
}

function __scribble_otf_buffer_read_s16(_buffer)
{
    static _transferBuffer = buffer_create(2, buffer_fixed, 1);
    
    var _a = buffer_read(_buffer, buffer_u8);
    var _b = buffer_read(_buffer, buffer_u8);
            
    buffer_poke(_transferBuffer, 0, buffer_u16, _b | (_a << 8));
    return buffer_peek(_transferBuffer, 0, buffer_s16); //TODO - Do this properly
}

function __scribble_otf_buffer_read_u32(_buffer)
{
    var _a = buffer_read(_buffer, buffer_u8);
    var _b = buffer_read(_buffer, buffer_u8);
    var _c = buffer_read(_buffer, buffer_u8);
    var _d = buffer_read(_buffer, buffer_u8);
    return (_d | (_c << 8) | (_b << 16) | (_a << 24));
}

function __scribble_otf_buffer_read_u64(_buffer)
{
    var _a = buffer_read(_buffer, buffer_u8);
    var _b = buffer_read(_buffer, buffer_u8);
    var _c = buffer_read(_buffer, buffer_u8);
    var _d = buffer_read(_buffer, buffer_u8);
    var _e = buffer_read(_buffer, buffer_u8);
    var _f = buffer_read(_buffer, buffer_u8);
    var _g = buffer_read(_buffer, buffer_u8);
    var _h = buffer_read(_buffer, buffer_u8);
    return (_h | (_g << 8) | (_f << 16) | (_e << 24) | (_d << 32) | (_c << 40) | (_b << 48) | (_a << 56));
}

function __scribble_otf_buffer_read_tag(_buffer)
{
    var _a = chr(buffer_read(_buffer, buffer_u8));
    var _b = chr(buffer_read(_buffer, buffer_u8));
    var _c = chr(buffer_read(_buffer, buffer_u8));
    var _d = chr(buffer_read(_buffer, buffer_u8));
    return _a + _b + _c + _d;
}