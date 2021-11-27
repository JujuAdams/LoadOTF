global.__scribble_otf_transfer_buffer = buffer_create(8, buffer_fixed, 1);

function __scribble_otf_class(_filename) constructor
{
    __filename = _filename;
    __master_table_dictionary = {};
    
    
    
    __scribble_trace("Loading \"", __filename, "\"");
    
    if (!file_exists(__filename))
    {
        __scribble_trace("\"", __filename, "\" does not exist");
    }
    else
    {
        try
        {
            __buffer = buffer_load(__filename);
        }
        catch(_)
        {
            __scribble_trace("\"", __filename, "\" failed to open");
            __buffer = undefined;
        }
        
        if (__buffer != undefined)
        {
            __scribble_trace("Size = 0x", ptr(buffer_get_size(__buffer)), " (d=", buffer_get_size(__buffer), ")");
            
            __read_preamble();
            __read_head();
            __read_cmap();
            __read_gpos();
            __read_gsub();
            
            buffer_delete(__buffer);
        }
    }
    
    __scribble_trace("Finished \"", __filename, "\"");
    
    
    
    static __read_preamble = function()
    {
        #region Preamble
        
        __sfnt_version = __read_u32();
    
        if (__sfnt_version == 0x00010000)
        {
            __scribble_trace("Valid table directory version found (TrueType outlines)");
        }
        else if (__sfnt_version == 0x4F5454AF)
        {
            __scribble_trace("Valid table directory version found (contains CFF data)");
        }
        else
        {
            __scribble_trace("Table directory version not recognised (", ptr(__sfnt_version), ")");
            buffer_delete(__buffer);
            return;
        }
        
        var _num_tables     = __read_u16();
        var _search_range   = __read_u16();
        var _entry_selector = __read_u16();
        var _range_shift    = __read_u16();
        
        __scribble_trace("Found ", _num_tables, " tables");
        
        repeat(_num_tables)
        {
            var _table_tag = __read_tag();
            var _checksum  = __read_u32();
            var _offset    = __read_u32();
            var _length    = __read_u32();
        
            __scribble_trace("\"", _table_tag, "\", offset = ", ptr(_offset));
        
            var _data = {   
                __tag      : _table_tag,
                __checksum : _checksum,
                __offset   : _offset,
                __length   : _length
            };
        
            __master_table_dictionary[$ _table_tag] = _data;
        }
        
        #endregion
    }
    
    static __read_head = function()
    {
        #region head
        
        var _table_data = __master_table_dictionary[$ "head"];
        if (!is_struct(_table_data))
        {
            __scribble_trace("Warning! head table not found");
            return;
        }
        else
        {
            __scribble_trace("Reading head table");
            buffer_seek(__buffer, buffer_seek_start, _table_data.__offset);
        
            var _major_version     = __read_u16();
            var _minor_version     = __read_u16();
            var _font_revision     = __read_fixed32();
            var _checksum_adj      = __read_u32();
            var _magic_number      = __read_u32();
            var _flags             = __read_u16();
            __units_per_em         = __read_u16();
            var _date_created      = __read_u64();
            var _data_modified     = __read_u64();
            var _x_min             = __read_s16();
            var _y_min             = __read_s16();
            var _x_max             = __read_s16();
            var _y_max             = __read_s16();
            var _mac_style         = __read_u16();
            var _lowest_rec_PPM    = __read_u16();
            var _direction_hint    = __read_s16();
            __index_to_loc_format  = __read_s16();
            var _glyph_data_format = __read_u16();
            
            if (_magic_number != 0x5F0F3CF5)
            {
                __scribble_trace("\"head\" magic number is invalid (", ptr(_magic_number), ")");
                return;
            }
            
            __scribble_trace("Units per em = ", __units_per_em, ", index-to-loc format = ", __index_to_loc_format);
        }
        
        #endregion
    }
    
    static __read_cmap = function()
    {
        #region cmap
        
        var _table_data = __master_table_dictionary[$ "cmap"];
        if (!is_struct(_table_data))
        {
            __scribble_trace("cmap table not found");
            return;
        }
        else
        {
            __scribble_trace("Reading cmap table");
            buffer_seek(__buffer, buffer_seek_start, _table_data.__offset);
        
            var _version   = __read_u16();
            var _numTables = __read_u16();
        
            __scribble_trace("cmap table is version ", _version);
        
            if (_version != 0)
            {
                __scribble_trace("cmap version not recognised");
                return;
            }
        
            __scribble_trace(_numTables, " cmap tables found");
        
            var _platform_dictionary = {};
            repeat(_numTables)
            {
                var _platform_id     = __read_u16();
                var _encoding_id     = __read_u16();
                var _subtable_offset = __read_u32();
            
                __scribble_trace("platform ID = ", _platform_id, ", encoding ID = ", _encoding_id, ", subtable offset = ", _subtable_offset);
            
                var _metadata = {
                    __platform_id     : _platform_id,
                    __encoding_id     : _encoding_id,
                    __subtable_offset : _subtable_offset + _table_data.__offset,
                };
            
                _platform_dictionary[$ _platform_id] = _metadata;
            }
        
            var _subtable_metadata = _platform_dictionary[$ 0];
            if (_subtable_metadata == undefined)
            {
                __scribble_trace("Unicode platform data not found");
                return;
            }
        
            var _subtable_format = undefined;
            if (_subtable_metadata.__encoding_id == 3)
            {
                _subtable_format = 4;
            }
            else
            {
                _subtable_format = 12;
            }
        
            if (_subtable_format == undefined)
            {
                __scribble_trace("Unicode encoding ID not supported");
                return;
            }
        
            __scribble_trace("Subtable format chosen as ", _subtable_format);
        
            buffer_seek(__buffer, buffer_seek_start, _subtable_metadata.__subtable_offset);
        
            if (_subtable_format == 4)
            {
                var _format = __read_u16();
                if (_format != 4)
                {
                    __scribble_trace("Was expecting format ID 4 but got ", _format);
                    return;
                }
            
                var _length        = __read_u16();
                var _language      = __read_u16();
                var _segCountx2    = __read_u16();
                var _searchRange   = __read_u16();
                var _entrySelector = __read_u16();
                var _rangeShift    = __read_u16();
            
                var _segCount = _segCountx2 div 2;
                __scribble_trace("Found ", _segCount, " segments");
            
                var _endCountArray      = array_create(_segCount);
                var _startCountArray    = array_create(_segCount);
                var _deltaArray         = array_create(_segCount);
                var _idRangeOffsetArray = array_create(_segCount);
            
                var _i = 0;
                repeat(_segCount)
                {
                    _endCountArray[@ _i] = __read_u16();
                    ++_i;
                }
            
                var _padding = __read_u16();
                if (_padding != 0)
                {
                    __scribble_trace("Padding interrupted by erroneous data");
                    return;
                }
            
                var _i = 0;
                repeat(_segCount)
                {
                    _startCountArray[@ _i] = __read_u16();
                    ++_i;
                }
            
                var _i = 0;
                repeat(_segCount)
                {
                    _deltaArray[@ _i] = __read_s16();
                    ++_i;
                }
            
                var _idRangeTableOffset = buffer_tell(__buffer);
            
                var _i = 0;
                repeat(_segCount)
                {
                    _idRangeOffsetArray[@ _i] = __read_u16();
                    ++_i;
                }
            
                glyph_id_to_unicode_array = [];
            
                var _i = 0;
                repeat(_segCount-1)
                {
                    var _start       = _startCountArray[_i];
                    var _end         = _endCountArray[_i];
                    var _delta       = _deltaArray[_i];
                    var _rangeOffset = _idRangeOffsetArray[_i];
                
                    var _offset = _idRangeTableOffset + 2*_i; //2 bytes per u16
                
                    var _j = _start;
                    repeat(1 + _end - _start)
                    {
                        var _charCode = _j;
                        var _id = undefined;
                    
                        if (_rangeOffset == 0)
                        {
                            _id = (_charCode + _delta) % 0xFFFF;
                        }
                        else
                        {
                            buffer_seek(__buffer, buffer_seek_start, _offset + _rangeOffset + 2*(_charCode - _start));
                            var _id = (__read_u16() + _delta) % 0xFFFF;
                        }
                    
                        if (_id < array_length(glyph_id_to_unicode_array))
                        {
                            if (glyph_id_to_unicode_array[_id] != 0)
                            {
                                __scribble_trace("Warning! ", _id, " overwritten. Old charcode = ", glyph_id_to_unicode_array[_id], ", new = ", _charCode);
                            }
                        }
                    
                        glyph_id_to_unicode_array[@ _id] = _charCode;
                    
                        ++_j;
                    }
                
                    ++_i;
                }
            
                __scribble_trace("glyph_id_to_unicode_array = ", glyph_id_to_unicode_array);
            
                //var _unicodeCoveredArray = array_create(array_length(_idToUnicodeArray));
                //array_copy(_unicodeCoveredArray, 0, _idToUnicodeArray, 0, array_length(_idToUnicodeArray));
                //array_sort(_unicodeCoveredArray, true);
                //__scribble_trace("Unicode covered = ", _unicodeCoveredArray);
                //
                //var _i = 0;
                //repeat(array_length(_unicodeCoveredArray))
                //{
                //    __scribble_trace(_unicodeCoveredArray[_i], " = \"", chr(_unicodeCoveredArray[_i]), "\"");
                //    ++_i;
                //}
            }
            else if (_subtable_format == 12)
            {
                __scribble_trace("Format 12 not currently supported");
            }
        }
        
        #endregion
    }
    
    static __read_gpos = function()
    {
        //
        //var _tableData = _tableDictionary[$ "GPOS"];
        //if (!is_struct(_tableData))
        //{
        //    __scribble_trace("\"GPOS\" table not found");
        //    return;
        //}
        //else
        //{
        //    __scribble_trace("\"GPOS\" table found, offset = 0x", ptr(_tableData.offset), ", length = ", ptr(_tableData.length));
        //    buffer_seek(_buffer, buffer_seek_start, _tableData.offset);
        //    
        //    var _majorVersion      = BUF_U16;
        //    var _minorVersion      = BUF_U16;
        //    var _scriptListOffset  = BUF_U16 + _tableData.offset;
        //    var _featureListOffset = BUF_U16 + _tableData.offset;
        //    var _lookupListOffset  = BUF_U16 + _tableData.offset;
        //    
        //    __scribble_trace("\"GPOS\" table is version ", _majorVersion, ".", _minorVersion);
        //    
        //    if ((_majorVersion == 1) && (_minorVersion == 0))
        //    {
        //        var _featureVariationsOffset = undefined;
        //    }
        //    else if ((_majorVersion == 1) && (_minorVersion == 1))
        //    {
        //        var featureVariationsOffset = BUF_U32;
        //        __scribble_trace("Warning! This \"GPOS\" table version has only partial support");
        //    }
        //    else
        //    {
        //        __scribble_trace("\"GPOS\" table version not supported");
        //        return;
        //    }
        //    
        //    
        //    
        //    //buffer_seek(_buffer, buffer_seek_start, _scriptListOffset);
        //    //
        //    //var _languageCount = BUF_U16;
        //    //
        //    //__scribble_trace("Found ", _languageCount, " languages");
        //    //var _languageArray = array_create(_languageCount);
        //    //var _i = 0;
        //    //repeat(_languageCount)
        //    //{
        //    //    var _tag    = BUF_TAG;
        //    //    var _offset = BUF_U16;
        //    //    
        //    //    _languageArray[@ _i] = {
        //    //        tag    : _tag,
        //    //        offset : _offset,
        //    //    };
        //    //    
        //    //    ++_i;
        //    //}
        //    
        //    
        //    
        //    buffer_seek(_buffer, buffer_seek_start, _lookupListOffset);
        //    
        //    var _lookupCount = BUF_U16;
        //    __scribble_trace("Found ", _lookupCount, " lookup tables");
        //    
        //    var _lookupOffsetArray = array_create(_lookupCount);
        //    var _i = 0;
        //    repeat(_lookupCount)
        //    {
        //        _lookupOffsetArray[@ _i] = BUF_U16 + _lookupListOffset;
        //        ++_i;
        //    }
        //    
        //    var _i = 0;
        //    repeat(_lookupCount)
        //    {
        //        __scribble_trace("Reading lookup table ", _i);
        //        
        //        var _lookupOffset = _lookupOffsetArray[_i];
        //        buffer_seek(_buffer, buffer_seek_start, _lookupOffset);
        //        
        //        var _lookupType    = BUF_U16;
        //        var _lookupFlags   = BUF_U16;
        //        var _subtableCount = BUF_U16;
        //        __scribble_trace("Found ", _subtableCount, " subtables");
        //        
        //        var _subtableOffsetArray = array_create(_subtableCount);
        //        var _j = 0;
        //        repeat(_subtableCount)
        //        {
        //            _subtableOffsetArray[@ _j] = BUF_U16 + _lookupOffset;
        //            ++_j;
        //        }
        //        
        //        var _markFilteringSet = BUF_U16;
        //        
        //        __scribble_trace("type = ", _lookupType, ", flags = ", ptr(_lookupFlags), ", mark filtering set = ", _markFilteringSet);
        //        
        //        var _j = 0;
        //        repeat(_subtableCount)
        //        {
        //            var _subtableOffset = _subtableOffsetArray[@ _j];
        //            __scribble_trace("Reading subtable ", _j, " (of lookup table ", _i, ")");
        //            
        //            var _posFormat = BUF_U16;
        //            switch(_posFormat)
        //            {
        //                case 1:
        //                    var _coverageOffset   = BUF_U16 + _subtableOffset;
        //                    var _valueFormat      = BUF_U16;
        //                    var _valueRecordArray = [OTFReadValueRecord(_buffer, _valueFormat, 0)];
        //                break;
        //                
        //                case 2:
        //                    var _coverageOffset = BUF_U16 + _subtableOffset;
        //                    var _valueFormat    = BUF_U16;
        //                    var _valueCount     = BUF_U16;
        //                    
        //                    var _valueRecordArray = array_create(_valueCount);
        //                    var _k = 0;
        //                    repeat(_valueCount)
        //                    {
        //                        _valueRecordArray[@ _k] = [OTFReadValueRecord(_buffer, _valueFormat, 0)];
        //                        ++_k;
        //                    }
        //                break;
        //                
        //                default:
        //                    __scribble_trace("\"GPOS\" lookup subtable format ", _posFormat, " not supported");
        //                break;
        //            }
        //            
        //            ++_j;
        //        }
        //        
        //        ++_i;
        //    }
        //}
        //
    }
    
    static __read_gsub = function()
    {
        //TODO
    }
    
    static __read_value_record = function(_offset, _format, _parentOffset)
    {
        var _record = {
            __x_placement               : undefined,
            __y_lacement                : undefined,
            __x_advance                 : undefined,
            __y_advance                 : undefined,
            __x_placement_device_offset : undefined,
            __y_placement_device_offset : undefined,
            __x_advance_device_offset   : undefined,
            __y_advance_device_offset   : undefined,
        };
        
        with(_record)
        {
            if (_format & 0x0001) __x_placement               = __read_s16();
            if (_format & 0x0002) __y_lacement                = __read_s16();
            if (_format & 0x0004) __x_advance                 = __read_s16();
            if (_format & 0x0008) __y_advance                 = __read_s16();
            if (_format & 0x0010) __x_placement_device_offset = __read_u16() + _parentOffset;
            if (_format & 0x0020) __y_placement_device_offset = __read_u16() + _parentOffset;
            if (_format & 0x0040) __x_advance_device_offset   = __read_u16() + _parentOffset;
            if (_format & 0x0080) __y_advance_device_offset   = __read_u16() + _parentOffset;
        }
        
        return _record;
    }
    
    static __read_u8 = function()
    {
        return buffer_read(__buffer, buffer_u8);
    }
    
    static __read_u16 = function()
    {
        var _a = buffer_read(__buffer, buffer_u8);
        var _b = buffer_read(__buffer, buffer_u8);
        return (_b | (_a << 8));
    }
    
    static __read_s16 = function()
    {
        var _a = buffer_read(__buffer, buffer_u8);
        var _b = buffer_read(__buffer, buffer_u8);
            
        buffer_poke(global.__scribble_otf_transfer_buffer, 0, buffer_u16, _b | (_a << 8));
        return buffer_peek(global.__scribble_otf_transfer_buffer, 0, buffer_s16); //TODO - Do this properly
    }
    
    static __read_u32 = function()
    {
        var _a = buffer_read(__buffer, buffer_u8);
        var _b = buffer_read(__buffer, buffer_u8);
        var _c = buffer_read(__buffer, buffer_u8);
        var _d = buffer_read(__buffer, buffer_u8);
        return (_d | (_c << 8) | (_b << 16) | (_a << 24));
    }
    
    static __read_fixed32 = function()
    {
        var _a = buffer_read(__buffer, buffer_u8);
        var _b = buffer_read(__buffer, buffer_u8);
        var _c = buffer_read(__buffer, buffer_u8);
        var _d = buffer_read(__buffer, buffer_u8);
        return (_d | (_c << 8) | (_b << 16) | (_a << 24));
    }
    
    static __read_u64 = function()
    {
        var _a = buffer_read(__buffer, buffer_u8);
        var _b = buffer_read(__buffer, buffer_u8);
        var _c = buffer_read(__buffer, buffer_u8);
        var _d = buffer_read(__buffer, buffer_u8);
        var _e = buffer_read(__buffer, buffer_u8);
        var _f = buffer_read(__buffer, buffer_u8);
        var _g = buffer_read(__buffer, buffer_u8);
        var _h = buffer_read(__buffer, buffer_u8);
        return (_h | (_g << 8) | (_f << 16) | (_e << 24) | (_d << 32) | (_c << 40) | (_b << 48) | (_a << 56));
    }
    
    static __read_tag = function()
    {
        var _a = chr(buffer_read(__buffer, buffer_u8));
        var _b = chr(buffer_read(__buffer, buffer_u8));
        var _c = chr(buffer_read(__buffer, buffer_u8));
        var _d = chr(buffer_read(__buffer, buffer_u8));
        return _a + _b + _c + _d;
    }
}