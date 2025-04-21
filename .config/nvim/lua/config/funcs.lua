-- LazyGitToggle run a lazygit app into a terminal
function LazyGitToggle()
    local Terminal  = require('toggleterm.terminal').Terminal
    local lazygit = Terminal:new({
        cmd = "lazygit",
        hidden = true,
        direction = "float"
    })
    lazygit:toggle()
end

-- OpenBarBar function for return the opt with description
function OptBarBar(description)
    local opt = {
        desc = description,
        noremap = true,
        silent = true
    }
    return opt
end
