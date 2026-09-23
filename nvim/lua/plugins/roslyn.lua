-- C# / .NET via the official Roslyn language server (same one VS Code uses).
--
-- Requirements:
--   • Neovim >= 0.12  (plugin will warn and bail out on older versions)
--   • dotnet SDK >= 10 recommended
--
-- Install the language server binary (pick one):
--   A) dotnet global tool (no Mason needed):
--        dotnet tool install -g Microsoft.CodeAnalysis.LanguageServer
--      The binary lands in ~/.dotnet/tools/ which should already be on PATH.
--
--   B) Via Mason (if you ever add it):
--        :MasonInstall roslyn
--
-- After install, run :checkhealth roslyn to verify everything is found.
--
-- Useful commands (once a .cs file is open):
--   :Roslyn target   — pick which .sln to use when multiple are detected
--   :lsp restart roslyn
--   :lsp stop roslyn
return {
	{
		"seblyng/roslyn.nvim",
		ft = { "cs" },
		config = function()
			require("roslyn").setup({
				config = {
					settings = {
						["csharp|inlay_hints"] = {
							csharp_enable_inlay_hints_for_implicit_object_creation = true,
							csharp_enable_inlay_hints_for_implicit_variable_types = true,
							csharp_enable_inlay_hints_for_lambda_parameter_types = true,
							csharp_enable_inlay_hints_for_types = true,
							dotnet_enable_inlay_hints_for_indexer_parameters = true,
							dotnet_enable_inlay_hints_for_literal_parameters = true,
							dotnet_enable_inlay_hints_for_object_creation_parameters = true,
							dotnet_enable_inlay_hints_for_other_parameters = true,
							dotnet_enable_inlay_hints_for_parameters = true,
							dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
						},
						["csharp|completion"] = {
							dotnet_provide_regex_completions = true,
							dotnet_show_completion_items_from_unimported_namespaces = true,
							dotnet_show_name_completion_suggestions = true,
						},
						["csharp|code_lens"] = {
							dotnet_enable_references_code_lens = true,
						},
					},
				},
			})
		end,
	},
}
