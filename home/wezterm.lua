local wezterm = require 'wezterm'

local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil

config.window_background_opacity = 0.9
config.color_scheme = "rose-pine-moon"
config.max_fps = 120
config.enable_tab_bar = false
config.font = wezterm.font("Hack Nerd Font", { weight = "DemiBold" })
config.window_decorations = "RESIZE"
config.window_frame = {
  font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
}
config.inactive_pane_hsb = {
  saturation = 0.0,
  brightness = 0.5,
}

if is_windows then
  config.win32_system_backdrop = "Acrylic"
  config.window_frame.font_size = 10.0
  config.default_domain = 'WSL:Ubuntu'
end

if is_macos then
  config.macos_window_background_blur = 50
  config.font_size = 15.0
  config.window_frame.font_size = 13.0
end

return config
