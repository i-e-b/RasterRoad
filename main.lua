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
  extern Image offsets; // shift -1..1 encoded in 16 bits across the
                        // red and green channels.

  vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float z = (1 - tc.y) + 1;
    float fx = (Texel(offsets, vec2(0, tc.y)).r) - 0.5;
    fx += (Texel(offsets, vec2(0, tc.y)).g - 0.5) / 254;
    float fy = (Texel(offsets, vec2(0, tc.y)).b);
    return Texel(texture, vec2(tc.x + fx, fy)); // divide by z to get night effect
  }
]] )
end

function love.update(dt)
  if (dt > 0.1) then return end
  time = time + (dt * 24)
  updateScanlines ()
end

function sat01(v)
  return math.min(1,math.max(0, v))
end

function updateScanlines ()
  -- left/right shift is encoded into red and green channels for precision
  -- TODO: encode virtual 'z' into blue, and shift tc.y based on that.
  for i=0, (screenHeight-1) do
    local wiggle = (math.sin((i+time) / 40) / 20) + 1
    local upper = 32258 * wiggle
    local lower = upper % 254
    local z = sat01((i) / screenHeight)
    offsetData:setPixel(0, i, upper / 254, lower, z * 255, 255)
  end
  offsetImg = love.graphics.newImage( offsetData )
end

function love.draw()
    shader:send("offsets", offsetImg)

    love.graphics.setShader(shader)
    mesh:setTexture( texture1 )
    --mesh:setTexture( offsetImg )
    love.graphics.draw(mesh, 0, 0)
    love.graphics.setShader()
end
