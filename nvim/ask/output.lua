-- Parses clean text returned by backends.
-- ANSI stripping and tool-line filtering are handled inside each backend.

local M = {}

local function split_trim(text)
	local lines = vim.split(text or "", "\n", { plain = true })
	while #lines > 0 and lines[1]:match("^%s*$")    do table.remove(lines, 1) end
	while #lines > 0 and lines[#lines]:match("^%s*$") do table.remove(lines) end
	return #lines > 0 and lines or { "(no response)" }
end

--- Extract displayable lines from backend output.
--- If <nvim_answer> tags are present, returns only their content.
--- Otherwise returns all non-empty lines.
function M.parse(text)
	local answer = (text or ""):match("<nvim_answer>%s*(.-)%s*</nvim_answer>")
	if answer and #answer > 0 then
		return split_trim(answer)
	end
	return split_trim(text)
end

return M
