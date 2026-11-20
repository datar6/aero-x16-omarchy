})

-- Razer DeathAdder V3: raw 1:1 aim for games (no acceleration, set speed via mouse DPI).
for _, name in ipairs({ "razer-razer-deathadder-v3", "razer-razer-deathadder-v3-1" }) do
  hl.device({ name = name, accel_profile = "flat", sensitivity = 0 })
end
