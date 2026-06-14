
return {
	{
		"nvim-mini/mini.completion",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},
	{
		"nvim-mini/mini.bracketed",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},
	{
		"nvim-mini/mini.comment",
		version = "*",
		event = "VeryLazy",
		opts = {},
	},
	{
		"nvim-mini/mini.diff",
		version = "*",
		opts = {
			view = {
				style = "sign",
			},
		},
	},
    { 
        "nvim-mini/mini.pairs",
        event = "VeryLazy",
        opts = {}
    },
    {
        "nvim-mini/mini.sessions",
        enabled = true,
        dependencies = { "folke/snacks.nvim" },
        version = "*",
        event = "VeryLazy",
        opts = {
            file = "Session.vim",
            -- autoread is intentionally omitted: mini.sessions loads on VeryLazy,
            -- which fires AFTER VimEnter, so the VimEnter autocmd that autoread
            -- registers would never trigger. Session restore is handled by the
            -- snacks dashboard "Restore Session" button instead.
            autowrite = true,
        },
        keys = {
            { "<leader>cS", function()
                Snacks.input({
                    prompt = "Session name: ",
                }, function(input)
                    if input then
                        require("mini.sessions").write(input)
                    end
                end)
            end, desc = "Save Session" },
            { "<leader>cL", function() require("mini.sessions").select() end, desc = "Load Session" },
        },
        config = function(_, opts)
            require("mini.sessions").setup(opts)
            -- Delete initial no-name buffer after session is manually loaded
            vim.api.nvim_create_autocmd("SessionLoadPost", {
                callback = function()
                    vim.defer_fn(function()
                        local bufs = vim.api.nvim_list_bufs()
                        for _, bufnr in ipairs(bufs) do
                            if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) == "" and vim.bo[bufnr].buftype == "" and not vim.bo[bufnr].modified then
                                vim.api.nvim_buf_delete(bufnr, { force = true })
                            end
                        end
                    end, 10)
                end,
            })
        end,
    }
}
