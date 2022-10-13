require "lspsaga".init_lsp_saga {
    --border_style = "single",
    saga_winblend = 20,
    -- float_term = {
    --     winblend = 25,
    --     shadow_background = false,
    -- },
    move_in_saga = { next = '<C-n>', prev = '<C-p>' },
    --move_in_saga = { prev = "k", next = "j" },
    scroll_in_preview = {
    scroll_down = "<C-d>",
    scroll_up = "<C-u>",
  },
    diagnostic_header = { " ", " ", " ", " " },
    -- add bracket or something with diagnostic source, just have 2 elements
    -- use emoji lightbulb in default
    code_action_icon = "",
    --code_action_icon = "ﯦ ",
    -- if true can press number to execute the codeaction in codeaction window
    code_action_num_shortcut = true,
    -- same as nvim-lightbulb but async
    code_action_lightbulb = {
        enable = false,
        sign = false,
        sign_priority = 20, --
        virtual_text = true,
    },
    finder_icons = {
        def = "  ",
        ref = "  ",
        link = "  ",
    },
    -- preview lines of lsp_finder and definition preview
    max_preview_lines = 5,
    definition_action_keys = {
        edit = '<CR>',
        vsplit = '<C-y>',
        split = '<C-x>',
        tabe = '<C-t>',
        quit = '<ESC>',
    },
    -- definition_preview_quit = '<ESC>',
    -- finder_preview_hl_ns = 8,
    finder_action_keys = {
        open = "o",
        vsplit = "v",
        split = "s",
        tabe = "t",
        quit = "<ESC>",
        scroll_down = "<C-j>",
        scroll_up = "<C-k>", -- quit can be a table
    },
    code_action_keys = {
        quit = "<ESC>",
        exec = "l",
    },
    rename_action_quit = "<ESC>",
    rename_in_select = true,
    symbol_in_winbar = {
        enable = true,
        in_custom = false,
        --in_custom = true,
        separator = '  ',
        --show_file = false,
        show_file = true,
        click_support = false,
    },
    show_outline = {
        win_position = 'right',
        --set special filetype win that outline window split.like NvimTree neotree
        -- defx, db_ui
        min_with = '',
        win_width = 40,
        auto_enter = false,
        auto_preview = true,
        virt_text = 'x',
        jump_key = 'l',
        -- auto refresh when change buffer
        auto_refresh = true,
    },
    custom_kind = {
        File          =  { " " },
        Module        =  { " " },
        Namespace     =  { "ﱕ " },
        Package       =  { " " },
        Class         =  { "ﴯ " },
        Method        =  { "" },
        Property      =  { "ﰠ " },
        Field         =  { "ﰠ " },
        Constructor   =  { " " },
        Enum          =  { " " },
        Interface     =  { " " },
        Function      =  { " " },
        Variable      =  { " " },
        Constant      =  { " " },
        String        =  { " " },
        Number        =  { " " },
        Boolean       =  { " " },
        Array         =  { " " },
        Object        =  { " " },
        Key           =  { "- " },
        Null          =  { " " },
        EnumMember    =  { " " },
        Struct        =  { " " },
        Event         =  { " " },
        Operator      =  { " " },
        TypeParameter =  { " " },
        TypeAlias     =  { " " },
        Parameter     =  { " " },
        StaticMethod  =  { " " },
        Macro         =  { "廓" },
    },
}

 -- Mappings.
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "gd", "<CMD>Lspsaga peek_definition<CR>", opts)
--map("n", "gp", "<Cmd>Lspsaga peek_definition<CR>", opts)
map("n", "gi", "<CMD>Lspsaga lsp_finder<CR>", opts)
--map("n", "gh", "<CMD>Lspsaga hover_doc<CR>", opts)
map("n", "gs", "<CMD>Lspsaga signature_help<CR>", opts)
map("n", "ga",    "<CMD>Lspsaga code_action<CR>",             opts)
map("v", "ga",    "<CMD><C-u>Lspsaga range_code_action<CR>",  opts)
map("n", "gl",    "<CMD>Lspsaga show_line_diagnostics<CR>",   opts)
map("n", "go",    "<CMD>Lspsaga open_floaterm fish<CR>", opts)
map("n", ";D",    "<CMD>Lspsaga show_cursor_diagnostics<CR>", opts)
map("n", "<gr>", "<CMD>Lspsaga rename<CR>",               opts)
map("n", "gk", "<CMD>Lspsaga diagnostic_jump_prev<CR>", opts)
map("n", "gj", "<CMD>Lspsaga diagnostic_jump_next<CR>", opts)
map("n", "[d", "<Cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
map("n", "]d", "<Cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
map("t", "<ESC>", "<CMD>Lspsaga close_floaterm<CR>", opts)




-- vim.keymap.set("n", "<C-f>", function() require "lspsaga.action".smart_scroll_with_saga(1) end, opts)
-- vim.keymap.set("n", "<C-b>", function() require "lspsaga.action".smart_scroll_with_saga(-1) end, opts)



vim.api.nvim_set_hl(0, "LspSagaHoverBorder",             { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaTermBorder",              { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspFloatWinBorder",              { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaAutoPrew",                { bg = "NONE", fg = "#BBE73D", })
vim.api.nvim_set_hl(0, "LspSagaAutoPreview",             { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaBorderTitle",             { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaCodeActionBorder",        { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaCodeActionContent",       { bg = "NONE", fg = "#000000", })
vim.api.nvim_set_hl(0, "LspSagaCodeActionTitle",           { bg = "NONE", fg = "#000000", })
vim.api.nvim_set_hl(0, "LspSagaCodeActionTrunCateLine",    { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "DefinitionBorder",                 { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "DefinitionArror",                  { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "DefinitionSearch",                 { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "DefinitionFile",                   { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticSource",          { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticQuickFix",        { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticMap",             { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticLineCol",         { bg = "NONE", fg = "#929292", })

vim.api.nvim_set_hl(0, "LspSagaDiagnosticBorder",          { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticHeader",          { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticError",           { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticWarn",            { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticInfo",            { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticHint",            { bg = "NONE", fg = "#929292", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticSource",          { bg = "NONE", fg = "#C53B82", })
vim.api.nvim_set_hl(0, "LspSagaDiagnosticTruncateLine",    { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaErrorTrunCateLine",         { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaFinderSelection",           { bg = "NONE", fg = "#888888", })
vim.api.nvim_set_hl(0, "LspSagaHintTrunCateLine",          { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaHoverTrunCateLine",         { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaInfoTrunCateLine",          { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaLightBulb",                 { bg = "NONE", fg = "#BBE73D", })
vim.api.nvim_set_hl(0, "LspSagaLspFinderBorder",           { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaRenameBorder",              { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaRenameMatch",               { bg = "NONE", fg = "#C53B82", })
vim.api.nvim_set_hl(0, "LspSagaShTrunCateLine",            { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaSignatureHelpBorder",       { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "LspSagaTrunCatgeLine",             { bg = "NONE", fg = "#353535", })

vim.api.nvim_set_hl(0, "TargetFileName",                   { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "FinderParam",                      { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "FinderVirtText",                   { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "DefinitionsIcon",                  { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "Definitions",                      { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "ReferencesIcon",                   { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "References",                       { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "DefinitionCount",                  { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "ReferencesCount",                  { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "FinderPreviewSearch",              { bg = "NONE", fg = "#888888", })
vim.api.nvim_set_hl(0, "FinderSpinnerBorder",              { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "FinderSpinnerTitle",               { bg = "NONE", fg = "#C53B82", })
vim.api.nvim_set_hl(0, "FinderSpinner",           { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "DefinitionPreviewTitle",  { bg = "NONE", fg = "#666666", })
vim.api.nvim_set_hl(0, "SagaShadow",              { bg = "NONE", fg = "#000000", })
--
---- Outline
vim.api.nvim_set_hl(0, "LSOutlinePreviewBorder",  { bg = "NONE", fg = "#353535", })
vim.api.nvim_set_hl(0, "OutlineIndentEvn",        { bg = "NONE", fg = "#ffffff", })
vim.api.nvim_set_hl(0, "OutlineIndentOdd",        { bg = "NONE", fg = "#ffffff", })
vim.api.nvim_set_hl(0, "OutlineFoldPrefix",       { bg = "NONE", fg = "#000000", })
vim.api.nvim_set_hl(0, "OutlineDetail",           { bg = "NONE", fg = "#383838", })
--
vim.api.nvim_set_hl(0, "LSOutLineFile",          { bg = "NONE", fg = "#AF87D7" })
vim.api.nvim_set_hl(0, "LSOutLineModule",        { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineNamespace",     { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLinePackage",       { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineClass",         { bg = "NONE", fg = "#BBE73D", bold = true, italic = true })
vim.api.nvim_set_hl(0, "LSOutLineMethod",        { bg = "NONE", fg = "#C53B82", italic = true })
vim.api.nvim_set_hl(0, "LSOutLineProperty",      { bg = "NONE", fg = "#6A5A9D" })
vim.api.nvim_set_hl(0, "LSOutLineField",         { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineConstructor",   { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineEnum",          { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineInterface",     { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineFunction",      { bg = "NONE", fg = "#C53B82", bold = true, italic = true })
vim.api.nvim_set_hl(0, "LSOutLineVariable",      { bg = "NONE", fg = "#696969" })
vim.api.nvim_set_hl(0, "LSOutLineConstant",      { bg = "NONE", fg = "#C53B82" })
vim.api.nvim_set_hl(0, "LSOutLineString",        { bg = "NONE", fg = "#444444" })
vim.api.nvim_set_hl(0, "LSOutLineNumber",        { bg = "NONE", fg = "#AFC460" })
vim.api.nvim_set_hl(0, "LSOutLineBoolean",       { bg = "NONE", fg = "#C53B82" })
vim.api.nvim_set_hl(0, "LSOutLineArray",         { bg = "NONE", fg = "#614F97" })
vim.api.nvim_set_hl(0, "LSOutLineObject",        { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineKey",           { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineNull",          { bg = "NONE", fg = "#C53B82" })
vim.api.nvim_set_hl(0, "LSOutLineEnummember",    { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineStruct",        { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineEvent",         { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineOperator",      { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineTypeparameter", { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineTypealias",     { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineParameter",     { bg = "NONE", fg = "#8567A3" })
vim.api.nvim_set_hl(0, "LSOutLineStaticmethod",  { bg = "NONE", fg = "#666666" })
vim.api.nvim_set_hl(0, "LSOutLineMacro",         { bg = "NONE", fg = "#666666" })


-- vim.api.nvim_create_autocmd("BufEnter", {
-- callback = function ()
--     if #vim.api.nvim_list_wins() == 1 and vim.bo.filetype == "lspsagaoutline" then
--     vim.cmd "quit"
--     end
-- end
-- })
