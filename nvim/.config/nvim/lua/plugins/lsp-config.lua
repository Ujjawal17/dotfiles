-- Language servers. Mason installs them; mason-lspconfig enables every
-- installed server automatically (Neovim 0.11+ vim.lsp.enable API).
local servers = {
  "lua_ls",
  "pyright",
  "terraformls",
  "rust_analyzer",
  "bashls",
  "yamlls",
  "jsonls",
}
-- gopls is built with go, so only ask for it where go exists
if vim.fn.executable("go") == 1 then
  table.insert(servers, "gopls")
end

return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = servers,
      automatic_enable = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      -- Advertise nvim-cmp completion capabilities to every server
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim", "Snacks" } } } },
      })

      -- clangd comes with the system clang package (or Xcode on macOS), not Mason
      if vim.fn.executable("clangd") == 1 then
        vim.lsp.enable("clangd")
      end

      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, { desc = "References" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
      vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, { desc = "Format" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
    end,
  },
}
