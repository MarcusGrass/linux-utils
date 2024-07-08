return {
    --- Theme ---
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    --- Functionality ---
    -- Automatically insert pairs (eg. <>)
    { 'windwp/nvim-autopairs', event = "InsertEnter", config = true },

    --- Language Meta ---
    -- Lsp
    { 'neovim/nvim-lspconfig' },

    -- Snippet engine
    { 'hrsh7th/vim-vsnip' },

    -- Language specific highlighting
    {
        'nvim-treesitter/nvim-treesitter',
        build = ":TSUpdate",
        tag = "v0.9.2",
    },

    --- Completion sources ---
    { 'hrsh7th/nvim-cmp' },
    -- Lsp completion
    { 'hrsh7th/cmp-nvim-lsp' },
    -- Snippet completion
    { 'hrsh7th/cmp-vsnip' },
    -- Other completion sources
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-cmdline' },

    --- Language: Rust ---
    -- Rust configuration
    { 
        'mrcjkb/rustaceanvim',
        version = "^4",
        lazy = false ,
    },
    -- Cargo tools
    { 
        'saecki/crates.nvim',
        tag = "stable",
        config = function() 
            require('crates').setup()
        end
    },
    -- Test
    {
        "nvim-neotest/neotest",
        opts = {
            adapters = {
                ["rustaceanvim.neotest"] = {}
            }
        },
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter",
        }
    },

    --- Language: Zig --
    { 'ziglang/zig.vim' },

    --- Git ---
    -- TODO: Check
    { 'airblade/vim-gitgutter' },
    -- Diffing
    { 'sindrets/diffview.nvim' },

    --- Directories ---
    -- File icons
    { 'kyazdani42/nvim-web-devicons' },
    -- Tree viewer 
    { 'kyazdani42/nvim-tree.lua' },

    --- Fuzzy find ---
    { 
        'nvim-telescope/telescope.nvim',
        branch = "0.1.x",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- Status line lsp progress
    { 'nvim-lua/lsp-status.nvim' },

    -- Symbol window
    { 'stevearc/aerial.nvim' },

    -- Airline bottom bar
    { 
        'nvim-lualine/lualine.nvim',
        requires = "nvim-tree/nvim-web-devicons",
    },

    { 'arkav/lualine-lsp-progress' },
    -- Tab bar
    --
    { 'romgrk/barbar.nvim' },

    -- Term 
    { 'akinsho/toggleterm.nvim' },

}
