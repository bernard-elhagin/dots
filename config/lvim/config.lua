lvim.log.level = "warn"
lvim.format_on_save.enabled = false
--lvim.colorscheme = 'pinkmare'
lvim.colorscheme = 'rose-pine'

reload("bertold.settings")
reload("bertold.mappings")
reload("bertold.plugin_overrides")
reload("bertold.plugins")
reload("bertold.treesitter")
reload("bertold.telescope")

require'lspconfig'.perlpls.setup{}
