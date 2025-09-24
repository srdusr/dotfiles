return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
  settings = {
    Lua = {
      diagnostics = {
        disable = { "undefined-global", "lowercase-global", "unused-local", "unused-vararg", "trailing-space" },
        globals = { "vim", "use", "_G", "packer_plugins", "P" }
      },
      telemetry = {
        enable = false
      },
      workspace = {
        checkThirdParty = false,
        library = { "/tmp/.mount_nvimOIpamk/usr/share/nvim/runtime", "${3rd}/luv/library", "${3rd}/busted/library" }
      }
    }
  }
}