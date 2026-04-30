-- nvim-ask  –  :Ah <question>  –  Ask the neovim-helper Copilot skill from Neovim.
--
-- Speed optimizations:
--   1. Doc context caching: Repeated queries with similar keywords use cached results
--   2. Async ripgrep: Non-blocking doc search with immediate UI feedback
--   3. Stdin context passing: No temp file I/O overhead
--   4. Fast model: claude-haiku-4.5 (~5× faster than Sonnet)
--   5. Performance timing: Detailed breakdown in verbose mode
--
-- Configure via lazy opts:
--   opts = { model = "claude-sonnet-4.6", verbose = true }

local M = {}

M.config = {
	model = "claude-haiku-4.5",
	verbose = false,
}

local DOC_DIR = vim.fn.expand("~/scoop/apps/neovim/current/share/nvim/runtime/doc")
local CONFIG_DIR = vim.fn.stdpath("config")

local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

-- Doc context cache to avoid redundant ripgrep searches
local doc_cache = {}

-- ── ANSI / output helpers ─────────────────────────────────────────────────────

local function strip_ansi(s)
	s = s:gsub("\27%[[%d;]*[A-Za-z]", "")
	s = s:gsub("\27%][^\7]*\7", "")
	s = s:gsub("\27.", "")
	s = s:gsub("\r", "")
	return s
end

local function clean_lines(raw)
	local lines = vim.split(raw, "\n", { plain = true })
	local out = {}
	for _, l in ipairs(lines) do
		table.insert(out, strip_ansi(l))
	end
	while #out > 0 and out[1]:match("^%s*$") do table.remove(out, 1) end
	while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
	return #out > 0 and out or { "(no response)" }
end

--- Strip copilot's tool-call progress lines (● Read …, │ path, └ N lines read).
--- These are copilot CLI's own stdout output, not the model's answer.
local TOOL_LINE = "^%s*[●│└├]"
local function is_tool_line(s)
	return s:match(TOOL_LINE) ~= nil
end

--- When verbose=false, extract only the content between <nvim_answer> tags.
--- Falls back to the full cleaned output (minus tool lines) if no tags found.
local function parse_output(raw, verbose)
	if not verbose then
		local answer = raw:match("<nvim_answer>%s*(.-)%s*</nvim_answer>")
		if answer and #answer > 0 then
			return clean_lines(answer)
		end
	end
	-- verbose=true OR no tags found: return everything, optionally keeping tool lines
	local lines = vim.split(raw, "\n", { plain = true })
	local out = {}
	for _, l in ipairs(lines) do
		local stripped = strip_ansi(l)
		if verbose or not is_tool_line(stripped) then
			table.insert(out, stripped)
		end
	end
	while #out > 0 and out[1]:match("^%s*$") do table.remove(out, 1) end
	while #out > 0 and out[#out]:match("^%s*$") do table.remove(out) end
	return #out > 0 and out or { "(no response)" }
end

-- ── floating window ───────────────────────────────────────────────────────────

local function open_float(lines, title)
	local cols, rows = vim.o.columns, vim.o.lines
	local W = math.min(math.max(72, math.floor(cols * 0.72)), cols - 4)
	local H = math.min(math.max(8, #lines + 2), math.floor(rows * 0.72))

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"

	local win_cfg = {
		relative = "editor",
		width = W,
		height = H,
		row = math.floor((rows - H) / 2),
		col = math.floor((cols - W) / 2),
		style = "minimal",
		border = "rounded",
		title = " " .. title .. " ",
		title_pos = "center",
	}
	if vim.fn.has("nvim-0.10") == 1 then
		win_cfg.footer = "  q / <Esc>  dismiss "
		win_cfg.footer_pos = "right"
	end

	local win = vim.api.nvim_open_win(buf, true, win_cfg)
	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	vim.wo[win].scrolloff = 3

	local function close()
		if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
	end
	vim.keymap.set("n", "q",     close, { buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })

	return buf, win
end

-- ── animated loading window ───────────────────────────────────────────────────

local function open_loading(question)
	local q = #question > 55 and (question:sub(1, 52) .. "…") or question
	local buf, win = open_float({ "", "  ⠋  Asking Copilot…", "", "  " .. q, "" }, "󰚩 neovim-helper")

	vim.bo[buf].modifiable = true

	local frame = 1
	local timer = vim.uv.new_timer()
	timer:start(100, 100, vim.schedule_wrap(function()
		if not vim.api.nvim_buf_is_valid(buf) then
			timer:stop()
			timer:close()
			return
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
			"",
			"  " .. SPINNER[frame] .. "  Asking Copilot…",
			"",
			"  " .. q,
			"",
		})
		frame = (frame % #SPINNER) + 1
	end))

	return win, timer
end

local function stop_loading(win, timer)
	if timer and not timer:is_closing() then
		timer:stop()
		timer:close()
	end
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

-- ── ripgrep context pre-fetch ─────────────────────────────────────────────────

local STOP_WORDS = {
	what=1, does=1, ["do"]=1, how=1, the=1, ["and"]=1, ["for"]=1,
	["with"]=1, that=1, this=1, when=1, where=1, ["from"]=1, about=1,
	["in"]=1, ["is"]=1, can=1, use=1, ["my"]=1, ["to"]=1,
	["a"]=1, ["an"]=1, ["it"]=1, ["or"]=1, ["not"]=1,
}

local function normalise_keys(q)
	q = q:gsub("<[Cc]%-([^>]+)>", function(k) return "CTRL-" .. k:upper() end)
	q = q:gsub("<[AaMm]%-([^>]+)>", function(k) return "META-" .. k:upper() end)
	return q
end

local function build_pattern(question)
	local q = normalise_keys(question)
	local seen, terms = {}, {}
	for token in q:gmatch("[A-Za-z][%w_%-]*") do
		local lo = token:lower()
		if #token >= 4 and not STOP_WORDS[lo] and not seen[lo] then
			seen[lo] = true
			table.insert(terms, vim.pesc(token))
		end
	end
	if #terms == 0 then return nil end
	return table.concat({ unpack(terms, 1, math.min(4, #terms)) }, "|")
end

--- Fetch doc context synchronously (for cache hits)
local function fetch_doc_context_sync(question)
	local pattern = build_pattern(question)
	if not pattern then return "" end

	-- Check cache first
	if doc_cache[pattern] then
		return doc_cache[pattern]
	end

	local result = vim.system(
		{ "rg", "-i", "-A", "7", "-B", "1", "-m", "4", "--trim", "--", pattern, DOC_DIR },
		{ text = true, stdin = false }
	):wait()

	if result.code ~= 0 or not result.stdout or result.stdout == "" then
		doc_cache[pattern] = ""
		return ""
	end

	local ctx = result.stdout:gsub(vim.pesc(DOC_DIR) .. "[/\\]?", "")
	ctx = #ctx > 4000 and (ctx:sub(1, 4000) .. "\n…(truncated)") or ctx
	
	-- Cache the result
	doc_cache[pattern] = ctx
	return ctx
end

--- Fetch doc context asynchronously (for cache misses)
local function fetch_doc_context_async(question, callback)
	local pattern = build_pattern(question)
	if not pattern then
		callback("")
		return
	end

	-- Check cache first
	if doc_cache[pattern] then
		callback(doc_cache[pattern])
		return
	end

	vim.system(
		{ "rg", "-i", "-A", "7", "-B", "1", "-m", "4", "--trim", "--", pattern, DOC_DIR },
		{ text = true, stdin = false },
		function(result)
			vim.schedule(function()
				if result.code ~= 0 or not result.stdout or result.stdout == "" then
					doc_cache[pattern] = ""
					callback("")
					return
				end

				local ctx = result.stdout:gsub(vim.pesc(DOC_DIR) .. "[/\\]?", "")
				ctx = #ctx > 4000 and (ctx:sub(1, 4000) .. "\n…(truncated)") or ctx
				
				-- Cache the result
				doc_cache[pattern] = ctx
				callback(ctx)
			end)
		end
	)
end

-- ── prompt builder ────────────────────────────────────────────────────────────

--- Build the full prompt with context embedded directly.
--- Context is now passed inline rather than via temp file.
local function build_prompt(question, doc_context)
	local parts = { "Use the /neovim-helper skill." }
	
	if doc_context and doc_context ~= "" then
		table.insert(parts, "\n\nPre-fetched Neovim manual context:\n```")
		table.insert(parts, doc_context)
		table.insert(parts, "```\n\nUse the above context as your primary doc reference and skip searching other doc files.")
	end
	
	table.insert(parts, "\n\nAnswer this question: " .. question)
	return table.concat(parts, "")
end

-- ── public API ────────────────────────────────────────────────────────────────

function M.ask(question)
	local t_start = vim.uv.now()
	
	-- Show loading spinner immediately
	local loading_win, spinner_timer = open_loading(question)
	local model = M.config.model

	-- Fetch doc context asynchronously, then call Copilot
	fetch_doc_context_async(question, function(doc_context)
		local t_ripgrep = vim.uv.now()
		
		-- Build complete prompt with embedded context
		local prompt = build_prompt(question, doc_context)

		vim.system(
			{ "copilot", "--no-alt-screen", "--yolo", "--model", model },
			{
				cwd = CONFIG_DIR,
				env = vim.tbl_extend("force", vim.fn.environ(), { NO_COLOR = "1" }),
				stdin = prompt,
				text = true,
			},
			function(result)
				vim.schedule(function()
					stop_loading(loading_win, spinner_timer)

					local t_end = vim.uv.now()
					local t_total = (t_end - t_start) / 1000
					local t_rg = (t_ripgrep - t_start) / 1000
					local t_api = (t_end - t_ripgrep) / 1000
					local elapsed = string.format("%.1fs", t_total)
					
					-- Only use stdout — stderr carries copilot's usage/timing stats
					local lines = parse_output(result.stdout or "", M.config.verbose)

					if result.code ~= 0 and lines[1] == "(no response)" then
						lines = {
							"⚠  copilot exited with code " .. result.code,
							"",
							"Make sure `copilot` is in your PATH and you are logged in.",
						}
					end

					table.insert(lines, "")
					table.insert(lines, "─────")
					if M.config.verbose then
						table.insert(lines, string.format("⏱ %.3fs (rg: %.3fs, api: %.3fs)  •  %s", t_total, t_rg, t_api, model))
					else
						table.insert(lines, "⏱ " .. elapsed .. "  •  " .. model)
					end

					local q_title = #question > 55 and (question:sub(1, 52) .. "…") or question
					open_float(lines, "󰚩  " .. q_title)
				end)
			end
		)
	end)
end

function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	vim.api.nvim_create_user_command("Ah", function(o)
		if o.args == "" then
			vim.notify(":Ah <question>  –  ask the neovim-helper skill", vim.log.levels.WARN)
			return
		end
		M.ask(o.args)
	end, { nargs = "+", desc = "Ask the neovim-helper Copilot skill" })
end

return M
