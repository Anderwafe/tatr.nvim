local HUID = {}
--- Generates HUID based on current time and concatenates it with suffix
--- @param suffix? string suffix for HUID
--- @return string HUID
HUID.Generate = function(suffix)
    if suffix ~= nil then
        assert(HUID.IsSuffixValid(suffix), 'Invalid suffix provided to generator')
    end
    suffix = suffix or ''
    local base = os.date('!%Y%m%d-%H%M%S')
    assert(HUID.IsBaseValid(base), 'HUID base generation fail: '..base)
    local result = base .. suffix
    assert(HUID.IsValid(result), 'HUID generation fail: '..result)
    return result
end
--- Checks if huid base is valid
--- @param base string HUID base to check
--- @return boolean validity Is HUID base valid or not
HUID.IsBaseValid = function(base)
    if #base ~= 15 then
        return false
    end
    if base:find('%D') ~= 9 then
        return false
    end
    if base:sub(9,9) ~= '-' then
        return false
    end
    if base:find('%D', 10) ~= nil then
        return false
    end
    return true
end
--- Checks if huid suffix is valid
--- @param suffix string HUID suffix to check
--- @return boolean validity Is HUID suffix valid or not
HUID.IsSuffixValid = function(suffix)
    if suffix:sub(1,1) ~= '-' then
        return false
    end
    if suffix:find('[^%w-]', 2) ~= nil then
        return false
    end
    return true
end
--- Checks if huid is valid
--- @param huid string HUID to check
--- @return boolean validity Is HUID valid or not
HUID.IsValid = function(huid)
    local result = HUID.IsBaseValid(huid:sub(1,15))
    if #huid > 15 then
        result = result and HUID.IsSuffixValid(huid:sub(16))
    end
    return result
end

_G.HUID = HUID

return HUID
