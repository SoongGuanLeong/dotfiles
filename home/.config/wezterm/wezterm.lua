local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- WSL
config.default_prog = { "wsl.exe", "-d", "Ubuntu" }

-- Appearance
config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.win32_system_backdrop = "Acrylic"

config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

config.hide_tab_bar_if_only_one_tab = true
config.window_close_confirmation = "NeverPrompt"

-- Dim unfocused windows.
local UNFOCUSED_FOREGROUND_TEXT_HSB = {
  hue = 1.0,
  saturation = 0.25,
  brightness = 0.45,
}

local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

local function same_text_hsb(actual, expected)
  if actual == nil or expected == nil then
    return actual == expected
  end

  return actual.hue == expected.hue
    and actual.saturation == expected.saturation
    and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
  local overrides = window:get_config_overrides() or {}

  local text_hsb
  local opacity

  if not window:is_focused() then
    text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
    opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
  end

  -- Avoid redundant set_config_overrides() calls.
  if same_text_hsb(overrides.foreground_text_hsb, text_hsb)
    and overrides.window_background_opacity == opacity then
    return
  end

  overrides.foreground_text_hsb = text_hsb
  overrides.window_background_opacity = opacity

  window:set_config_overrides(overrides)
end)

return config
