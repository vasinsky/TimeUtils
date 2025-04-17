local love = require("love")
local os = require("os")
local Config = require("config")
local log = require("log")
local http = require("socket.http")
local json = require("dkjson")

local bg_img

local hours, minutes, seconds = 0, 0, 0
local activeField = "hours"
local timerRunning = false
local timeLeft = 0

local font

local soundCD
local soundDataCD
local soundSWminute
local soundDataSWminute
local soundSWhalfMinute
local soundDataSWhalfMinute
local startSample
local factor = 2

local isMenu = true
local activeMenuField = "countdown"
local startCountdown = false
local startStopwatch = false
local startWatch = false
local startWeather = false
--theme app
local theme
-- font + font_size app
local fontData

local themeSaved
local fontSaved

local isPaused = false
local savedTime, savedHours, savedMinutes, savedSeconds = 0, 0, 0, 0

local zoom = 1

local sampleRate = 44100
local duration = 0.2
local frequency = 1030
local totalDuration = 10

local keyPressed
local logtext

local a
local b
local c
local x
local y
local z

--weather
currentCityIndex = 1
CITY = Config.cities[currentCityIndex]
URL_CURRENT = "http://api.openweathermap.org/data/2.5/weather?q=" .. CITY .. "&appid=" .. Config.API_KEY .. "&units=metric"
URL_FORECAST = "http://api.openweathermap.org/data/2.5/forecast?q=" .. CITY .. "&appid=" .. Config.API_KEY .. "&units=metric"

currentWeather = nil
forecastWeather = nil
errorMessage = nil
weatherIcon = nil
iconImage = nil
forecastIcons = {}
lastUpdateTime = 0 -- Переменная для хранения времени последнего обновления
saveInterval = 15 * 60 -- Интервал сохранения данных (15 минут в секундах)
--end weather

function love.load()
    log.clear()
    log.write("Load")
    themeSaved = getSavedTheme()
    fontSaved = getSavedFont()

    fontData = Config.Font[fontSaved]

    setFontActual(fontSaved)

    theme = Config.Theme[themeSaved]

    if Config.useGlyph then
        loadGlyph()
    end

    logtext = ""

    if startWatch or startWeather then
        --love.graphics.setFont(love.graphics.newFont(16))
        renderLog("asdasdasa")
        updateWeather()
        currentWeather = loadWeatherData()

        weatherIcon = currentWeather.weather[1].icon
        iconImage, errorMessage = loadIcon(weatherIcon)
    end
end

function love.update(dt)
    if timerRunning then
        log.write("dT: " .. math.floor(timeLeft))

        if startCountdown then
            if timeLeft > 1 then
                timeLeft = timeLeft - dt
                savedTime = timeLeft

                if math.floor(timeLeft) == 10  then
                        soundCD:play()
                end

                if math.floor(timeLeft) <= 5  then
                        if math.floor(timeLeft)%2 > 0  then
                            zoom = 1.03
                        else
                            zoom = 1
                        end
                end
            else
                timerRunning = false
                timeLeft = 0
                savedTime = 0
                hours, minutes, seconds = 0, 0, 0
                activeField = "hours"
            end
        elseif startStopwatch then
            timeLeft = timeLeft + dt
            savedTime = timeLeft

            if (math.floor(timeLeft)%60  < 1)  and math.floor(timeLeft) > 0 then
               soundSWhalfMinute:play()
            end

             if (math.floor(timeLeft)%30  < 1) and math.floor(timeLeft) > 0 then
                soundSWminute:play()
             end
        end
    end

    if startWatch or startWeather then
        local currentTime = love.timer.getTime()
        if currentTime - lastUpdateTime >= saveInterval then -- Проверяем, прошли ли 15 минут
            updateWeather()
        end
    end
end

function love.keypressed(key)
    log.write("Pressed: " .. key)
    log.write("timerRunning is: " .. tostring(timerRunning))

    keyPressed = key

    if key == "escape" then
        love.event.quit()
    end

    -- theme manager
    if key == "w" then
        if tonumber(themeSaved) + 1 <= #Config.Theme then
            newThemeIndex = themeSaved + 1
            themeSaved = newThemeIndex
            theme = Config.Theme[newThemeIndex]
            saveTheme(newThemeIndex)
        end
    elseif key == "q" then
        if  themeSaved - 1 > 0 then
            newThemeIndex = themeSaved - 1
            themeSaved = newThemeIndex
            theme = Config.Theme[newThemeIndex]
            saveTheme(newThemeIndex)
        end
    end

    -- font manager
    if key == "r" then
        if tonumber(fontSaved) + 1 <= #Config.Font then
            newFontIndex = fontSaved + 1
            fontSaved = newFontIndex
            font = Config.Font[newFontIndex]
            saveFont(newFontIndex)
            setFontActual(newFontIndex)
        end
    elseif key == "e" then
        if  tonumber(fontSaved) - 1 > 0 then
            newFontIndex = fontSaved - 1
            fontSaved = newFontIndex
            font = Config.Font[newFontIndex]
            saveFont(newFontIndex)
            setFontActual(newFontIndex)
        end
    end

    if isMenu then
        if key == "up" or key == "down" or key == "left" or key == "right" then
            getActiveMenuField()
        end

        if key == "return"  then
            if activeMenuField == "countdown" then
                startCountdown = true
                startStopwatch = false
                startWatch = false
                startWeather = false
                setAudioCountDown()
            elseif activeMenuField == "stopwatch" then
                startStopwatch = true
                startCountdown = false
                startWatch = false
                startWeather = false
                setAudioStopWatchHalfMinute()
                setAudioStopWatchMinute()
            elseif activeMenuField == "watch" then
                startWatch = true
                startCountdown = false
                startStopwatch = false
                startWeather = false
            end
            isMenu = false
        end
    else
        if key == "x" then
            isMenu = true
            hours, minutes, seconds = 0,0,0
            remainingHours, remainingMinutes, remainingSeconds = 0,0,0
            timeLeft = 0
            savedTime = 0
            timerRunning = false
        end

        if startCountdown then
            if not timerRunning then
                if key == "right" then
                    if activeField == "hours" then
                        activeField = "minutes"
                    elseif activeField == "minutes" then
                        activeField = "seconds"
                    end
                elseif key == "left" then
                    if activeField == "seconds" then
                        activeField = "minutes"
                    elseif activeField == "minutes" then
                        activeField = "hours"
                    end
                elseif key == "up" then
                    if activeField == "hours" then
                        hours = (hours + 1) % 24
                    elseif activeField == "minutes" then
                        minutes = (minutes + 1) % 60
                    elseif activeField == "seconds" then
                        seconds = (seconds + 1) % 60
                    end
                elseif key == "down" then
                    if activeField == "hours" then
                        hours = (hours - 1) % 24
                    elseif activeField == "minutes" then
                        minutes = (minutes - 1) % 60
                    elseif activeField == "seconds" then
                        seconds = (seconds - 1) % 60
                    end
                end
            end

            if key == "return" then
                startPauseCountDown()
            end

            if key == "space" then
                if math.floor(timeLeft) > 10 then
                    editCountDown()
                end
            end
        elseif startStopwatch then
            if key == "return" then
                startPauseStopWatch()
            end
        end
    end

    if startWatch or startWeather then
        if key == "space" and startWeather == false then
            startWatch = false
            startWeather = true

            if key == "z" then
                currentCityIndex = currentCityIndex - 1
                if currentCityIndex < 1 then
                    currentCityIndex = #Config.cities
                end
            elseif key == "x" then
                currentCityIndex = currentCityIndex + 1
                if currentCityIndex > #Config.cities then
                    currentCityIndex = 1
                end

            end

            updateWeather()
        else
            startWatch = true
            startWeather = false
        end
    end
end

function love.draw()
    local h = font:getHeight()
    love.graphics.clear(theme.BG_COLOR)

    if isMenu then
        love.graphics.setColor(theme.DIGITAL_COLOR)
        if activeMenuField == "countdown" then
            love.graphics.setColor(theme.SELECT_COLOR)
       end
       love.graphics.print(Config.MENU_COUNTDOWN, 400, 225, 0, 0.3, 0.3, font:getWidth(Config.MENU_COUNTDOWN) / 2, font:getHeight() / 2)

       love.graphics.setColor(theme.DIGITAL_COLOR)
       if activeMenuField == "stopwatch" then
           love.graphics.setColor(theme.SELECT_COLOR)
       end
       love.graphics.print(Config.MENU_STOPWATCH, 400, 298, 0, 0.3, 0.3, font:getWidth(Config.MENU_STOPWATCH) / 2, font:getHeight() / 2)

       love.graphics.setColor(theme.DIGITAL_COLOR)
       if activeMenuField == "watch" then
           love.graphics.setColor(theme.SELECT_COLOR)
       end
       love.graphics.print(Config.MENU_WATCH, 400, 370, 0, 0.3, 0.3, font:getWidth(Config.MENU_WATCH) / 2, font:getHeight() / 2)

       love.graphics.setColor(theme.HINT_COLOR)
       love.graphics.line(0,158,  800,158)
       love.graphics.line(0,160,  800,160)
       love.graphics.line(0,430,  800,430)
       love.graphics.line(0,432,  800,432)

       love.graphics.setColor(theme.LABEL_COLOR)
       love.graphics.print(Config.LABEL_TIME_UTILS, 400, 80, 0, 0.3, 0.3, font:getWidth(Config.LABEL_TIME_UTILS) / 2, font:getHeight() / 2)

       love.graphics.setColor(theme.HINT_COLOR)
        if Config.useGlyph then
            drawTextWithImages(Config.HINT_GLYPH_MENU, {400, 520, 0, 0.19, 0.19, font:getWidth(Config.HINT_GLYPH_MENU) / 2, font:getHeight() / 2}, {a}, {2, 2})
        else
            love.graphics.print(Config.HINT_MENU, 400, 520, 0, 0.19, 0.19, font:getWidth(Config.HINT_MENU) / 2, font:getHeight() / 2)
        end
    else
        if startCountdown then
            local displayHours, displayMinutes, displaySeconds = string.format("%02d", hours), string.format("%02d", minutes), string.format("%02d", seconds)

            love.graphics.setColor(theme.LABEL_COLOR)
            love.graphics.print(Config.LABEL, 400, 100, 0, 0.3, 0.3, font:getWidth(Config.LABEL) / 2, font:getHeight() / 2)
            love.graphics.setColor(theme.HINT_COLOR)

        if Config.useGlyph then
            drawTextWithImages(Config.HINT_GLYPH, {400, 500, 0, 0.19, 0.19, font:getWidth(Config.HINT_GLYPH) / 2, font:getHeight() / 2}, {a, x}, {2, 2})
        else
                love.graphics.print(Config.HINT, 400, 500, 0, 0.18, 0.18, font:getWidth(Config.HINT) / 2, font:getHeight() / 2)
        end

            love.graphics.line(0,188,  800,188)
            love.graphics.line(0,400,  800,400)
            love.graphics.line(0,190,  800,190)
            love.graphics.line(0,402,  800,402)

            if timerRunning or isPaused then
                local remainingHours, remainingMinutes, remainingSeconds = math.floor(timeLeft / 3600), math.floor((timeLeft % 3600) / 60), math.floor(timeLeft % 60)

                if zoom <= 1 or timeLeft == 0 then
                     love.graphics.setColor(theme.DIGITAL_COLOR)
                else
                    love.graphics.setColor(theme.SELECT_COLOR)
                end

                love.graphics.print(string.format("%02d:%02d:%02d", remainingHours, remainingMinutes, remainingSeconds), 400, 300, 0, zoom, zoom, font:getWidth("00:00:00") / 2, font:getHeight() / 2)
                love.graphics.setColor(theme.DIGITAL_COLOR)
            else
                love.graphics.setColor(theme.DIGITAL_COLOR)
                if activeField == "hours" then
                    love.graphics.setColor(theme.SELECT_COLOR)
                end
                love.graphics.print(displayHours, 123, 300, 0, 1, 1, font:getWidth("00") / 2, font:getHeight() / 2)
                love.graphics.setColor(theme.DIGITAL_COLOR)
                if activeField == "minutes" then
                    love.graphics.setColor(theme.SELECT_COLOR)
                end
                love.graphics.print(displayMinutes, 400, 300, 0, 1, 1, font:getWidth("00") / 2, font:getHeight() / 2)
                love.graphics.setColor(theme.DIGITAL_COLOR)
                if activeField == "seconds" then
                    love.graphics.setColor(theme.SELECT_COLOR)
                end
                love.graphics.print(displaySeconds, 675, 300, 0, 1, 1, font:getWidth("00") / 2, font:getHeight() / 2)
                love.graphics.setColor(theme.DIGITAL_COLOR)
            end
        elseif startStopwatch then
            local remainingHours, remainingMinutes, remainingSeconds = math.floor(timeLeft / 3600), math.floor((timeLeft % 3600) / 60), math.floor(timeLeft % 60)

            love.graphics.setColor(theme.LABEL_COLOR)
            love.graphics.print(Config.LABEL_STOPWATCH, 400, 100, 0, 0.3, 0.3, font:getWidth(Config.LABEL) / 2, font:getHeight() / 2)

            love.graphics.line(0,188,  800,188)
            love.graphics.line(0,400,  800,400)
            love.graphics.line(0,190,  800,190)
            love.graphics.line(0,402,  800,402)

            love.graphics.setColor(theme.DIGITAL_COLOR)

            love.graphics.print(string.format("%02d:%02d:%02d", remainingHours, remainingMinutes, remainingSeconds), 400, 300, 0, zoom, zoom, font:getWidth("00:00:00") / 2, font:getHeight() / 2)

            love.graphics.setColor(theme.HINT_COLOR)

            if Config.useGlyph then
                drawTextWithImages(Config.HINT_GLYPH_STOPWATCH, {400, 500, 0, 0.19, 0.19, font:getWidth(Config.HINT_GLYPH_STOPWATCH) / 2, font:getHeight() / 2}, {a, x}, {2, 2})
            else
                love.graphics.print(Config.HINT_STOPWATCH, 400, 500, 0, 0.18, 0.18, font:getWidth(Config.HINT_STOPWATCH) / 2, font:getHeight() / 2)
            end
        elseif startWatch then
            love.graphics.setColor(theme.LABEL_COLOR)
            love.graphics.print(Config.LABEL_WATCH, 400, 80, 0, 0.3, 0.3, font:getWidth(Config.LABEL_WATCH) / 2, font:getHeight() / 2)

           love.graphics.line(0,158,  800,158)
           love.graphics.line(0,160,  800,160)
           love.graphics.line(0,430,  800,430)
           love.graphics.line(0,432,  800,432)

            love.graphics.setColor(theme.DIGITAL_COLOR)
            love.graphics.print(os.date("%H:%M:%S"), 400, 280, 0, 1.1, 1.1, font:getWidth(os.date("%H:%M:%S")) / 2, font:getHeight() / 2)
            local dateInfo = os.date("%Y-%m-%d %A")
            love.graphics.print(dateInfo, 400, 395, 0, 0.2, 0.2, font:getWidth(dateInfo) / 2, font:getHeight() / 2)

            love.graphics.setColor(theme.HINT_COLOR)
            if Config.useGlyph then
                drawTextWithImages(Config.HINT_GLYPH_WATCH, {400, 520, 0, 0.19, 0.19, font:getWidth(Config.HINT_GLYPH_WATCH) / 2, font:getHeight() / 2}, {x}, {2, 2})
            else
                love.graphics.print(Config.HINT_WATCH, 400, 520, 0, 0.18, 0.18, font:getWidth(Config.HINT_WATCH) / 2, font:getHeight() / 2)
            end
        elseif startWeather then
            --love.graphics.clear() -- Очищаем экран перед рисованием

            if errorMessage then
                local message = errorMessage
                local font = love.graphics.getFont()
                local textWidth = font:getWidth(message)
                local textHeight = font:getHeight()
                love.graphics.printf(message, 0, (love.graphics.getHeight() - textHeight) / 3, love.graphics.getWidth(), "center", 0, 0.22, 0.22)
                return
            end

            --love.graphics.printf("Weather in " .. CITY, 0, 10, font:getWidth("Weather in " .. CITY), "center", 0, 0.2, 0.2)
            local label = "Weather in " .. CITY
            love.graphics.print(label, 400, 50 , 0, 0.3, 0.3, font:getWidth(label) / 2, font:getHeight())

            --renderLog(tostring(errorMessage))

            if currentWeather then
                local scaleX = 0.15
                local scaleY = 0.15
                --love.graphics.printf("Today's Weather:", 10, 70, love.graphics.getWidth()*2, "left", 0, 0.15, 0.15)
                local temperature = "Temperature: " .. currentWeather.main.temp .. "°C"
                love.graphics.printf(temperature, 10, 70, font:getWidth(temperature), "left", 0, scaleX, scaleY)
                local weather = "Weather: " .. currentWeather.weather[1].description
                love.graphics.printf(weather, 10, 100, font:getWidth(weather), "left", 0, scaleX, scaleY)
                local humidity = "Humidity: " .. currentWeather.main.humidity .. "%"
                love.graphics.printf(humidity, 10, 130, font:getWidth(humidity), "left", 0, scaleX, scaleY)
                local wind = "Wind Speed: " .. currentWeather.wind.speed .. " m/s"
                love.graphics.printf(wind, 10, 160, font:getWidth(wind), "left", 0, scaleX, scaleY)

                if iconImage then
                    love.graphics.draw(iconImage, love.graphics.getWidth() - 100, 40)
                end

            end

            if forecastWeather then

                --love.graphics.printf("5-Day Forecast:", 10, 160, love.graphics.getWidth(), "left", 0, 0.1, 0.1)

                local headers = {"Date", "Temperature (°C)", "Weather", "Humidity (%)", "Wind Speed (m/s)", "Icon"}
                local x = 10
                local y = 220
                local cellWidth = (love.graphics.getWidth() - 20)/ #headers
                local cellHeight = 40
                local padding = 2

                for i, header in ipairs(headers) do
                    love.graphics.rectangle("line", x + (i-1) * cellWidth, y, cellWidth, cellHeight)
                    --love.graphics.printf(header, x + (i-1) * cellWidth, y + cellHeight / 2 - 7, cellWidth, "center", 0 , 0.1, 0.1)


                    love.graphics.print(header, x + 20 + (i-1) * cellWidth, y + 10 + cellHeight / 2 - 7 , 0, 0.085, 0.085, cellWidth, font:getHeight())
                end
--[[
                for i = 1, 5 do
                    local day = forecastWeather.list[(i-1)*8 + 1]
                    if day then
                        local date = day.dt_txt:sub(1, 10)
                        local temp = day.main.temp
                        local description = day.weather[1].description
                        local humidity = day.main.humidity
                        local wind_speed = day.wind.speed

                        love.graphics.rectangle("line", x, y + i * cellHeight, cellWidth, cellHeight)
                        love.graphics.printf(date, x, y + i * cellHeight + cellHeight / 2 - 7, cellWidth, "center", 0, 0.2, 0.2)

                        love.graphics.rectangle("line", x + cellWidth, y + i * cellHeight, cellWidth, cellHeight)
                        love.graphics.printf(temp, x + cellWidth, y + i * cellHeight + cellHeight / 2 - 7, cellWidth, "center", 0, 0.2, 0.2)

                        love.graphics.rectangle("line", x + 2 * cellWidth, y + i * cellHeight, cellWidth, cellHeight)
                        love.graphics.printf(description, x + 2 * cellWidth, y + i * cellHeight + cellHeight / 2 - 7, cellWidth, "center", 0, 0.2, 0.2)

                        love.graphics.rectangle("line", x + 3 * cellWidth, y + i * cellHeight, cellWidth, cellHeight)
                        love.graphics.printf(humidity, x + 3 * cellWidth, y + i * cellHeight + cellHeight / 2 - 7, cellWidth, "center", 0, 0.2, 0.2)

                        love.graphics.rectangle("line", x + 4 * cellWidth, y + i * cellHeight, cellWidth, cellHeight)
                        love.graphics.printf(wind_speed, x + 4 * cellWidth, y + i * cellHeight + cellHeight / 2 - 7, cellWidth, "center", 0, 0.2, 0.2)

                        love.graphics.rectangle("line", x + 5 * cellWidth, y + i * cellHeight, cellWidth, cellHeight)
                        if forecastIcons[i] then
                            local iconWidth = forecastIcons[i]:getWidth()
                            local iconHeight = forecastIcons[i]:getHeight()
                            local scaleX = (cellWidth - 2 * padding) / iconWidth
                            local scaleY = (cellHeight - 2 * padding) / iconHeight
                            local scale = math.min(scaleX, scaleY)
                            local iconX = x + 5 * cellWidth + (cellWidth - iconWidth * scale) / 2
                            local iconY = y + i * cellHeight + (cellHeight - iconHeight * scale) / 2
                            love.graphics.draw(forecastIcons[i], iconX, iconY, 0, scale, scale)
                        end
                    end
                end
                --]]
            end
        end
    end

    --log
    renderLog(logtext)
end

function drawTextWithImages(text, textParams, images, imageScales)
    local x, y, r, sx, sy, ox, oy, kx, ky = unpack(textParams)

    local cleanedText = text:gsub("{%d+}", "    ")

    if fontData.FONT_GLYPH_PROBLEM or false  then
        cleanedText = text:gsub("{%d+}", " ")
    end

    love.graphics.print(cleanedText, x, y, r, sx, sy, ox, oy, kx, ky)

    local font = love.graphics.getFont()
    local fontHeight = font:getHeight()

    local currentX = (x - ox  * sx)  + (fontData.FONT_OFFSET_X or 0)

    for beforeText, label in text:gmatch("([^{}]*){(%d+)}") do
        currentX = currentX + font:getWidth(beforeText) * sx

        local imgIndex = tonumber(label)
        if imgIndex and images[imgIndex] then
            local img = images[imgIndex]
            local scaleX, scaleY = unpack(imageScales)
            local imgWidth = img:getWidth()
            local imgHeight = img:getHeight()

            local imgX = currentX
            local imgY = y + (fontHeight * sy - imgHeight * scaleY) / 2 - oy * sy + (fontData.FONT_OFFSET_Y or 0)

            if not Config.useGlyphColorFromTheme then
                love.graphics.setColor(1, 0, 0)
            end

            love.graphics.draw(img, imgX, imgY, r, scaleX, scaleY, 0, 0, kx, ky)

            currentX = currentX + imgWidth * scaleX
        end
    end
end

function love.quit()

end

function renderLog(string)
    if Config.logtext then
        love.graphics.print(string, 400, 570, 0, 0.2, 0.2, font:getWidth(string) / 2, font:getHeight() / 2)
    end
end

function getActiveMenuField()
        if activeMenuField == "countdown" and keyPressed == "down" then
            activeMenuField = "stopwatch"
        elseif activeMenuField == "countdown" and keyPressed == "up" then
            activeMenuField = "watch"
        elseif activeMenuField == "stopwatch" and keyPressed == "down" then
            activeMenuField = "watch"
        elseif activeMenuField == "stopwatch" and keyPressed == "up" then
            activeMenuField = "countdown"
        elseif activeMenuField == "watch" and keyPressed == "down" then
            activeMenuField = "countdown"
        elseif activeMenuField == "watch" and keyPressed == "up" then
            activeMenuField = "stopwatch"
        end

        return activeMenuField
end

function editCountDown()
        timerRunning = false
        isPaused = false
        savedTime = 0
        hours, minutes, seconds = 0, 0, 0
        activeField = "hours"
end

function startPauseCountDown()
    if not timerRunning then
        if savedTime == 0 then
            timeLeft = hours * 3600 + minutes * 60 + seconds
        else
            timeLeft = savedTime
        end

        timerRunning = true
        isPaused = false
    else
        if math.floor(timeLeft) > 10 then
            timerRunning = false
            isPaused = true
        end
    end
end

function startPauseStopWatch()
    if not timerRunning then
        if savedTime == 0 then
            timeLeft = hours * 3600 + minutes * 60 + seconds
        else
            timeLeft = savedTime
        end

        timerRunning = true
        isPaused = false
    else
        timerRunning = false
        isPaused = true
    end
end

function setAudioCountDown()
        soundDataCD = love.sound.newSoundData(sampleRate * totalDuration, sampleRate, 16, 1)

        for i = 0, totalDuration - 1 do
            startSample = i * sampleRate

            if i < 9 then
                factor = 2
                for j = 0, sampleRate * duration - 1 do
                    local sample = math.sin(factor * math.pi * frequency * (j / sampleRate))
                    soundDataCD:setSample(startSample + j, sample)
                end
            elseif i == 9 then
                factor = 1

                for j = 0, sampleRate - 1 do
                    local sample = math.sin(factor * math.pi * frequency * (j / sampleRate))
                    soundDataCD:setSample(startSample + j, sample)
                end
            end
        end

        soundCD = love.audio.newSource(soundDataCD)
end

function setAudioStopWatchMinute()
        factor = 1
        i = 0
        soundDataSWminute = love.sound.newSoundData(sampleRate * totalDuration, sampleRate, 16, 1)

        startSample = i * sampleRate

        for j = 0, sampleRate * duration - 1 do
            local sample = math.sin(factor* math.pi * frequency * (j / sampleRate))
            soundDataSWminute:setSample(startSample + j*2, sample)
        end

        soundSWminute = love.audio.newSource(soundDataSWminute)
end

function setAudioStopWatchHalfMinute()
        factor = 1
        i = 0
        soundDataSWhalfMinute = love.sound.newSoundData(sampleRate * totalDuration, sampleRate, 16, 1)

        startSample = i * sampleRate

        for j = 0, sampleRate * duration - 1 do
            local sample = math.sin(factor* math.pi * frequency * (j / sampleRate))
            soundDataSWhalfMinute:setSample(startSample + j, sample)
        end

        soundSWhalfMinute = love.audio.newSource(soundDataSWhalfMinute)
end

function saveTheme(index)
        love.filesystem.write(Config.saveFileTheme, index)
end

function saveFont(index)
    love.filesystem.write(Config.saveFileFont, index)
end

function getSavedTheme()
    return tonumber((love.filesystem.read(Config.saveFileTheme))) or 1
end

function getSavedFont()
    return tonumber((love.filesystem.read(Config.saveFileFont))) or 1
end

function setFontActual(index)
    fontData = Config.Font[index]
    font = love.graphics.setNewFont(fontData.FONT, fontData.FONT_SIZE)
end

function loadGlyph()
    a = love.graphics.newImage(Config.Glyph.a)
    b = love.graphics.newImage(Config.Glyph.b)
    c = love.graphics.newImage(Config.Glyph.c)
    x = love.graphics.newImage(Config.Glyph.x)
    y = love.graphics.newImage(Config.Glyph.y)
    z = love.graphics.newImage(Config.Glyph.z)
end

function getWidthFont(string)
    return font:getWidth(string)
end

--weather
function isInternetAvailable()
    local testUrl = "http://www.google.com"
    local _, status = http.request(testUrl)
    return status == 200
end

function getWeather(url)
    local response_body = {}
    local result, status = http.request{
        url = url,
        sink = ltn12.sink.table(response_body)
    }
    if status == 200 then
        return json.decode(table.concat(response_body))
    else
        return nil, "Error: Unable to fetch data (status code: " .. status .. ")"
    end
end

function loadIcon(icon)
    local iconUrl = "http://openweathermap.org/img/wn/" .. icon .. "@2x.png"
    local response_body = {}
    local result, status = http.request{
        url = iconUrl,
        sink = ltn12.sink.table(response_body)
    }
    if status == 200 then
        local imgData = love.filesystem.newFileData(table.concat(response_body), "weather_icon.png")
        return love.graphics.newImage(imgData)
    else
        return nil, "Error: Unable to load icon (status code: " .. status .. ")"
    end
end

function saveWeatherData(data)
    local file = love.filesystem.newFile(Config.weatherCurrentFileName, "w")
    if file then
        file:write(json.encode(data))
        file:close()
    else
        errorMessage = "Error: Unable to save weather data to file."
    end
end

function fileExistsCurrentWeather()
    return love.filesystem.exists(Config.weatherCurrentTimeLastTimeUpdateFileName)
end

function fileExistsForecastWeather()
    return love.filesystem.exists( Config.weatherForecastTimeLastTimeUpdateFileName)
end

function loadWeatherData()
    if love.filesystem.getInfo(Config.weatherCurrentFileName) then
        local file = love.filesystem.newFile(Config.weatherCurrentFileName, "r")
        if file then
            local contents = file:read()
            file:close()
            return json.decode(contents)
        else
            errorMessage = "Error: Unable to load weather data from file."
        end
    end
    return nil
end

function updateWeather()
    if not isInternetAvailable() then
        errorMessage = "No internet connection available."
        return
    end

    CITY = Config.cities[currentCityIndex]
    URL_CURRENT = "http://api.openweathermap.org/data/2.5/weather?q=" .. CITY .. "&appid=" .. Config.API_KEY .. "&units=metric"
    URL_FORECAST = "http://api.openweathermap.org/data/2.5/forecast?q=" .. CITY .. "&appid=" .. Config.API_KEY .. "&units=metric"

    currentWeather, errorMessage = getWeather(URL_CURRENT)
    ---------forecastWeather, errorMessage = getWeather(URL_FORECAST)

    if currentWeather then
        weatherIcon = currentWeather.weather[1].icon
        iconImage, errorMessage = loadIcon(weatherIcon)
        saveWeatherData(currentWeather)
    end

    if forecastWeather then
        for i = 1, 5 do
            local day = forecastWeather.list[(i-1)*8 + 1]
            local icon = day.weather[1].icon
            forecastIcons[i] = loadIcon(icon)
        end
    end

    lastUpdateTime = love.timer.getTime() -- Обновляем время последнего обновления
end



