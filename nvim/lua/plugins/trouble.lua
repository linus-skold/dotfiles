return {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Trouble Toggle" },
    }
}
