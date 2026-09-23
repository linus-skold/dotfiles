return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		lsp = {
			-- Override markdown rendering so that other plugins use Treesitter.
			-- Note: cmp.entry.get_documentation is intentionally omitted —
			-- this config uses mini.completion, not nvim-cmp.
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
		},
		presets = {
			bottom_search = true, -- classic bottom cmdline for search
			command_palette = true, -- cmdline and popupmenu together
			long_message_to_split = true, -- long messages sent to a split
			inc_rename = false,
			lsp_doc_border = false,
		},
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
}
