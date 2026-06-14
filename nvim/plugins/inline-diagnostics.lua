return {
	"rachartier/tiny-inline-diagnostic.nvim",
	event = "LspAttach",
	opts = {
		options = {
			multilines = {
				enabled = false,
			},
		},
	},
	config = function(_, opts)
		local tid = require("tiny-inline-diagnostic")
		tid.setup(opts)
		vim.diagnostic.config({
			virtual_text = false,
		})

		vim.api.nvim_create_user_command("TinyInlineDiagnosticMultilinesToggle", function()
			local current = tid.config.options.multilines.enabled
			tid.config.options.multilines.enabled = not current
		end, {})
	end,
	keys = {
		{
			"<leader>tm",
			"<cmd>TinyInlineDiagnosticMultilinesToggle<CR>",
			desc = "Toggle Tiny Inline Diagnostic Multilines",
		},
	},
}
