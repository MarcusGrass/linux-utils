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

-- Bar nav
key.mapn("<Tab>", ":tabnext<CR>")
key.mapn("<S-Tab>", ":tabprev<CR>")
key.mapn("<leader>tc", ":tabclose<CR>")

-- Use del to navigate between windows
key.mapn("<C-H>", "<C-w>W")
key.mapn("<C-S-H>", "<C-w>w")
