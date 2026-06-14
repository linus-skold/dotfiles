-- Assembles prompts sent to backends.
-- build_copilot() → plain string for the Copilot CLI (uses /neovim-helper skill).
-- build_messages() → chat messages array for HTTP-based backends (ollama, llama.cpp).

local M = {}

local SYSTEM_PROMPT = [[You are a Neovim expert. Give short, direct answers — ideally 1–3 lines or a brief list.
No preamble, no explanation of what you're about to do, no closing remarks.
Wrap your answer in <nvim_answer>...</nvim_answer> tags.]]

local function context_block(doc_context)
	if not doc_context or doc_context == "" then return "" end
	return "\n\nPre-fetched Neovim manual context:\n```\n"
		.. doc_context
		.. "\n```\n\nUse the above context as your primary doc reference and skip searching other doc files."
end

function M.build_copilot(question, doc_context)
	local parts = { "Use the /neovim-helper skill." }
	local ctx = context_block(doc_context)
	if ctx ~= "" then table.insert(parts, ctx) end
	table.insert(parts, "\n\nAnswer this question: " .. question)
	return table.concat(parts, "")
end

---@return {role: string, content: string}[]
function M.build_messages(question, doc_context)
	local ctx = context_block(doc_context)
	local user_content = ctx ~= ""
		and (ctx .. "\n\nAnswer this question: " .. question)
		or  question
	return {
		{ role = "system", content = SYSTEM_PROMPT },
		{ role = "user",   content = user_content },
	}
end

return M