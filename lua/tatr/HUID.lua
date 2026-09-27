local HUID = {
    Patterns = {
        BasePattern = ((vim.lpeg.R('09')^8-vim.lpeg.R('09')^9)*vim.lpeg.P('-')*(vim.lpeg.R('09')^6-vim.lpeg.R('09')^7)),
        SuffixPattern = vim.lpeg.P('-') * ((vim.lpeg.P('-')+vim.lpeg.R('az', 'AZ', '09'))^0),
    },
}
HUID.Patterns.ExtendedPattern = HUID.Patterns.BasePattern * HUID.Patterns.SuffixPattern
--- Generates HUID based on current time and concatenates it with suffix
--- @param suffix? string suffix for HUID
--- @return string HUID
HUID.Generate = function(suffix)
    if suffix ~= nil then
        assert(HUID.Patterns.SuffixPattern:match(suffix) != nil, 'Invalid suffix provided to generator')
    end
    suffix = suffix or ''
    local base = os.date('!%Y%m%d-%H%M%S')
    local result = base .. suffix
    assert(HUID.IsValid(result))
    return result
end
--- Checks if huid is valid
--- @param huid string HUID to check
--- @return boolean validity Is HUID valid or not
HUID.IsValid = function(huid)
    if HUID.Patterns.BasePattern:match(huid) == nil then
        return false
    end
    if #huid == 15 then
        return true
    end
    if HUID.Patterns.SuffixPattern:match(huid, 16) == nil then
        return false
    end
    return true
end

_G.HUID = HUID

return HUID
