local function colorscheme_picker()
	local themes = vim.tbl_map(function(name)
		return {
			text = name,
			apply = function() vim.cmd.colorscheme(name) end,
		}
	end, vim.fn.getcompletion("", "color"))

	local original = vim.g.colors_name

	Snacks.picker.pick({
		title = "Colorschemes",
		items = themes,
		format = "text",
		preview = "none",
		on_change = function(_, item)
			if item then
				pcall(item.apply)
			end
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				item.apply()
			else
				vim.cmd.colorscheme(original)
			end
		end,
		win = {
			input = {
				keys = {
					["<Esc>"] = { "close", mode = { "i", "n" } },
				},
			},
		},
	})
end

return {
	"folke/snacks.nvim",
	keys = {
		{ "<leader>uC", function() colorscheme_picker() end, desc = "Colorscheme Picker" },
	},
}
