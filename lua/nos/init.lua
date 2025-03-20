local util = require('nos.util')

local M = {}

local function parse_pattern(pat_str)
	return pat_str or ""
end

local function parse_normal(norm_str)
	return norm_str or ""
end

local function parse_flags(flags_str)
	return flags_str
end

local function parse_cmd_str(cmd)
	if #cmd == 0 then return "", "", nil end
	local sep = cmd:sub(1, 1)
	local parts = vim.split(cmd:sub(2), sep, { plain = true })
	return parse_pattern(parts[1]), parse_normal(parts[2]), parse_flags(parts[3])
end

local nos_preview_flags = {
	["$"] = function()
		vim.api.nvim_win_set_cursor(0, { vim.fn.line('$'), 0 })
	end,
	["0"] = function()
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	end,
	["w"] = function(data, next, cursors)
		vim.api.nvim_win_set_cursor(0, { vim.fn.line('w' .. next()), 0 })
	end,
	["'"] = function(data, next, cursors)
		vim.api.nvim_win_set_cursor(0, { vim.fn.line("'" .. next()), 0 })
	end,
	["n"] = function(data, next, cursors)
		data.last_focused_cursor_index = data.last_focused_cursor_index + 1
	end,
	["N"] = function(data, next, cursors)
		data.last_focused_cursor_index = data.last_focused_cursor_index - 1
	end,
}

local function nos_command(ns, opts, cmd_opts)
	local line1 = cmd_opts.line1
	local line2 = cmd_opts.line2
	local buf = vim.api.nvim_get_current_buf()

	local pat, norm, flags = parse_cmd_str(cmd_opts.args)

	local cursors = {}

	local cursor_hl = vim.api.nvim_get_hl_id_by_name("Cursor")
	local search_hl = vim.api.nvim_get_hl_id_by_name("Search")
	local unfocused_cursor_hl = vim.api.nvim_get_hl_id_by_name("IncSearch")
	local focused_cursor_hl = vim.api.nvim_get_hl_id_by_name("CurSearch")
	local focused_cursor_line_hl = vim.api.nvim_get_hl_id_by_name("CursorLine")
	local visual_hl = vim.api.nvim_get_hl_id_by_name("Visual")

	if #pat > 0 then
		while line1 ~= line2 + 1 do
			local line_iteration_count = 0
			local last_idx = 1
			while line_iteration_count < opts.max_line_matches do
				local line = vim.api.nvim_buf_get_lines(buf, line1 - 1, line1, false)[1]
				local start_idx, end_idx = string.find(line, pat, last_idx + 1)
				if not start_idx or not end_idx then break end
				if #norm == 0 then
					vim.api.nvim_buf_set_extmark(buf, ns, line1 - 1, start_idx, {
						hl_group = search_hl,
						end_row = line1 - 1,
						end_col = end_idx,
						priority = 48,
					})
				end

				local cursor_id = vim.api.nvim_buf_set_extmark(buf, ns, line1 - 1, start_idx - 1, {
					hl_group = cursor_hl,
					end_row = line1 - 1,
					end_col = start_idx,
					priority = 20000,
				})

				table.insert(cursors, cursor_id)
				last_idx = end_idx + 1
				line_iteration_count = line_iteration_count + 1
			end

			line1 = line1 + 1
		end

		if #norm > 0 then
			for _, cursor_id in ipairs(cursors) do
				local cursor = vim.api.nvim_buf_get_extmark_by_id(buf, ns, cursor_id, {})
				vim.api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] })
				vim.cmd.normal(norm)
				cursor = vim.api.nvim_win_get_cursor(0)
				vim.api.nvim_buf_set_extmark(buf, ns, cursor[1] - 1, cursor[2], {
					id = cursor_id,
					hl_group = cursor_hl,
					end_row = cursor[1] - 1,
					end_col = cursor[2] + 1,
					priority = 49,
				})
			end
		end
	else
		vim.api.nvim_buf_set_extmark(buf, ns, line1 - 1, 0, {
			hl_group = visual_hl,
			hl_eol = true,
			end_row = line2,
			end_col = 0,
		})
	end

	local flag_data = {
		last_focused_cursor_index = 0,
	}

	if flags then
		for i = 1, #flags do
			local flag = flags:sub(i, i)
			local flag_fn = nos_preview_flags[flag]
			local function next()
				i = i + 1
				return flags:sub(i, i)
			end
			if flag_fn then
				flag_fn(flag_data, next, cursors)
			end
		end

		for _, cursor_id in ipairs(cursors) do
			local cursor = vim.api.nvim_buf_get_extmark_by_id(buf, ns, cursor_id, {})
			vim.api.nvim_buf_set_extmark(buf, ns, cursor[1], cursor[2], {
				hl_group = unfocused_cursor_hl,
				end_row = cursor[1],
				end_col = cursor[2] + 1,
				priority = 20001,
			})
		end

		local focused_cursor_id = cursors[(flag_data.last_focused_cursor_index % #cursors) + 1]
		if focused_cursor_id then
			local cursor = vim.api.nvim_buf_get_extmark_by_id(buf, ns, focused_cursor_id, {})
			vim.api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] })
			vim.api.nvim_buf_set_extmark(buf, ns, cursor[1], cursor[2], {
				hl_group = focused_cursor_hl,
				end_row = cursor[1],
				end_col = cursor[2] + 1,
				priority = 20002,
			})
			vim.api.nvim_buf_set_extmark(buf, ns, cursor[1], 0, {
				hl_group = focused_cursor_line_hl,
				end_row = cursor[1],
				end_col = string.len(vim.api.nvim_buf_get_lines(buf, cursor[1], cursor[1] + 1, false)[1]),
				hl_eol = true,
				priority = 39,
			})
		end
	else
		for _, cursor_id in ipairs(cursors) do
			local cursor = vim.api.nvim_buf_get_extmark_by_id(buf, ns, cursor_id, {})
			vim.api.nvim_buf_set_extmark(buf, ns, cursor[1], cursor[2], {
				hl_group = cursor_hl,
				end_row = cursor[1],
				end_col = cursor[2] + 1,
				priority = 49,
			})
		end
	end

	return cursors
end

local function preview_diff(before_lines, after_lines, opts, cmd_opts, preview_ns, preview_buf)
	local diff_hl = vim.api.nvim_get_hl_id_by_name("DiffAdd")

	for line_index = 1, math.max(#before_lines, #after_lines) do
		local row = cmd_opts.line1 + line_index - 1
		local before_line = before_lines[line_index] or ""
		local after_line = after_lines[line_index] or ""

		local diff_matrix = {}
		local before_len = #before_line
		local after_len = #after_line

		-- Initialize the matrix
		for i = 0, before_len do
			diff_matrix[i] = {}
			for j = 0, after_len do
				diff_matrix[i][j] = 0
			end
		end

		-- Compute longest common subsequence
		for i = 1, before_len do
			for j = 1, after_len do
				if before_line:sub(i, i) == after_line:sub(j, j) then
					diff_matrix[i][j] = diff_matrix[i - 1][j - 1] + 1
				else
					diff_matrix[i][j] = math.max(
						diff_matrix[i - 1][j] or 0,
						diff_matrix[i][j - 1] or 0
					)
				end
			end
		end

		-- Backtrack to find differences
		local highlights = {}
		local i, j = before_len, after_len
		local current_highlight = nil

		while i > 0 and j > 0 do
			if before_line:sub(i, i) == after_line:sub(j, j) then
				-- Reset current highlight if we had one
				if current_highlight then
					table.insert(highlights, current_highlight)
					current_highlight = nil
				end
				i = i - 1
				j = j - 1
			else
				-- Check which direction to move
				if (diff_matrix[i - 1] and diff_matrix[i - 1][j] or 0) > (diff_matrix[i][j - 1] or 0) then
					-- Deletion in before_line
					i = i - 1
				else
					-- Addition in after_line
					if not current_highlight then
						current_highlight = { end_col = j - 1 }
					end
					current_highlight.start = j - 1
					j = j - 1
				end
			end
		end

		-- Handle any remaining highlight
		if current_highlight then
			table.insert(highlights, current_highlight)
		end

		for _, hl in ipairs(highlights) do
			vim.api.nvim_buf_set_extmark(0, preview_ns, row - 1, hl.start, {
				hl_group = diff_hl,
				end_row = row - 1,
				end_col = hl.end_col + 1,
				priority = 40,
			})
		end
	end
end

function M.setup(opts)
	opts = vim.tbl_extend('keep', opts, {
		max_line_matches = 32,
	})
	vim.api.nvim_create_user_command("NOS", function(cmd_opts)
		local ns = vim.api.nvim_create_namespace("NOS")
		pcall(nos_command, ns, opts, cmd_opts)
		vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	end, {
		nargs = "*",
		range = true,
		preview = function(cmd_opts, preview_ns, preview_buf)
			local before_lines = vim.api.nvim_buf_get_lines(0, cmd_opts.line1 - 1, cmd_opts.line2, false)
			local success, error_or_cursors = pcall(nos_command, preview_ns, opts, cmd_opts)
			if not success then
				---@type string
				---@diagnostic disable-next-line: assign-type-mismatch
				local error_message = error_or_cursors
				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Preview Function Failed", error_message })
				return 2
			end

			local after_lines = vim.api.nvim_buf_get_lines(0, cmd_opts.line1 - 1, cmd_opts.line2, false)
			pcall(preview_diff, before_lines, after_lines, opts, cmd_opts, preview_ns, preview_buf)
			return 2
		end,
	})

	function _G.NosOperatorFunc(motion_type)
		return M._operatorfunc(motion_type)
	end
end

local function nos_cmdline(range)
	util.start_cmdline_with_temp_cr({
		initial_cmdline = range .. "NOS/",
		initial_cmdline_pos = 10,
		cr_handler = function()
			local cmdline = vim.fn.getcmdline()
			local _, cmd_end_idx = cmdline:find("NOS", 1, true)
			local nos_cmd = cmdline:sub(cmd_end_idx + 1)
			local sep = nos_cmd:sub(1, 1)
			if sep == nil then return "<cr>" end
			local parts = vim.split(nos_cmd, sep, { plain = true })
			if #parts < 4 then
				cmdline = cmdline .. sep
				vim.fn.setcmdline(cmdline, #cmdline + 1)
				util.refresh_cmdline()
				return ""
			end
			return "<cr>"
		end,
	})
end

function M._operatorfunc(_)
	vim.cmd("normal! `[v`]")
	nos_cmdline("'<,'>")
end

function M.opkeymapfunc()
	vim.opt.operatorfunc = 'v:lua.NosOperatorFunc'
	return 'g@'
end

function M.bufkeymapfunc()
	nos_cmdline("%")
end

return M
