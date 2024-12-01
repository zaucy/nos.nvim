let root = [$env.FILE_PWD, '..'] | path join | path expand;
let test_text = [$env.FILE_PWD, 'test.txt'] | path join;
let init_lua = ([$env.FILE_PWD, '../lua/nos/init.lua'] | path join | path relative-to $env.PWD) | str replace --all '\' '/';
let cmd = "+lua require('nos').setup({})";

print $init_lua;
print $cmd;

(nvim
	([$env.FILE_PWD, 'test.txt'] | path join)
	--clean
	$"+cd ($root)/lua/nos"
	"+lua require('init').setup({})"
	$"+cd ($env.FILE_PWD)"
	"+lua require('test')"
);
