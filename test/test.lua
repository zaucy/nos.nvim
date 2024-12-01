local nos = require('nos')
nos.setup({ debug = true })
vim.keymap.set({ 'n', "v" }, 'gs', nos.opkeymapfunc, { expr = true })
vim.keymap.set({ 'n' }, 'gss', nos.bufkeymapfunc)
