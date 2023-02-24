require'lspconfig'.perlnavigator.setup {
    settings = {
        perlnavigator = {
            perlPath = '/usr/bin/perl',
            enableWarnings = true,
            perltidyProfile = '',
            perlcriticProfile = '',
            perlcriticEnabled = true,
        }
    }
}
