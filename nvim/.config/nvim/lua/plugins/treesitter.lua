return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      "c", "lua", "vim", "vimdoc", "query",
      "markdown", "markdown_inline",
      "regex", "javascript", "typescript", "tsx",
      "css", "html", "scss", "bash", "ruby", "python",
      "json", "yaml",
    })

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
