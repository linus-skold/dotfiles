-- Not the default theme. Select it with the colorscheme picker (<leader>uC).
return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	opts = {
		flavour = "mocha",
		integrations = {
			treesitter = true,
			snacks = true,
			lualine = true,
			bufferline = true,
		},
	},
}
