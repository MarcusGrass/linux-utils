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

vim.keymap.set("n", "<leader>no", function()
    local reveal_file = vim.fn.expand("%:p")
    if reveal_file == "" then
        reveal_file = vim.fn.getcwd()
    else
        local f = io.open(reveal_file, "r")
        if f then
            f.close(f)
        else
            reveal_file = vim.fn.getcwd()
        end
    end
    require("neo-tree.command").execute({
        action = "focus", -- OPTIONAL, this is the default value
        source = "filesystem", -- OPTIONAL, this is the default value
        position = "left", -- OPTIONAL, this is the default value
        reveal_file = reveal_file, -- path to file or folder to reveal
    })
end, { desc = "Open neo-tree at current file or working directory" })

--- Try to open to current buffer in a new tab.
--- Preserves location.
--- Preserves the old buffer in the old tab.
--- Mostly used for browsing dependencies separately, after navigating to a file in the dependency.
vim.keymap.set("n", "<leader>nn", function()
    local cur_buf = vim.fn.expand("%")
    if cur_buf == "" then
        vim.notify("Buf with no name, can't go-to", vim.log.levels.WARN)
        return
    end
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    local f = io.open(cur_buf, "r")
    if f then
        f.close(f)
    else
        vim.notify(string.format("failed to open %s can't go-to", cur_buf), vim.log.levels.WARN)
        return
    end
    vim.cmd(string.format(":tabnew %s", cur_buf))
    vim.api.nvim_win_set_cursor(0, { line, col })
    require("neo-tree.command").execute({
        action = "show", -- OPTIONAL, this is the default value
        source = "filesystem", -- OPTIONAL, this is the default value
        position = "left", -- OPTIONAL, this is the default value
        reveal_file = cur_buf, -- path to file or folder to reveal
        reveal_force_cwd = true, -- switch cwd without asking
    })
end, { desc = "Open neo-tree at current file or working directory" })

-- Switch focus to file tree
map("n", "<leader>nt", ":Neotree focus<CR>", nil)
-- Switch focus to file tree
map("n", "<leader>nb", ":Neotree focus buffers<CR>", nil)
map("n", "<leader>ng", ":Neotree focus git_status<CR>", nil)
-- Collapse all files in tree
map("n", "<leader>nc", ":Neotree close<CR>", nil)

-- Open edgy left panel
map("n", "<leader>eo", ':lua require("edgy").open()<CR>')
map("n", "<leader>ec", ':lua require("edgy").close("left")<CR>')
map("n", "<leader>em", ':lua require("edgy").goto_main()<CR>')

-- Open snacks grep (Ctrl+Shift+f)
map("n", "<C-S-f>", ':lua Snacks.picker.pick("grep")<CR>', nil)

-- Open snacks file finder
map("n", "<leader>ff", ':lua Snacks.picker.pick("files")<CR>', nil)
-- Open snacks buffer finder
map("n", "<leader>fb", ':lua Snacks.picker.pick("buffers")<CR>', nil)

-- Toggle aerial
map("n", "<leader>aet", ":AerialToggle!<CR>", nil)

-- Toggle Trouble
map("n", "<leader>tt", ":Trouble split_preview toggle<CR>", nil)
map("n", "<leader>to", ":Trouble split_preview focus<CR>", nil)

map("n", "<leader>gt", ":lua Snacks.terminal.toggle()<CR>", nil)
-- Toggle terminal
map("n", "<C-S-t>", ":lua Snacks.terminal.toggle()<CR>", nil)
-- nnoremap <F33> :TermExec size=15 cmd='cargo test -- --nocapture'<CR>
-- nnoremap <F29> :TermExec size=15 cmd='cargo build --release'<CR>

-- Bar nav
map("n", "<Tab>", ":tabnext<CR>", nil)
map("n", "<S-Tab>", ":tabprev<CR>", nil)
map("n", "<leader>tc", ":tabclose<CR>", nil)
-- Use del to navigate between windows
map("n", "<C-H>", "<C-w>w", nil)
map("n", "<C-S-H>", "<C-w>W", nil)
map("n", "<C-c>", ":lua Snacks.bufdelete.delete()<CR>", nil)
map("n", "<leader>bd", ":lua Snacks.bufdelete.other()<CR>", nil)

-- Diffview
map("n", "<leader>do", ":DiffviewOpen<CR>", nil)
map("n", "<leader>dc", ":DiffviewClose<CR>", nil)
map("n", "<leader>df", ":DiffviewFileHistory %<CR>", nil)

-- Gitsigns
map("n", "]g", ":Gitsigns next_hunk<CR>", nil)
map("n", "[g", ":Gitsigns prev_hunk<CR>", nil)
map("n", "<leader>gph", ":Gitsigns preview_hunk<CR>", nil)
map("n", "<leader>gpi", ":Gitsigns preview_hunk_inline<CR>", nil)
map("n", "<leader>gsh", ":Gitsigns select_hunk<CR>", nil)
map("n", "<leader>gbo", ":Gitsigns blame<CR>", nil)
map("n", "<leader>gbi", ":Gitsigns blame_line<CR>", nil)
map("n", "<leader>grh", ":Gitsigns reset_hunk<CR>", nil)
map("n", "<leader>grb", ":Gitsigns reset_buffer<CR>", nil)
map("n", "<leader>gsh", ":Gitsigns stage_hunk<CR>", nil)
map("n", "<leader>gsb", ":Gitsigns stage_buffer<CR>", nil)

-- Fugitive
map("n", "<leader>gfo", ":Git<CR>")
map("n", "<leader>gff", ":Git fetch<CR>")
map("n", "<leader>gfp", ":Git push<CR>")

-- Picker search for word under cursor
map("n", "gs", ':lua Snacks.picker.pick("grep_word")<CR>')
map("x", "gs", '<ESC>:lua Snacks.picker.pick("grep_word")<CR>')
vim.keymap.set("n", "<leader>tdo", function()
    require("plug-ext.snacks.diff-picker").snacks_diff_file_picker("~/.local/bin/difft", true, false)
end, nil)
vim.keymap.set("n", "<leader>tde", function()
    require("plug-ext.snacks.diff-picker").snacks_diff_file_picker("~/.local/bin/difft", false, false)
end, nil)
vim.keymap.set("n", "<leader>tdu", function()
    require("plug-ext.snacks.diff-picker").snacks_diff_file_picker("~/.local/bin/difft", false, true)
end, nil)
vim.keymap.set("n", "<leader>tgo", function()
    require("plug-ext.snacks.diff-picker").snacks_diff_file_picker(nil, true, false)
end, nil)
vim.keymap.set("n", "<leader>tge", function()
    require("plug-ext.snacks.diff-picker").snacks_diff_file_picker(nil, false, false)
end, nil)
vim.keymap.set("n", "<leader>tgu", function()
    require("plug-ext.snacks.diff-picker").snacks_diff_file_picker(nil, false, true)
end, nil)
