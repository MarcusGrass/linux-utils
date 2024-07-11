local cfg = function()
    --- Completion https://github.com/hrsh7th/nvim-cmp#basic-configuration
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
            { name = 'crates' },
        },
    })
end

return {
    {
        'hrsh7th/nvim-cmp',
        config = cfg,
        dependencies = {
            'hrsh7th/vim-vsnip',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-vsnip',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-cmdline',
            'windwp/nvim-autopairs',
        },
    },

}
