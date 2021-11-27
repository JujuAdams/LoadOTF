function OTFReadValueRecord(_buffer, _format, _parentOffset)
{
    var _record = {
        xPlacement       : undefined,
        yPlacement       : undefined,
        xAdvance         : undefined,
        yAdvance         : undefined,
        xPlaDeviceOffset : undefined,
        yPlaDeviceOffset : undefined,
        xAdvDeviceOffset : undefined,
        yAdvDeviceOffset : undefined,
    };
    
    with(_record)
    {
        if (_format & 0x0001) xPlacement       = BUF_S16;
        if (_format & 0x0002) yPlacement       = BUF_S16;
        if (_format & 0x0004) xAdvance         = BUF_S16;
        if (_format & 0x0008) yAdvance         = BUF_S16;
        if (_format & 0x0010) xPlaDeviceOffset = BUF_U16 + _parentOffset;
        if (_format & 0x0020) yPlaDeviceOffset = BUF_U16 + _parentOffset;
        if (_format & 0x0040) xAdvDeviceOffset = BUF_U16 + _parentOffset;
        if (_format & 0x0080) yAdvDeviceOffset = BUF_U16 + _parentOffset;
    }
    
    trace("Found record ", _record);
    
    return _record;
}