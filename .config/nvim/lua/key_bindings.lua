-- Functional wrapper for mapping custom keybindings
local function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Disable highlighting after enter
map("n", "<CR>", ":noh<CR><CR>", nil)
-- Next window
map("n", "<leader>ne", ":wincmd l<CR>", nil)
map("n", "<leader>b", ":wincmd h<CR>", nil)

local fallback_live_grep = function()
    vim.cmd(':Telescope live_grep')
end

local op = function(input_node)
    local node = input_node or require("nvim-tree.lib").get_node_at_cursor()
    if node == nil then
        fallback_live_grep()
        return
    end
    local absolute_path = node.absolute_path
    if absolute_path == nil then
        fallback_live_grep()
        return
    end
    local cwd = require("nvim-tree.core").get_cwd()
    if cwd == nil then
        fallback_live_grep()
        return
    end
    local utils = require("nvim-tree.utils")

    local relative_path = utils.path_relative(absolute_path, cwd)
    local content = node.nodes ~= nil and utils.path_add_trailing(relative_path) or relative_path
    --require("nvim-tree.notify").info("Copy!")
    vim.cmd(string.format(':Telescope live_grep search_dirs=./%s', content))
end

-- Reload files in file tree
map("n", "<leader>nvr", ":NvimTreeRefresh<CR>", nil)
-- Switch focus to file tree
map("n", "<leader>nvt", ":NvimTreeFocus<CR>", nil)
-- Open current file in tree
map("n", "<leader>nvo", ":NvimTreeFindFile<CR>", nil)
-- Collapse all files in tree
map("n", "<leader>nvc", ":NvimTreeCollapse<CR>", nil)
-- Open telescope live grep at current nvt location if present
vim.keymap.set("n", "<leader>nvf", op, nil)

-- Open telescope live grep (Ctrl+Shift+f)
map("n", "<C-S-f>", ":Telescope live_grep<CR>", nil)

-- Open telescope live grep (Ctrl+Shift+f)
-- map("n", "<C-S-f>", ":Telescope live_grep", nil)
-- Open telescope file finder
map("n", "<leader>ff", ":Telescope find_files<CR>", nil)

-- Toggle aerial
map("n", "<leader>aet", ":AerialToggle!<CR>", nil)

-- Toggle Trouble
map("n", "<leader>tt", ":Trouble split_preview toggle<CR>", nil)
map("n", "<leader>to", ":Trouble split_preview focus<CR>", nil)

-- Toggle terminal
map("n", "<C-S-t>", ":ToggleTerm size=15<CR>", nil)
-- nnoremap <F33> :TermExec size=15 cmd='cargo test -- --nocapture'<CR>
-- nnoremap <F29> :TermExec size=15 cmd='cargo build --release'<CR>

-- Bar nav
map("n", "<Tab>", ":BufferNext<CR>", nil)
map("n", "<S-Tab>", ":BufferPrevious<CR>", nil)
map("n", "<C-c>", ":BufferClose<CR>", nil)

-- Diffview
map("n", "<leader>dvo", ":DiffviewOpen<CR>", nil)
map("n", "<leader>dvc", ":DiffviewClose<CR>", nil)
map("n", "<leader>dvf", ":DiffviewFileHistory %<CR>", nil)

-- Telescope search for word under cursor
map("n", "gs", ":Telescope grep_string<CR>")
map("x", "gs", "<ESC>:Telescope grep_string<CR>")

vim.keymap.set("n", "<leader>tdo", function()
    require("util.telescope_diff_picker").diff_file_picker("~/.local/bin/difft", true)
end, nil)
vim.keymap.set("n", "<leader>tde", function()
    require("util.telescope_diff_picker").diff_file_picker("~/.local/bin/difft", false)
end, nil)
vim.keymap.set("n", "<leader>tgo", function()
    require("util.telescope_diff_picker").diff_file_picker(nil, true)
end, nil)
vim.keymap.set("n", "<leader>tge", function()
    require("util.telescope_diff_picker").diff_file_picker(nil, false)
end, nil)


