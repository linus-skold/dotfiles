-- Copilot CLI backend.
-- Shells out to `copilot --no-alt-screen --yolo --model <model>` with the prompt on stdin.
-- Strips ANSI codes and separates tool-call progress lines into diagnostics.

local prompt = require("ask.prompt")

local M = {}

local CONFIG_DIR = vim.fn.stdpath("config")

local function strip_ansi(s)
	s = s:gsub("\27%[[%d;]*[A-Za-z]", "")
	s = s:gsub("\27%][^\7]*\7", "")
	s = s:gsub("\27.", "")
	s = s:gsub("\r", "")
	return s
end

local TOOL_LINE = "^%s*[●│└├]"

---@param question string
---@param doc_context string
---@param opts table  Full config.options
---@param callback fun(result: table, err: string|nil)
function M.run(question, doc_context, opts, callback)
	local bcfg  = opts.backend or {}
	local model = bcfg.model or "claude-haiku-4.5"
	local full_prompt = prompt.build_copilot(question, doc_context)

	vim.system(
		{ "copilot", "--no-alt-screen", "--yolo", "--model", model },
		{
			cwd  = CONFIG_DIR,
			env  = vim.tbl_extend("force", vim.fn.environ(), { NO_COLOR = "1" }),
			stdin = full_prompt,
			text  = true,
		},
		function(result)
			vim.schedule(function()
				local text_lines = {}
				local diag_lines = {}

				for _, l in ipairs(vim.split(result.stdout or "", "\n", { plain = true })) do
					local stripped = strip_ansi(l)
					if stripped:match(TOOL_LINE) then
						table.insert(diag_lines, stripped)
					else
						table.insert(text_lines, stripped)
					end
				end

				local err = result.code ~= 0
					and ("copilot exited with code " .. result.code)
					or nil

				callback({
					text        = table.concat(text_lines, "\n"),
					diagnostics = diag_lines,
					exit_code   = result.code,
				}, err)
			end)
		end
	)
end

return M
