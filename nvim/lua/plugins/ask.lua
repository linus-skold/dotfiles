-- nvim-ask lives in its own repository: ~/dev/ask
return {
	dir = vim.fn.expand("~/dev/ask"),
	name = "nvim-ask",
	lazy = false,
	opts = {
		verbose = false,
		backend = {
			provider = "copilot",
			model = "claude-haiku-4.5",
		},
	},
	config = function(_, opts)
		require("ask").setup(opts)
	end,
	keys = {
		{ "<leader>ah", ":Ah ", desc = "Ask neovim-helper", mode = "n" },
	},
}
