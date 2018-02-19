local fonts = {}

fonts.console = lg.newFont("media/RobotoMono-Regular.ttf", 16)

local default = "media/Lato-Regular.ttf"
fonts.small = lg.newFont(default, 14)
fonts.default = lg.newFont(default, 18)
fonts.big = lg.newFont(default, 22)
fonts.bigger = lg.newFont(default, 26)
fonts.huge = lg.newFont(default, 32)
fonts.huger = lg.newFont(default, 36)

return fonts
