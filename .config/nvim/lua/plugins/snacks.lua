return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    explorer = { enabled = false, replace_netrw = true }, -- Oil owns the explorer
    -- NOTE: snacks has no top-level `undo` module (main 882c996). The undo
    -- viewer is the PICKER source Snacks.picker.undo() — bound in keys below.
    picker = {
      enabled = true,
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
      },
    },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    terminal = { enabled = true },
    styles = {
      notification = {
        wo = { wrap = true } -- Wrap notifications
      }
    }
  },
  keys = {
    -- <leader>e now owned by Oil (config/remap.lua); explorer module disabled
    { "<leader>p",  function() Snacks.picker.smart() end, desc = "Smart Picker" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Live Grep" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Help Tags" },
    { "<leader>fr", function() Snacks.picker.registers() end, desc = "Registers" },
    { "<C-p>",      function() Snacks.picker.smart() end, desc = "Smart Picker" },
    { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>u",  function() Snacks.picker.undo() end, desc = "Undo History (replaces undotree)" },
    { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    { "<c-/>",      function() Snacks.terminal() end, desc = "Toggle Terminal" },
    { "<c-_>",      function() Snacks.terminal() end, desc = "which_key_ignore" },
  },
}