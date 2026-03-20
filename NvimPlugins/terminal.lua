return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          position = "float",
          border = "single", -- or "single", "double", "solid", "shadow"
        },
      },
    },
    keys = {
      {
        "<leader>ft",
        function()
          Snacks.terminal()
        end,
        desc = "Terminal (cwd)",
      },
    },
  },
}
