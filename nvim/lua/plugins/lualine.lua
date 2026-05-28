return {
	"nvim-lualine/lualine.nvim",
	lazy = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			theme = "auto",
		},
		sections = {
			lualine_c = {
				{ "filename", path = 1 }, -- 3 = full absolute path
			},
		},
	},
}
