call plug#begin('~/.config/nvim/plugged')
" Collection of common configurations for the Nvim LSP client
Plug 'neovim/nvim-lspconfig'

" Completion framework
Plug 'hrsh7th/nvim-cmp'

" LSP completion source for nvim-cmp
Plug 'hrsh7th/cmp-nvim-lsp'

" Snippet completion source for nvim-cmp
Plug 'hrsh7th/cmp-vsnip'

" Other usefull completion sources
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-cmdline'

" See hrsh7th's other plugins for more completion sources!

" To enable more of the features of rust-analyzer, such as inlay hints and more!
Plug 'simrat39/rust-tools.nvim'

" Snippet engine
Plug 'hrsh7th/vim-vsnip'

" Fuzzy finder
" Optional
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Directory
Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'kyazdani42/nvim-tree.lua'

" Autopair brackets etc
Plug 'windwp/nvim-autopairs'

" Toggle term
Plug 'akinsho/toggleterm.nvim'
" Tabs
Plug 'kyazdani42/nvim-web-devicons'
Plug 'romgrk/barbar.nvim'
" Airline
Plug 'nvim-lualine/lualine.nvim'
" Tag bar
Plug 'stevearc/aerial.nvim'
call plug#end()
" =======================================
" ===============General=================
" =======================================

" Shared clipboard with rest of system
set clipboard^=unnamed,unnamedplus

" TextEdit might fail if hidden is not set.
set hidden
set lazyredraw
set mouse=n

set scrolljump=10                  " Scroll more than one line
set scrolloff=5                   " Minimum lines to keep above or below the cursor when scrolling

" searching
set hlsearch                      " Highlight search matches
set ignorecase                    " Do case insensitive search unless there are capital letters
set incsearch                     " Perform incremental searching
set smartcase

" indentation
set expandtab                     " Indent with spaces
set shiftwidth=4                  " Number of spaces to use when indenting
set smartindent                   " Auto indent new lines
set softtabstop=4                 " Number of spaces a <tab> counts for when inserting
set tabstop=4                     " Number of spaces a <tab> counts for
set number

" Disable highlight after search
nnoremap <CR> :noh<CR><CR>

" =======================================
" ==========Convenience plugs============
" =======================================
" TreeSitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
    highlight = {
        enable = true,
        disable = {},
    },
    ensure_installed = {
        "toml",
        "bash",
        "json",
        "yaml",
        "python"
    }
}
EOF
" lualine
lua <<EOF
require('lualine').setup()
EOF
lua <<EOF
require'nvim-tree'.setup {
  open_on_setup       = true,
  auto_close          = false,
  open_on_tab         = true,
  update_to_buf_dir   = {
    enable = true,
    auto_open = true,
  },
  git = {
    enable = true,
    ignore = true,
    timeout = 500,
  },
}
EOF
" Maybe autostart unfocused
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * NvimTreeToggle
autocmd VimEnter * if argc() > 0 || exists("s:std_in") | wincmd p | endif

" Toggleterm
lua <<EOF

require'toggleterm'.setup{
  shade_terminals = true,
  close_on_exit = true,
  size = 60
}

function _G.set_terminal_keymaps()
  local opts = {noremap = true}
  vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
EOF
nnoremap <C-t> :ToggleTerm size=15<CR>
nnoremap <F33> :TermExec size=15 cmd='cargo build'<CR>
nnoremap <F29> :TermExec size=15 cmd='cargo build --release'<CR>
"Bar bar
nnoremap <silent> <Tab> :BufferNext<CR>
nnoremap <silent> <S-Tab> :BufferPrevious<CR>
nnoremap <silent> <C-c> :BufferClose<CR>

" Telescope
lua <<EOF
local actions = require('telescope.actions')
require('telescope').setup{
  defaults = {
    mappings = {
      n = {
        ["q"] = actions.close
      },
    },
  }
}
EOF
nnoremap <C-S-F> :Telescope live_grep<CR>
nnoremap <C-G> :Telescope find_files<CR>
"aerial
nnoremap <C-s> :AerialToggle!<CR>

lua <<EOF
-- Call the setup function to change the default behavior
require("aerial").setup({
  -- Priority list of preferred backends for aerial.
  -- This can be a filetype map (see :help aerial-filetype-map)
  backends = { "lsp", "treesitter", "markdown" },

  -- Enum: persist, close, auto, global
  --   persist - aerial window will stay open until closed
  --   close   - aerial window will close when original file is no longer visible
  --   auto    - aerial window will stay open as long as there is a visible
  --             buffer to attach to
  --   global  - same as 'persist', and will always show symbols for the current buffer
  close_behavior = "auto",

  -- Set to false to remove the default keybindings for the aerial buffer
  default_bindings = true,

  -- Enum: prefer_right, prefer_left, right, left, float
  -- Determines the default direction to open the aerial window. The 'prefer'
  -- options will open the window in the other direction *if* there is a
  -- different buffer in the way of the preferred direction
  default_direction = "prefer_right",

  -- Disable aerial on files with this many lines
  disable_max_lines = 10000,

  -- A list of all symbols to display. Set to false to display all symbols.
  -- This can be a filetype map (see :help aerial-filetype-map)
  -- To see all available values, see :help SymbolKind
  filter_kind = false,
  -- Automatically open aerial when entering supported buffers.
  -- This can be a function (see :help aerial-open-automatic)
  open_automatic = true,
  -- Run this command after jumping to a symbol (false will disable)
  post_jump_cmd = "normal! zz",

})
EOF
" =======================================
" ============Language server============
" =======================================


" Set completeopt to have a better completion experience
" :help completeopt
" menuone: popup even when there's only one match
" noinsert: Do not insert text until a selection is made
" noselect: Do not select, force user to select one from the menu
set completeopt=menu,menuone,noinsert,noselect

" Avoid showing extra messages when using completion
set shortmess+=c

" Configure LSP through rust-tools.nvim plugin.
" rust-tools will configure and enable certain LSP features for us.
" See https://github.com/simrat39/rust-tools.nvim#configuration
lua <<EOF
local nvim_lsp = require'lspconfig'

local lsp_cfg_opts = { noremap=true, silent=true }
local do_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'ga', '<cmd>lua require(\'telescope.builtin\').lsp_code_actions()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gA', '<cmd>lua require(\'telescope.builtin\').lsp_range_code_actions()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua require(\'telescope.builtin\').lsp_definitions()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua require(\'telescope.builtin\').lsp_references()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua require(\'telescope.builtin\').lsp_implementations()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gW', '<cmd>lua require(\'telescope.builtin\').lsp_workspace_symbols()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'g0', '<cmd>lua require(\'telescope.builtin\').lsp_document_symbols()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<S-r>', '<cmd>lua vim.lsp.buf.rename()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', lsp_cfg_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', lsp_cfg_opts)
  require("aerial").on_attach(client, bufnr)
end
local opts = {
    tools = { -- rust-tools options
        autoSetHints = true,
        hover_with_actions = true,
        inlay_hints = {
            show_parameter_hints = false,
            parameter_hints_prefix = "",
            other_hints_prefix = "",
        },
    },

    -- all the opts to send to nvim-lspconfig
    -- these override the defaults set by rust-tools.nvim
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#rust_analyzer
    server = {
        -- on_attach is a callback called when the language server attachs to the buffer
        on_attach = on_attach,
        settings = {
            -- to enable rust-analyzer settings visit:
            -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
            ["rust-analyzer"] = {
                -- enable clippy on save
                checkOnSave = {
                    command = "clippy"
                },
            }
        }
    },
}
require('rust-tools').setup(opts)
require('nvim-autopairs').setup{}

EOF

" Setup Completion
" See https://github.com/hrsh7th/nvim-cmp#basic-configuration
lua <<EOF
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require'cmp'
cmp.event:on( 'confirm_done', cmp_autopairs.on_confirm_done({ map_char = { tex = ''} }))
cmp.setup({
  -- Enable LSP snippets
  snippet = {
    expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    -- Add tab support
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    })
  },

  -- Installed sources
  sources = {
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'path' },
    { name = 'buffer' },
  },
})
EOF

" Set updatetime for CursorHold
" 300ms of no cursor movement to trigger CursorHold
set updatetime=300
" Show diagnostic popup on cursor hold
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })

" Goto previous/next diagnostic warning/error
nnoremap <silent> g[ <cmd>lua vim.diagnostic.goto_prev()<CR>
nnoremap <silent> g] <cmd>lua vim.diagnostic.goto_next()<CR>

" have a fixed column for the diagnostics to appear in
" this removes the jitter when warnings/errors flow in
set signcolumn=yes:1

" format on write
autocmd BufWritePre *.rs lua vim.lsp.buf.formatting_sync(nil, 200)


