-- every workspace, hidden from screen sharing/recording, never steals focus
-- when it appears.
o.window({ class = "^(my-ai-assistant)$" }, {
  float = true,
  pin = true,
  no_screen_share = true,
  no_initial_focus = true,
  focus_on_activate = false,
  border_size = 0,
  no_shadow = true,
  no_blur = true,
})
