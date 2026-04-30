local reload_module = require("user.utils").reload_module

function remap(mode, keybinding, command, options)
	options = options or { noremap = true, silent = true }
	if type(command) == "string" then
		command = "<cmd>" .. command .. "<CR>"
	end
	vim.keymap.set(mode, keybinding, command, options)
end

function nremap(keybinding, command, options)
	remap("n", keybinding, command, options)
end

function imemap(keybinding, command, options)
	remap("i", keybinding, command, options)
end

function tremap(keybinding, command, options)
	remap("t", keybinding, command, options)
end

function vremap(keybinding, command, options)
	remap("v", keybinding, command, options)
end

-- -- Insert mode mapping
-- vim.api.nvim_set_keymap("i", "<C-v>", "<C-o>:<C-r>+", {})

-- -- Terminal mode mapping
-- vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-N>", {})

-- Normal mode mappings
nremap("<A-.>", "bnext", { desc = "Next buffer" })
nremap("<A-,>", "bprevious", { desc = "Previous buffer" })
nremap("<A-c>", "bd", { desc = "Close buffer" })
nremap("<leader>bC", "%bd|e#", { desc = "Close all buffers except current" })

nremap("<leader>e", function()
	vim.diagnostic.open_float(0, { scope = "line", focusable = false })
end, { desc = "Show line diagnostics" })

nremap("<leader>tb", function()
	local word = vim.fn.expand("<cword>")
	if word == "true" then
		vim.cmd("normal! ciwfalse")
	elseif word == "false" then
		vim.cmd("normal! ciwtrue")
	end
end, { desc = "Toggle true/false" })

-- Map reloading keymap
nremap("<leader>kR", function()
	reload_module("user.keymap")
	vim.schedule(function()
		vim.notify("keymap.lua reloaded")
	end)
end, { desc = "Reload keymap.lua" })

-- C/C++: switch between header and source file via clangd
nremap("<A-o>", function()
	local ext = vim.fn.expand("%:e")
	local cpp_exts = { c = true, cpp = true, cc = true, cxx = true, h = true, hpp = true, hxx = true }
	if not cpp_exts[ext] then return end

	-- Ask clangd for the counterpart file
	local params = { uri = vim.uri_from_bufnr(0) }
	vim.lsp.buf_request(0, "textDocument/switchSourceHeader", params, function(err, result)
		if err or not result or result == "" then
			vim.notify("clangd: no counterpart found", vim.log.levels.WARN)
			return
		end
		vim.cmd("edit " .. vim.uri_to_fname(result))
	end)
end, { desc = "C++: switch header/source" })

nremap("<leader>sr", "lua require('telescope').extensions.git_worktree.git_worktrees()", { noremap = true, silent = true, desc = "Git Worktrees" })
nremap("<leader>sR", "lua require('telescope').extensions.git_worktree.create_git_worktree()", { noremap = true, silent = true, desc = "Create Git Worktree" })
nremap("<leader>sC", "nohl", { noremap = true, silent = true, desc = "Clear Search Highlight" })

vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+yg_")
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>yy", "\"+yy")

vim.keymap.set("v", "<leader>p", "\"+p")
vim.keymap.set("v", "<leader>P", "\"+P")
vim.keymap.set("n", "<leader>p", "\"+p")
vim.keymap.set("n", "<leader>P", "\"+P")


