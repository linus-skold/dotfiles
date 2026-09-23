-- The default theme. The only spec that calls :colorscheme at start.
return {
	"ember-theme/nvim",
	name = "ember",
	lazy = false,
	priority = 1000,
	config = function()
		require("ember").setup({
			variant = "ember", -- "ember" | "ember-soft" | "ember-light"
		})
		vim.cmd("colorscheme ember")
	end,
}
