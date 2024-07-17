-- Zoom Effect Script for Aseprite with Zoom In and Zoom Out Options

-- Prompt the user for input
local dlg = Dialog("Zoom Effect")
dlg:number{ id="zoomFactor", label="Zoom Factor (%)", text="200", decimals=0 }
dlg:number{ id="numFrames", label="Number of Frames", text="10", decimals=0 }
dlg:combobox{ id="moveDirection", label="Move Direction",
              options={"Centered", "Left", "Right", "Up", "Down", "Top Left", "Top Right", "Bottom Left", "Bottom Right"},
              selected=1 }
dlg:check{ id="zoomIn", label="Zoom In", selected=true }
dlg:check{ id="zoomOut", label="Zoom Out", selected=false }
dlg:button{ id="ok", text="OK" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()

local data = dlg.data

if data.cancel then
  return
end

local zoomFactorPercentage = data.zoomFactor / 100.0  -- Convert percentage to decimal
local numFrames = data.numFrames
local moveDirection = data.moveDirection
local zoomIn = data.zoomIn
local zoomOut = data.zoomOut

-- Ensure only one zoom option is selected
if zoomIn and zoomOut then
  app.alert("Please select either Zoom In or Zoom Out, not both.")
  return
elseif not zoomIn and not zoomOut then
  app.alert("Please select either Zoom In or Zoom Out.")
  return
end

-- Ensure a sprite is active
local sprite = app.activeSprite
if not sprite then
  app.alert("No active sprite found.")
  return
end

-- Ensure a specific layer is active
local layer = app.activeLayer
if not layer or not layer.isImage then
  app.alert("Please select an image layer.")
  return
end

-- Ensure a specific frame is active
local frame = app.activeFrame
if not frame then
  app.alert("Please select a frame.")
  return
end

-- Get the selected cel
local cel = layer:cel(frame)
if not cel then
  app.alert("No cel found in the active frame.")
  return
end

-- Get the image from the cel
local image = cel.image

-- Function to scale an image using nearest neighbor interpolation
local function scaleImageNearestNeighbor(img, factor)
  local newWidth = math.floor(img.width * factor)
  local newHeight = math.floor(img.height * factor)
  local newImage = Image(newWidth, newHeight, img.colorMode)

  for y = 0, newHeight - 1 do
    for x = 0, newWidth - 1 do
      local srcX = math.floor(x / factor)
      local srcY = math.floor(y / factor)
      local color = img:getPixel(srcX, srcY)
      newImage:putPixel(x, y, color)
    end
  end

  return newImage
end

-- Function to center the scaled image
local function centerImage(img, spriteWidth, spriteHeight, offsetX, offsetY)
  local centeredImage = Image(spriteWidth, spriteHeight, img.colorMode)
  centeredImage:clear()

  local imageWidth = img.width
  local imageHeight = img.height

  local destX = offsetX
  local destY = offsetY

  if moveDirection == "Left" or moveDirection == "Top Left" or moveDirection == "Bottom Left" then
    destX = 0
  elseif moveDirection == "Right" or moveDirection == "Top Right" or moveDirection == "Bottom Right" then
    destX = spriteWidth - imageWidth
  else
    destX = math.floor((spriteWidth - imageWidth) / 2)
  end

  if moveDirection == "Up" or moveDirection == "Top Left" or moveDirection == "Top Right" then
    destY = 0
  elseif moveDirection == "Down" or moveDirection == "Bottom Left" or moveDirection == "Bottom Right" then
    destY = spriteHeight - imageHeight
  else
    destY = math.floor((spriteHeight - imageHeight) / 2)
  end

  for y = 0, imageHeight - 1 do
    for x = 0, imageWidth - 1 do
      local color = img:getPixel(x, y)
      centeredImage:putPixel(x + destX, y + destY, color)
    end
  end

  return centeredImage
end

-- Add frames and apply the zoom effect progressively
local stepFactor = math.abs((zoomFactorPercentage - 1) / (numFrames - 1))  -- Ensure stepFactor is positive

for i = 1, numFrames do
  local currentFactor
  if zoomOut then
    currentFactor = zoomFactorPercentage - stepFactor * (i - 1)
  else
    currentFactor = 1 + stepFactor * (i - 1)
  end

  if not zoomIn then
    currentFactor = 1 / currentFactor
  end

  local scaledImage = scaleImageNearestNeighbor(image, currentFactor)
  local centeredImage = centerImage(scaledImage, sprite.width, sprite.height, 0, 0)
  
  -- Create a new frame and add the centered image as a new cel
  local newFrame = sprite:newEmptyFrame()
  local newCel = sprite:newCel(layer, newFrame, centeredImage, Point(0, 0))
end

-- Alert user of completion
app.alert("Zoom effect applied successfully!")
