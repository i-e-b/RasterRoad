-- Test of 'outrun' style raster effect with pixel shader

local screenWidth, screenHeight
local shader, mesh
local texture1


function love.load()
  love.window.fullscreen = (love.system.getOS() == "Android")
  screenWidth, screenHeight = love.graphics.getDimensions( )

  texture1 = love.graphics.newImage("assets/road.png")


  local r = screenWidth
  local h = screenHeight
  local t = screenHeight / 3
  mesh = love.graphics.newMesh( { -- x,y, u,v (screen, texture)
    { 0,t,  0,0 }, { r,h,  1,1 }, { 0,h,  0,1 }, -- triangle #1
    { r,h,  1,1 }, { r,t,  1,0 }, { 0,t,  0,0 }  -- triangle #2
  }, "triangles" )

  shader = love.graphics.newShader(
[[
  extern float sharpness; // 1 to about 100
  extern float nearness; // 0 to 1
  extern float strength; // 1 to about 250. Higher is a larger radius
  vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float fy = pow(1 - tc.y + nearness, sharpness) / strength;
    float z = 1; //(1 - tc.y) + 1;
    return Texel(texture, vec2(tc.x + fy, tc.y)) / z;
  }
]] )
end

function love.update(dt)
  if (dt > 0.1) then return end

end

function love.draw()
    local x = love.mouse.getX() / screenWidth
    local y = love.mouse.getY() / screenHeight
    shader:send( "sharpness", 1 + (y * 20.0))
    shader:send( "nearness", y)
    shader:send( "strength", 1 + (x * 170))
    love.graphics.setShader(shader)
    mesh:setTexture( texture1 )
    love.graphics.draw(mesh, 0, 0)
    love.graphics.setShader()
end
