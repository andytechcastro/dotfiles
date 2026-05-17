local M = {}

-- Run Graphify update in the current directory
function M.graphify_update()
    vim.notify("Actualizando Grafo de Conocimiento...", vim.log.levels.INFO)
    vim.fn.jobstart({ "graphify", "update", "." }, {
        on_exit = function(j, code)
            if code == 0 then
                vim.notify("Grafo actualizado con éxito", vim.log.levels.INFO)
            else
                vim.notify("Fallo al actualizar el Grafo", vim.log.levels.ERROR)
            end
        end,
    })
end

-- Run Hexagonal Architecture check for Go projects
function M.hex_check()
    local root = vim.fs.root(0, { "go.mod" })
    if not root then
        vim.notify("No se ha encontrado go.mod", vim.log.levels.WARN)
        return
    end
    
    local cmd = string.format("go run %s/.config/opencode/tool/hex_check.go", os.getenv("HOME") .. "/Projects/dotfiles")
    
    vim.notify("Validando Arquitectura Hexagonal...", vim.log.levels.INFO)
    local output = vim.fn.system(cmd)
    
    if vim.v.shell_error ~= 0 then
        vim.notify("Violación de Arquitectura detectada:\n" .. output, vim.log.levels.ERROR)
    else
        vim.notify("Arquitectura Hexagonal válida", vim.log.levels.INFO)
    end
end

-- Re-generate OpenCode Agents
function M.opencode_build()
    vim.notify("Re-generando Agentes OpenCode...", vim.log.levels.INFO)
    local builder_dir = os.getenv("HOME") .. "/Projects/dotfiles/.config/opencode/builder"
    vim.fn.jobstart({ "go", "run", "main.go" }, {
        cwd = builder_dir,
        on_exit = function(j, code)
            if code == 0 then
                vim.notify("Plataforma OpenCode regenerada", vim.log.levels.INFO)
            else
                vim.notify("Error al construir OpenCode", vim.log.levels.ERROR)
            end
        end,
    })
end

return M
