pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

--[[

      +-----------------+
      |     16x16       |
      |   map chunk     |
      |   with size     | 12.05
      |   correction    |
      |                 |
20.05 |         +-------+
      |         |
      |         |
      |         | 8
      |         |
      +---------+

]]--

-- steps of (20.05/8)^n/8 for the zoom level
expt = { [0]=1, 1.1248, 1.2652, 1.4231, 1.6008, 1.8006, 2.0253, 2.2781, 2.5625, }
function expz(x)
  local n=x%8
  local t=n%1
  return (1-t)*expt[n\1]+t*expt[n\1+1]
end

-- cell width: steps of 2^n/8 for 0..7 then just 1 for 8..15
dx = { [0]=2, 1.83, 1.68, 1.54, 1.41, 1.30, 1.19, 1.09, 1, 1, 1, 1, 1, 1, 1, 1 }
-- sum of cell widths
sdx = {}
for i=0,15 do
  dx[i] /= 20.05
  sdx[i] = (sdx[i-1] or 0) + dx[i]
end

function _init()
  p =
  {
    -- z is 0..3
    x=1,y=1,z=1
  }
end

function _update()
  if btnp(0) then p.x-=1 end
  if btnp(1) then p.x+=1 end
  if btnp(2) then p.y-=1 end
  if btnp(3) then p.y+=1 end

if p.x>8 and p.y > 8 then
  p.x -= 8
  p.y -= 8
end

alpha = 20.05/8
--  while test >= alpha do test /= alpha end
end

function _draw()
  cls()

--  zx = expz(p.x+4.4)
--  zy = expz(p.y+4.4)
  zx = expz(p.x)*1.6645
  zy = expz(p.y)*1.6645
  if p.x > p.y then
    local mz = 1 - zy
    local dz = sdx[p.x] - sdx[p.y]
    draw_map(160*mz - 160*dz*zy*8/20.05, 160*mz, 160*zy)
  else
    local mz = 1 - zx
    local dz = sdx[p.y] - sdx[p.x]
    draw_map(160*mz, 160*mz - 160*dz*zx*8/20.05, 160*zx)
  end

  spr(52,60,60)

print('x='..p.x, 103, 5, 14)
print('y='..p.y, 103, 12, 14)
print('zx='..zx, 83, 18, 10)
print('zy='..zy, 83, 24, 10)
--line(0,64,128,64,9)
end

function draw_map(x0,y0,w, depth)
  depth = depth or 0
--x0*=1.5 x0-=40
--y0*=1.5 y0-=40
--w*=1.5
  camera(-x0, -y0)
  -- draw background
  fillp(0x5a5a.8)
  for j=0,15 do
    for i=0,15 do
      if mget(i,j)>2 then
        if i<8 or j<8 then
          local sx = w * dx[i] * 0.5
          local sy = w * dx[j] * 0.5
          local x, y = w * sdx[i], w * sdx[j]
--size=w
          rectfill(x-sx,y-sy,x+sx+1,y+sy+1,12)
          --rect(x-sx,y-sy,x+sx+1,y+sy+1,10)
        end
      end
    end
  end
  fillp()
  -- draw empty space
  for j=0,15 do
    for i=0,15 do
      if i<8 or j<8 then
        if mget(i,j)<=2 then
          local sx = w * dx[i] * 0.5
          local sy = w * dx[j] * 0.5
          local x, y = w * sdx[i], w * sdx[j]
          rectfill(x-sx,y-sy,x+sx,y+sy,0)
          --rect(x-size*.75,y-size*.75,x+size*.75,y+size*.75,3)
        end
      end
    end
  end
  -- draw pellets
  for j=0,15 do
    for i=0,15 do
      if i<8 or j<8 then
        if mget(i,j)<=2 then
          --local size=w*(1-min(i,j)/16)
          local sx = w * dx[i] * 0.5
          local sy = w * dx[j] * 0.5
          local x, y = w * sdx[i], w * sdx[j]
          --circfill(x,y,size/6,7)
if i == 5 then
print(j,x-sx/10,y-sy/10,7)
else
          rectfill(x-sx/10,y-sy/10,x+sx/10,y+sy/10,6)
end
        end
      end
    end
  end

  if depth >= 2 then
    camera()
    return
  end
  local d = 12.05 * w / 20.05
  draw_map(x0 + d, y0 + d, w * 8 / 20.05, depth + 1)
end

__gfx__
0000000000000000000000000000000000c00c00000000000000000000c00c00000000000000000000000c0000c0000000000000000000000000000000000000
0000000000000000000000000000000000c00c00000000000000000000c00c00000000000000000000000c0000c0000000000000000000000000000000000000
000000000057750000000000cccccccc00c00c00000cc000000ccccc00c00c00ccccc00000000000000000cccc00000000000000000000000000000000000000
0000000000777700000770000000000000c00c0000c00c0000c0000000c00c0000000c0000000000000000000000000000000000000000000000000000000000
0000000000777700000770000000000000c00c0000c00c0000c0000000c00c0000000c0000000000000000000000000000000000000000000000000000000000
000000000057750000000000cccccccc00c00c0000c00c00000ccccc000cc000ccccc000000000cc0000000000000000cc000000000000000000000000000000
0000000000000000000000000000000000c00c0000c00c0000000000000000000000000000000c00000000000000000000c00000000000000000000000000000
0000000000000000000000000000000000c00c0000c00c0000000000000000000000000000000c00000000000000000000c00000000000000000000000000000
0000000000c0000000000c00000000000000000000c000000000000000000c000000000000c00c0000c00c000000000000000000000000000000000000000000
0000000000c0000000000c00000000000000000000c000000000000000000c000000000000c00c0000c00c000000000000000000000000000000000000000000
0000cccc00c0000000000c00cccc0000cccccccc00c000000000000000000c000000cccc00c000cccc000c00cccc000000000000000000000000000000000000
000c000000c0000000000c000000c0000000000000c000000000000000000c00000c000000c0000000000c000000c00000000000000000000000000000000000
00c00000000c00000000c00000000c000000000000c000000000000000000c0000c00000000c00000000c00000000c0000000000000000000000000000000000
00c000000000cccccccc000000000c000000000000c00000cccccccc00000c0000c000cc0000cccccccc0000cc000c0000000000000000000000000000000000
00c00000000000000000000000000c000000000000c000000000000000000c0000c00c00000000000000000000c00c0000000000000000000000000000000000
00c00000000000000000000000000c000000000000c000000000000000000c0000c00c00000000000000000000c00c0000000000000000000000000000000000
00c0000000c00c0000c00c0000000c000000000000000c0000c00000000000000000000000c00c0000c00c0000c00c0000000000000000000000000000000000
00c0000000c00c0000c00c0000000c000000000000000c0000c00000000000000000000000c00c0000c00c0000c00c0000000000000000000000000000000000
00c0000000c000cccc000c0000000c00cccccccc000000cccc000000cccccccccccccccc00c000cccc0000cccc000c0000000000000000000000000000000000
00c0000000c0000000000c0000000c00000000000000000000000000000000000000000000c000000000000000000c0000000000000000000000000000000000
00c0000000c0000000000c0000000c00000000000000000000000000000000000000000000c000000000000000000c0000000000000000000000000000000000
00c000cc00c0000000000c00cc000c00000000cccccccccccccccccccc000000cc0000cc00c000cccccccccccc000c0000000000000000000000000000000000
00c00c0000c0000000000c0000c00c0000000c00000000000000000000c0000000c00c0000c00c000000000000c00c0000000000000000000000000000000000
00c00c0000c0000000000c0000c00c0000000c00000000000000000000c0000000c00c0000c00c000000000000c00c0000000000000000000000000000000000
88888888cccccccc000000000000000000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc00000000000000000aaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc0000000000000000aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc0000000000000000aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc0000000000000000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc0000000000000000aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc00000000000000000aaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc000000000000000000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0916161616161616161202111616161600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020102020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702101424030308020603030802101400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702111612020202020202020202111600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020202020603030303030802020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702050205020202020202020202101400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702040221141302060308020603261600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702070211161202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020202020202303030303002303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1202050206030303303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202040202020202303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1302040205020502303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702040204020402303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702070207020402023030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020202020402303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702101414142202303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
