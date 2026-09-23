-- Treesitter parsers, highlight and indent (nvim-treesitter `main` branch).
--
-- The main branch builds parsers locally. It needs on PATH:
--   tree-sitter CLI >= 0.26.1  (scoop install tree-sitter, not npm)
--   a C compiler               (zig, gcc or clang)
local languages = {
	"bash", "c", "c_sharp", "cpp", "css", "go", "gomod", "gosum", "gowork",
	"html", "javascript", "json", "lua", "markdown", "markdown_inline",
	"nu", "prisma", "query", "rust", "scss", "toml", "tsx", "typescript",
	"vim", "vimdoc", "yaml",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false, -- the main branch does not support lazy loading
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")
		local missing = vim.tbl_filter(function(lang)
			return not vim.tbl_contains(ts.get_installed(), lang)
		end, languages)
		if #missing > 0 then
			if vim.fn.executable("tree-sitter") == 1 then
				ts.install(missing)
			else
				vim.notify("tree-sitter CLI not found: cannot install " .. #missing .. " treesitter parsers", vim.log.levels.WARN)
			end
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
			callback = function(ev)
				-- start() fails when no parser exists for the filetype
				if pcall(vim.treesitter.start, ev.buf) then
					vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
