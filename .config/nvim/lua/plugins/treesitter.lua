return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- new API rewrite (master is frozen)
    lazy = false,   -- this plugin does not support lazy-loading
    build = ":TSUpdate",
    dependencies = {
        { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
    config = function()
        -- Main-branch API: async install (no-op if already installed).
        -- 'vimfix' dropped: not a parser in main's language list.
        require("nvim-treesitter").install({
            "go",
            "gomod", -- go.mod (heavy Go user; SRC list omitted these)
            "gosum", -- go.sum
            "hcl",   -- Terraform/OpenTofu plain .hcl (SRC dropped; exists on main)
            "helm",  -- Chart templates (set.lua assigns ft=helm; exists on main, built on gotmpl)
            "proto", -- protobuf (SRC dropped; exists on main)
            "sql",   -- SRC dropped; exists on main
            "templ", -- Go templ files (tabs autocmd + conform fmt use it)
            "rust",
            "lua",
            "vim",
            "vimdoc",
            "bash",
            "json",
            "yaml",
            "toml",
            "terraform",
            "dockerfile",
            "markdown",
            "markdown_inline",
            "python",
            "javascript",
            "typescript",
            "html",
            "css",
            "regex",
        })

        -- Highlighting/folds are provided by Neovim core: start the parser
        -- per filetype when it is actually installed (no configs.setup on main).
        -- NOTE: no indent module — main dropped it; nvim 0.12 handles indent
        -- natively where indent queries ship, else 'smartindent'.
        local apply_move_keys --[[ forward decl: defined with move maps below ]]
        vim.api.nvim_create_autocmd("FileType", {
            desc = "Start treesitter parsing when parser is available",
            pattern = {
                "go", "gomod", "gosum", "hcl", "helm", "proto", "sql", "templ",
                "rust", "lua", "vim", "help", "bash", "sh", "json",
                "yaml", "toml", "terraform", "dockerfile", "markdown",
                "python", "javascript", "typescript", "html", "css",
            },
            callback = function(event)
                local lang = vim.treesitter.language.get_lang(event.match)
                -- language.add() returns false when the parser is not installed
                if lang and vim.treesitter.language.add(lang) then
                    vim.treesitter.start()
                    apply_move_keys(event.buf) -- beat ftplugin buffer maps (go.vim etc.)
                end
            end,
        })

        -- Textobjects (main-branch API verified in installed README:
        -- require("nvim-treesitter-textobjects").setup + select/move modules)
        require("nvim-treesitter-textobjects").setup({
            select = { lookahead = true },
            move = { set_jumps = true },
        })

        local textobjects_select = require("nvim-treesitter-textobjects.select")
        local textobjects_move = require("nvim-treesitter-textobjects.move")

        -- select: a/i + function, class, method, comment
        local selects = {
            { "f", "@function.outer", "@function.inner" },
            { "c", "@class.outer", "@class.inner" },
            { "m", "@method.outer", "@method.inner" },
            { "C", "@comment.outer", "@comment.outer" },
        }
        for _, s in ipairs(selects) do
            vim.keymap.set({ "x", "o" }, "a" .. s[1], function()
                textobjects_select.select_textobject(s[2], "textobjects")
            end, { desc = "Around " .. s[1] .. " (treesitter)" })
            vim.keymap.set({ "x", "o" }, "i" .. s[1], function()
                textobjects_select.select_textobject(s[3], "textobjects")
            end, { desc = "Inner " .. s[1] .. " (treesitter)" })
        end

        -- move: next/prev function (]], [[), class (][, []), method (]m, [m)
        -- NOTE: ]] / [[ previously Snacks.words.jump — treesitter now owns them.
        -- ftplugins (go.vim, sql.vim, rust.vim, markdown...) map ]] / [[ as
        -- BUFFER-LOCAL, which beats any global map — so we re-apply per-buffer
        -- in the FileType autocmd below.
        local move_maps = {
            { "]]", function() textobjects_move.goto_next_start("@function.outer", "textobjects") end, "Next function start" },
            { "[[", function() textobjects_move.goto_previous_start("@function.outer", "textobjects") end, "Prev function start" },
            { "][", function() textobjects_move.goto_next_end("@class.outer", "textobjects") end, "Next class end" },
            { "[]", function() textobjects_move.goto_previous_end("@class.outer", "textobjects") end, "Prev class end" },
            { "]m", function() textobjects_move.goto_next_start("@method.outer", "textobjects") end, "Next method start" },
            { "[m", function() textobjects_move.goto_previous_start("@method.outer", "textobjects") end, "Prev method start" },
        }
        apply_move_keys = function(buf)
            for _, m in ipairs(move_maps) do
                vim.keymap.set({ "n", "x", "o" }, m[1], m[2], {
                    desc = m[3],
                    buffer = buf, -- nil => global
                    noremap = true,
                })
            end
        end
        apply_move_keys(nil)
    end,
}
