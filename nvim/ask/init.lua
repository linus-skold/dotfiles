-- nvim-ask  –  :Ah <question>  –  Ask the neovim-helper Copilot skill from Neovim.
--
-- Configure via lazy opts:
--   opts = {
--     verbose = true,
--     backend = {
--       provider = "ollama",
--       model    = "llama3.2",
--       host     = "192.168.1.50",  -- optional, defaults to localhost
--       port     = 11434,           -- optional, uses provider default
--     },
--   }

local config  = require("ask.config")
local ui      = require("ask.ui")
local context = require("ask.context")
local output  = require("ask.output")

local M = {}

local BACKENDS = {
	copilot    = "ask.backends.copilot",
	ollama     = "ask.backends.ollama",
	llamacpp   = "ask.backends.llamacpp",
	["llama.cpp"] = "ask.backends.llamacpp",
}

function M.ask(question)
	local t_start = vim.uv.now()
	local opts     = config.options
	local provider = (opts.backend and opts.backend.provider) or "copilot"

	local backend_path = BACKENDS[provider]
	if not backend_path then
		vim.notify(
			string.format("ask: unknown backend %q. Valid: %s",
				provider, table.concat(vim.tbl_keys(BACKENDS), ", ")),
			vim.log.levels.ERROR
		)
		return
	end

	local backend_mod = require(backend_path)
	local loading_win, spinner_timer = ui.open_loading(question, provider)

	context.fetch_async(question, opts.doc_dir, function(doc_context)
		local t_context = vim.uv.now()

		backend_mod.run(question, doc_context, opts, function(result, err)
			ui.stop_loading(loading_win, spinner_timer)

			local t_end   = vim.uv.now()
			local t_total = (t_end   - t_start)   / 1000
			local t_ctx   = (t_context - t_start) / 1000
			local t_api   = (t_end   - t_context) / 1000

			local lines
			if err and (not result or not result.text or result.text:match("^%s*$")) then
				lines = {
					"⚠  " .. err,
					"",
					"Make sure the backend is available and configured correctly.",
				}
			else
				lines = output.parse(result and result.text or "")

				if opts.verbose and result and result.diagnostics and #result.diagnostics > 0 then
					local all = {}
					vim.list_extend(all, result.diagnostics)
					table.insert(all, "─────")
					vim.list_extend(all, lines)
					lines = all
				end
			end

			local bcfg  = opts.backend or {}
			local model = bcfg.model or provider

			table.insert(lines, "")
			table.insert(lines, "─────")
			if opts.verbose then
				table.insert(lines, string.format(
					"⏱ %.3fs (ctx: %.3fs, api: %.3fs)  •  %s  •  %s",
					t_total, t_ctx, t_api, provider, model
				))
			else
				table.insert(lines, string.format(
					"⏱ %.1fs  •  %s  •  %s", t_total, provider, model
				))
			end

			local q_title = #question > 55 and (question:sub(1, 52) .. "…") or question
			ui.open_float(lines, "󰚩  " .. q_title)
		end)
	end)
end

function M.setup(opts)
	config.setup(opts)

	vim.api.nvim_create_user_command("Ah", function(o)
		if o.args == "" then
			vim.notify(":Ah <question>  –  ask the neovim-helper skill", vim.log.levels.WARN)
			return
		end
		M.ask(o.args)
	end, { nargs = "+", desc = "Ask the neovim-helper Copilot skill" })
end

return M
