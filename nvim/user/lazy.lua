-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		"nvim-lua/plenary.nvim",
		"editorconfig/editorconfig-vim",
		{ import = "plugins" },
	},
})

require("noice").setup({
	lsp = {
		-- Override markdown rendering so that other plugins use Treesitter.
		-- Note: cmp.entry.get_documentation is intentionally omitted —
		-- this config uses mini.completion, not nvim-cmp.
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
	},
	presets = {
		bottom_search = true, -- classic bottom cmdline for search
		command_palette = true, -- cmdline and popupmenu together
		long_message_to_split = true, -- long messages sent to a split
		inc_rename = false,
		lsp_doc_border = false,
	},
})

-- Defer worktree + telescope extension setup until after all plugins are loaded
--
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	once = true,
	callback = function()
		require("git-worktree").setup()
		require("telescope").load_extension("git_worktree")
	end,
})
