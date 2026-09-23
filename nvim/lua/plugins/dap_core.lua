return {
    {
        "mfussenegger/nvim-dap",
        event = "VeryLazy",
    },
    {
        "rcarriga/nvim-dap-ui",
        event = "VeryLazy",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",  -- required by nvim-dap-ui
        },
    },
}
