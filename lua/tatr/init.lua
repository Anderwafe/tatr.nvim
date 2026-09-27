require'tatr/HUID'

local M = {}

-- ---@param opts? lazydev.Config
M.setup = function (opts)
    -- require("tatr.config").setup(opts)
    vim.api.nvim_create_user_command('Tatr', 
    function(cmdopts)
        local wsp = M.find_workspace()
        vim.print(cmdopts)
        if wsp == nil then
            local msg = 'Cannot find tatr tasks folder in all of the parents directory. You should create one (for example with tatr tool: "tatr init")'
            vim.notify(msg, vim.log.levels.ERROR)
            error(msg, vim.log.levels.ERROR)
            return
        end
        if #cmdopts.fargs < 1 then
            local msg = 'Tatr expects at least one subcommand.\nSupported subcommands:\n\tinsert\t--- inserts specified task info into current line'
            vim.notify(msg, vim.log.levels.ERROR)
            error(msg, vim.log.levels.ERROR)
            return
        end
        if cmdopts.fargs[1] == 'insert' then
            if #cmdopts.fargs != 2 then
                local msg = 'Tatr insert expects task id as an argument'
                vim.notify(msg, vim.log.levels.ERROR)
                error(msg, vim.log.levels.ERROR)
                return
            end
            if not HUID.IsValid(cmdopts.fargs[2]) then
                local msg = 'Tatr task id format is incorrect! expected: [0-9]{8}-[0-9]{6}(-[a-zA-Z0-9\\-]*)?'
                vim.notify(msg, vim.log.levels.ERROR)
                error(msg, vim.log.levels.ERROR)
                return
            end
            local msg = 'Tatr task id format is correct!'
            vim.notify(msg, vim.log.levels.INFO)
            return
        else
            local msg = 'Unknown command specified'
            vim.notify(msg, vim.log.levels.ERROR)
            error(msg, vim.log.levels.ERROR)
            return
        end
    end, { nargs = '*' })
end

--- Checks if the current buffer is in a tasks workspace
--- Returns the workspace root if found
---@param buf? integer
M.find_workspace = function (buf)
    -- local directory = vim.api.nvim_buf_get_name(buf or 0)
    -- local Workspace = require("lazydev.workspace")
    -- local ws = Workspace.find({ path = fname })
    root = vim.fs.find('tasks', { type = 'directory', upward = true })

    if root != {} then
        return root
    else
        return nil
    end
end

return M

