return {
	{
		"neovim/nvim-lspconfig",
		lazy = true,
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{ "gh", vim.lsp.buf.hover,        desc = "LSP Hover Documentation" },
			{ "gd", vim.lsp.buf.definition,    desc = "LSP Go to Definition" },
			{ "gr", vim.lsp.buf.rename,        desc = "LSP Rename" },
			{ "ga", vim.lsp.buf.code_action,   desc = "LSP Code Action" },
		},
		config = function()
			-- Build shared LSP capabilities
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- Shared on_attach: runs for every server that attaches to a buffer
			local function on_attach(client, bufnr)
				-- Uncomment to disable semantic tokens per-server if you prefer treesitter colours:
				-- client.server_capabilities.semanticTokensProvider = nil
			end

			-- Global defaults applied to every enabled server
			vim.lsp.config("*", {
				capabilities = capabilities,
				on_attach = on_attach,
			})

			-- ts_ls: restrict to JS/TS only -- do NOT attach to cshtml/razor/html
			vim.lsp.config("ts_ls", {
				filetypes = {
					"javascript", "javascriptreact",
					"javascript.jsx", "typescript",
					"typescriptreact", "typescript.tsx",
				},
			})

			-- html: restrict to plain HTML, not cshtml/razor
			vim.lsp.config("html", {
				filetypes = { "html" },
			})

			-- clangd: C/C++/ObjC language server
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

			-- omnisharp: handles C#, .NET Framework 4.8, and Razor/cshtml files
			-- NOTE: csharp_ls has poor support for .NET Framework 4.8 legacy projects.
			-- If you primarily work with .NET Framework / Razor / cshtml, use "omnisharp".
			vim.lsp.config("omnisharp", {
				filetypes = { "cs", "cshtml" },
				settings = {
					FormattingOptions = {
						EnableEditorConfigSupport = true,
						OrganizeImports = true,
					},
					RoslynExtensionsOptions = {
						EnableAnalyzersSupport = true,
						EnableImportCompletion = true,
					},
				},
			})

			-- NOTE: The following servers were previously managed by Mason.
			-- Install them manually and ensure they are on your PATH:
			--   ts_ls        → npm install -g typescript-language-server typescript
			--   rust_analyzer → ships with rustup: `rustup component add rust-analyzer`
			--   lua_ls       → https://github.com/LuaLS/lua-language-server/releases
			--   html         → npm install -g vscode-langservers-extracted
			--   cssls        → npm install -g vscode-langservers-extracted
			--   omnisharp    → dotnet tool install -g OmniSharp  (or via VS / Build Tools)
			--   clangd       → winget install LLVM.LLVM  (ships with clangd)
			vim.lsp.enable({ "ts_ls", "rust_analyzer", "lua_ls", "html", "cssls", "omnisharp", "clangd" })
		end,
	},
}
