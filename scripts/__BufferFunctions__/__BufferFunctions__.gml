function buffer_read_little(_buffer, _datatype)
{
    static _transferBuffer = buffer_create(8, buffer_fixed, 1);
    
    switch(_datatype)
    {
        case buffer_u8:
            return buffer_read(_buffer, buffer_u8);
        break;
        
        case buffer_u16:
            var _a = buffer_read(_buffer, buffer_u8);
            var _b = buffer_read(_buffer, buffer_u8);
            return (_b | (_a << 8));
        break;
        
        case buffer_s16:
            var _a = buffer_read(_buffer, buffer_u8);
            var _b = buffer_read(_buffer, buffer_u8);
            
            buffer_poke(_transferBuffer, 0, buffer_u16, _b | (_a << 8));
            return buffer_peek(_transferBuffer, 0, buffer_s16); //TODO - Do this properly
        break;
        
        case buffer_u32:
            var _a = buffer_read(_buffer, buffer_u8);
            var _b = buffer_read(_buffer, buffer_u8);
            var _c = buffer_read(_buffer, buffer_u8);
            var _d = buffer_read(_buffer, buffer_u8);
            return (_d | (_c << 8) | (_b << 16) | (_a << 24));
        break;
        
        case buffer_u64:
            var _a = buffer_read(_buffer, buffer_u8);
            var _b = buffer_read(_buffer, buffer_u8);
            var _c = buffer_read(_buffer, buffer_u8);
            var _d = buffer_read(_buffer, buffer_u8);
            var _e = buffer_read(_buffer, buffer_u8);
            var _f = buffer_read(_buffer, buffer_u8);
            var _g = buffer_read(_buffer, buffer_u8);
            var _h = buffer_read(_buffer, buffer_u8);
            return (_h | (_g << 8) | (_f << 16) | (_e << 24) | (_d << 32) | (_c << 40) | (_b << 48) | (_a << 56));
        break;
    }
    
    return undefined;
}

function buffer_read_tag(_buffer)
{
    var _a = chr(buffer_read(_buffer, buffer_u8));
    var _b = chr(buffer_read(_buffer, buffer_u8));
    var _c = chr(buffer_read(_buffer, buffer_u8));
    var _d = chr(buffer_read(_buffer, buffer_u8));
    return _a + _b + _c + _d;
}