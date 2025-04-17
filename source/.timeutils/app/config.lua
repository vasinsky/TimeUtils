local themes = require("apptheme")
local fonts = require("appfont")
local Config = {}

Config.LOGFILE = "data/countdown.txt"

-- countdown
Config.LABEL = "C O U N T  D O W N"
Config.HINT = "control: D-pad/ start or A / select / X - menu"
Config.HINT_GLYPH = "D-pad Start or  {1}   Select   {2}   Menu"

-- stopwatch
Config.LABEL_STOPWATCH = "S T O P W A T C H"
Config.HINT_STOPWATCH = "control: Start or A for start/pause / X - menu"
Config.HINT_GLYPH_STOPWATCH = "Start or  {1}  for start/pause   {2}   Menu"

-- watch
Config.LABEL_WATCH = "W A T C H"
Config.HINT_WATCH = "control: X - menu"
Config.HINT_GLYPH_WATCH = "{1}  Menu"

-- menu
Config.HINT_MENU = "control:  d-pad / start or A"
Config.HINT_GLYPH_MENU = "D-pad Start or  {1}"

Config.LABEL_TIME_UTILS = "T I M E - U T I L S"
Config.MENU_COUNTDOWN = "COUNTDOWN"
Config.MENU_STOPWATCH = "STOPWATCH"
Config.MENU_WATCH = "WATCH"

Config.Font = fonts
Config.Theme = themes

Config.saveFileTheme = "theme.txt"
Config.saveFileFont = "font.txt"
Config.TMP_TIME = "tmptime.txt"

Config.useGlyph = false
Config.useGlyphColorFromTheme = true

Glyph = {
    a = "assets/glyph/a.png",
    b = "assets/glyph/b.png",
    c = "assets/glyph/c.png",
    x = "assets/glyph/x.png",
    y = "assets/glyph/y.png",
    z = "assets/glyph/z.png",
}

Config.Glyph = Glyph
Config.logtext = true

-- weather
Config.API_KEY = "26d3e0402435faf5a393d0a9f0f18878"
Config.weatherCurrentFileName = "current_weather.json"
Config.weatherCurrentTimeLastTimeUpdateFileName = "current_weather_last_time.txt"
Config.weatherForecasttFileName = "forecast_weather.json"
Config.weatherForecastTimeLastTimeUpdateFileName = "forecast_weather_last_time.txt"
Config.weatherFileName = "current_weather.json"
Config.cities = {"Novosibirsk", "Mochische", "Ufa"}

return Config