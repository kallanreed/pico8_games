pico-8 cartridge // http://www.pico-8.com
version 33
__lua__

function _init()
	a=45
	pa=0
end

function _update()
 --a=(a+1)%360
 if (btnp(⬅️)) a=(a-1)%360
 if (btnp(➡️)) a=(a+1)%360
end

function rotate(x,y,cx,cy,a)
 ca=cos(a/360) sa=sin(a/360)
 x-=cx y-=cy
 local rx=x*ca-y*sa
 local ry=x*sa+y*ca
 return rx+cx,ry+cy
end

function draw_shape(points)
 for i=2,#points do
  local cx,cy=64,64
  local p1=points[i-1]
  local p2=points[i]
  local x1,y1=rotate(
   p1[1],p1[2],cx,cy,a)
  local x2,y2=rotate(
   p2[1],p2[2],cx,cy,a)
  line(x1,y1,x2,y2,7)
 end
end

function _draw()
 if (pa==a) return
 
 pa=a

 cls()
 
 --tline(x1-ay,y1-ax,x2-ay,y2-ax,
 -- 1+(7/8),0,-.125)
 --tline(x1,y1,x2,y2,1,0)
 --tline(x1+ay,y1+ax,x2+ay,y2+ax,
 -- 1+(7/8),0,-.125)
 
 draw_shape({
  {72,64},{64,72},{56,64},
  {64,56},{72,64},{64,64},
  {80,48}
 })
 
 local x1,y1,x2,y2=48,120,56,120
 
 for i=1,5 do
  local oy=(i-3)/2
  local rx1,ry1=rotate(x1,y1+oy,x1,y1,a)
  local rx2,ry2=rotate(x2,y2+oy,x1,y1,a)
  tline(rx1,ry1,rx2,ry2,3,(i-1)/8)
 end
 
 draw_tile(20,20,1,0,a/360)
 draw_rotated_tile(
  40,20,a/360,1,0,1)
  
 draw_tile2(60,20,1,0,a/360)

 draw_tile3(80,20,7,2,a/360)
 
 print(ca..","..sa.." "..a)
end

function draw_tile(x,y,tx,ty,ang)
 local cos_a,sin_a=cos(ang),-sin(ang)
 local x1,x2=-4,4

 for off_y=-4,4 do
  local _y=off_y
  tline(x+x1*cos_a-sin_a*_y,
        y+x1*sin_a+cos_a*_y,
        x+x2*cos_a-sin_a*_y,
        y+x2*sin_a+cos_a*_y,
        tx,(ty+4)/8)
 end
end

function draw_tile2(x,y,tx,ty,ang)
 local cos_a,sin_a=cos(ang),sin(ang)
 
 -- the draw box needs to be
 -- able to hold the rotated
 -- square which is srqt(2) 
 -- from corner to corner
 -- only if we care about
 -- 1:1 scale
 local w=8*sqrt(2)
 local half=w/2
 local x1,y1,x2,y2=
  -half,-half,half,half
  
 -- source box also needs to
 -- include diagonals so it
 -- needs to have r=sqrt(2)/2
 local moff=sqrt(2)/2
 
 -- center of the tile is
 -- is just .5 from the corner
 local ctx,cty=tx+.5,ty+.5
 
 -- step is the y coord on the
 -- map tile, range -moff,moff
 local step=-moff
 
 -- x col vect, left side
 local cosx=cos_a*-moff
 local sinx=sin_a*-moff

 for _y=y1,y2 do
  local siny=sin_a*step
  local cosy=cos_a*step
  tline(x+x1,y+_y,
        x+x2,y+_y,
        ctx+cosx-siny,
        cty+sinx+cosy,
        -- map mdx,mdy to
        -- output size w
        -- considering moff
        cos_a*moff*2/w,
        sin_a*moff*2/w)
  -- map output range to tile
  step+=(2*moff)/w
 end
 
 rect(x+x1,y+y1,x+x2,y+y2,6)
end


function draw_tile3(x,y,tx,ty,ang)
 printh("---------------")

 local cos_a,sin_a=cos(ang),sin(ang)
 
 -- the draw box needs to be
 -- able to hold the rotated
 -- square which is srqt(2) 
 -- from corner to corner
 -- only if we care about
 -- 1:1 scale
 
 -- source box also needs to
 -- include diagonals so it
 -- needs to have r=sqrt(2)/2
 --local moff=sqrt(2)/2
 
 local sqrt2=sqrt(2)
 local bdx=mid(-1,sqrt2*cos_a,1)
 local bdy=mid(-1,sqrt2*sin_a,1)
 
 local moff=sqrt(bdx^2+bdy^2)/2
 
 local w=16*moff*2
 local half=w/2
 local x1,y1,x2,y2=
  -half,-half,half,half
  

 -- center of the tile is
 -- is just .5 from the corner
 local ctx,cty=tx+.5,ty+.5
 
 -- step is the y coord on the
 -- map tile, range -moff,moff
 local step=-moff
 
 -- x col vect, left side
 local cosx=cos_a*-moff
 local sinx=sin_a*-moff

 -- somehow need to keep
 -- from reading past the
 -- tile boundary for that we
 -- need to clamp the starting
 -- position and modify
 -- mdx,mdy - should just be
 -- a modificaiton on moff
 -- based on ang

 for _y=y1,y2-1 do
  local siny=sin_a*step
  local cosy=cos_a*step
  tline(x+x1,y+_y,
        x+x2,y+_y,
        ctx+cosx-siny,
        cty+sinx+cosy,
        -- map mdx,mdy to
        -- output size w
        -- considering moff
        cos_a*moff*2/w,
        sin_a*moff*2/w)
  -- map output range to tile
  printh(ctx+cosx-siny..","..cty+sinx+cosy)
  step+=(2*moff)/w
 end
 --rect(x+x1,y+y1,x+x2,y+y2,6)
 pset(x-bdx*half,y+bdy*half,11)
end


function draw_rotated_tile(
 x,y,rot,mx,my,w)
  w+=.8 --???
  local halfw=-w/2 --? why neg
  --cx/cy center
  local cx, cy=
   mx-halfw-.4, my-halfw-.4
   
  -- pre-calc'd cos/sin
  local cr, sr=
   cos(rot), sin(rot)
   
  -- rotated values?
  -- center circle values
  -- these are the x comps
  -- of the column vector and
  -- won't change so are pre-
  -- computed.
  local rx, ry=
    cx+cr*halfw, cy+sr*halfw
    
  -- ??
  local hx, hy=w*4, w*4
  
  rect(x-hx,y-hy,x+hx,y+hy,5)

  -- weird, instead rotating
  -- the lines, it's rotating
  -- the way the source is read
  for py=y-hy,y+hy do
    tline(x-hx,py,
          x+hx,py,
          rx-sr*halfw,
          ry+cr*halfw,
          -- scale the step to
          -- the output line
          -- length of 8?
          cr/8, sr/8)
    
    -- this varies the y comp
    -- of the coumn vector of
    -- each line end
    halfw+=1/8
  end
end

--[[
function draw_rotated_tile(x,y,rot,mx,my,w,flip,scale)
  scale = scale or 1
  w+=.8
  local halfw, cx  = scale*-w/2, mx + w/2 -.4
  local cs, ss, cy = cos(rot)/scale, -sin(rot)/scale, my-halfw/scale-.4
  local sx, sy, hx, hy = cx + cs*halfw, cy - ss*halfw, w*(flip and -4 or 4)*scale, w*4*scale

  --this just draw a bounding box to show the exact draw area
  rect(x-hx,y-hy,x+hx,y+hy,5)

  for py = y-hy, y+hy do
    tline(x-hx, py, x+hx, py, sx + ss*halfw, sy + cs*halfw, cs/8, -ss/8)
    halfw+=1/8
  end
end
]]
__gfx__
000000008888888889abc12e00aaaa0066666666fdddfddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000009999999989abc12e0aaaaaa066666666dddfdddf00000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaa89abc12eaa0aa0aa77777777ddfdddfd00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000bbbbbbbb89abc12eaaaaaaaa77777777dfdddfdd00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccc89abc12eaaaaaaaaddddddddfdddfddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001111111189abc12eaa0aa0aa00000000dddfdddf00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddd89abc12e0aa00aa000000000ddfdddfd00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeee89abc12e00aaaa0000000000dfdddfdd00000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0102030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000502050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
