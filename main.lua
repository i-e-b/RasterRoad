-- Test of 'outrun' style raster effect with pixel shader

local screenWidth, screenHeight
local shader, mesh
local texture1, texture2, offsetImg, offsetData
local time = 0


function love.load()
  love.window.fullscreen = (love.system.getOS() == "Android")
  screenWidth, screenHeight = love.graphics.getDimensions( )

  texture1 = love.graphics.newImage("assets/road.png")
  texture2 = love.graphics.newImage("assets/road2.png")

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
                        // z position encoded in 16 bits across blue and alpha

  extern Image alternate; // the 'other' scanline image. This is used to fake road
                          // lines and distance. The main and alt images should be
                          // less different as distance increases, to limit aliasing.

  extern float movement; // increase proportional to speed.

  extern float fog; // higher is more foggy

  vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float haze = pow((1 - tc.y) + 1, fog);

    // X offset, for left right curvature of road
    float fx = (Texel(offsets, vec2(0, tc.y)).r * 2) - 1;
    fx += (Texel(offsets, vec2(0, tc.y)).g) / 127;

    // Y offset, to simulate Z position of road
    float fy = (Texel(offsets, vec2(0, tc.y)).b) * 2;
    fy += (Texel(offsets, vec2(0, tc.y)).a) / 127;

    // switch between two textures to simulate scanline palette swap effect
    // switches happen more often at higher 'z-distance'
    float checker = floor(mod((2 / fy) + movement, 1) * 2); // change constant to alter checker scale
    checker = clamp(checker,0,1);

    vec4 sample1 = Texel(texture, vec2(tc.x + fx, fy));
    vec4 sample2 = Texel(alternate, vec2(tc.x + fx, fy));

    return mix(sample1, sample2, checker) / haze; // divide by z to get haze effect
  }
  ]] )
  shader:send("alternate", texture2)
end

function love.update(dt)
  if (dt > 0.1) then return end
  time = time + (dt)
end

-- saturate value between 0 and 1
function sat01(v)
  return math.min(1,math.max(0, v))
end

-- saturate value between 0 and 2
function sat02(v)
  return math.min(2,math.max(0, v))
end

-- split a number between two bytes
function splitBytes(n)
  local upper = 32258 * n
  local lower = upper % 254
  return upper / 254, lower
end

function updateScanlines (position)
  local y = love.mouse.getY() / screenHeight
  local carPos = (2 * love.mouse.getX() / screenWidth) - 1 -- should be affected by steering

  local z = 0
  local x = 1
  local dx = 0
  local scale = 0.000001 -- curves are sensitive!
  local gamma = 1.5 * y + 0.5 -- hills < 1 > valleys

  for i=(screenHeight-1),0,-1 do -- bottom to top is near to far.
    local fz = 0.5 + (i / screenHeight)
    local d = (position / 10) + ((screenHeight - i) / screenHeight)

    x = x + (dx*fz)
    local xupper, xlower = splitBytes(sat02((x + carPos)))

    -- test: S-bend with a straight afterwards
    -- TODO: read these out of a distance/cuvature list
    d = d % 10
    if (d < 2) then
    elseif (d < 4) then
      dx = dx + (7 * scale) -- curve left
    elseif (d < 6) then
      dx = dx - (3 * scale) -- curve right
    else
      -- straight
    end

    z = math.pow(i / screenHeight, gamma)
    local zupper, zlower = splitBytes(z)
    -- encode curve shift into red+green. hill height into blue+alpha
    offsetData:setPixel(0, i, xupper, xlower, zupper, zlower)
  end
  offsetImg = love.graphics.newImage( offsetData )
end


function drawCar ()
  local x = love.mouse.getX()
  local y = screenHeight - 40

  love.graphics.setColor(0, 0, 0, 100)
  love.graphics.rectangle("fill", x-10, y+17, 70, 14)

  love.graphics.setColor(244, 0, 0, 255)
  love.graphics.rectangle("fill", x, y, 40, 20)

  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.rectangle("fill", x, y-5, 10, 30)
  love.graphics.rectangle("fill", x+40, y-5, 10, 30)
end

function love.draw()
  local position = time * 4
  love.graphics.setColor(255, 255, 255, 255)
  updateScanlines(position)

  love.graphics.setBackgroundColor( 112, 159, 237 )
  shader:send("offsets", offsetImg)
  shader:send("movement", position) -- 10 x time is about the limit.
  shader:send("fog", 0.3)

  love.graphics.setShader(shader)
  mesh:setTexture( texture1 )
  --mesh:setTexture( offsetImg )
  love.graphics.draw(mesh, 0, 0)
  love.graphics.setShader()

  drawCar()
end
