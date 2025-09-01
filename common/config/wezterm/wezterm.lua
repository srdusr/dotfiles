local wezterm = require("wezterm")

---- Function to unset Ctrl+C keybinding
--local function unsetCtrlCKeybinding(window)
--  local keys = window:get_config().keys
--  for i, key in ipairs(keys) do
--    if key.key == 'c' and key.mods == 'CTRL' then
--      table.remove(keys, i)
--      break
--    end
--  end
--  window:set_config({ keys = keys })
--end
--
---- Event handler to unset Ctrl+C keybinding when using nvim
--wezterm.on("spawn_command", function(window, pane)
--  local cmd = pane:get_command()
--  if cmd and cmd[1] == "nvim" then
--    unsetCtrlCKeybinding(window)
--  end
--end)

--local function isNvimRunning(window)
--  local pane = window.active_pane
--  local cmd = pane:get_command()
--  return cmd and cmd[1] == "nvim"
--end
--
---- Function to modify keybindings based on the current program
--local function updateKeybindings(window)
--  local isNvim = isNvimRunning(window)
--
--  local keys = {}
--  if not isNvim then
--    -- Add the default Ctrl+C keybinding
--    keys = {
--      {
--        key = "c",
--        mods = "CTRL",
--        action = wezterm.action{CopyTo = "ClipboardAndPrimarySelection"}
--      }
--    }
--  end
--
--  window:set_config({
--    keys = keys
--  })
--end
--
---- Event handler to update keybindings when the active program changes
--wezterm.on("update-right-status", function(window)
--  updateKeybindings(window)
--end)

wezterm.on("toggle-opacity", function(window)
  local overrides = window:get_config_overrides() or {}
  if not overrides.window_background_opacity then
    overrides.window_background_opacity = 1.0
  elseif overrides.window_background_opacity == 1.0 then
    overrides.window_background_opacity = 0.6
  else
    overrides.window_background_opacity = nil
  end
  window:set_config_overrides(overrides)
end)

return {
  front_end = "OpenGL",
  --font = wezterm.font 'JetBrains Mono',
  font = wezterm.font_with_fallback({
    {
      family = "JetBrains Mono",
      --intensity = 'Normal',
      weight = "Medium",
      italic = false,
      harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
    },
    { family = "Hack Nerd Font", weight = "Medium" },
    {
      family = "Fira Code",
      harfbuzz_features = { "zero" },
    },
    { family = "Terminus",       weight = "Bold" },
    "Noto Color Emoji",
  }),
  font_size = 9,
  warn_about_missing_glyphs = false,
  adjust_window_size_when_changing_font_size = false,
  line_height = 1.0,
  --dpi = 96.0,
  -- Keybinds
  disable_default_key_bindings = true,
  use_dead_keys = false,
  mouse_bindings = {
    -- Ctrl-click will open the link under the mouse cursor
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "CTRL",
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
  },
  keys = {
    --leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 },
    {
      key = "O",
      mods = "CTRL|SHIFT",
      action = wezterm.action({ EmitEvent = "toggle-opacity" }),
    },
    { key = "R", mods = "CTRL", action = "ReloadConfiguration" },
    { key = "Y", mods = "CTRL", action = "ShowDebugOverlay" },
    {
      key = "-",
      mods = "CTRL",
      action = wezterm.action.DecreaseFontSize,
    },
    {
      key = "=",
      mods = "CTRL",
      action = wezterm.action.IncreaseFontSize,
    },
    {
      key = "0",
      mods = "CTRL",
      action = wezterm.action.ResetFontSize,
    },
    {
      key = "v",
      mods = "CTRL",
      action = wezterm.action({ PasteFrom = "Clipboard" }),
    },
    --{
    --	key = "c",
    --	mods = "CTRL",
    --	action = wezterm.action({ CopyTo = "ClipboardAndPrimarySelection" }),
    --},
    {
      key = "c",
      mods = "CTRL",
      action = wezterm.action_callback(function(window, pane)
        local has_selection = window:get_selection_text_for_pane(pane) ~= ""
        if has_selection then
          window:perform_action(wezterm.action({ CopyTo = "ClipboardAndPrimarySelection" }), pane)
          window:perform_action("ClearSelection", pane)
        else
          window:perform_action(wezterm.action({ SendKey = { key = "c", mods = "CTRL" } }), pane)
        end
      end),
    },
  },
  -- Aesthetic Night Colorscheme
  bold_brightens_ansi_colors = true,
  -- Padding
  window_padding = {
    left = 5,
    right = 5,
    top = 6,
    bottom = 4,
  },
  -- Cursor style
  --default_cursor_style = "BlinkingUnderline",
  default_cursor_style = "BlinkingBar",
  cursor_blink_rate = 700,
  -- needed to prevent 'easing' from using 40%+ cpu util ...
  --animation_fps = 1,
  force_reverse_video_cursor = true,
  colors = {
    cursor_bg = "white",
    compose_cursor = "orange",
    --cursor_border = 'white',
  },

  -- Tab Bar
  enable_tab_bar = false,
  --hide_tab_bar_if_only_one_tab = true,
  --show_tab_index_in_tab_bar = false,
  tab_bar_at_bottom = false,

  -- General
  -- X11
  enable_wayland = false,
  audible_bell = "Disabled",

  visual_bell = {
    fade_in_duration_ms = 5,
    fade_out_duration_ms = 5,
    target = "CursorColor",
  },
  automatically_reload_config = true,
  scrollback_lines = 3500,
  --inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 },
  --text_background_opacity = 0.3,
  window_background_opacity = 0.8,
  --window_background_image = '/path/to/wallpaper.jpg',
  --window_background_image_hsb = {
  --  -- Darken the background image by reducing it to 1/3rd
  --  brightness = 0.3,
  --  -- You can adjust the hue by scaling its value.
  --  -- a multiplier of 1.0 leaves the value unchanged.
  --  hue = 1.0,
  --  -- You can adjust the saturation also.
  --  saturation = 1.0,
  --},
  window_close_confirmation = "NeverPrompt",
  --color_scheme = 'transparent',
  use_resize_increments = true,
}
