---@class AskBackendConfig
---@field provider string   "copilot" | "ollama" | "llama.cpp"
---@field model    string   Model name (provider-specific)
---@field host     string?  Host for local backends (ollama / llama.cpp). Defaults to "127.0.0.1"
---@field port     integer? Port for local backends. Defaults to provider default (ollama: 11434, llama.cpp: 8080)

---@class AskConfig
---@field verbose boolean        Show timing and diagnostic output
---@field doc_dir string         Path to Neovim :help doc files for context pre-fetch
---@field backend AskBackendConfig

local M = {}

M.defaults = {
	verbose = false,
	doc_dir = vim.fn.fnamemodify(
		vim.api.nvim_get_runtime_file("doc/helphelp.txt", false)[1], ":h"
	),
	backend = {
		provider = "copilot",
		model    = "claude-haiku-4.5",
	},
}

M.options = vim.tbl_deep_extend("force", {}, M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
