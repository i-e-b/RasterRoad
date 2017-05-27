-- Test of 'outrun' style raster effect with pixel shader

local screenWidth, screenHeight
local shader, mesh
local texture1, offsetImg, offsetData
local time = 0


function love.load()
  love.window.fullscreen = (love.system.getOS() == "Android")
  screenWidth, screenHeight = love.graphics.getDimensions( )

  texture1 = love.graphics.newImage("assets/road.png")

  offsetData = love.image.newImageData(1,screenHeight)
  offsetImg = love.graphics.newImage( offsetData ) -- store scanline offsets

  local r = screenWidth
  local h = screenHeight
  local t = screenHeight / 3
  mesh = love.graphics.newMesh( { -- x,y, u,v (screen, texture)
    { 0,t,  0,0 }, { r,h,  1,1 }, { 0,h,  0,1 }, -- triangle #1
    { r,h,  1,1 }, { r,t,  1,0 }, { 0,t,  0,0 }  -- triangle #2
  }, "triangles" )

  shader = love.graphics.newShader(
[[
  extern Image offsets; // shift -1..1 encoded as -1..0 in red
                        // and 0..1 in green.
                        // which maps to 0..1 for both in GLSL

  vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float z = (1 - tc.y) + 1;
    float fx = (Texel(offsets, vec2(0, tc.y)).r / 2) * -1;
    fx += (Texel(offsets, vec2(0, tc.y)).g / 2);
    return Texel(texture, vec2(tc.x + fx, tc.y)) / z;
  }
]] )
end

function love.update(dt)
  if (dt > 0.1) then return end
  time = time + (dt * 10)
  updateScanlines ()
end

function updateScanlines ()
  for i=0, (screenHeight-1) do
    local wiggle = math.sin((i+time) / 40)
    offsetData:setPixel(0, i, math.min(0, wiggle) * -255, math.max(0, wiggle) * 255, 0, 255)
  end
  offsetImg = love.graphics.newImage( offsetData )
end

function love.draw()
  -- TODO: draw a lookup texture for the road curvature. x:1, y:height
  -- send this to the pixel shader and offset directly.
    local x = love.mouse.getX() / screenWidth
    local y = love.mouse.getY() / screenHeight
    --[[shader:send( "sharpness", 1 + (y * 20.0))
    shader:send( "nearness", y)
    shader:send( "strength", 1 + (x * 170))]]
    shader:send("offsets", offsetImg)

    love.graphics.setShader(shader)
    mesh:setTexture( texture1 )
    --mesh:setTexture( offsetImg )
    love.graphics.draw(mesh, 0, 0)
    love.graphics.setShader()
end
