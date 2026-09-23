return {
	"ThePrimeagen/git-worktree.nvim",
	dependencies = { "nvim-telescope/telescope.nvim" },
	keys = {
		{ "<leader>sr", function() require("telescope").extensions.git_worktree.git_worktrees() end, desc = "Git Worktrees" },
		{ "<leader>sR", function() require("telescope").extensions.git_worktree.create_git_worktree() end, desc = "Create Git Worktree" },
	},
	config = function()
		require("git-worktree").setup()
		require("telescope").load_extension("git_worktree")
	end,
}
