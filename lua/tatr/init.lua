local M = {}

local getHUID = function() return require'tatr/HUID' end

-- ---@param opts? tatr.Config
M.setup = function (opts)
    -- require("tatr.config").setup(opts)
    vim.api.nvim_create_user_command('Tatr', 
    function(cmdopts)
        local wsp = M.find_workspace()
        -- vim.print(cmdopts)
        if wsp == nil then
            local msg = 'Cannot find tatr tasks folder in all of the parents directory. You should create one (for example with tatr tool: "tatr init")'
            vim.notify(msg, vim.log.levels.ERROR)
            -- error(msg, vim.log.levels.ERROR)
            return
        end
        if #cmdopts.fargs < 1 then
            local msg = 'Tatr expects at least one subcommand.\nSupported subcommands:\n\tinsert\t--- inserts specified task info into current line'
            vim.notify(msg, vim.log.levels.ERROR)
            -- error(msg, vim.log.levels.ERROR)
            return
        end
        if cmdopts.fargs[1] == 'insert' then
            if #cmdopts.fargs ~= 2 then
                local msg = 'Tatr insert expects task id as an argument'
                vim.notify(msg, vim.log.levels.ERROR)
                -- error(msg, vim.log.levels.ERROR)
                return
            end
            if not getHUID().IsValid(cmdopts.fargs[2]) then
                local msg = 'Tatr task id format is incorrect! expected: [0-9]{8}-[0-9]{6}(-[a-zA-Z0-9\\-]*)?'
                vim.notify(msg, vim.log.levels.ERROR)
                -- error(msg, vim.log.levels.ERROR)
                return
            end

            local taskLocation = M.find_task_by_id(cmdopts.fargs[2])
            local taskInfo = io.open(taskLocation.task, 'r'):read()
            taskInfo = taskInfo or '# ERROR: CHECK TASK FILE FOR ERRORS'
            local linenum = vim.api.nvim_win_get_cursor(0)[1]
            local textToInsert = vim.bo.commentstring:gsub('%%s', 'TASK(' .. cmdopts.fargs[2] .. '): ' .. taskInfo:sub(taskInfo:find(' ')+1))
            vim.api.nvim_buf_set_lines(0, linenum-1, linenum-1, false, {textToInsert})
            return
        elseif cmdopts.fargs[1] == 'new' then
            local taskTitle = vim.iter(cmdopts.fargs):skip(1):join(' ')
            if taskTitle == '' then taskTitle = 'New task' end
            
            local taskID = getHUID().Generate()
            local taskCollision = M.find_task_by_id(taskID)
            if taskCollision ~= nil then
                vim.uv.sleep(1000)
                taskID = getHUID().Generate()
                taskCollision = M.find_task_by_id(taskID)
                if taskCollision ~= nil then
                    local msg = 'New task id ('..taskID..') colliding with existed task. Check your time settings or you trying to create tasks too fast.'
                    vim.notify(msg, vim.log.levels.ERROR)
                    return
                end
            end
            local taskData = '# '..taskTitle..'\n\n'
            taskData = taskData..'- STATUS: OPEN\n'
            taskData = taskData..'- PRIORITY: 100\n'
            taskData = taskData..'- TAGS:\n\n'
            local taskPath = vim.fs.joinpath(wsp, taskID)
            local resultBuf = vim.uv.fs_mkdir(taskPath, tonumber('755', 8))
            if resultBuf ~= true then
                local msg = 'Failed to create task directory: '..vim.inspect(resultBuf)
                vim.notify(msg, vim.log.levels.ERROR)
                return
            end
            if vim.fn.writefile(taskData, vim.fs.joinpath(taskPath, 'TASK.md'), 's') ~= 0 then
                local msg = 'Failed to create task file'
                vim.notify(msg, vim.log.levels.ERROR)
                return
            end
            local msg = 'Created task with ID '..taskID
            vim.notify(msg, vim.log.levels.INFO)
        else
            local msg = 'Unknown subcommand specified'
            vim.notify(msg, vim.log.levels.ERROR)
            -- error(msg, vim.log.levels.ERROR)
            return
        end
    end, { nargs = '*',
    complete = function(ArgLead, CmdLine, CursorPos)
        local wsp = M.find_workspace()
        if wsp == nil then
            local msg = 'Cannot find tatr tasks folder in all of the parents directory. You should create one (for example with tatr tool: "tatr init")'
            vim.notify(msg, vim.log.levels.ERROR)
            return
        end
        
        local subcommands = {'insert', 'new'}

        if CmdLine:match('Tatr $') then
            return subcommands
        end
        if CmdLine:match('Tatr %l+$') then
            return vim.iter(subcommands):map(function(subcmd) if subcmd:sub(1, ArgLead:len()):match(ArgLead) then return subcmd end end):totable()
        end

        local tasksIter = vim.iter(vim.fs.dir(wsp)):map(function(name, type) if type == 'directory' then return name end end)
        if CmdLine:match('Tatr insert $') then
            return tasksIter:totable()
        end
        if CmdLine:match('Tatr insert [%w-]+$') then
            return tasksIter:map(function(taskName) if taskName:sub(1, ArgLead:len()):match(ArgLead) then return taskName end end):totable()
        end

        return {}
    end,
})
end

--- Checks if the current buffer is in a tasks workspace
--- Returns the workspace root if found
---@param buf? integer
M.find_workspace = function (buf)
    -- local directory = vim.api.nvim_buf_get_name(buf or 0)
    -- local Workspace = require("lazydev.workspace")
    -- local ws = Workspace.find({ path = fname })
    local root = vim.fs.find('tasks', { type = 'directory', upward = true })

    if root ~= {} then
        return root[1]
    else
        return nil
    end
end

--- A non-recursive task finder function
-- 
M.find_task_by_id = function(id)
    local tws = M.find_workspace()
    if tws == nil then
        local msg = 'Cannot find tatr tasks folder in all of the parents directory. You should create one (for example with tatr tool: "tatr init")'
        vim.notify(msg, vim.log.levels.ERROR)
        -- error(msg, vim.log.levels.ERROR)
        return nil
    end
    if not getHUID().IsValid(id) then
        local msg = 'Tatr task id format is incorrect! expected: [0-9]{8}-[0-9]{6}(-[a-zA-Z0-9\\-]*)?'
        vim.notify(msg, vim.log.levels.ERROR)
        -- error(msg, vim.log.levels.ERROR)
        return nil
    end
    local task_fld = vim.fs.joinpath(tws, id)
    local task_fld_stat = vim.uv.fs_stat(task_fld)
    if not task_fld_stat or bit.band(task_fld_stat.mode, 61440) ~= 16384 then
        local msg = 'Task is not found in tasks folder'
        vim.notify(msg, vim.log.levels.ERROR)
        -- error(msg, vim.log.levels.ERROR)
        return nil
    end
    local task_md = vim.fs.joinpath(task_fld, 'TASK.md')
    local task_md_stat = vim.uv.fs_stat(task_md)
    if not task_md_stat or bit.band(task_md_stat.mode, 61440) ~= 32768 then
        local msg = 'Task is not found in tasks folder'
        vim.notify(msg, vim.log.levels.ERROR)
        -- error(msg, vim.log.levels.ERROR)
        return nil
    end
    return { folder = task_fld, task = task_md }
end

return M

