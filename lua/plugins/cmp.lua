
-- Setup nvim-cmp.
vim.opt.completeopt = "menu,menuone,noselect"
--vim.g.completeopt = "menu,menuone,noselect,noinsert"
local cmp_status_ok, cmp = pcall(require, "cmp")
if not cmp_status_ok then
	return
end
--local WIDE_HEIGHT = 40

local opts = {
	-- whether to highlight the currently hovered symbol
	-- disable if your cpu usage is higher than you want it
	-- or you just hate the highlight
	-- default: true
	highlight_hovered_item = true,
	show_guides = true,
}
require("symbols-outline").setup(opts)


--local snippets_paths = function()
--	local plugins = { "friendly-snippets" }
--	local paths = {}
--	local path
--	local root_path = vim.env.HOME .. "/.vim/plugged/"
--	for _, plug in ipairs(plugins) do
--		path = root_path .. plug
--		if vim.fn.isdirectory(path) ~= 0 then
--			table.insert(paths, path)
--		end
--	end
--	return paths
--end
--
--require("luasnip.loaders.from_vscode").lazy_load({
--	paths = snippets_paths(),
--	include = nil, -- Load all languages
--	exclude = {},
--})

--require("luasnip.loaders.from_vscode").lazy_load()
local lspkind = require("lspkind")
local kind_icons = {
  Text = "",
  Method = "m", --"",
  Function = "",
  Constructor = "", --"⚙️",
  Field = "",
  Variable = "",
  Class = "ﴯ",
  Interface = "",
  Module = "",
  Property = "",
  Unit = "",
  Value = "",
  Enum = "",
  Keyword = "",
  Snippet = "",
  Color = "",
  File = "",
  Reference = "",
  Folder = "",
  EnumMember = "",
  Constant = "",
  Struct = "",
  Event = "",
  Operator = "",
  TypeParameter = "",
}
cmp.setup({
	snippet = {
		--expand = function(args)
		--	require("luasnip").lsp_expand(args.body)
		--end,
    expand = function(args)
      local luasnip = require("luasnip")
      if not luasnip then
          return
      end
      luasnip.lsp_expand(args.body)
    end,
	},
	mapping = cmp.mapping.preset.insert({
--		["<CR>"] = cmp.mapping.confirm({
--			behavior = cmp.ConfirmBehavior.Replace,
--			select = true,
--		}),
    --["<C-k>"] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
    --["<C-j>"] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
		--["<C-e>"] = cmp.mapping.close(),
    --['<C-e>'] = cmp.mapping({
    --  i = cmp.mapping.abort(),
    --  c = cmp.mapping.close(),
    --}),
    ["<C-e>"] = cmp.mapping({
      i = function()
        if cmp.visible() then
          cmp.abort()
          require("user.utils").toggle_completion()
          require("notify")("completion off")
        else
          cmp.complete()
          require("user.utils").toggle_completion()
          require("notify")("completion on")
        end
      end,
    }),
    --["<CR>"] = cmp.mapping({
    --  i = function(fallback)
    --    if cmp.visible() then
    --      cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
    --      require("user.utils").toggle_completion()
    --    else
    --      fallback()
    --    end
    --  end,
    --}),

--      ["<C-e>"] = cmp.mapping({
--    i = function()
--      if cmp.visible() then
--        require("notify")("visible")
--        cmp.abort()
--      else
--        require("notify")("not visible")
--        cmp.complete()
--      end
--    end,
--    c = function()
--      if cmp.visible() then
--        require("notify")("visible")
--        cmp.close()
--      else
--        require("notify")("not visible")
--        cmp.complete()
--      end
--    end,
--  }),
    --['<CR>'] = cmp.config.disable,
		["<C-u>"] = cmp.mapping.scroll_docs(-4),
		["<C-d>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
    --['<C-o>'] = function(fallback)
    --  if cmp.visible() then
    --    cmp.mapping.confirm({ select = true })(fallback)
    --  else
    --    cmp.mapping.complete()(fallback)
    --  end
    --end
	}),

  sources = cmp.config.sources({
		--{ name = "nvim_lua" },
    { name = "luasnip" },
		--{ name = 'luasnip', option = { use_show_condition = false } },
		{ name = "gh_issues" },
		{ name = "nvim_lsp", max_item_count = 6 },
    { name = "nvim_lua" },
		--{ name = "luasnip" },
		--{ name = "luasnip", keyword_length = 4 },
		--{ name = "buffer", keyword_length = 3 },
		{ name = "path" },
    { name = "buffer", max_item_count = 6 },
    --{ name = "buffer", option = { get_bufnrs = function()
    --  return vim.api.nvim_list_bufs()
    --end
    --}},
    { name = "cmp_git"},
    { name = "spell"},
    { name = "zsh" },
    { name = "treesitter" },
    { name = "calc" },
    { name = "nvim_lsp_signature_help" },
    --{ name = "cmdline" },
    --{ name = 'treesitter' },
		--{ name = "cmdline", keyword_pattern = [=[[^[:blank:]\!]*]=] }, --exclamation mark hangs a bit without this
		--{name = 'luasnip', keyword_length = 2},
	}),
	formatting = {
      --formatting = {
      --local icons = kind_icons
        --format = function(entry, vim_item)
        ----vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
        ----vim_item.kind = lspkind.presets.default[vim_item.kind]
        --vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
        ----vim_item.kind = string.format("%s %s", icons[vim_item.kind], vim_item.kind)
        --vim_item.menu = ({
				----nvim_lsp = "LSP",
				----luasnip = "snip",
				----buffer = "buf",
				----path = "path",
        ----cmdline = "cmd",
        --buffer = "[buf]",
        --nvim_lsp = "[LSP]",
        --nvim_lua = "[api]",
        --path = "[path]",
        --luasnip = "[snip]",
        --cmdline = "[cmd]",
        --gh_issues = "[issues]",
        --})[entry.source.name]
        --return vim_item
        --end,
    format = lspkind.cmp_format {
      with_text = true,
      menu = {
        nvim_lsp = "[LSP]",
        luasnip = "[snip]",
        buffer = "[buf]",
        nvim_lua = "[api]",
        path = "[path]",
        gh_issues = "[issues]",
        spell = "[spell]",
        zsh = "[zsh]",
        treesitter = "[treesitter]",
        calc = "[calc]",
        nvim_lsp_signature_help = "[signature]",
        cmdline = "[cmd]"

      },
    },
  --},

    --
    --
		--fields = { "abbr", "kind", "menu" },
   --    format = lspkind.cmp_format({
   --   mode = 'symbol_text', -- show only symbol annotations
   --   maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
   -- })
    --format = require('lspkind').cmp_format {
    --  with_text = true,
    --  menu = {
    --    luasnip = "Snip",
    --    buffer = "Buf",
    --    nvim_lsp = "LSP",
    --    path = "Path",
    --    cmdline = "Cmd",
    --    cmp_git = "Git",
    --  },
    --},
  },
		--format = function(entry, vim_item)
		--	-- Kind icons
		--	--vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
    --  vim_item.kind = lspkind.presets.default[vim_item.kind]
		--	-- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
		--	vim_item.menu = ({
		--		nvim_lsp = "LSP",
		--		luasnip = "Snip",
		--		buffer = "Buf",
		--		path = "Path",
    --    cmdline = "Cmd",
		--	})[entry.source.name]
		--	return vim_item
		--end,
  confirm_opts = {
		behavior = cmp.ConfirmBehavior.Replace,
		select = false,
	},


  event = {},

    experimental = {
      ghost_text = true, -- this feature conflicts with copilot.vim's preview.
      hl_group = 'Nontext',
      --native_menu = false,
    },

    view = {
      entries = { name = 'custom', selection_order = 'top_down' },
    },

    window = {
      --completion = cmp.config.window.bordered(),
      completion = {
        border = { '', '', '', ' ', '', '', '', ' ' },
        --border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        --border = { '', '', '', '', '', '', '', '' },
        --border = "CmpBorder",
        winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None',
        --winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None",
      },
      --documentation = cmp.config.window.bordered(),
      documentation = {
        --max_height = math.floor(WIDE_HEIGHT * (WIDE_HEIGHT / vim.o.lines)),
        --max_width = math.floor((WIDE_HEIGHT * 2) * (vim.o.columns / (WIDE_HEIGHT * 2 * 16 / 9))),
        border = { '', '', '', ' ', '', '', '', ' ' },
        --border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        winhighlight = 'FloatBorder:NormalFloat',
      },
    },
})


cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
	sources = {
		{ name = "buffer" },
  },
})

cmp.setup.cmdline(":", {
  mapping = {
    ["<C-p>"] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
    ["<C-n>"] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
    ["<C-y>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { 'i', 'c' }),
    ["<C-e>"] = cmp.mapping(cmp.mapping.close(), { 'i', 'c' }),
    ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    --["<C-k>"] = cmp.mapping.select_prev_item(),
    --["<C-j>"] = cmp.mapping.select_next_item(),
    --['<C-y>'] = cmp.mapping.confirm({ select = true }),
		--["<C-e>"] = cmp.mapping.close(),
    ----['<CR>'] = cmp.config.disable,
		--["<C-u>"] = cmp.mapping.scroll_docs(-4),
		--["<C-d>"] = cmp.mapping.scroll_docs(4),
		--["<C-Space>"] = cmp.mapping.complete(),
  },

	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		--{ name = "cmdline" },
    { name = "cmdline", keyword_pattern = [=[[^[:blank:]\!]*]=], keyword_length = 3 },
  })
})


