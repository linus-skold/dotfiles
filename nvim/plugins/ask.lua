return {
	dir = vim.fn.stdpath("config"),
	name = "nvim-ask",
	lazy = false,
	opts = {
		verbose = false,
		backend = {
			provider = "llamacpp",
			model    = "random model name here",
			host     = "127.0.0.1",
			port     = 8080,
		},
	},
	config = function(_, opts)
		require("ask").setup(opts)
	end,
	keys = {
		{ "<leader>ah", ":Ah ", desc = "Ask neovim-helper", mode = "n" },
	},
}
