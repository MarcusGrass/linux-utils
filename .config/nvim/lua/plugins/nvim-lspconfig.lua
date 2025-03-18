-- Lsp
return {
    "neovim/nvim-lspconfig",
    config = function()
        local slf = require("lspconfig")
        local on_attach = require("util.lsp_attach").lsp_do_attach
        local status = require("lsp-status")
        status.register_progress()
        local lsp_on_attach = function(client, bufnr)
            on_attach(client, bufnr)
            status.on_attach(client, bufnr)
        end
        local status_capabilities = status.capabilities
        local all_capabilities = require("blink.cmp").get_lsp_capabilities(status_capabilities)
        slf.harper_ls.setup({
            on_attach = lsp_on_attach,
            settings = {
                ["harper-ls"] = {
                    userDictPath = "~/.config/nvim/spell/harper",
                },
            },
        })
        slf.gopls.setup({
            on_attach = lsp_on_attach,
        })
        slf.lua_ls.setup({
            capabilities = all_capabilities,
            on_init = function(client)
                local path = client.workspace_folders[1].name
                if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
                    return
                end

                client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                    runtime = {
                        -- Tell the language server which version of Lua you're using
                        -- (most likely LuaJIT in the case of Neovim)
                        version = "LuaJIT",
                    },
                    -- Make the server aware of Neovim runtime files
                    workspace = {
                        checkThirdParty = false,
                        library = {
                            vim.env.VIMRUNTIME,
                            -- Depending on the usage, you might want to add additional paths here.
                            -- "${3rd}/luv/library"
                            -- "${3rd}/busted/library",
                        },
                        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                        -- library = vim.api.nvim_get_runtime_file("", true)
                    },
                    format = {
                        enable = false,
                    },
                })
            end,
            on_attach = lsp_on_attach,
            settings = {
                Lua = {},
            },
        })
        slf.pylsp.setup({
            capabilities = all_capabilities,
            on_attach = lsp_on_attach,
        })
        require("ccls").setup({
            lsp = {
                server = {
                    capabilities = all_capabilities,
                    name = "ccls",
                    cmd = { "/usr/bin/ccls" },
                    init_options = {
                        cache = {
                            directory = vim.fs.normalize("~/.cache/ccls/"),
                        },
                    },
                    root_dir = vim.fs.dirname(vim.fs.find({ "compile_commands.json", ".git" }, { upward = true })[1]), -- or some other function that returns a string
                    on_attach = lsp_on_attach,
                    --capabilities = my_caps_table_or_func
                },
            },
        })
        vim.g.rustaceanvim = {
            tools = {
                enable_clippy = true,
                float_win_config = {
                    auto_focus = true,
                },
            },
            server = {
                auto_attach = true,
                on_attach = lsp_on_attach,
                default_settings = {
                    ["rust-analyzer"] = {
                        capabilities = all_capabilities,
                        -- enable clippy on save
                        checkOnSave = true,
                        inlayHints = {
                            -- never truncate inlay hints
                            maxLength = 9999,
                        },
                    },
                },
            },
        }
    end,
}
