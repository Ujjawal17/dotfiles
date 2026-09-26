-- AI assistant. Needs ANTHROPIC_API_KEY in the environment (set it in
-- ~/.zshrc.local, never in this repo).
return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false, -- track main; the prebuilt binary is fetched by `make`
  build = "make",
  opts = {
    provider = "claude",
    providers = {
      claude = {
        model = "claude-sonnet-5",
      },
    },
    -- Reuse snacks for pickers/prompts instead of pulling in telescope/fzf/dressing
    selector = { provider = "snacks" },
    input = { provider = "snacks" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "folke/snacks.nvim",
    "hrsh7th/nvim-cmp", -- completion for avante commands and mentions
    "echasnovski/mini.icons",
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = { insert_mode = true },
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "markdown", "Avante" } },
      ft = { "markdown", "Avante" },
    },
  },
}
