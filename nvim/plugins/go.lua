-- Enable built-in treesitter highlighting for Go (Neovim 0.12+).
-- Requires parsers to be installed first: :TSInstall go gomod gosum gowork
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "go", "gomod", "gosum", "gowork" },
    callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
    end,
})

return {}
