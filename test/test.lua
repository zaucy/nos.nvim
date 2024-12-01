vim.keymap.set({ 'n', "v" }, 'gs', function()
	vim.opt.operatorfunc = 'v:lua.NosOperatorFunc'
	return 'g@'
end, { expr = true })
