-- Pull in the wezterm API
local wezterm = require("wezterm")
-- General Config
local config = wezterm.config_builder()
-- config.leader = { key = 'w', mods = 'CTRL', timeout_milliseconds = 1000 }
config.color_scheme = "Gruvbox Dark (Gogh)"
config.font = wezterm.font("FiraCode Nerd Font", { weight = "DemiBold" })
config.font_size = 10
config.hide_tab_bar_if_only_one_tab = true
config.warn_about_missing_glyphs=false

config.window_decorations = "NONE"
config.background = {
	{

		source = {
			File = "/home/sen/Pictures/Wallpapers/1.jpg",
		},
		hsb = {
			brightness = 0.2,
		},
	},
}

config.window_padding = {
	top = 0,
	bottom = 0,
	left = 0,
	right = 0,
}
config.use_fancy_tab_bar = false
-- tmux will handle tab switching
config.keys = {
	{
		key = "Tab",
		mods = "CTRL",
		action = wezterm.action.DisableDefaultAssignment,
	},
}

-- Start maximised
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():toggle_fullscreen()
end)

-- and finally, return the configuration to wezterm
return config
