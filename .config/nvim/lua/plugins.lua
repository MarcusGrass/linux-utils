local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    --- Functionality ---
    -- Automatically insert pairs (eg. <>)
    use 'windwp/nvim-autopairs'

    --- Language Meta ---
    -- Lsp
    use 'neovim/nvim-lspconfig'
    -- Snippet engine
    use 'hrsh7th/vim-vsnip'
    -- Language specific highlighting
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    }

    --- Completion sources ---
    use 'hrsh7th/nvim-cmp'
    -- Lsp completion
    use 'hrsh7th/cmp-nvim-lsp'
    -- Snippet completion
    use 'hrsh7th/cmp-vsnip'
    -- Other completion sources
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-cmdline'

    --- Language: Rust ---
    -- Rust configuration
    use 'simrat39/rust-tools.nvim'
    -- Cargo tools TODO: Check
    use 'saecki/crates.nvim'

    --- Language: Zig --
    -- TODO: Check
    use 'ziglang/zig.vim'

    --- Git ---
    -- TODO: Check
    use 'airblade/vim-gitgutter'
    -- TODO: Check
    use 'sindrets/diffview.nvim'

    --- Directories ---
    -- File icons TODO: Check
    use 'kyazdani42/nvim-web-devicons'
    -- Tree viewer TODO: Check
    use 'kyazdani42/nvim-tree.lua'

    --- Fuzzy find ---
    -- TODO: Check all
    use 'nvim-lua/popup.nvim'
    use 'nvim-lua/plenary.nvim'
    use 'nvim-telescope/telescope.nvim'

    --- Cosmetic ---
    -- Vim one theme
    use 'rakr/vim-one'

    -- Status line lsp progress
    use 'nvim-lua/lsp-status.nvim'
    -- Symbol window
    use 'stevearc/aerial.nvim'
    -- Airline bottom bar
    use 'nvim-lualine/lualine.nvim'
    use 'arkav/lualine-lsp-progress'
    -- Tab bar
    use 'romgrk/barbar.nvim'
    -- Term Todo: Check
    use 'akinsho/toggleterm.nvim'

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if packer_bootstrap then
        require('packer').sync()
    end
end)