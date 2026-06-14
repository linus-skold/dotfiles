-- Floating window UI: result display and loading spinner.

local M = {}

local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

function M.open_float(lines, title)
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

function M.open_loading(question, provider)
	local label = "Asking " .. (provider or "Copilot") .. "…"
	local q = #question > 55 and (question:sub(1, 52) .. "…") or question
	local buf, win = M.open_float({ "", "  ⠋  " .. label, "", "  " .. q, "" }, "󰚩 neovim-helper")

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
			"  " .. SPINNER[frame] .. "  " .. label,
			"",
			"  " .. q,
			"",
		})
		frame = (frame % #SPINNER) + 1
	end))

	return win, timer
end

function M.stop_loading(win, timer)
	if timer and not timer:is_closing() then
		timer:stop()
		timer:close()
	end
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

return M
