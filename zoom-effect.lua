-- Zoom and Rotate Effect Script for Aseprite with Zoom In, Zoom Out, and Rotation Options

-- Function to update checkboxes based on selection
local function updateZoomOptions(dlg, option)
  if option == "zoomIn" then
    dlg:modify{id="zoomOut", selected=false}
  elseif option == "zoomOut" then
    dlg:modify{id="zoomIn", selected=false}
  end
end

-- Function to enable or disable rotation options based on selection
local function updateRotationOptions(dlg)
  local rotate = dlg.data.rotate
  dlg:modify{id="rotationAngle", enabled=rotate}
  dlg:modify{id="rotationDirection", enabled=rotate}
end

-- Prompt the user for input
local dlg = Dialog("Zoom and Rotate Effect")
dlg:number{ id="zoomFactor", label="Zoom Factor (%)", text="200", decimals=0 }
dlg:number{ id="numFrames", label="Number of Frames", text="10", decimals=0 }
dlg:combobox{ id="moveDirection", label="Move Direction",
              options={"Centered", "Left", "Right", "Up", "Down", "Top Left", "Top Right", "Bottom Left", "Bottom Right"},
              selected=1 }
dlg:check{ id="zoomIn", label="Zoom In", selected=true, onclick=function() updateZoomOptions(dlg, "zoomIn") end }
dlg:check{ id="zoomOut", label="Zoom Out", selected=false, onclick=function() updateZoomOptions(dlg, "zoomOut") end }
dlg:check{ id="rotate", label="Rotate", selected=false, onclick=function() updateRotationOptions(dlg) end }
dlg:number{ id="rotationAngle", label="Rotation Angle (degrees)", text="0", decimals=0, enabled=false }
dlg:combobox{ id="rotationDirection", label="Rotation Direction", options={"Left", "Right"}, selected=1, enabled=false }
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
local rotate = data.rotate
local rotationAngle = data.rotationAngle
local rotationDirection = data.rotationDirection

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

-- Function to rotate an image
local function rotateImage(img, angle, direction)
  local rotatedImage = Image(img.width, img.height, img.colorMode)
  rotatedImage:clear()

  local centerX = img.width / 2
  local centerY = img.height / 2
  local radians = math.rad(angle * (direction == "Right" and -1 or 1))

  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local srcX = math.floor(centerX + (x - centerX) * math.cos(radians) - (y - centerY) * math.sin(radians))
      local srcY = math.floor(centerY + (x - centerX) * math.sin(radians) + (y - centerY) * math.cos(radians))
      
      if srcX >= 0 and srcX < img.width and srcY >= 0 and srcY < img.height then
        local color = img:getPixel(srcX, srcY)
        rotatedImage:putPixel(x, y, color)
      end
    end
  end

  return rotatedImage
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

-- Add frames and apply the zoom and rotation effects progressively
local stepFactor = math.abs((zoomFactorPercentage - 1) / (numFrames - 1))  -- Ensure stepFactor is positive
local stepRotation = rotationAngle / numFrames

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
  local rotatedImage = scaledImage

  if rotate then
    local currentRotation = stepRotation * (i - 1)
    rotatedImage = rotateImage(scaledImage, currentRotation, rotationDirection)
  end

  local centeredImage = centerImage(rotatedImage, sprite.width, sprite.height, 0, 0)
  
  -- Create a new frame and add the centered image as a new cel
  local newFrame = sprite:newEmptyFrame()
  local newCel = sprite:newCel(layer, newFrame, centeredImage, Point(0, 0))
end

-- Alert user of completion
app.alert("Zoom effect applied successfully!")
