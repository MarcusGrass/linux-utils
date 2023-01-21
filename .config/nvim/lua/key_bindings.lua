-- Functional wrapper for mapping custom keybindings
function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Disable highlighting after enter
map('n', '<CR>', ':noh<CR><CR>', nil)
-- Next window
map('n', '<leader>ne', ':wincmd l<CR>', nil)
map('n', '<leader>b', ':wincmd h<CR>', nil)
-- Go to next in gitgutter
map('n', '<leader>j', ':GitGutterNextHunk<CR>', nil)
map('n', '<leader>k', ':GitGutterPrevHunk<CR>', nil)

-- Reload files in file tree
map('n', '<leader>nvr', ':NvimTreeRefresh<CR>', nil)
-- Switch focus to file tree
map('n', '<leader>nvt', '::NvimTreeFocus<CR>', nil)

-- Open telescope live grep (Ctrl+Shift+f)
map('n', '<C-S-f>', ':Telescope live_grep<CR>', nil)
-- Open telescope file finder (Ctrl+g)
map('n', '<C-g>', ':Telescope find_files<CR>', nil)

-- Toggle aerial
map('n', '<C-s>', ':AerialToggle!<CR>', nil)

-- Toggle terminal
map('n', '<C-t>', ':ToggleTerm size=15<CR>', nil)
-- nnoremap <F33> :TermExec size=15 cmd='cargo test -- --nocapture'<CR>
-- nnoremap <F29> :TermExec size=15 cmd='cargo build --release'<CR>

-- Bar nav
map('n', '<Tab>', ":BufferNext<CR>", nil)
map('n', '<S-Tab>', ":BufferPrevious<CR>", nil)
map('n', '<C-c>', ":BufferClose<CR>", nil)