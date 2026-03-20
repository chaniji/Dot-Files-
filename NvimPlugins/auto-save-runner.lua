-- Auto-save Configuration
-- Place this file in: ~/.config/nvim/lua/plugins/auto-save-runner.lua

return {
  -- Auto-save plugin (VS Code-like behavior)
  {
    "okuuva/auto-save.nvim",
    event = { "InsertLeave", "TextChanged" },
    opts = {
      enabled = true,
      trigger_events = {
        immediate_save = { "BufLeave", "FocusLost" },
        defer_save = { "InsertLeave", "TextChanged" },
        cancel_deferred_save = { "InsertEnter" },
      },
      condition = function(buf)
        local fn = vim.fn
        local utils = require("auto-save.utils.data")
        
        -- Don't save for certain filetypes
        if utils.not_in(fn.getbufvar(buf, "&filetype"), {
          "gitcommit",
          "gitrebase",
          "hgcommit",
          "svn",
          "NeogitCommitMessage",
        }) then
          return true
        end
        return false
      end,
      write_all_buffers = false,
      debounce_delay = 1000,
    },
    keys = {
      { "<leader>as", "<cmd>ASToggle<cr>", desc = "Toggle Auto-save" },
    },
  },
}
