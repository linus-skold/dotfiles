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

			-- ── Shared capabilities ───────────────────────────────────────────────
			-- Plain client capabilities are correct for mini.completion. Check this
			-- again if you change the completion plugin.
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			vim.lsp.config("*", {
				capabilities = capabilities,
			})

			-- ── npm-installed servers on Windows ──────────────────────────────────
			-- npm installs these as .cmd shims. libuv cannot spawn a .cmd by its bare
			-- name (ENOENT), so name the shim explicitly.
			local function npm_cmd(name, ...)
				if vim.fn.has("win32") == 1 then
					name = name .. ".cmd"
				end
				return { name, ... }
			end

			vim.lsp.config("cssls", { cmd = npm_cmd("vscode-css-language-server", "--stdio") })

			-- ── ts_ls ─────────────────────────────────────────────────────────────
			-- Restrict to JS/TS only — do NOT attach to cshtml/razor/html.
			vim.lsp.config("ts_ls", {
				cmd = npm_cmd("typescript-language-server", "--stdio"),
				-- Projects use their own node_modules/typescript. Outside a project, fall
				-- back to the global (mise) install, which the server cannot find itself.
				init_options = (function()
					local tsc = vim.fn.exepath("tsc")
					if tsc == "" then
						return nil
					end
					local lib = vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(tsc)), "typescript", "lib")
					return { tsserver = { fallbackPath = lib } }
				end)(),
				filetypes = {
					"javascript", "javascriptreact",
					"javascript.jsx", "typescript",
					"typescriptreact", "typescript.tsx",
				},
			})

			-- ── html ──────────────────────────────────────────────────────────────
			vim.lsp.config("html", {
				cmd = npm_cmd("vscode-html-language-server", "--stdio"),
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
				cmd = npm_cmd("prisma-language-server", "--stdio"),
				filetypes = { "prisma" },
				root_markers = { "schema.prisma", "package.json", ".git" },
				settings = {
					prisma = { prismaFmtBinPath = "" },
				},
			})

			-- ── yamlls ────────────────────────────────────────────────────────────
			-- Schemas from schemastore.org match on file name (GitHub workflows,
			-- docker-compose, etc.).
			vim.lsp.config("yamlls", {
				cmd = npm_cmd("yaml-language-server", "--stdio"),
				settings = {
					yaml = {
						schemaStore = { enable = true },
						keyOrdering = false,
					},
				},
			})

			-- ── basedpyright + ruff (Python) ──────────────────────────────────────
			-- basedpyright does types and hover; ruff does lint and quick fixes.
			vim.lsp.config("basedpyright", {
				cmd = npm_cmd("basedpyright-langserver", "--stdio"),
			})
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local client = vim.lsp.get_client_by_id(ev.data.client_id)
					if client and client.name == "ruff" then
						client.server_capabilities.hoverProvider = false -- basedpyright owns hover
					end
				end,
			})

			-- ── enabled servers ───────────────────────────────────────────────────
			-- C# is handled by roslyn.nvim (see plugins/roslyn.lua), not listed here.
			--
			-- Install (all must be on PATH; mise tools live in ~/.config/mise/config.toml):
			--   ts_ls         mise use -g npm:typescript-language-server npm:typescript@6
			--                 (TypeScript 7 is the native port and has no tsserver)
			--   rust_analyzer rustup component add rust-analyzer
			--   lua_ls        mise use -g lua-language-server
			--   html / cssls  mise use -g npm:vscode-langservers-extracted
			--   clangd        mise use -g github:clangd/clangd
			--   gopls         mise use -g go go:golang.org/x/tools/gopls
			--   prismals      npm install -g @prisma/language-server
			--   yamlls        mise use -g npm:yaml-language-server
			--   taplo         mise use -g taplo
			--   basedpyright  mise use -g npm:basedpyright
			--   ruff          mise use -g ruff
			local configured_servers = {
				"ts_ls", "rust_analyzer", "lua_ls",
				"html", "cssls",
				"clangd",
				"gopls",
				"prismals",
				"yamlls",
				"taplo",
				"basedpyright", "ruff",
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
