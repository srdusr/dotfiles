--ft = { "latex", "tex" },
--if vim.loop.os_uname().sysname == "Linux" then
--  vim.g.vimtex_view_method = "zathura"
--end
--vim.g["vimtex_view_method"] = "zathura" -- main variant with xdotool (requires X11; not compatible with wayland)
--vim.g.vimtex_compiler_method = "pdflatex"
-- compilation configuration
vim.g["vimtex_compiler_method"] = "latexmk"
--vim.g["vimtex_compiler_method"] = "xelatex"
--vim.g["vimtex_compiler_method"] = "lualatex"
vim.g["vimtex_compiler_latexmk"] = {
  callback = 1,
  continuous = 1,
  executable = "latexmk",
  options = {
    "-shell-escape",
    "-verbose",
    "-file-line-error",
    "-synctex=1",
    "-interaction=nonstopmode",
  },
}
vim.g["vimtex_view_enabled"] = 1
vim.g["vimtex_view_zathura_check_libsynctex"] = 0
--vim.g["vimtex_view_method"] = "zathura" -- main variant with xdotool (requires X11; not compatible with wayland)
if vim.loop.os_uname().sysname == "Linux" then
  vim.g.vimtex_view_method = "zathura"
end
--vim.g.vimtex_view_method = "sioyek"
--vim.g["vimtex_view_method"] = "zathura_simple" -- for variant without xdotool to avoid errors in wayland
vim.g["vimtex_quickfix_mode"] = 0    -- suppress error reporting on save and build
vim.g["vimtex_mappings_enabled"] = 0 -- Ignore mappings
vim.g["vimtex_indent_enabled"] = 0   -- Auto Indent
vim.g["tex_flavor"] = "latex"        -- how to read tex files
vim.g["tex_indent_items"] = 0        -- turn off enumerate indent
vim.g["tex_indent_brace"] = 0        -- turn off brace indent
--vim.g.vimtex_view_forward_search_on_start = 0
--vim.g["vimtex_context_pdf_viewer"] = "zathura" -- external PDF viewer run from vimtex menu command
--vim.g["latex_view_general_viewer"] = "zathura"
vim.g["vimtex_log_ignore"] = { -- Error suppression:
  "Underfull",
  "Overfull",
  "specifier changed to",
  "Token not allowed in a PDF string",
}
