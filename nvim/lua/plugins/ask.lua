return {
	dir = vim.fn.stdpath("config"),
	name = "nvim-ask",
	lazy = false,
	opts = {
		model = "claude-haiku-4.5",
		verbose = false,
	},
	config = function(_, opts)
		require("ask").setup(opts)
	end,
	keys = {
		{ "<leader>ah", ":Ah ", desc = "Ask neovim-helper", mode = "n" },
	},
}
