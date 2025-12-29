return {
  "sindrets/diffview.nvim",
  event = "VeryLazy",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git Diff View (Local)" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Git File History" },
  },
  config = function()
    require("diffview").setup({
      enhanced_diff_hl = true, -- Better diff highlighting
      view = {
        -- Configure the layout for merge conflicts and diffs
        merge_tool = {
          layout = "diff3_mixed",
        },
        file_history = {
          layout = "diff2_horizontal",
        },
      },
      hooks = {
        diff_buf_read = function(bufnr)
          -- Disable some heavy plugins in diff buffers to keep it fast
          vim.opt_local.wrap = false
        end,
      },
    })
  end,
}
