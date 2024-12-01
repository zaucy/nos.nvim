local nos = require('nos')
nos.setup({ debug = true })
vim.keymap.set({ 'n', "v" }, 'gs', nos.keymapfunc, { expr = true })
