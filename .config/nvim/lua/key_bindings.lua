local key = require("util.keymap")
-- Disable highlighting after enter
key.mapn("<CR>", ":noh<CR><CR>")
-- Next window
key.mapn("<leader>ne", ":wincmd l<CR>")
key.mapn("<leader>b", ":wincmd h<CR>")

-- Send window to bottom
key.mapn("<leader>wb", "<C-W>J")
-- Send bottom window to top left
key.mapn("<leader>wt", "<C-W>H")
-- Equalize all windows horisontally
key.mapn("<leader>wh", ":horizontal wincmd =<CR>")
-- Equalize all windows vertically
key.mapn("<leader>wv", ":vertical wincmd =<CR>")

-- Open snacks grep (Ctrl+Shift+f)
key.mapn("<C-S-f>", ':lua Snacks.picker.pick("grep")<CR>')

-- Open snacks file finder
key.mapn("<leader>ff", ':lua Snacks.picker.pick("files")<CR>')
-- Open snacks git file finder (when there's a bunch of files in e.g. ./target), could restrict to cwd
key.mapn("<leader>fg", ':lua Snacks.picker.pick("git_files")<CR>')

-- Open snacks buffer finder
key.mapn("<leader>fb", ':lua Snacks.picker.pick("buffers")<CR>')
-- Toggle aerial
key.mapn("<leader>aet", ":AerialToggle!<CR>")

-- Toggle Trouble
key.mapn("<leader>tt", ":Trouble split_preview toggle<CR>")
key.mapn("<leader>to", ":Trouble split_preview focus<CR>")

key.mapn("<leader>gt", ":lua Snacks.terminal.toggle()<CR>")
-- Toggle terminal
key.mapn("<C-S-t>", ":lua Snacks.terminal.toggle()<CR>")
-- nnoremap <F33> :TermExec size=15 cmd='cargo test -- --nocapture'<CR>
-- nnoremap <F29> :TermExec size=15 cmd='cargo build --release'<CR>

-- Bar nav
key.mapn("<Tab>", ":tabnext<CR>")
key.mapn("<S-Tab>", ":tabprev<CR>")
key.mapn("<leader>tc", ":tabclose<CR>")

-- Use del to navigate between windows
key.mapn("<C-H>", "<C-w>W")
key.mapn("<C-S-H>", "<C-w>w")
key.mapn("<C-c>", ":lua Snacks.bufdelete.delete()<CR>")
key.mapn("<leader>bd", ":lua Snacks.bufdelete.other()<CR>")

-- Diffview
key.mapn("<leader>do", ":DiffviewOpen<CR>")
key.mapn("<leader>dc", ":DiffviewClose<CR>")
key.mapn("<leader>df", ":DiffviewFileHistory %<CR>")

-- Gitsigns
key.mapn("]g", ":Gitsigns next_hunk<CR>")
key.mapn("[g", ":Gitsigns prev_hunk<CR>")
key.mapn("<leader>gph", ":Gitsigns preview_hunk<CR>")
key.mapn("<leader>gpi", ":Gitsigns preview_hunk_inline<CR>")
key.mapn("<leader>gsh", ":Gitsigns select_hunk<CR>")
key.mapn("<leader>gbo", ":Gitsigns blame<CR>")
key.mapn("<leader>gbi", ":Gitsigns blame_line<CR>")
key.mapn("<leader>grh", ":Gitsigns reset_hunk<CR>")
key.mapn("<leader>grb", ":Gitsigns reset_buffer<CR>")
key.mapn("<leader>gsh", ":Gitsigns stage_hunk<CR>")
key.mapn("<leader>gsb", ":Gitsigns stage_buffer<CR>")

-- Fugitive
key.mapn("<leader>gfo", ":Git<CR>")
key.mapn("<leader>gff", ":Git fetch<CR>")
key.mapn("<leader>gfp", ":Git push<CR>")
key.mapnfn("<leader>gfr", function()
    vim.cmd(":Git fetch")
    vim.cmd(":Git rebase -i origin/main")
end)

-- Picker search for word under cursor
key.mapn("gs", ':lua Snacks.picker.pick("grep_word")<CR>')
key.map("x", "gs", '<ESC>:lua Snacks.picker.pick("grep_word")<CR>')
