function __scribble_otf_lookup_table(_buffer, _offset) constructor
{
    __buffer = _buffer;
    
    
    
    __scribble_trace("Reading lookup table at offset ", ptr(_offset));
    buffer_seek(_buffer, buffer_seek_start, _offset);
    
    __lookup_type    = __scribble_otf_buffer_read_u16(__buffer);
    __lookup_flags   = __scribble_otf_buffer_read_u16(__buffer);
    var _subtable_count = __scribble_otf_buffer_read_u16(__buffer);
    
    __scribble_trace("Found ", _subtable_count, " subtables");
    __subtable_offset_array = __scribble_otf_buffer_read_array(__buffer, _subtable_count, buffer_u16, _offset);
    
    __mark_filtering_set = __scribble_otf_buffer_read_u16(__buffer);
    
    __scribble_trace("type = ", __lookup_type, ", flags = ", ptr(__lookup_flags), ", mark filtering set = ", __mark_filtering_set);
    
    
    
    static __read_gpos = function()
    {
        var _subtable_count = array_length(__subtable_offset_array);
        
        var _i = 0;
        repeat(_subtable_count)
        {
            var _subtable_offset = __subtable_offset_array[@ _i];
            __scribble_trace("Reading subtable ", _i);
        
            var _pos_format = __scribble_otf_buffer_read_u16(__buffer);
            switch(_pos_format)
            {
                case 1:
                    var _coverage_offset    = __scribble_otf_buffer_read_u16(__buffer) + _subtable_offset;
                    var _value_format       = __scribble_otf_buffer_read_u16(__buffer);
                    var _value_record_array = [new __scribble_otf_value_record(__buffer, _value_format, 0)];
                break;
            
                case 2:
                    var _coverage_offset = __scribble_otf_buffer_read_u16(__buffer) + _subtable_offset;
                    var _value_format    = __scribble_otf_buffer_read_u16(__buffer);
                    var _value_count     = __scribble_otf_buffer_read_u16(__buffer);
                
                    var _value_record_array = array_create(_value_count);
                    var _j = 0;
                    repeat(_value_count)
                    {
                        _value_record_array[@ _j] = new __scribble_otf_value_record(__buffer, _value_format, 0);
                        ++_j;
                    }
                break;
            
                default:
                    __scribble_trace("Lookup subtable format ", _pos_format, " not supported");
                break;
            }
        
            ++_i;
        }
    }
}