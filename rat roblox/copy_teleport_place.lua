local place = game.PlaceId
local job = game.JobId

local script_a_coller = string.format(
    [[
if game.Players.LocalPlayer.Name == "SpeedFraks" then return end
game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)
]],
    place,
    job
)

if setclipboard then
    setclipboard(script_a_coller)
else
    print(script_a_coller)
end