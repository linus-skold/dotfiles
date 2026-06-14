-- Async ripgrep doc-context fetching with result caching.

local M = {}

local doc_cache = {}

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

--- Fetch relevant doc snippets via ripgrep and call callback(ctx_string).
---@param question string   The user's question (used to extract search terms)
---@param doc_dir string    Path to the Neovim runtime doc directory
---@param callback fun(ctx: string)
function M.fetch_async(question, doc_dir, callback)
	local pattern = build_pattern(question)
	if not pattern then
		callback("")
		return
	end

	if doc_cache[pattern] then
		callback(doc_cache[pattern])
		return
	end

	vim.system(
		{ "rg", "-i", "-A", "7", "-B", "1", "-m", "4", "--trim", "--", pattern, doc_dir },
		{ text = true, stdin = false },
		function(result)
			vim.schedule(function()
				if result.code ~= 0 or not result.stdout or result.stdout == "" then
					doc_cache[pattern] = ""
					callback("")
					return
				end

				local ctx = result.stdout:gsub(vim.pesc(doc_dir) .. "[/\\]?", "")
				ctx = #ctx > 4000 and (ctx:sub(1, 4000) .. "\n…(truncated)") or ctx

				doc_cache[pattern] = ctx
				callback(ctx)
			end)
		end
	)
end

return M
