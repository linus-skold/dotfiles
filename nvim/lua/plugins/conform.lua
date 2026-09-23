-- conform.nvim replaces none-ls (nvimtools/none-ls.nvim) for formatting.
--
-- Formatters must be installed manually and available on PATH:
--   prettierd  → npm install -g @fsouza/prettierd
--   stylua     → cargo install stylua  (or download from GitHub releases)
--
-- NOTE on ESLint diagnostics/code-actions:
--   none-ls previously provided ESLint diagnostics and code actions.
--   conform.nvim handles formatting only — it does not provide diagnostics.
--   To restore ESLint diagnostics, enable the eslint LSP server by adding
--   "eslint" to the vim.lsp.enable({...}) call in lua/plugins/lsp.lua, then
--   install it with:  npm install -g vscode-langservers-extracted
--   Alternatively, ts_ls provides basic JS/TS linting without a separate server.

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>fF",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			desc = "Format current buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "prettierd" },
			javascriptreact = { "prettierd" },
			typescript = { "prettierd" },
			typescriptreact = { "prettierd" },
			css = { "prettierd" },
			scss = { "prettierd" },
			html = { "prettierd" },
			json = { "prettierd" },
			yaml = { "prettierd" },
			markdown = { "prettierd" },
		},
	},
}
