-- Ollama backend.
-- POST to http://host:port/api/chat (non-streaming).
-- Requires ollama running locally or on a reachable host.

local prompt = require("ask.prompt")

local M = {}

local DEFAULT_HOST = "127.0.0.1"
local DEFAULT_PORT = 11434

local function base_url(host, port)
	if host:match("^https?://") then
		return host:gsub("/*$", "")
	end
	return string.format("http://%s:%d", host, port)
end

---@param question string
---@param doc_context string
---@param opts table  Full config.options
---@param callback fun(result: table, err: string|nil)
function M.run(question, doc_context, opts, callback)
	local bcfg = opts.backend or {}
	local host  = bcfg.host  or DEFAULT_HOST
	local port  = bcfg.port  or DEFAULT_PORT
	local model = bcfg.model or "llama3.2"

	local url  = base_url(host, port) .. "/api/chat"
	local body = vim.json.encode({
		model    = model,
		messages = prompt.build_messages(question, doc_context),
		stream   = false,
	})

	vim.system(
		{ "curl", "-sf", "-X", "POST", url,
		  "-H", "Content-Type: application/json",
		  "--data-binary", "@-" },
		{ stdin = body, text = true },
		function(result)
			vim.schedule(function()
				if result.code ~= 0 then
					callback(nil, string.format(
						"curl failed (code %d) — is ollama running at %s:%d?",
						result.code, host, port
					))
					return
				end

				local ok, decoded = pcall(vim.json.decode, result.stdout or "")
				if not ok or type(decoded) ~= "table" then
					callback(nil, "ollama: could not parse response JSON")
					return
				end

				local text = vim.tbl_get(decoded, "message", "content")
				if not text then
					callback(nil, "ollama: unexpected response shape")
					return
				end

				callback({ text = text, exit_code = 0 }, nil)
			end)
		end
	)
end

return M
