-- C# / .NET via the official Roslyn language server (same one VS Code uses).
--
-- First-time setup:
--   1. :Lazy install   (installs the plugin)
--   2. :RoslynInstall  (downloads Microsoft.CodeAnalysis.LanguageServer via dotnet)
--
-- Supports .NET Core, .NET 5+, and .NET Framework projects.
-- Solution picker appears automatically when multiple .sln files are found.
return {
	{
		"seblyng/roslyn.nvim",
		ft = { "cs" },
		config = function()
			require("roslyn").setup({
				config = {
					-- Settings use the VS Code key format: "section|subsection"
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
