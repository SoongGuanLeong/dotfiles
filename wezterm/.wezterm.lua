local wezterm = require 'wezterm'

return {
  default_prog = { 'wsl.exe', '-d', 'Ubuntu' },

  font = wezterm.font('JetBrainsMono Nerd Font'),

  font_size = 12.0,

  window_padding = {
    left = 8,
    right = 8,
    top = 8,
    bottom = 8,
  },

  enable_tab_bar = true,

  color_scheme = 'Catppuccin Mocha',

  window_close_confirmation = 'NeverPrompt',
  hide_tab_bar_if_only_one_tab = true,
}