local M = {}
local uv = vim.uv or vim.loop

function M.reload_module(module_name)
	for k in pairs(package.loaded) do
		if k:match("^" .. module_name) then
			package.loaded[k] = nil
		end
	end
	return require(module_name)
end

return M
