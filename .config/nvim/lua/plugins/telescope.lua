return {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = "Telescope",
    keys = {
        { '<leader>ff', require('telescope.builtin').find_files, desc = 'Telescope find files' },
        { '<leader>fg', require('telescope.builtin').live_grep, desc = 'Telescope live grep' },
        { '<leader>fb', require('telescope.builtin').buffers, desc = 'Telescope buffers' },
        { '<leader>fh', require('telescope.builtin').help_tags, desc = 'Telescope todo comments' },
        { '<leader>fr', require('telescope.builtin').registers, desc = 'Telescope Registers' },
    }
}
