pico-8 cartridge // http://www.pico-8.com
version 33
__lua__

function _init()
	a=0
	pa=-1
	manual=true
end

function _update()
 if (btnp(❎)) manual=not manual
 
 if manual then
  if (btn(⬅️)) a=(a-1)%360
  if (btn(➡️)) a=(a+1)%360
 else
  a=(a+1)%360
 end
end

function dist(x1,y1,x2,y2)
 return sqrt((x1-x2)^2+(y1-y2)^2)
end 

function rotate(x,y,cx,cy,a)
 local ca,sa=cos(a),-sin(a)
 x-=cx y-=cy
 local rx=x*ca-y*sa
 local ry=x*sa+y*ca
 return rx+cx,ry+cy
end

function draw_shape(points,col)
 for i=2,#points do
  local a=points[i-1]
  local b=points[i]
  line(a[1],a[2],b[1],b[2],(col or 7))
 end
end

function rotate_shape(points,cx,cy,a)
 for p in all(points) do
  local x,y=p[1],p[2]
  p[1],p[2]=rotate(x,y,cx,cy,a)
 end
end

function tfill(x,y,w,h,tx,ty)
 local hx,hy=w/2,h/2
 local step=0

 rect(x-hx,y-hy,x+hx,y+hy,6)

 for _y=y-hy,y+hy do
  tline(x-hx,_y,x+hx,_y,
   tx,ty+step,1/w)
  step+=1/h
 end
end

function out(...)
 local str=""
 for i in all({...}) do
  str=str.." "..i
 end
 printh(str)
end

function prn(...)
 local str=""
 for i in all({...}) do
  str=str.." "..i
 end
 print(str)
end

function _draw()
 if (pa==a) return
 
 pa=a
 cls()
 
 local cx,cy,r=32,74,24
 local is=r*-sin(.125)
 local os=r
 
 tfill(cx,cy,is*2,is*2,7,2)
 circ(cx,cy,r,11)
 
 local rect1={{cx-os,cy-os},
  {cx+os,cy-os},{cx+os,cy+os},
  {cx-os,cy+os},{cx-os,cy-os}}

 rotate_shape(rect1,cx,cy,a/360)
 draw_shape(rect1)
 
 local lines={
  {cx-os,cy},{cx+os,cy},
  {cx+os,cy-r/4*1},{cx-os,cy-r/4*1},
  {cx-os,cy-r/4*2},{cx+os,cy-r/4*2},
  {cx+os,cy-r/4*3},{cx-os,cy-r/4*3}
 }

 rotate_shape(lines,cx,cy,a/360)
 draw_shape(lines,9) 
 
 draw_tile(30,20,24,24,7,2,a/360)
 draw_tile2(80,20,24,7,2,a/360)
 draw_tile4(96,74,7,2,a/360)
 
 prn(a,cos(a/360),sin(a/360))
end


function draw_tile4(x,y,tx,ty,ang)
 local cos_a,sin_a=cos(ang),-sin(ang)
 
 -- the draw box needs to be
 -- able to hold the rotated
 -- square which is srqt(2) 
 -- from corner to corner
 -- only if we care about
 -- 1:1 scale
 
 -- source box also needs to
 -- include diagonals so it
 -- needs to have r=sqrt(2)/2
 -- local moff=sqrt(2)/2
 
 local sqrt2=sqrt(2)
 local bdx=mid(-1,sqrt2*cos_a,1)
 local bdy=mid(-1,sqrt2*sin_a,1)
 
 -- moff is the offset in map
 -- coord, basically radius
 --local moff=sqrt(bdx^2+bdy^2)/2
 local moff=sqrt2/2
 
 local w=32*moff*2 -- output range
 local hw=w/2
 local x1,y1,x2,y2=
        -hw,-hw,hw,hw
  
 rect(x-hw,y-hw,x+hw,y+hw,5)

 -- center of the tile is
 -- is just .5 from the corner
 local ctx,cty=tx+.5,ty+.5
 
 -- step is the y coord on the
 -- map tile, range -moff,moff
 local step=-moff
 
 -- somehow need to keep
 -- from reading past the
 -- tile boundary for that we
 -- need to clamp the starting
 -- position and modify
 -- mdx,mdy - should just be
 -- a modificaiton on moff
 -- based on ang
 
 -- x col vect, left side

 out("-----")
 for _y=y1,y2 do
  -- in map coords

  -- circle boundary, find
  -- circle chord at map y 
  --local _x=sqrt(.5-step^2)
  
  local _x=.5/cos_a

  -- offset triangle with edge
  local _ox=sin_a*step/cos_a
  
  --if (_dy<0) _ox=cos_a*_dy/sin_a
  
  local _oxw=w*_ox/sqrt2/2
  
  -- renormalize tline width
  local _w=w*(2*_x/sqrt2)
  local _hw=_w/2

  local cosx=cos_a*-(_x-_ox)//-moff
  local sinx=sin_a*-(_x-_ox)//-moff
  local siny=sin_a*step
  local cosy=cos_a*step
  
    
  local _dy=step
  
  --out("_x:",_x,"_y:",_y,"_w:",_w)
  out("_dy:",_dy)
  tline(x-_hw+_oxw,y+_y,
        x+_hw+_oxw,y+_y,
        ctx+cosx-siny,
        cty+sinx+cosy,
        -- map mdx,mdy to
        -- output size w
        -- considering moff
        cos_a*_x*2/_w,
        sin_a*_x*2/_w)
  -- map output range to tile
 step+=(2*moff)/w
 end
end
-->8
-- lkg

function draw_tile(x,y,w,h,tx,ty,a)
 local w,h=w-1,h-1
 local hw,hh=w/2,h/2
 local step=0

 for _y=-hh,hh do
  local x1,y1=
   rotate(x-hw,y+_y,x,y,a)
  local x2,y2=
   rotate(x+hw,y+_y,x,y,a)
  -- well this is odd...
  -- basically cos from
  -- 0-pi/4 reflected ??
  local _w=w*max(abs(cos(a)),
                 abs(sin(a)))
  tline(x1,y1,x2,y2,
        tx,ty+step,
        1/_w)
  step+=1/h
 end
end


function draw_tile2(x,y,s,tx,ty,ang)
 local cos_a,sin_a=cos(ang),-sin(ang)
 
 -- the draw box needs to be
 -- able to hold the rotated
 -- square which is srqt(2) 
 -- from corner to corner
 -- only if we care about
 -- 1:1 scale
 local w=s*sqrt(2)-1
 local hw,hh=w/2,w/2
 local x1,y1,x2,y2=
        -hw,-hh,hw,hh
  
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
 local cos_a,sin_a=cos(ang),-sin(ang)
 
 -- the draw box needs to be
 -- able to hold the rotated
 -- square which is srqt(2) 
 -- from corner to corner
 -- only if we care about
 -- 1:1 scale
 
 -- source box also needs to
 -- include diagonals so it
 -- needs to have r=sqrt(2)/2
 -- local moff=sqrt(2)/2
 
 local sqrt2=sqrt(2)
 local bdx=mid(-1,sqrt2*cos_a,1)
 local bdy=mid(-1,sqrt2*sin_a,1)
 
 -- moff is the offset in map
 -- coord, basically radius
 --local moff=sqrt(bdx^2+bdy^2)/2
 local moff=sqrt2/2
 
 local w=32*moff*2 -- output range
 local hw=w/2
 local x1,y1,x2,y2=
        -hw,-hw,hw,hw
  
 rect(x-hw,y-hw,x+hw,y+hw,5)

 -- center of the tile is
 -- is just .5 from the corner
 local ctx,cty=tx+.5,ty+.5
 
 -- step is the y coord on the
 -- map tile, range -moff,moff
 local step=-moff
 
 -- somehow need to keep
 -- from reading past the
 -- tile boundary for that we
 -- need to clamp the starting
 -- position and modify
 -- mdx,mdy - should just be
 -- a modificaiton on moff
 -- based on ang
 
 -- x col vect, left side

 for _y=y1,y2 do
  -- in map coords

  -- circle boundary, find
  -- circle chord at map y 
  local _x=sqrt(.5-step^2)
  
  -- renormalize tline width
  local _w=2*_x*w/sqrt2
  local _hw=_w/2

  local cosx=cos_a*-_x//-moff
  local sinx=sin_a*-_x//-moff
  local siny=sin_a*step
  local cosy=cos_a*step
  
  --out("_x:",_x,"_y:",_y,"_w:",_w)
  tline(x-_hw,y+_y,
        x+_hw,y+_y,
        ctx+cosx-siny,
        cty+sinx+cosy,
        -- map mdx,mdy to
        -- output size w
        -- considering moff
        cos_a*_x*2/_w,
        sin_a*_x*2/_w)
  -- map output range to tile
 step+=(2*moff)/w
 end
end
__gfx__
000000008888888889abc12e00aaaa0066666666fdddfddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000009999999989abc12e0aaaaaa066666666dddfdddf00000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaa89abc12eaa0aa0aa77777777ddfdddfd00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000bbbbbbbb89abc12eaaaaaaaa77777777dfdddfdd00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccc89abc12eaaaaaaaaddddddddfdddfddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001111111189abc12eaa0aa0aa00000000dddfdddf00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddd89abc12e0aa00aa000000000ddfdddfd00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeee89abc12e00aaaa0000000000dfdddfdd00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000089abc12e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000089abc12e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000890bc02e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000089abc12e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000089abc12e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000890bc02e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000089a0012e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000089abc12e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0102030400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000512050012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
