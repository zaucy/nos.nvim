# NOS (**N**ormal **O**n **S**earch)

Have you ever just wanted to run some normal commands on your search results? I bet you have and you've done something like this `g/wow/normal cwlookatme!`. It kinda worked, but you couldn't really preview what you were doing and it only worked on 1 match per line.


<img align="right" width="297" height="124" src="https://github.com/user-attachments/assets/b4998c0b-e060-433f-9a46-0810f67bd85d">

nos.nvim makes doing normal on searches a breeze by:
 * executes normal commands for multiple matches on the same line
 * showing you an incremental preview
 * easily allows you to use NOS as an operator

## Install

Use lazy plugin manager

```lua
{
	"zaucy/nos.nvim",
	lazy = false,
	opts = {},
	config = function()
		local nos = require('nos')
		nos.setup({})
		-- optionally set an operator keymap
		vim.keymap.set({ 'n', "v" }, 'gs', nos.opkeymapfunc, { expr = true })
		-- optionally set a whole buffer keymap
		vim.keymap.set({ 'n' }, 'gss', nos.bufkeymapfunc)
	end,
}
```
