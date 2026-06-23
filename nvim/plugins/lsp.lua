return {
	{
		"neovim/nvim-lspconfig",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{ "gh", vim.lsp.buf.hover,          desc = "LSP Hover" },
			{ "gd", vim.lsp.buf.definition,      desc = "LSP Go to Definition" },
			{ "gD", vim.lsp.buf.type_definition, desc = "LSP Go to Type Definition" },
			{ "gi", vim.lsp.buf.implementation,  desc = "LSP Go to Implementation" },
			-- gR = find references;  gr = rename
			{ "gR", vim.lsp.buf.references,      desc = "LSP Find References" },
			{ "gr", vim.lsp.buf.rename,          desc = "LSP Rename" },
			{ "ga", vim.lsp.buf.code_action,     desc = "LSP Code Action" },
		},
		config = function()
			-- ── Prisma filetype detection ─────────────────────────────────────────
			-- Must run before any .prisma buffer is opened so the server can attach.
			vim.filetype.add({ extension = { prisma = "prisma" } })

			-- ── Shared capabilities / on_attach ───────────────────────────────────
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local function on_attach(client, bufnr) end

			vim.lsp.config("*", {
				capabilities = capabilities,
				on_attach = on_attach,
			})

			-- ── ts_ls ─────────────────────────────────────────────────────────────
			-- Restrict to JS/TS only — do NOT attach to cshtml/razor/html.
			vim.lsp.config("ts_ls", {
				filetypes = {
					"javascript", "javascriptreact",
					"javascript.jsx", "typescript",
					"typescriptreact", "typescript.tsx",
				},
			})

			-- ── html ──────────────────────────────────────────────────────────────
			vim.lsp.config("html", {
				filetypes = { "html" },
			})

			-- ── clangd ────────────────────────────────────────────────────────────
			vim.lsp.config("clangd", {
				cmd = {
					"clangd",
					"--background-index",
					"--clang-tidy",
					"--header-insertion=iwyu",
					"--completion-style=detailed",
				},
				filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
			})

			-- ── gopls ─────────────────────────────────────────────────────────────
			vim.lsp.config("gopls", {
				filetypes = { "go", "gomod", "gosum", "gowork", "mod", "sum" },
			})

			-- ── prismals ──────────────────────────────────────────────────────────
			-- Install: npm install -g @prisma/language-server
			vim.lsp.config("prismals", {
				cmd = { "prisma-language-server", "--stdio" },
				filetypes = { "prisma" },
				root_markers = { "schema.prisma", "package.json", ".git" },
				settings = {
					prisma = { prismaFmtBinPath = "" },
				},
			})

			-- ── enabled servers ───────────────────────────────────────────────────
			-- C# is handled by roslyn.nvim (see plugins/roslyn.lua), not listed here.
			--
			-- Install instructions (all must be on PATH):
			--   ts_ls         npm install -g typescript-language-server typescript
			--   rust_analyzer rustup component add rust-analyzer
			--   lua_ls        https://github.com/LuaLS/lua-language-server/releases
			--   html / cssls  npm install -g vscode-langservers-extracted
			--   clangd        winget install LLVM.LLVM
			--   gopls         go install golang.org/x/tools/gopls@latest
			--   prismals      npm install -g @prisma/language-server
			local configured_servers = {
				"ts_ls", "rust_analyzer", "lua_ls",
				"html", "cssls",
				"clangd",
				"gopls",
				"prismals",
			}
			vim.lsp.enable(configured_servers)

			-- ── LSP info command ──────────────────────────────────────────────────
			local lsp_info = require("user.lsp_info")
			lsp_info.set_configured_servers(configured_servers)
			vim.api.nvim_create_user_command("LspInfo", function()
				lsp_info.show()
			end, { desc = "Show LSP server status" })
		end,
	},
}
