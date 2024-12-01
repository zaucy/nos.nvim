let root = [$env.FILE_PWD, '..'] | path join | path expand | str replace --all '\' '/';
let test_text = [$env.FILE_PWD, 'test.txt'] | path join;
let init_lua = ([$env.FILE_PWD, '../lua/nos/init.lua'] | path join | path relative-to $env.PWD) | str replace --all '\' '/';
let cmd = "+lua require('nos').setup({})";

(nvim
	([$env.FILE_PWD, 'test.txt'] | path join)
	--clean
	$"+lua package.path = package.path .. ';($root)/lua/?/init.lua;($root)/lua/?.lua'"
	$"+cd ($env.FILE_PWD)"
	"+lua require('test')"
);
