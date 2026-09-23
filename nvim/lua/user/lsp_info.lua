--- user/lsp_info.lua
--- Floating window that shows all configured LSP servers and their active status.
--- Usage:  require("user.lsp_info").show()
--- Command registered by plugins/lsp.lua:  :LspInfo

local M = {}

--- List of server names passed in via set_configured_servers().
M._configured = {}

--- Call this once from the LSP plugin config so lsp_info knows the full list.
function M.set_configured_servers(servers)
	M._configured = servers
end

--- Build and open the floating window.
function M.show()
	local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
	local all_clients = vim.lsp.get_clients()

	-- Index: name → client (first seen wins for display; multiples are counted)
	local buf_by_name = {}
	for _, c in ipairs(buf_clients) do
		buf_by_name[c.name] = c
	end

	local all_by_name = {}
	for _, c in ipairs(all_clients) do
		if not all_by_name[c.name] then
			all_by_name[c.name] = c
		end
	end

	-- ── helpers ────────────────────────────────────────────────────────────
	local lines = {}
	local hls = {} -- { line (0-based), col_start, col_end, hl_group }

	local function add(text, hl_group, hl_col_start, hl_col_end)
		local idx = #lines -- 0-based
		table.insert(lines, text)
		if hl_group then
			table.insert(hls, { idx, hl_col_start or 0, hl_col_end or -1, hl_group })
		end
	end

	local SEP = "  " .. string.rep("─", 43)

	-- ── header ─────────────────────────────────────────────────────────────
	add("")
	add(SEP, "Comment")
	add("")

	-- ── section: active in current buffer ──────────────────────────────────
	if #buf_clients > 0 then
		add("  ● Active  (current buffer)", "DiagnosticOk", 2, 3)
		for _, c in ipairs(buf_clients) do
			local ft = table.concat(c.config.filetypes or {}, ", ")
			local name_part = "    " .. c.name
			local line = ft ~= "" and (name_part .. "   [" .. ft .. "]") or name_part
			add(line, "DiagnosticOk", 4, 4 + #c.name)
		end
		add("")
	end

	-- ── section: active in other buffers ───────────────────────────────────
	local other = {}
	for name, c in pairs(all_by_name) do
		if not buf_by_name[name] then
			table.insert(other, c)
		end
	end
	table.sort(other, function(a, b) return a.name < b.name end)

	if #other > 0 then
		add("  ◌ Active  (other buffers)", "DiagnosticWarn", 2, 3)
		for _, c in ipairs(other) do
			local ft = table.concat(c.config.filetypes or {}, ", ")
			local name_part = "    " .. c.name
			local line = ft ~= "" and (name_part .. "   [" .. ft .. "]") or name_part
			add(line, "DiagnosticWarn", 4, 4 + #c.name)
		end
		add("")
	end

	-- ── section: configured but not running ────────────────────────────────
	local inactive = {}
	for _, name in ipairs(M._configured) do
		if not all_by_name[name] then
			table.insert(inactive, name)
		end
	end

	if #inactive > 0 then
		add("  ○ Configured  (not running)", "Comment", 2, 3)
		for _, name in ipairs(inactive) do
			add("    " .. name, "Comment", 4, 4 + #name)
		end
		add("")
	end

	-- ── footer ─────────────────────────────────────────────────────────────
	add(SEP, "Comment")
	add("  q / <Esc>  close", "Comment")
	add("")

	-- ── window sizing ──────────────────────────────────────────────────────
	local width = 50
	for _, l in ipairs(lines) do
		width = math.max(width, #l + 2)
	end
	local height = #lines

	local ui = vim.api.nvim_list_uis()[1]
	local ui_w = ui and ui.width or 120
	local ui_h = ui and ui.height or 40
	local row = math.floor((ui_h - height) / 2)
	local col = math.floor((ui_w - width) / 2)

	-- ── buffer + window ────────────────────────────────────────────────────
	local winbuf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(winbuf, 0, -1, false, lines)

	local ns = vim.api.nvim_create_namespace("lsp_info_float")
	for _, h in ipairs(hls) do
		-- h = { line, col_start, col_end, hl_group }
		vim.api.nvim_buf_add_highlight(winbuf, ns, h[4], h[1], h[2], h[3])
	end

	vim.bo[winbuf].modifiable = false
	vim.bo[winbuf].buftype = "nofile"
	vim.bo[winbuf].filetype = "lsp_info"

	local win = vim.api.nvim_open_win(winbuf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = "  LSP Servers ",
		title_pos = "center",
	})

	vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
	vim.wo[win].cursorline = false

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q",     close, { buffer = winbuf, nowait = true, silent = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = winbuf, nowait = true, silent = true })
end

return M
