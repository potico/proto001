pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- number of Z layers
zlayers = 4

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
for i=0,15 do dx[31-i]=dx[i] end
dx[32] = 2
-- sum of cell widths
sdx = { [-1]=-dx[0], [0]=0 }
for i=0,31 do
  dx[i] /= 20.05
  sdx[i+1] = sdx[i] + dx[i]
end

function offset(x) -- x: 0..32
  return sdx[x\1]+x%1*dx[x\1+1]
end

function prev_layer(n) return (n - 2) % zlayers + 1 end

function next_layer(n) return n % zlayers + 1 end

function init_layer()
  dots, walls = {}, {}
  for j=0,31 do
    for i=0,31 do
      if max(abs(15.5-i),abs(15.5-j))>8 then -- ignore inner layer
        local s = mget(i,j)
        if s==1 or s==2 then
          add(dots,{x=i,y=j,spr=s,alive=true})
        elseif s>2 then
          add(walls,{x=i,y=j})
        end
      end
    end
  end
  layer = { dots=dots, walls=walls }
  return layer
end

function _init()
  music(1)
  p =
  {
    -- z is 0..3
    x=15,y=4,cx=15,cy=4,z=1,
    dir=1,wantdir=1,move=0
  }

  layers = {}
  for i=1,zlayers do
    layers[i] = init_layer()
  end
end

function cango(dir)
  local cx,cy = p.cx,p.cy
  if dir==0 then cx-=1 end
  if dir==1 then cx+=1 end
  if dir==2 then cy-=1 end
  if dir==3 then cy+=1 end
  return mget(cx,cy) <= 2, cx, cy
end

function _update()
  for i=0,3 do if (btn(i)) p.wantdir=i end

  if p.move == 0 then
    if cango(p.wantdir) then
      p.dir = p.wantdir
    end
    local b, cx, cy = cango(p.dir)
    if b then
      p.wantcx, p.wantcy = cx, cy
    end
  end

  p.move += 0.25
  if p.move == 1 then
    p.cx,p.cy = p.wantcx,p.wantcy
    p.move = 0
  end

  p.x = p.cx + p.move * (p.wantcx - p.cx)
  p.y = p.cy + p.move * (p.wantcy - p.cy)

  -- handle teleports
  local tx, ty = 0, 0
  if p.y < 0 or p.y == 32 then
    tx = ({[9]=4, [22]=-4})[p.cx]
    ty = p.y < 0 and 8 or -8
    p.z = prev_layer(p.z)
  elseif p.x < 0 or p.x == 32 then
    tx = p.x < 0 and 8 or -8
    ty = ({[7]=5, [24]=-5})[p.cy]
    p.z = prev_layer(p.z)
  elseif p.x >= 8 and p.x < 24 and p.y >= 8 and p.y < 24 then
    if p.x == 8 or p.x > 23 then
      tx = p.x == 8 and -8 or 8
      ty = ({[12]=-5, [19]=5})[p.cy]
    else
      tx = ({[13]=-4, [18]=4})[p.cx]
      ty = p.y == 8 and -8 or 8
    end
    p.z = next_layer(p.z)
  end
  p.cy += ty p.wantcy += ty p.y += ty
  p.cx += tx p.wantcx += tx p.x += tx
end

function _draw()
  cls()

  local zx = expz(min(p.x, 31-p.x))*1.8
  local zy = expz(min(p.y, 31-p.y))*1.8
  local off = 15
  if p.x > p.y then
    local mz = 1 - zy
    local dz = offset(p.x) - offset(p.y)
    draw_layer(prev_layer(p.z), 160*mz - 160*dz*zy*8/20.05 + off, 160*mz + off, 160*zy)
  else
    local mz = 1 - zx
    local dz = offset(p.y) - offset(p.x)
    draw_layer(prev_layer(p.z), 160*mz + off, 160*mz - 160*dz*zx*8/20.05 + off, 160*zx)
  end

  if p.move > 0.5 then
    spr(51,60,60)
  else
    spr(52+p.dir,60,60)
  end

  print(p.x,2,2,9)
  print(p.y,2,8,9)
  print(p.z,2,14,9)

  print(zx,2,24,10)
  print(zy,2,30,10)
end

function draw_layer(n, x0,y0,w, depth)
  depth = depth or 0
  camera(-x0, -y0)

  -- draw background
  fillp(0x5a5a.8)
  foreach(layers[n].walls, function(d)
    local sx = w*dx[d.x]
    local sy = w*dx[d.y]
    local x,y = w * sdx[d.x], w * sdx[d.y]
    rectfill(x,y,x+sx+1,y+sy+1,12)
--    rect(x,y,x+sx,y+sy,10)
  end)
  fillp()

  -- draw empty space
  foreach(layers[n].dots, function(d)
    local sx = w*dx[d.x]
    local sy = w*dx[d.y]
    local x,y = w * sdx[d.x], w * sdx[d.y]
    rectfill(x,y,x+sx,y+sy,0)
  end)

  -- draw pellets
  foreach(layers[n].dots, function(d)
    if d.alive then
      -- collision!
      if n == p.z and d.x == p.cx and d.y == p.cy then
        d.alive = false
      end
      local sx = w*dx[d.x]
      local sy = w*dx[d.y]
      local x,y = w * sdx[d.x], w * sdx[d.y]
      rectfill(x+sx*9/20,y+sy*9/20,x+sx*11/20,y+sy*11/20,6)
    end
  end)

  if depth >= 2 then
    camera()
    return
  end
  local d = 12.05 * w / 20.05
  draw_layer(next_layer(n), x0 + w * sdx[8], y0 + w * sdx[8], w - d, depth + 1)
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
88888888cccccccc0000000000aaaa0000aaaa0000aaaa000000000000aaaa000000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc000000000aaaaaa00aaaaaa00aaaaaa00a0000a00aaaaaa00000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc00000000aaaaaaaa00aaaaaaaaaaaa00aaa000aaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc00000000aaaaaaaa000aaaaaaaaaa000aaaa0aaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc00000000aaaaaaaa0000aaaaaaaa0000aaaaaaaaaaaa0aaa0000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc00000000aaaaaaaa000aaaaaaaaaa000aaaaaaaaaaa000aa0000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc000000000aaaaaa00aaaaaa00aaaaaa00aaaaaa00a0000a00000000000000000000000000000000000000000000000000000000000000000
88888888cccccccc0000000000aaaa0000aaaa0000aaaa0000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0916161616161616120211161616161616161616161102121616161616161609000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020102020202020202020202020202020202020202020202020201020217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702101424030802060303030802101414100208030303060208032414100217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702111612020202020202020202111616110202020202020202021216110217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020202020603030303030802020202020208030303030306020202020217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702050205020202020202020202101414100202020202020202020502050217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1202040221141302060308020603261616260306020803060213142102040212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202040211161202020202020202020202020202020202020212161102040202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1302070202020202303030303002303030300230303030300202020202070213000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020206030303303030303030303030303030303030300303030602020217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702050202020202303030303030303030303030303030300202020202050217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702040205020502303030303030303030303030303030300205020502040217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702040204020402023030300000000000000000303030020204020402040217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702070207020402303030300000000000000000303030300204020702070217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020202020402303030300000000000000000303030300204020202020217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702101414142202303030300000000000000000303030300222141414100217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702101414142202303030300000000000000000303030300222141414100217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020202020402303030300000000000000000303030300204020202020217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702070207020402303030300000000000000000303030300204020702070217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702040204020402023030300000000000000000303030020204020402040217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702040205020502303030303030303030303030303030300205020502040217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702050202020202303030303030303030303030303030300202020202050217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020206030303303030303030303030303030303030300303030602020217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1302070202020202303030303002303030300230303030300202020202070213000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202040211161202020202020202020202020202020202020212161102040202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1202040221141302060308020603261616260306020803060213142102040212000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702050205020202020202020202101414100202020202020202020502050217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020202020603030303030802020202020208030303030306020202020217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702111612020202020202020202111616110202020202020202021216110217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702101424030802060303030802101414100208030303060208032414100217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1702020102020202020202020202020202020202020202020202020201020217000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0916161616161616120211161616161616161616161102121616161616161609000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010e0000185231f5232b1032420323203292032320329203000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200
010c000023574235022f570185002a5701c50027570000002f5702a5702b5000050027575005000050000500245740050030570005002b570005002857000500305702b5702b5020050228575005020050200502
010c3f00235741a5002f570185002a5701c50027570005002f5702a5702b500005002757500500005000050027574285702957000500295702a5702b570005002b5702c5702b5002d570285002f5752f5052f500
010c00001852300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001f52300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00002e3732c3032a37324303293732430326373243032537324303273032470024400000002d571005002d571002000000000000000000000000000000000000000000000000000000000000000000000200
010c0000002301351002130021300c230135100213002130002301351002130021300c230135100213002130002301351002130021300c230135100213002130002301351002130021300c230135100213002130
0110000023504215012350123501235012150123501235052f5042d5012f5012f5012f5012d5012f5012f50500000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01064744
02 02064344

