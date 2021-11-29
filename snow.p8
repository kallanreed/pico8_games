pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
function rndwind(x)
 return rnd()-.5
end

function _init()
 part={}
 snowing=true
 wind=rndwind()
end

function _update60()
 if snowing then
  snow(flr(rnd(128)),0,7)
 end
 update_particles()
 if (btnp(❎)) snowing=not snowing
 if (btnp(🅾️)) wind=rndwind()
end

function _draw()
 cls()
 color(10)
 line(10,100,118,100)
 line(30,30,50,30) 
 draw_particles()
end
-->8
function snow(x,y,col)
 local p=particle(
  x,y,wind,1,200+rnd(200),col)
 p.stuck=false
 
 p.update=function(my)
  if (my.y>128) my.age=9999
  
  if pget(my.x,my.y-1)==7 then
   my.mxage+=1
  end
  
  if (my.stuck) return
 
  local ny=my.y+1
  my.dx=wind
  my.dy=1
  if pget(my.x,ny)!=0 then
   if pget(my.x+1,ny)==0 then
    my.dx=1
   elseif pget(my.x-1,ny)==0 then
    my.dx=-1
   else
    my.dy=0
    my.dx=0
    my.stuck=true
   end
  end
 end
 p.draw=function(my)
  pset(my.x,flr(my.y),my.col)
 end

 add(part,p)
end

function particle(
 x,y,dx,dy,mxage,col)
 return {
  x=x, y=y,
  dx=dx, dy=dy,
  age=0, mxage=mxage or 10,
  col=col or 7
 }
end

-- update each particle in 'part'
function update_particles()
 -- reverse iter for easy delete
 for i=#part,1,-1 do
  local p=part[i]

  p.age+=1
  if p.age>p.mxage then
   deli(part,i)

  else
   if (p.update) p:update()
   p.x+=p.dx
   p.y+=p.dy
  end
 end
end

function draw_particles()
 for p in all(part) do
  if p.draw then
   p:draw()
  else
   pset(p.x,p.y,p.col)
  end 
 end
end
-->8
function sig(x)
 x=abs(x)
 if x<.682 then
  return 1
 elseif x<.954 then
  return 2
 else
  return 3
 end
end

function norm(mean,stddev)
 local v=rnd(2)-1
 local s=sig(v)
 local d=rnd(s*stddev*2)-(s*stddev)
 return d+mean
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
