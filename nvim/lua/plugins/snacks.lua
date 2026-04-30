local vc = require("user.version_checker")

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	config = true,
	opts = {
		bigfile = { enabled = true },
		dashboard = {
			sections = {
				{ section = "header" },
				{ section = "keys", gap = 1, padding = 1 },
				{ pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                -- Custom sessions section: lists every file in the mini.sessions
                -- global directory as an individual, clickable dashboard entry.
                -- The function-as-child pattern lets snacks resolve() call our
                -- function at render time, inherit pane/indent from the parent
                -- table, and auto-insert the "Sessions" title before the items.
                {
                    pane = 2,
                    icon = "󰆓 ",
                    title = "Sessions",
                    indent = 2,
                    padding = 1,
                    function()
                        -- mini.sessions stores global sessions in stdpath("data")/session/
                        -- Files have no forced extension; the name IS the session key.
                        local dir = vim.fn.stdpath("data") .. "/session"
                        local items = {}
                        local ok, entries = pcall(vim.fn.readdir, dir)
                        if ok and entries then
                            for _, name in ipairs(entries) do
                                -- skip any subdirectories that may exist in the folder
                                if vim.fn.isdirectory(dir .. "/" .. name) == 0 then
                                    local n = name -- capture for the closure
                                    table.insert(items, {
                                        icon = "󰆓 ",
                                        desc = n,
                                        action = function()
                                            require("mini.sessions").read(n)
                                        end,
                                    })
                                end
                            end
                        end
                        -- returning an empty table hides the title too (no children = no section)
                        return items
                    end,
                },
				{ section = "startup" },
				{
					text = (function()
						local t = {
							{ "Neovim", hl = "header" },
							{ " v" },
							{ vc.get_current() },
						}

						if vc.update_available() then
							table.insert(t, { " -> v" .. vc.get_latest(), hl = "Special" })
						end

						return t
					end)(),
					align = "center",
				},
			},
		},
		picker = {
			enabled = true,
			sources = {
				explorer = {
					title = "",
				},
			},
		},
		image = { enabled = false },
		indent = { enabled = true },
		input = { enabled = true },
		notifier = {
			enabled = true,
			timeout = 4000,
		},
		quickfile = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		terminal = { enabled = true, shell = "nu" },
		words = { enabled = true },
		styles = {
			notification = {},
			terminal = { position = "right" },
		},
	},
    -- stylua: ignore start
    keys = {
        { "<leader>z",       function() Snacks.zen() end,                                             desc = "Toggle Zen Mode", },
        { "<leader>Z",       function() Snacks.zen.zoom() end,                                        desc = "Toggle Zoom", },
        { "<leader>.",       function() Snacks.scratch() end,                                         desc = "Toggle Scratch Buffer", },
        { "<leader>S",       function() Snacks.scratch.select() end,                                  desc = "Select Scratch Buffer", },
        { "<leader>n",       function() Snacks.notifier.show_history() end,                           desc = "Notification History", },
        { "<leader>bd",      function() Snacks.bufdelete() end,                                       desc = "Delete Buffer", },
        { "<leader>cR",      function() Snacks.rename.rename_file() end,                              desc = "Rename File", },
        { "<leader>gB",      function() Snacks.gitbrowse() end,                                       desc = "Git Browse",                   mode = { "n", "v" }, },
        { "<leader>gb",      function() Snacks.git.blame_line() end,                                  desc = "Git Blame Line", },
        { "<leader>gf",      function() Snacks.lazygit.log_file() end,                                desc = "Lazygit Current File History", },
        { "<leader>gg",      function() Snacks.lazygit() end,                                         desc = "Lazygit", },
        { "<leader>gl",      function() Snacks.lazygit.log() end,                                     desc = "Lazygit Log (cwd)", },
        { "<leader>un",      function() Snacks.notifier.hide() end,                                   desc = "Dismiss All Notifications", },
        { "<leader>tT",      function() Snacks.terminal.toggle() end,                                 desc = "Toggle Terminal", },
        { "<leader>tF",      function() Snacks.terminal.open(nil, { win = { style = "float" } }) end, desc = "Toggle Floating Terminal", },
        { "]]",              function() Snacks.words.jump(vim.v.count1) end,                          desc = "Next Reference",               mode = { "n", "t" }, },
        { "[[",              function() Snacks.words.jump(-vim.v.count1) end,                         desc = "Prev Reference",               mode = { "n", "t" }, },
        { "<leader>qp",function() Snacks.picker.projects() end,                                 desc = "Projects", },
        { "<leader><space>", function() Snacks.picker.files() end,                                    desc = "Find Files", },
        {
            "<A-O>",
            function()
                local default = { glob =
                "*.{c,cpp,cc,cxx,h,hpp,hxx,lua,py,js,ts,jsx,tsx,rs,go,cs,java,rb,sh,zig,toml,json,yaml,yml,md}" }
                local ok, project = pcall(require, "project")
                local opts = (ok and project.find_files) and project.find_files or default
                Snacks.picker.files(opts)
            end,
            desc = "Find Code Files",
        },
        { "<leader>gc", function() Snacks.picker.git_log() end,      desc = "Git Log", },
        { "<leader>gs", function() Snacks.picker.git_status() end,   desc = "Git Status", },
        { "<leader>fg", function() Snacks.picker.git_files() end,    desc = "Find Git Files", },
        { "<leader>E",  function() Snacks.picker.explorer() end,     desc = "File Explorer", },
        { "<leader>sb", function() Snacks.picker.lines() end,        desc = "Buffer Lines" },
        { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
        { "<leader>sg", function() Snacks.picker.grep() end,         desc = "Grep" },
        { "<leader>sw", function() Snacks.picker.grep_word() end,    desc = "Visual selection or word", mode = { "n", "x" } },
    },
    -- stylua: ignore stop
    init = function()
        vim.api.nvim_create_autocmd("User", {
            pattern = "VeryLazy",
            callback = function()
                -- Setup some globals for debugging (lazy-loaded)
                _G.dd = function(...)
                    Snacks.debug.inspect(...)
                end
                _G.bt = function()
                    Snacks.debug.backtrace()
                end
                vim.print = _G.dd -- Override print to use snacks for `:=` command

                -- Create some toggle mappings
                Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
                Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
                Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
                Snacks.toggle.diagnostics():map("<leader>ud")
                Snacks.toggle.line_number():map("<leader>ul")
                Snacks.toggle
                    .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
                    :map("<leader>uc")
                Snacks.toggle.treesitter():map("<leader>uT")
                Snacks.toggle
                    .option("background", { off = "light", on = "dark", name = "Dark Background" })
                    :map("<leader>ub")
                Snacks.toggle.inlay_hints():map("<leader>uh")
                Snacks.toggle.indent():map("<leader>ug")
                Snacks.toggle.dim():map("<leader>uD")
            end,
        })
    end,
}
