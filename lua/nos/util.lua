local M = {}

local setcmdline_delayed = vim.schedule_wrap(function(cmdline, pos)
	vim.fn.setcmdline(cmdline, pos)
	M.refresh_cmdline()
end)

function M.refresh_cmdline()
	local backspace = vim.api.nvim_replace_termcodes("<bs>", true, false, true)
	-- Hack to trigger command preview again after new buffer contents have been computed
	vim.api.nvim_feedkeys("a" .. backspace, "n", false)
end

function M.start_cmdline_with_temp_cr(opts)
	local original_mapping = vim.fn.maparg('<CR>', 'c', false, true)
	local cleanup_group = vim.api.nvim_create_augroup('NOSTempCmdlineMapping', { clear = true })
	vim.api.nvim_create_autocmd('CmdlineLeave', {
		group = cleanup_group,
		callback = function()
			---@diagnostic disable-next-line: param-type-mismatch
			if not vim.tbl_isempty(original_mapping) then
				vim.keymap.set('c', '<CR>', original_mapping.rhs, {
					silent = original_mapping.silent == 1,
					expr = original_mapping.expr == 1,
					noremap = original_mapping.noremap == 1,
				})
			else
				vim.keymap.del('c', '<CR>')
			end
			vim.api.nvim_del_augroup_by_name('NOSTempCmdlineMapping')
			if opts.cleanup then
				return opts.cleanup()
			end
		end,
		once = true,
	})

	vim.keymap.set('c', '<CR>', function()
		if opts.cr_handler then
			return opts.cr_handler()
		end
		return '<CR>'
	end, { expr = true, replace_keycodes = true })

	vim.fn.feedkeys(":")

	setcmdline_delayed(opts.initial_cmdline, opts.initial_cmdline_pos)
end

return M
