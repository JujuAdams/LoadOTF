#macro BUF_U8       buffer_read(_buffer, buffer_u8)
#macro BUF_U16      buffer_read_little(_buffer, buffer_u16)
#macro BUF_U32      buffer_read_little(_buffer, buffer_u32)
#macro BUF_U64      buffer_read_little(_buffer, buffer_u64)
#macro BUF_S16      buffer_read_little(_buffer, buffer_s16)
#macro BUF_FIXED32  buffer_read(_buffer, buffer_s32) //TODO
#macro BUF_TAG      buffer_read_tag(_buffer)

function LoadOTF(_filename)
{
    trace("Loading \"", _filename, "\"");
    var _buffer = buffer_load(_filename);
    trace("Size = 0x", ptr(buffer_get_size(_buffer)), " (d=", buffer_get_size(_buffer), ")");
    
    
    
    #region Header
    
    var _sfntVersion   = BUF_U32;
    var _numTables     = BUF_U16;
    var _searchRange   = BUF_U16;
    var _entrySelector = BUF_U16;
    var _rangeShift    = BUF_U16;
    
    if (_sfntVersion == 0x00010000)
    {
        trace("Valid table directory version found (TrueType outlines)");
    }
    else if (_sfntVersion == 0x4F5454AF)
    {
        trace("Valid table directory version found (contains CFF data)");
    }
    else
    {
        trace("Table directory version not recognised (", ptr(_sfntVersion), ")");
        buffer_delete(_buffer);
        return;
    }
    
    trace("Found ", _numTables, " tables");
    
    var _tableDictionary = {};
    var _tableOrderArray = [];
    
    repeat(_numTables)
    {
        var _tableTag = BUF_TAG;
        var _checksum = BUF_U32;
        var _offset   = BUF_U32;
        var _length   = BUF_U32;
        
        trace("\"", _tableTag, "\", offset = ", ptr(_offset), ", length = ", ptr(_length), " (end = ", ptr(_offset + _length), ")");
        
        var _data = {   
            tag    : _tableTag,
            offset : _offset,
            length : _length
        };
        
        _tableDictionary[$ _tableTag] = _data;
        array_push(_tableOrderArray, _data);
    }
    
    array_sort(_tableOrderArray, function(_a, _b)
    {
        return _a.offset - _b.offset;
    });
    
    #endregion
    
    
    
    #region head
    
    var _tableData = _tableDictionary[$ "head"];
    if (!is_struct(_tableData))
    {
        trace("\"head\" table not found");
        return;
    }
    else
    {
        trace("\"head\" table found, offset = 0x", ptr(_tableData.offset), ", length = ", ptr(_tableData.length));
        buffer_seek(_buffer, buffer_seek_start, _tableData.offset);
        
        var _majorVersion     = BUF_U16;
        var _minorVersion     = BUF_U16;
        var _fontRevision     = BUF_FIXED32;
        var _checksumAdj      = BUF_U32;
        var _magicNumber      = BUF_U32;
        var _flags            = BUF_U16;
        var _unitsPerEm       = BUF_U16;
        var _dateCreated      = BUF_U64;
        var _dataModified     = BUF_U64;
        var _xMin             = BUF_S16;
        var _yMin             = BUF_S16;
        var _xMax             = BUF_S16;
        var _yMax             = BUF_S16;
        var _macStyle         = BUF_U16;
        var _lowestRecPPM     = BUF_U16;
        var _directionHint    = BUF_S16;
        var _indexToLocFormat = BUF_U16; //Should be a signed integer, but we're taking a shortcut here
        var _glyphDataFormat  = BUF_U16;
        
        if (_magicNumber != 0x5F0F3CF5)
        {
            trace("\"head\" magic number is invalid (", ptr(_magicNumber), ")");
            return;
        }
        
        trace("Units per em = ", _unitsPerEm, ", indexToLocFormat = ", _indexToLocFormat);
    }
    
    #endregion
    
    
    
    
    #region cmap
    
    var _tableData = _tableDictionary[$ "cmap"];
    if (!is_struct(_tableData))
    {
        trace("\"cmap\" table not found");
        return;
    }
    else
    {
        trace("\"cmap\" table found, offset = 0x", ptr(_tableData.offset), ", length = ", ptr(_tableData.length));
        buffer_seek(_buffer, buffer_seek_start, _tableData.offset);
        
        var _version   = BUF_U16;
        var _numTables = BUF_U16;
        
        trace("cmap table is version ", _version);
        
        if (_version != 0)
        {
            trace("cmap version not recognised");
            return;
        }
        
        trace(_numTables, " cmap tables found");
        
        var _platformDictionary = {};
        repeat(_numTables)
        {
            var _platformID     = BUF_U16;
            var _encodingID     = BUF_U16;
            var _subtableOffset = BUF_U32;
            
            trace("platformID = ", _platformID, ", encodingID = ", _encodingID, ", subtableOffset = ", _subtableOffset);
            
            var _metadata = {
                platformID     : _platformID,
                encodingID     : _encodingID,
                subtableOffset : _subtableOffset
            };
            
            _platformDictionary[$ _platformID] = _metadata;
        }
        
        var _subtableMetadata = _platformDictionary[$ 0];
        if (_subtableMetadata == undefined)
        {
            trace("Unicode platform data not found");
            return;
        }
        
        var _subtableFormat = undefined;
        if (_subtableMetadata.encodingID == 3)
        {
            _subtableFormat = 4;
        }
        else
        {
            _subtableFormat = 12;
        }
        
        if (_subtableFormat == undefined)
        {
            trace("Unicode encoding ID not supported");
            return;
        }
        
        trace("Subtable format chosen as ", _subtableFormat);
        
        buffer_seek(_buffer, buffer_seek_start, _subtableMetadata.subtableOffset + _tableData.offset);
        
        if (_subtableFormat == 4)
        {
            var _format = BUF_U16;
            if (_format != 4)
            {
                trace("Was expecting format ID 4 but got ", _format);
                return;
            }
            
            var _length        = BUF_U16;
            var _language      = BUF_U16;
            var _segCountx2    = BUF_U16;
            var _searchRange   = BUF_U16;
            var _entrySelector = BUF_U16;
            var _rangeShift    = BUF_U16;
            
            var _segCount = _segCountx2 div 2;
            trace("Found ", _segCount, " segments");
            
            var _endCountArray      = array_create(_segCount);
            var _startCountArray    = array_create(_segCount);
            var _deltaArray         = array_create(_segCount);
            var _idRangeOffsetArray = array_create(_segCount);
            
            var _i = 0;
            repeat(_segCount)
            {
                _endCountArray[@ _i] = BUF_U16;
                ++_i;
            }
            
            var _padding = BUF_U16;
            if (_padding != 0)
            {
                trace("Padding interrupted by erroneous data");
                return;
            }
            
            var _i = 0;
            repeat(_segCount)
            {
                _startCountArray[@ _i] = BUF_U16;
                ++_i;
            }
            
            var _i = 0;
            repeat(_segCount)
            {
                _deltaArray[@ _i] = BUF_S16;
                ++_i;
            }
            
            var _idRangeTableOffset = buffer_tell(_buffer);
            
            var _i = 0;
            repeat(_segCount)
            {
                _idRangeOffsetArray[@ _i] = BUF_U16;
                ++_i;
            }
            
            var _idToUnicodeArray = [];
            
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
                        buffer_seek(_buffer, buffer_seek_start, _offset + _rangeOffset + 2*(_charCode - _start));
                        var _id = (BUF_U16 + _delta) % 0xFFFF;
                    }
                    
                    if (_id < array_length(_idToUnicodeArray))
                    {
                        if (_idToUnicodeArray[_id] != 0)
                        {
                            trace("Warning! ", _id, " overwritten. Old charcode = ", _idToUnicodeArray[_id], ", new = ", _charCode);
                        }
                    }
                    
                    _idToUnicodeArray[@ _id] = _charCode;
                    
                    ++_j;
                }
                
                ++_i;
            }
            
            trace("idToUnicodeArray = ", _idToUnicodeArray);
            
            //var _unicodeCoveredArray = array_create(array_length(_idToUnicodeArray));
            //array_copy(_unicodeCoveredArray, 0, _idToUnicodeArray, 0, array_length(_idToUnicodeArray));
            //array_sort(_unicodeCoveredArray, true);
            //trace("Unicode covered = ", _unicodeCoveredArray);
            //
            //var _i = 0;
            //repeat(array_length(_unicodeCoveredArray))
            //{
            //    trace(_unicodeCoveredArray[_i], " = \"", chr(_unicodeCoveredArray[_i]), "\"");
            //    ++_i;
            //}
        }
        else if (_subtableFormat == 12)
        {
            trace("Format 12 not currently supported");
        }
    }
    
    #endregion
    
    
    
    #region GPOS
    //
    //var _tableData = _tableDictionary[$ "GPOS"];
    //if (!is_struct(_tableData))
    //{
    //    trace("\"GPOS\" table not found");
    //    return;
    //}
    //else
    //{
    //    trace("\"GPOS\" table found, offset = 0x", ptr(_tableData.offset), ", length = ", ptr(_tableData.length));
    //    buffer_seek(_buffer, buffer_seek_start, _tableData.offset);
    //    
    //    var _majorVersion      = BUF_U16;
    //    var _minorVersion      = BUF_U16;
    //    var _scriptListOffset  = BUF_U16 + _tableData.offset;
    //    var _featureListOffset = BUF_U16 + _tableData.offset;
    //    var _lookupListOffset  = BUF_U16 + _tableData.offset;
    //    
    //    trace("\"GPOS\" table is version ", _majorVersion, ".", _minorVersion);
    //    
    //    if ((_majorVersion == 1) && (_minorVersion == 0))
    //    {
    //        var _featureVariationsOffset = undefined;
    //    }
    //    else if ((_majorVersion == 1) && (_minorVersion == 1))
    //    {
    //        var featureVariationsOffset = BUF_U32;
    //        trace("Warning! This \"GPOS\" table version has only partial support");
    //    }
    //    else
    //    {
    //        trace("\"GPOS\" table version not supported");
    //        return;
    //    }
    //    
    //    
    //    
    //    //buffer_seek(_buffer, buffer_seek_start, _scriptListOffset);
    //    //
    //    //var _languageCount = BUF_U16;
    //    //
    //    //trace("Found ", _languageCount, " languages");
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
    //    trace("Found ", _lookupCount, " lookup tables");
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
    //        trace("Reading lookup table ", _i);
    //        
    //        var _lookupOffset = _lookupOffsetArray[_i];
    //        buffer_seek(_buffer, buffer_seek_start, _lookupOffset);
    //        
    //        var _lookupType    = BUF_U16;
    //        var _lookupFlags   = BUF_U16;
    //        var _subtableCount = BUF_U16;
    //        trace("Found ", _subtableCount, " subtables");
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
    //        trace("type = ", _lookupType, ", flags = ", ptr(_lookupFlags), ", mark filtering set = ", _markFilteringSet);
    //        
    //        var _j = 0;
    //        repeat(_subtableCount)
    //        {
    //            var _subtableOffset = _subtableOffsetArray[@ _j];
    //            trace("Reading subtable ", _j, " (of lookup table ", _i, ")");
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
    //                    trace("\"GPOS\" lookup subtable format ", _posFormat, " not supported");
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
    #endregion
    
    
    
    #region GSUB
    
    var _tableData = _tableDictionary[$ "GSUB"];
    if (!is_struct(_tableData))
    {
        trace("\"GSUB\" table not found");
        return;
    }
    else
    {
        trace("\"GSUB\" table found, offset = 0x", ptr(_tableData.offset), ", length = ", ptr(_tableData.length));
        buffer_seek(_buffer, buffer_seek_start, _tableData.offset);
        
        var _majorVersion      = BUF_U16;
        var _minorVersion      = BUF_U16;
        var _scriptListOffset  = BUF_U16 + _tableData.offset;
        var _featureListOffset = BUF_U16 + _tableData.offset;
        var _lookupListOffset  = BUF_U16 + _tableData.offset;
        
        trace("\"GSUB\" table is version ", _majorVersion, ".", _minorVersion);
        
        if ((_majorVersion == 1) && (_minorVersion == 0))
        {
            var _featureVariationsOffset = undefined;
        }
        else if ((_majorVersion == 1) && (_minorVersion == 1))
        {
            var featureVariationsOffset = BUF_U32;
            trace("Warning! This \"GSUB\" table version has only partial support");
        }
        else
        {
            trace("\"GSUB\" table version not supported");
            return;
        }
        
        
        
        buffer_seek(_buffer, buffer_seek_start, _lookupListOffset);
        
        var _lookupCount = BUF_U16;
        trace("Found ", _lookupCount, " lookup tables");
        
        var _lookupOffsetArray = array_create(_lookupCount);
        var _i = 0;
        repeat(_lookupCount)
        {
            _lookupOffsetArray[@ _i] = BUF_U16 + _lookupListOffset;
            ++_i;
        }
        
        var _i = 0;
        repeat(_lookupCount)
        {
            trace("Reading lookup table ", _i);
            
            var _lookupOffset = _lookupOffsetArray[_i];
            buffer_seek(_buffer, buffer_seek_start, _lookupOffset);
            
            var _lookupType    = BUF_U16;
            var _lookupFlags   = BUF_U16;
            var _subtableCount = BUF_U16;
            trace("Found ", _subtableCount, " subtables");
            
            var _subtableOffsetArray = array_create(_subtableCount);
            var _j = 0;
            repeat(_subtableCount)
            {
                _subtableOffsetArray[@ _j] = BUF_U16 + _lookupOffset;
                ++_j;
            }
            
            var _markFilteringSet = BUF_U16;
            
            trace("type = ", _lookupType, ", flags = ", ptr(_lookupFlags), ", mark filtering set = ", _markFilteringSet);
            
            var _j = 0;
            repeat(_subtableCount)
            {
                var _subtableOffset = _subtableOffsetArray[@ _j];
                trace("Reading subtable ", _j, " (of lookup table ", _i, ")");
                
                var _posFormat = BUF_U16;
                switch(_posFormat)
                {
                    case 1:
                        var _coverageOffset   = BUF_U16 + _subtableOffset;
                        var _valueFormat      = BUF_U16;
                        var _valueRecordArray = [OTFReadValueRecord(_buffer, _valueFormat, 0)];
                    break;
                    
                    case 2:
                        var _coverageOffset = BUF_U16 + _subtableOffset;
                        var _valueFormat    = BUF_U16;
                        var _valueCount     = BUF_U16;
                        
                        var _valueRecordArray = array_create(_valueCount);
                        var _k = 0;
                        repeat(_valueCount)
                        {
                            _valueRecordArray[@ _k] = [OTFReadValueRecord(_buffer, _valueFormat, 0)];
                            ++_k;
                        }
                    break;
                    
                    default:
                        trace("\"GPOS\" lookup subtable format ", _posFormat, " not supported");
                    break;
                }
                
                ++_j;
            }
            
            ++_i;
        }
    }
    
    #endregion
    
    
    
    buffer_delete(_buffer);
}