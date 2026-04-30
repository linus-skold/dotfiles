vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.syntax = "on"
vim.opt.listchars = { space = ".", tab = ">-" }
vim.opt.list = true
vim.opt.exrc = true  -- load .nvim.lua from project root (secured by vim.secure)

require("user.lazy")
require("user.keymap")

vim.api.nvim_command("hi Normal guibg=NONE")
vim.api.nvim_command("hi NormalNC guibg=NONE")
vim.api.nvim_command("hi SignColumn guibg=NONE")

-- cd into directory when launched with `nvim path/to/folder`
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local arg = vim.fn.argv(0)
		if arg and arg ~= "" and vim.fn.isdirectory(arg) == 1 then
			vim.cmd.cd(arg)
		end
	end,
})

-- Disable mini.completion in Snacks.nvim prompts
vim.api.nvim_create_autocmd("FileType", {
	-- "snacks_files" and "snacks_pick" do not exist; the real filetypes are:
	--   snacks_picker_input  (the search/input line)
	--   snacks_picker_list   (the results list)
	pattern = { "snacks_picker_input", "snacks_picker_list", "prompt" },
	callback = function()
		vim.b.minicompletion_disable = true
	end,
})
