
local share = require "plugin.share"
share.init()

local button

-- Some image/group we want to share
local group = display.newGroup()
local image = display.newImage( group, "photo.png" )
image:scale(.5,.5)
image.x, image.y = display.contentCenterX, display.contentCenterY+20
local text = display.newText( group, "{", image.x+3, image.y+55, native.systemFontBold, 100 )
text.rotation = 90
text:setFillColor(0.1)

-- Save image to system.DocumentsDirectory
-- Notice: Instagram accepts only 612 px wide/high or higher!
timer.performWithDelay( 1000, function () -- display.save needs a small delay to work
    display.save( group, "photo.png", system.DocumentsDirectory )
    button:setEnabled(true)
end)

-- Share it
local function buttonHandler()
	share.popUp {
        imageName="photo.png", -- must filename of png in system.DocumentsDirectory
        message="Check out my #moustache",
        url="http://moustache.net",
        origin = { x=384, y=140 } --  If iPad: the point the share popup emerges from.
    }
end

-- Share button
local widget = require "widget"

button = widget.newButton
{
    label = "Share",
    onRelease = buttonHandler,
    shape="roundedRect",
    width = 100,
    height = 35,
    cornerRadius = 3,
    fillColor = { default={ 1, 1, 1, 1 }, over={ 1, 1, 1, 0.5 } },
}
button.x, button.y = 160, 60
button:setEnabled(false)


