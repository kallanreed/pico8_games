pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- grave matters
-- by 😐 kallanreed

music(0,0,7)

-- todo: only draw particles
-- in active view

-- drawables

-- swap with second sprite
function spr_swap(sp,rate,jit)
 local sp2=sp
 local r=rate or .5
 local j=jit or r/2
 local ani=0
 
	return function(it)
  if (t()-ani>r) then
    it.sp,sp2=sp2,it.sp
    ani=t()+(rnd(2*j)-j)
  end
	end
end

-- randomize offset
function jitter(jit)
 local ani=0
 local jit=jit or 1
 return function(it)
  if t()-ani>.1 then
   ani=t()
   it.off_x=flr(rnd(2*jit+1))-jit
   it.off_y=flr(rnd(2*jit+1))-jit
  end
 end
end

-- subtle animation y axis
function idle()
 local ani=0
 return function(it)
  if t()-ani>1 then
   it.off_y^^=1
   ani=t()
  end
 end
end

-- bounce in place y axis
function bounce(it)
 it.off_y=sin(t())*2
end

-- wiggle in place x axis
function wiggle(it)
 it.off_x=cos(t())*2
end

-- look at player
function look(it)
 if plr.x<it.x+it.w/2 then
  it.flp=true
 else
  it.flp=false
 end
end

-- player relative
function plr_rel()
 local px=plr.x
 local py=plr.y
 return function(it)
  it.x+=plr.x-px
  it.y+=plr.y-py
  px=plr.x py=plr.y
 end
end

-- camera relative
function cam_rel(speed)
 local px=cam_x or 0
 local spd=speed or 1
 return function(it)
  it.x+=(cam_x-px)*spd
  px=cam_x
 end
end

-- sprite relative
function spr_rel(sp)
 local px=sp.x
 local py=sp.y
 return function(it)
  it.x+=sp.x-px
  it.y+=sp.y-py
  it.off_x=sp.off_x
  it.off_y=sp.off_y
  px=sp.x py=sp.y
 end
end

-- base drawable
function drawable_item(x,y)
 return {
  x=x, y=y,
  off_x=0, off_y=0,
  mods={},
  
  apply_mods=function(my)
   for m in all(my.mods) do
    m(my)
   end
  end,
  add_mod=function(my,...)
   for m in all({...}) do
    add(my.mods,m)
   end
   return my -- fluent api
  end
 }
end

-- drawable sprite
-- w/h are in tiles
function sprite(sp,x,y,w,h,flp)
 local it=drawable_item(x,y)
 it.sp=sp
 it.w=w or 1
 it.h=h or 1
 it.flp=flp or false
 it.draw=function(my)
   my:apply_mods()
   spr(my.sp,
    my.x+my.off_x,
    my.y+my.off_y,
    my.w,my.h,my.flp)
  end
 return it
end

-- drawable text
function text(x,y,txt,col)
 local w=print(txt,0,-20) 
 local it=drawable_item(x-w/2,y)
 it.w=w
 it.txt=txt
 it.col=col or 7
 it.draw=function(my)
  my:apply_mods()
  print(my.txt,my.x+my.off_x,
   my.y+my.off_y,my.col)
 end
 return it
end

-- parallax bg sprite
function spr_bg(sp,x,y,w,h,spd)
 add(background,
  sprite(sp,x,y,w or 1,h or 1)
   :add_mod(cam_rel(spd or 1)))
end

-- timers

function run_after(sec,fn)
 return {
  action=fn,
  end_time=t()+sec,
  update=function(my)
   if t()>my.end_time then
    if not my:action() then
     del(timer,my)
    end
   end
  end
 }
end

function del_after(sec,list,item)
 return add(timer, run_after(sec,
  function() del(list,item) end))
end

-- swap map tile @x,y with
-- next sprite on the sheet
function map_swap(sp,x,y,rate,jit)
 local r=rate or .5
 local j=jit or r/2
 local sp=sp
 local cur=1
 local fn=function(my)
  cur^^=1
  mset(x,y,sp+cur)
  my.end_time=t()+r+(rnd(2*j)-j)
  return true -- loop
 end
 return add(timer,run_after(r,fn))
end

function temp_text(x,y,txt,col)
 it=add(drawable,
   text(x,y,txt,col))
 del_after(3,drawable,it)
 return it
end

function _init()
 pal()
 poke(0x5f2e,1)

	-- camera tracking
 cam_x=0
 map_min=0
 map_max=127*8

 -- game objects
 background={}
 drawable={}
 inter={} -- interactive
 gen={} -- generators
 part={} -- particles
 timer={}
 act={} -- actors
 
 game={
  game_over=
   text(64,56,"\#0gAME oVER")
    :add_mod(jitter(),cam_rel()),
  x_to_restart=
   text(64,70,"\#0❎ rESTART")
    :add_mod(cam_rel()),
  over=false,
  ani=0, fade=0,
  faded=false,
  black=129,
 }

 -- player state 
 plr={
  sp=1, w=8, h=16,
  x=109*8, y=96,flp=f,
  dx=0, dy=0,
  max_dx=1.5, max_dy=4,
  acc=0.5, jump=3,
  grav=0.3, frct=0.8,
  walking=false,
  jumping=false,
  falling=false,
  landed=true,
  grabbing=false, gt=0,
  ani=0,
  health=3, invincible=0,
  items={"potion"},
  has=function(my, it)
   return count(my.items, it)>0
  end
 }

 -- todo: consolidate into lists
 -- stars, moon, and clouds
 spr_bg(27,4,18)
 spr_bg(27,75,54)
 spr_bg(27,58,24)
 spr_bg(27,100,8)
 spr_bg(37,32,32,2,2,.98)
 spr_bg(40,30,28,4,1,.8)
 spr_bg(40,74,40,4,1,.8)
 spr_bg(40,130,30,4,1,.8)
 spr_bg(40,175,32,4,1,.8)

 -- pumpkins, lights
 add(timer, map_swap(51,6,11,.2))
 add(timer, map_swap(35,12,13))
 add(timer, map_swap(35,41,10))
 add(timer, map_swap(51,62,11,.2))
 add(timer, map_swap(35,102,9))

 -- interactive
 add(inter, key_collectible(2,7))
 add(inter, locked_door(18,13))
 add(inter, gem_collectible(58,3))
 add(inter, witch_brew(14,2))
 add(inter, locked_door(70,13))
 add(inter, shovel_collectible(109,02))
 add(inter, dirt_pile(81,3))
 add(inter, corn_plant(119,13))
 add(inter, trick_treat(125,13))
 add(inter, ghost_grave(
  36,13,35,8,"eLLIS",
  "fELL LOOKING FOR JEWELS"))

 add_as(act, spider, {
  {15,6,6}, {23,7,5,true},
  {29,9,3}, {35,11,2},
  {53,5,6}, {59,7,3},
  {77,7,2}, {80,7,2,true},
  {83,7,2}, {86,7,2,true},
  {108,11,2}
 })
 
 add_as(act, bat, {
  {9,8}, {26,6}, {70,10},
  {76,1}, {86,0}, {99,4},
  {104,2}
 })
 
 add(inter, grave(22,13,"bELVA",
  "sPOOKED BY A GHOST"))
 add(inter, grave(27,13,"jETHRO",
  "dRAINED BY A VAMPIRE"))
 add(inter, grave(48,13,"aGNES",
  "mAULED BY A WEREWOLF"))
 add(inter, grave(64,13,"jAMES",
  "zAPPED BY A WIZARD"))
 add(inter, grave(81,13,"nICK",
  "dRANK A BAD POTION"))
  
 temp_text(64,40,"\#dgRAVE mATTERS",0)
  :add_mod(cam_rel())
 temp_text(64,48,"\#d🅾️=act ❎=jump",0)
  :add_mod(cam_rel())

 add(gen, shiny(7*8+1,13*8+1,6,4))
 add(gen, shiny(53*8,12*8+1,64,4))

 -- test rect
 x1r=0 y1r=0 x2r=0 y2r=0
end
-->8
-- update

function player_update()
 -- input
 if btn(⬅️) then
  plr.dx-=plr.acc
  plr.flp=true
  plr.walking=true
 elseif btn(➡️) then
  plr.dx+=plr.acc
  plr.flp=false
  plr.walking=true
 end
  
 if btnp(❎) and plr.landed then
  plr.dy-=plr.jump
  plr.landed=false
  sfx(10)
 end

 -- physics
 plr.dx*=plr.frct
 plr.dy+=plr.grav

 if plr.dy>0 then
  plr.falling=true
  plr.jumping=false
  plr.landed=false

  if collide(plr,⬇️,5) then
   plr.dy=0
   plr.y-=((plr.y+plr.h+1)%8)-1
   plr.falling=false
   plr.landed=true
  end
 elseif plr.dy<0 then
  plr.jumping=true
 end

 if plr.dx>0 then
  if collide(plr,➡️,7) then
   plr.dx=0
  end
 elseif plr.dx<0 then
  if collide(plr,⬅️,7) then
   plr.dx=0
  end
 end
 
 if abs(plr.dx)<.2 then
  plr.dx=0
  plr.walking=false
 end

 -- todo: walking and grabbing?
 -- process pickups
 if btnp(🅾️) then
  plr.grabbing=true
  plr.gt=t()
  local i=get_inter()
  if i then i:action()
  else sfx(11) -- no-op sound
  end
 end
 
 plr.dx=clamp(plr.dx,plr.max_dx)
 plr.dy=clamp(plr.dy,plr.max_dy)

 plr.x+=plr.dx
 plr.y+=plr.dy
 
 if plr.x<map_min then
  plr.x=map_min
  plr.dx=0
 end

 if enemy_collision() then
  player_hurt()
 end
 
 if plr.invincible>0 then
  plr.invincible-=1
 end
end

function _update()
 if game.over
 and game.faded
 and btn(❎) then
  _init()
  return
 end

 if not game.over then
  player_update()
  foreach(act, do_update)
 end

 foreach(gen, do_update)
 foreach(timer, do_update)

 update_particles()

 -- camera tracking
 -- plr.x has a lot of jitter so flr
 cam_x=flr(plr.x)-56
 if (cam_x < map_min) cam_x=0
 if (cam_x > map_max-128) cam_x=map_max-128;
end

function player_hurt()
 if plr.invincible==0 then
  sfx(19)
  plr.health-=1
  plr.invincible=20
  if (plr.health<1) player_die()
 end
end

function player_die()
 sfx(15)
 game.over=true
 plr.walking=false
 game.black=0
end
-->8
-- draw

function draw_player()
 if plr.jumping then
  plr.sp=4
 elseif plr.falling then
  plr.sp=5
 elseif plr.grabbing then
  plr.sp=6  --hack
  if t()-plr.gt>.2 then
   plr.grabbing=false
   plr.sp=1
  end
 elseif plr.walking then
  if t()-plr.ani>.2 then
   plr.sp=nxt(plr.sp,2,3)
   plr.ani=t()
  end
 else -- idle
  plr.sp=1
 end

 if not game.over then
  if plr.invincible>0 then
   pal({[4]=6,[8]=6,[12]=6,[15]=7})
  end
 end
 
 spr(plr.sp,plr.x,plr.y,plr.w/8,plr.h/8,plr.flp)
 if (not game.over) pal();
end

function fade()
 if t()-game.ani<.15
 or game.faded then
  return
 end

 for c=0,15 do
  local s,i=flr(c/8),c%8
  pal(c,sget((14+s)*8+game.fade,7*8+i))
 end
  
 game.ani=t()
 game.fade+=1
 game.faded=game.fade>7
end

-- main draw loop
function _draw()
 cls()

 camera(cam_x,0)
 foreach(background, do_draw)
 map(0,0,0,0,128,32,0)

 draw_particles()
 
 foreach(act, do_draw)
 foreach(drawable, do_draw)

 draw_player()

 -- draw foreground
 map(0,0,0,0,128,32,2)

-- for i=1,#inter do
--  local _i=inter[i]
--  rect(_i.x,_i.y,_i.x+_i.w,_i.y+_i.h,6)
-- end 

 -- collected items
 for i=1,#plr.items do
   local sp=0
   local it=plr.items[i]
   if it=="key" then sp=57
   elseif it=="gem" then sp=59
   elseif it=="shroom" then sp=24
   elseif it=="shovel" then sp=63
   elseif it=="potion" then sp=32
   elseif it=="candy" then sp=9
   end
   spr(sp,(i-1)*8+cam_x,1)
 end
 
 -- health
 for i=1,3 do
  local sp=16
  if (plr.health<i) sp=78
  spr(sp,(i+12)*8+cam_x,1)
 end

 if game.over then
  fade()
  game.game_over:draw()
  if (game.faded) game.x_to_restart:draw() 
 end

 --rect(x1r,y1r,x2r,y2r,7)

 -- pretty colors
 pal({1,2,131,132,5,6,7,136,
  9,135,3,140,13,142,15,
  game.black},1)
end
-->8
-- collision

-- only for player w/ map
-- todo: generalize
function collide(obj,dir,flag)
 local x=obj.x local y=obj.y
 local w=obj.w local h=obj.h
 local x1=0 local y1=0
 local x2=0 local y2=0

 if dir==⬅️ then
  x1=x-1 y1=y+3
  x2=x-2 y2=y+h-1
 elseif dir==➡️ then
  x1=x+w   y1=y+3
  x2=x+w+1 y2=y+h-1
 elseif dir==⬇️ then
  x1=x+2   y1=y+h
  x2=x+w-3 y2=y+h+1
 end
 
 --x1r=x1 y1r=y1 x2r=x2 y2r=y2
 x1/=8 y1/=8 x2/=8 y2/=8
 
 if fget(mget(x1,y1),flag)
 or fget(mget(x1,y2),flag)
 or fget(mget(x1,y1),flag)
 or fget(mget(x2,y2),flag)
 then return true end
 
 return false
end

function overlaps(a,b)
 local ax2=a.x+a.w-1
 local ay2=a.y+a.h-1
 local bx2=b.x+b.w-1
 local by2=b.y+b.h-1
 -- no overlap if any true
 return not (ax2<b.x
          or a.x>bx2
          or ay2<b.y
          or a.y>by2)
end

-- true if any pixels overlap
-- needs {sp,x,y,w,h}
-- doesn't account for flip
function pxl_overlap(a,b)
 local offx=b.x-a.x
 local offy=b.y-a.y
 
 local rx1=a.x
 local rx2=min(a.w+a.x,
               b.w+b.x)-1
 local ry1=a.y
 local ry2=min(a.h+a.y,
               b.h+b.y)-1
 
 if offx>0 then
  -- left b is left r
  rx1=b.x
  rx2=b.x+min(b.w,a.w-offx)-1
 elseif offx<0 then
  -- left a is left r
  rx1=a.x
  rx2=a.x+min(a.w,b.w+offx)-1
 end
 
 if offy>0 then
  -- top of b is top r
  ry1=b.y
  ry2=b.y+min(b.h,a.h-offy)-1
 elseif offy<0 then
  -- top of a is top r
  ry1=a.y
  ry2=a.y+min(a.h,b.h+offy)-1
 end
 
 local aoffx=rx1-a.x
 local aoffy=ry1-a.y
 local boffx=rx1-b.x
 local boffy=ry1-b.y
 
 for x=0,(rx2-rx1) do
  for y=0,(ry2-ry1) do
   local pa=spget(a.sp,aoffx+x,aoffy+y)
   local pb=spget(b.sp,boffx+x,boffy+y)
   if pa>0 and pb>0 then
    return true
   end
  end
 end
 
 return false
end

-- get first overlapping interactive
function get_inter()
 local reach=4
 local hb={
  x=plr.x, y=plr.y+8,
  w=plr.w+reach, h=plr.h-8
 }

 -- looking left?
 if (plr.flp) hb.x-=reach

 x1r=hb.x y1r=hb.y
 x2r=hb.x+hb.w y2r=hb.y+hb.h

 for i in all(inter) do
  if (overlaps(hb,i)) return i
 end
end

-- get a list of map tiles
-- that the player overlaps
function get_map_tiles(flag)
 local x1=plr.x
 local y1=plr.y
 local x2=x1+plr.w-1
 local y2=y1+plr.h-1
 
 x1=flr(x1/8) y1=flr(y1/8)
 x2=flr(x2/8) y2=flr(y2/8)
 
 local tiles={
  {x=x1,y=y1},
  {x=x1,y=y2}
 }
 
 if x1!=x2 then
  add(tiles,{x=x2,y=y1})
  add(tiles,{x=x2,y=y2})
 end
 
 for i=#tiles,1,-1 do
  local t=tiles[i]
  t.sp=mget(t.x,t.y)
  if not fget(t.sp,flag) then
   deli(tiles,i)
  end
 end
 
 return tiles
end

function enemy_collision()
 for a in all(act) do
  if overlaps(plr,a) then
   a.ol=true
   if pxl_overlap(plr,a) then
    return true
   end
  end
 end
 
 local tiles=get_map_tiles(4)
 for t in all(tiles) do
  t.x*=8 t.y*=8 t.w=8 t.h=8
  if pxl_overlap(plr,t) then
   return true
  end
 end

 return false
end
-->8
-- particles

function particle(
 x,y,dx,dy,mxage,col)
 return {
  x=x, y=y,
  dx=dx, dy=dy,
  age=0, mxage=mxage or 10,
  col=col or 7
 }
end

-- generator that emits particles
-- outward from a single point
function sparkler(x,y,col1,col2)
 local ani=0
 return {
  update=function()
   if t()-ani>.1 then
    ani=t()
    
    local p=particle(x,y,
     (.25+rnd(.25))*rnd_sign(),
     (.25+rnd(.25))*rnd_sign(),
     rnd(8)+8,col1)
    p.update=function(my)
     if (my.age*1.5>my.mxage) my.col=col2
    end
    
    add(part,p)
   end
  end
 }
end

-- generator that emits particles
-- upward from a line of w width
function bubbler(x,y,w,col1,col2)
 local ani=0
 return {
  update=function()
   if t()-ani>.1 then
    ani=t()
    
    local p=particle(
     x-w/2+rnd(w),y,
     0,-(.25+rnd(.25)),
     rnd(8)+8,col1)
    p.update=function(my)
     if (my.age*1.5>my.mxage) my.col=col2
    end
    
    add(part,p)
   end
  end
 }
end

-- generator that emits particles
-- upward from a line
function smoke(x,y,cols)
 local ani=0
 local cnt=30
 return {
  update=function(self)
   if t()-ani>.05 then
    ani=t()
    cnt-=1
    if (cnt<1) del(gen,self)
    
    local p=particle(
     x+rnd(8),y,
     0,-(.25+rnd(.5)),
     rnd(8)+8,rnd(cols))
    p.draw=function(my)
     local r=map_rng(my.age,0,my.mxage,3,1)
     fillp(0xa5a5.8)
     circfill(my.x,my.y,r,my.col)
     fillp()
    end
    
    add(part,p)
   end
  end
 }
end

-- shiny random box
function shiny(x,y,w,h)
 local ani=0
 local cmap={5,6,7,6,5}
 return {
  update=function()
   if t()-ani>.5 then
    ani=t()
    
    local p=particle(
     x+rnd(w),y+rnd(h),
     0,0,#cmap*5,5)
    p.update=function(my)
     my.col=cmap[ceil(my.age/5)]
    end
    printh(p.x.." "..p.y)
    add(part,p)
   end
  end
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
-- utils

function do_update(o)
 o:update()
end

function do_draw(o)
 o:draw()
end

function rnd_sign()
 if (rnd()<.5) return -1
 return 1
end

function clamp(val,max_v)
 return mid(-max_v,val,max_v)
end

-- get next sprite
function nxt(i,_min,_max)
 i+=1
 if (i>=_min and i<=_max) return i
 return _min
end

function map_rng(v,
 min_in,max_in,
 min_out,max_out)
 local d_in=max_in-min_in
 local d_out=max_out-min_out
 return (v-min_in)/d_in*
         d_out+min_out
end

function dist_dir(ax,ay,bx,by)
 -- the math overflows with
 -- large dx,dy. clamp to 90
 local dx=clamp(ax-bx,90)
 local dy=clamp(ay-by,90)
 
 return sqrt(dx^2+dy^2),
        atan2(dx,dy)
end

function dist_dir2(a,b)
 local cen_ax=a.x+a.w/2
 local cen_ay=a.y+a.h/2
 local cen_bx=b.x+b.w/2
 local cen_by=b.y+b.h/2

 return dist_dir(cen_ax,cen_ay,
                 cen_bx,cen_by)
end

function spget(sp,x,y)
 local sx=sp%16*8
 local sy=flr(sp/16)*8
 return sget(sx+x,sy+y)
end

function str(s)
 return tostring(s)
end

function log_rect(x1,y1,x2,y2)
 printh(x1..","..y1.." "..x2..","..y2)
end

function add_as(t,fn,items)
 for i in all(items) do
  add(t, fn(unpack(i)))
 end
end
-->8
-- interactive

-- make an interactive at x,y
function interactive(x,y,w,h,fn)
 return {
  x=x, y=y, w=w, h=h,
  action=fn
 }
end

-- make collectible at map x,y
function collectible(sp,x,y,w,h,col,on_collect)
 local fn=function(my)
  del(drawable, my.sprite)
  del(inter, my)
  del(gen, my.sparkler)
  sfx(14)
  my:on_collect()
 end
 local _i=interactive(x*8,y*8,w*8,h*8,fn)
 _i.sprite=add(drawable,
  sprite(sp,x*8,y*8,w,h)
   :add_mod(bounce))
 _i.sparkler=add(gen,
  sparkler(x*8+w*4,y*8+h*4,7,col))
 _i.on_collect=on_collect
 return _i
end

-- make key at map x,y
function key_collectible(x,y)
 return collectible(
  57,x,y,1,1,10,function()
   add(plr.items, "key")
  end)
end

-- make gem at map x,y
function gem_collectible(x,y)
 return collectible(
  59,x,y,1,1,14,function()
   add(plr.items, "gem")
  end)
end

-- make shroom at map x,y
function shroom_collectible(x,y)
 return collectible(
  24,x,y,1,1,14,function()
   add(plr.items, "shroom")
  end)
end

-- make shovel at map x,y
function shovel_collectible(x,y)
 return collectible(
  63,x,y,1,1,9,function()
   add(plr.items, "shovel")
  end)
end

-- make candy at map x,y
function candy_collectible(x,y)
 return collectible(
  9,x,y,1,1,9,function()
   add(plr.items, "candy")
  end)
end

-- make potion at map x,y
function potion_collectible(x,y)
 return collectible(
  32,x,y,1,1,10,function()
   add(plr.items, "potion")
  end)
end

-- make door at map x,y interactive
function locked_door(x,y)
 -- ensure door placed
 mset(x,y-1,87)
 mset(x,y,103)
 local fn=function(my)
  if not plr:has("key") then
   sfx(13) -- fail
   del_after(3, drawable,
    add(drawable,
     sprite(58,plr.x,plr.y-12)
      :add_mod(plr_rel(),bounce)))
  else
   sfx(12) -- success
   -- remove door
   mset(x,y,0)
   mset(x,y-1,0)
   -- remove trigger
   del(inter, my)
   -- consume key
   del(plr.items, "key")
  end
 end
 return interactive(x*8,y*8,8,8,fn)
end

-- make ghost at map x,y
function gem_ghost(x,y)
 local fn=function(my)
  sfx(9)
  if not plr:has("gem") then
   del_after(3, drawable,
    add(drawable,
     sprite(62,my.x,my.y-10)
      :add_mod(spr_rel(my.ghst),bounce)))
  else
   -- remove trigger
   del(inter, my)
   del(drawable, my.ghst)
   -- consume gem
   del(plr.items, "gem")
   -- leave a key
   add(gen,
    smoke(my.x,my.y+4,{5,6}))
   add(timer, run_after(1,
    function()
     add(inter,
      key_collectible(my.x/8,my.y/8))
    end))
  end
 end
 local _i=interactive(x*8,y*8,8,8,fn)
 _i.ghst=add(drawable,
  sprite(48,x*8,y*8)
   :add_mod(look,wiggle,bounce))
 return _i
end

-- make witch at map x,y
function witch_brew(x,y)
 local fn=function(my)
  sfx(17)
  if not plr:has("shroom") then
   del_after(3, drawable,
    add(drawable,
     sprite(25,my.x,my.y-10)
      :add_mod(spr_rel(my.witch),bounce)))
  else
   -- remove trigger
   del(inter, my)
   -- consume gem
   del(plr.items, "shroom")
      -- leave a key
   add(gen,
    smoke(my.x+8,my.y+4,{5,6}))
   add(timer, run_after(1,
    function()
     add(inter,
      potion_collectible(my.x/8+1,my.y/8))
    end))
  end
 end
 local _i=interactive(x*8,y*8,16,16,fn)
 _i.witch=add(drawable,
  sprite(7,x*8,y*8)
   :add_mod(look,idle()))
 _i.witch_body=add(drawable,
  sprite(23,x*8,(y+1)*8))
 _i.cauldron=add(drawable,
  sprite(56,(x+1)*8,(y+1)*8))
 _i.bubbles=add(gen,
  bubbler((x+1)*8+3,(y+1)*8+2,5,10,11))
 return _i
end

-- make dirt pile at map x,y
function dirt_pile(x,y)
 local fn=function(my)
  if not plr:has("shovel") then
   sfx(13)
   del_after(3, drawable,
    add(drawable,
     sprite(47,plr.x,plr.y-10)
      :add_mod(plr_rel(),bounce)))
  else
   sfx(18)
   -- remove trigger
   del(inter, my)
   del(drawable, my.pile)
   del(gen, my.dust)
   -- consume shovel
   del(plr.items, "shovel")
   -- leave a shroom
   add(gen,
    smoke(my.x,my.y+4,{4,5,6}))
   add(timer, run_after(1,
    function()
     add(inter,
      shroom_collectible(my.x/8,my.y/8))
    end))
  end
 end
 local _i=interactive(x*8,y*8,8,8,fn)
 _i.pile=add(drawable,sprite(8,x*8,y*8))
 _i.dust=add(gen,
  bubbler(x*8+4,y*8+6,6,4,5))
 return _i
end

function grave(x,y,name,txt)
 return interactive(x*8,y*8,8,8,
  function()
   sfx(15)
   temp_text(x*8,40,"\#1hERE LIES "..name)
   temp_text(x*8,48,"\#1"..txt)
    :add_mod(jitter())
  end)
end

-- make corn plant at map x,y
function corn_plant(x,y)
 local fn=function(my)
  if not plr:has("potion") then
   sfx(13)
   del_after(3, drawable,
    add(drawable,
     sprite(76,plr.x,plr.y-10)
      :add_mod(plr_rel(),bounce)))
  else
   sfx(12)
   -- remove trigger
   del(inter, my)
   del(drawable, my.corn)
   del(gen, my.sparkler)
   -- consume potion
   del(plr.items, "potion")
   -- leave a candy
   add(gen,
    smoke(my.x,my.y+4,{5,6}))
   add(timer, run_after(1,
    function()
     add(inter,
      candy_collectible(my.x/8,my.y/8-1))
    end))
  end
 end
 local _i=interactive(x*8,y*8,8,8,fn)
 _i.corn=add(drawable,sprite(74,x*8,(y-1)*8,1,2))
 _i.sparkler=add(gen,
  sparkler(x*8+4,y*8,7,11))
 return _i
end

-- make trick_treat at map x,y
function trick_treat(x,y)
 local fn=function(my)
  if not plr:has("candy") then
   sfx(13)
   del_after(3, drawable,
    add(drawable,
     sprite(76,plr.x,plr.y-10)
      :add_mod(plr_rel(),bounce)))
  else
   sfx(12)
   -- remove trigger
   del(inter, my)
   del(drawable, my.corn)
   del(gen, my.sparkler)
   -- consume potion
   del(plr.items, "potion")
   -- leave a candy
   add(gen,
    smoke(my.x,my.y+4,{5,6}))
   add(timer, run_after(1,
    function()
     add(inter,
      candy_collectible(my.x/8,my.y/8-1))
    end))
  end
 end
 local _i=interactive(x*8,y*8,8,8,fn)
 _i.corn=add(drawable,sprite(74,x*8,(y-1)*8,1,2))
 _i.sparkler=add(gen,
  sparkler(x*8+4,y*8,7,11))
 return _i
end

function ghost_grave(x,y,g_x,g_y,name,txt)
 local g=grave(x,y,name,txt)
 g.triggered=false
 g.bubbler=add(gen,
  bubbler(x*8+4,y*8,8,7,5))
 g.base_action=g.action
 g.action=function(my)
  my:base_action()
  if (my.triggered) return
  
  my.triggered=true
  del(gen, my.bubbler)
  add(gen, smoke(g_x*8,g_y*8,{5,6}))
  add(timer, run_after(2,function()
   sfx(9)
   add(inter, gem_ghost(g_x,g_y))
  end))
 end
 return g
end

-- add sound trigger at map x,y
function sndtrig(x,y,snd)
 return interactive(x*8,y*8,8,8,
  function() sfx(snd) end)
end

-->8
-- actors
-- would it be better for actor
-- to have a drawable in it?

function spider(x,y,h,rev)
 local orig_y=y*8
 local max_y=(y+h)*8
 local ani=0
 local flp=false
 local state="⬇️"
 local st_next=""
 if rev then
  y=max_y
  state="⬆️"
 end
 return {
  sp=14,x=x*8,y=orig_y,w=8,h=8,
  update=function(my)
   if state=="⬇️" then
    my.y+=2
    if my.y>=max_y then
     state="⧗"
     st_next="⬆️"
     ani=t()
    end
   elseif state=="⧗" then
    if t()-ani>1 then
     state=st_next
     flp=state=="⬆️"
    end
   elseif state=="⬆️" then
    my.y-=2
    if my.y<=orig_y then
     state="⧗"
     st_next="⬇️"
     ani=t()
    end
   end
  end,
 
  draw=function(my)
   local off_y=my.y-orig_y
   local threads=flr(off_y/8)
   for i=0,threads do
    spr(13,my.x,(orig_y/8+i)*8)
   end
  
   spr(my.sp,my.x,my.y,1,1,false,flp)
  end
 }
end

function bat(x,y)
 local ani=0
 local dx=0  local dy=0
 local rad=40
 local sitting=true
 local attack=true
 return {
  sp=10,x=x*8,y=y*8,w=8,h=8,
  update=function(my)
   local a  local d
   if sitting then
    d,a=dist_dir2(plr,my)
    if d<rad then
     sfx(16)
     dx=cos(a)*1.5
     dy=sin(a)*1.5
     sitting=false
     attack=true
    end
    
   else
    if t()-ani>.1 then
     my.sp=nxt(my.sp,11,12)
     ani=t()
    end
    
    my.x+=dx*.5
    my.y+=dy*.5
    d,a=dist_dir(x*8,y*8,my.x,my.y)

    if d>rad and attack then
     dx=cos(a)
     dy=sin(a)
     attack=false
    end
    
    if d<2 and not attack then
     my.sp=10
     my.x=x*8
     my.y=y*8
     sitting=true
    end
   end
  end,
  
  draw=function(my)
   local flp=my.x>plr.x
   spr(my.sp,my.x,my.y,1,1,flp)
  end
 }
end


__gfx__
00000000000000000000000000000000000000000000000000000000555000000000000000d75000000000000000000000000000000d0000000000000d000000
00000000000400000040000000400000004000000004000000040000055500dd0000000000777000000000000000000000000000000500000060006080d0d000
00000000000800000008000000080000000800000008000000080000055ddd00000000000df7f50000d000d050d00d0500d00d000000d00000042400000dd000
0000000004444400044444000444440004444400044444000444440005dcccc0000000000eeeee00000ddd00555dd555055dd55000005000066222660000d000
0000000044fff44044fff44044fff44044fff44044fff44044fff4400dc9b90000044000deeeee50005858500558585055585855000d0000000222000005d0dd
00000000457557404575574045755740457557404575574045755740d0cbbbbb04454450a9eee9a0005555500005500050055005000500000064246000055d50
00000000f55f55f0f55f55f0f55f55f0f55f55f0f55f55f0f55f55f000cbbb0045545444aaaaaaa00055555000000000000000000000d0000608280600050500
00000000ff444ff0ff444ff0ff444ff0ff444ff0ff444ff0ff444ff000cbba00544544550aaaaa00000505000000000000000000000050000006060000005500
000000000f4f4f000f4f4f000f4f4f000f4f4f000f4f4f000f4f4f00000bb000002ee200000006600080000000000000000000d000d55500000ddd5000000660
0fe0fe000666660006666600066666000666660006666600066666000055550002e88f20022260060688000000000000000d0d0800d50500ddd5000400006006
f88f88800f666f000f666f000f666f000f666f000f666f000f666fff050550500e7888802fe820068886800000000000000dd000000550005050055000b00006
e88888800f666f000f666f000f666f00f06660f0f06660f00f6660000505500b2e887f828e87866000d0036000060000000d000000d55d00000550080f990660
088888200fcccf000fcccf000fcccf0000ccc00000ccc0000fccc0000b5555008888fe88288826000d00633300000000dd0d50000d55550000000800fa9a9600
0088820000c0c00000c0c000000cc0000c00c00000c0c00000c0c0000055550028888882006000000d0000d00000000005d550000d555500000000009fafe000
0008200000c0c00000c00c0005cc0000c00c0000000c0c0000c0c000006006000006d00006d006000dd000d000000000005050000555050000000000099e0600
0000000000505000005005000005000050050000000505000050500000880880006d00000000000000dd0d00000000000055000000d550000000000000000000
0064450000030000006666d00000b0000000b0000000066677700000000d50000000000000000000050500000000000000d5500000000d400dd0d00044400660
00600500088030000666666d000b3000000b30000006666666777000000d50000000000000000050505050000000000000d500005dddd000400dddd505006006
00066000028030000655556d0f9999e00f9999e0006d666666666700000d500000000505050005050505050500000000000550dd505005080050005505000006
007e8600000030b00656556df9a99a9ef959959e06ddd666556d6670000d50000000505050505050505050505000000000d55d55000500500500050055600660
06e7885000003b000666566d999999999999999906d5d66dd56dd670000d50000005050505050505050505050505000000d5555000408040080550005d600600
0688825000b030000666666d999aa9999995599966ddd666ddd66676000d50000050505050505050505050505050505000d55500000000000004000006000000
00582500000555000666666de9a9aa9ee959559e6d55666666dd6776000d50000005050505050505050505050505050500d50500000000000000000000000600
0005500005555550333333330e9999e00e9999e06d5d666776dd6676000d5000000000005050505000005050505050000d555500000000000000000000000000
0067760000003000006666d0000d5000000d50006dddd66776667776000d50000000000400099000090006600008000040ddd00000d550000000066000444000
06777760000308800666666d00d5550000d555006666dd6677777776000d50000000004000900900909060060087800005005dddd0d550000800600600d0d000
07777570000308200655556d05000050050000506666dd6677677766000d5000000004000090090009000006087f8800804005055d5550008780000600050000
075777760b0300000655656d05009050050000500666666776767760000d500056666dd50009900009900660087f880000055000055055007e80066000050000
077757f700b300000665666d05096050050a60500667777777777660000d5000055dd5500009000009000600087e880000080000005555008820060000050000
07f7577700030b000666666d050996500509a6500066767777776600000d50005d66ddd50009900009900000088e8200000000000d5550000200000000556000
07777777005550000666666d05098050050890500006776777666000000d500056666dd5000900000000060000882000000000000d550d0000000600005d6000
067077060555555033333333055555500555555000000776666000000055550005dddd50000990000000000000020000000000000d5555d00000000000060000
d2222d2222d2222222222d22d2222d2200022d2222d2200022b3535353535b220000000002d2222000b0b0000000000000000660000000000000000000000000
222d222222222d222db2b2222222222200222222222b2200d23531353515352d00000000d22b2bd203030b000000000000006006000000000760760000000000
5b2b2bb3b22b522b5b5bb2dbb22b2b2b02d22b2b4234b22022bb535353534b22000000002dbbb5b20bb300000067760000000006000000007557555000000000
3525b5353bb53bb53535b5253b25b525222bb5253253222222b5353534353b22000000002b5b5352b113bb300677776006450660000000006555555000000000
532353135353335353135343532153532db1535353531b2d2db15353535313d20000000034353135b00b01b07777777706650600000000000555551000000000
343535353135353535353535354535352b35353535353b222bb5353535353bb2000000400353535300b300007757757767825000000000000055510000000000
535153535353515353535313535353132b534313515353b2225343135153532205000050013535300bbb1ba97777777768825600000000000005100000000000
3535353535353535353535353535353525353535353535b22b353535353535b20505005003035000b313ba9b7777777706550000000000000000000000000000
53535353535351535351535353535353222222220d000d00135353530005550002222d202d2222d2b30ba9b0f777777f00000000000000000000000000000000
3515353335753535353535353377753522222222d500d50035373535005050502db2b22222b22222b30bbb00ff99eeff00000000000000000000000000000000
53535153567353535353535357575653b22b22240500050053576353005050502b5bb2d22b37b2bb0b030000779eee7700000000000000000000000000000000
353535353dd7343531353515377766313b25b2b505000500357dd535050050052535b522b3576b53000bb00076eee86700000000000000000000000000000000
53135253535d77535353535353766d5353535b515555555577d353530500500553135343357dd5350bb3bb0060c88c0600000000000000000000000000000000
3535353535356d3135353535356d65353517773505000500d6353515050555053535353077d35353b30313b000c00c0000000000000000000000000000000000
525353135153d35353515343515dd35353737363050005005d5313530555055503535310d6353515000300b000c00c0000000000000000000000000000000000
3535353535353535353535353535353515777665050005003535353505500055000530305d531353004455000040040000000000000000000000000000000000
535353535353515353515353535353535357d6d30500050005000500055505550000000000000000000000000000000000000000000000000000000000000000
3535153335351515151515151314351515151dd50500050005000500050505050000000000000000000000000000000000000000000000000000000000000000
53515151515151515153515151535351513151410500050005000500050555050000000000000000000000000000000000000000000000000000000000000000
15151515151514151315151515151513151515150500050005000500050050050000000000000000000000000000000000000000000000000000000000000000
51315150515151515150515151013151515101515555555555555555055555550000000000000000000000000000000000000000000000000000000000000000
05151010051510131010051005051515005400150500050005000500050050050700070000000000000000000000000000000000000000000000000000000000
00500000005050510050010001000500000500000500050005000500050050057760776000000000000000000000000000000000000000000000000000000000
00000000000000050000050000000000000000000500050005000500050050057665766500000000000000000000000000000000000000000000000000000000
050005005351535322b353b253515353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088822250
0024200015151515d23531b215151510000000000000000000000000000000000000000000000000000000000000000000000000000000001111155099994450
554445505153515122bb5322515351000000000000000000000000000000000000000000000000000000000000000000000000000000000022222250aa999455
004440001315151522b53bd2131515100000000000000000000000000000000000000000000000000000000000000000000000000000000033335550bbb33330
05242500515d51512db15b22515051500000000000000000000000000000000000000000000000000000000000000000000000000000000044455550ccc11110
50848050101505102bb535b2101005100000000000000000000000000000000000000000000000000000000000000000000000000000000055555555dd222250
005050000050d1002253432d005001000000000000000000000000000000000000000000000000000000000000000000000000000000000066655550eee22200
00000000000055002b3535b2000005000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777ffeee225
__label__
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhh555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhssssd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh939sdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh33333shdhhhhh3hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh333shhhhnhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhn33shhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh33hhhhhhhhhhkhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5555hhhhhhnhkhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h55h5hhhhhhkhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhh5h55hh356666dd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh35555hhh55dd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5555hh5d66ddd5hhhhhhkhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5hhh5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hh6hh56666dd5h5hhhh5hhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhoohoohh5dddd5hh5h5hh5hhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h5656575h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhh22d222222222222d222222d2222d222d22hhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h56565657575h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhh2222222222222222222d2222322222222322hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5d56565656575h5h5h5h5h5hhhhhhhhhhhhhhhhhhhh2d223233223222k3223522323j73233k2jk322hhhhhhhhhhhhh5
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5d5d565556d6575h5h5h5hhhhhhhhhhhhhhhhhhhhhh22233525j3253235j335j3353j57635jj25j2222hhhhhhhhhhh5h
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6d5d66dd56dd67hhhhhhhhhhhhhhhhhhhhhhhhhhhhh2d315j5j5j5j53515j5jjj5jj57dd5j55j5j132dhhhhhhhhhhhh5
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66ddd666ddd66676hhhhhhhhhhhhhhhhhhhhhhhhhhhh23j5j5j5j51777j5j1j5j5j577dj5j5jj5j5j322hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6d55666666dd6776hhhhhhhhhhhhhhhhhhhhhhhhhhhh235jkj1j5j7j7j6j5j5j515jd6j5j515515j5j32hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6d5d666776dd6676hhhhhhhhhhhhhhhhhhhhhhhhhhhh25j5j5j515777665j5j5j5j55d5j1j5jj5j5j532hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6dddd66776667776hhhhhhhhhhhhhhhhhhhhhhhhhhhh5j515j5j5j57d6dj5j515j5j5j5j5j5j5j5j515jhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666dd6677777776hhhhhhhhhhhhhhhhhhhhhhhhhhhh1515151515151dd5151515151j1kj515j5j51515hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666dd6677677766hhhhhhhhhhhhhhhhhhhhhhhhhh5h515j515151j151k1515j5151515j5j5151515151hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66666677676776hhhhhhhhhhhhhhhhhhhhhhhhhh5h51j151515151515151j1515151515151j15151k15hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66777777777766hhhhhhhhhhhhhhhhhhhhhhhhh5h5h515h515151515151515d515151h1j15151515151hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh667677777766hhhhhhhhhhhhhhhhhhhhhhhhh5h5h51515h515h55kh5151515h515h5h51515h5151h1jhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6776777666hhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h515h5h555h5h5h5hd15h51hhh5hhhh5h5h51hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh776666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5hhhhh5h5h5h555hhhhhhhhhhhhhhhhh5hhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhhhhhhhhhhhhhhhhhhhhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhddhhhddhdhdhdddhhhhhdddhhddhdddhdddhdddhddhhhddhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhdhdhdhdhdhdhddhhhhhhdhdhdhdhhdhhhdhhddhhdhdhdhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhddhhdddhdddhdhhhhhhhdhdhdddhhdhhhdhhdhhhddhhhhdhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdddhdhdhdhdhhdhhhddhhhhhdhdhdhdhhdhhhdhhhddhdhdhddhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdddddhhhhhhdddhhddhdddhhhhhhdddddhhhhhhdddhdhdhdddhdddhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhhddhdddhdhdhdhhhhdhhhhhhddhdhddhdddhhdhhdhdhdddhdhdhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhdhddhhhhhdddhdhhhhdhhhhhhdddhdddhhhhhhdhhdhdhdhdhdddhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhhddhdddhdhdhdhhhhdhhhhhhddhdhddhdddhhdhhdhdhdhdhdhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdddddhhhhhhdhdhhddhhdhhhhhhhdddddhhhhhhddhhhddhdhdhdhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhohhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5d55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
dhhhdhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
5hhd5hhd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55hddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd55d55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
55555555555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhh5hhh5hhhhhhhhhhhhhd5hhhhhhhhhhhkhdddhhhhhd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhdhhhdhhhdhhhdhhhdhhh
hhhh5hhh5hhhhhhhhhhhhd555hhhhhhhhhhh5hh5ddddhd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhd5hhd5hhd5hhd5hhd5hhd
hhhh5hhh5hhhhhhhhhhh5hhhh5hhhhhhhhhohkhh5h55d555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhh5hhh5hhh5hhh5hhh5hhh
hhhh5hhh5hhhhhhhhhhh5hh9h5hhhhhhhhhhhh55hhhh55h55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhh5hhh5hhh5hhh5hhh5hhh
hhh55555555hhhhhhhhh5h96h5hhhhhhhhhhhhohhhhhh5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhh555555555555555555555
hhhh5hhh5hhhhhhhhhhh5h9965hhhhhhhhhhhhhhhhhhd555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhh5hhh5hhh5hhh5hhh5hhh
hhhh5hhh5hhhhhhhhhhh5h9oh5hhhhhhhhhhhhhhhhhhd55hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhh5hhh5hhh5hhh5hhh5hhh
hhhh5hhh5hhhhhhhhhhh555555hhhhhhhhhhhhhhhhhhd5555dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhh5hhh5hhh5hhh5hhh5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd55hhhhhhddd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5dhh5hh5hhh5hhh5hhh5hhhhh555hhh5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd5hhhhddd5hhhkkhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2k2hhh5hhh5hhh5hhh5hhhh5h5h5hh5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhh55hdd5h5hh55hohhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55kkk55h5hhh5hhh5hhh5hhhh5h5h5hh5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd55d55hhh55hkkkkkhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhkkkhhh5hhh5hhh5hhh5hhh5hh5hh5h5hhh
hhh5555555555555555hhhd5hhhhhhhhhhhhhhhhhhhhhd5555hhhhhhkkfffkkhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh52k25h5555555555555555h5hh5hh555555
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd555hhhhhhhk57557khhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hokoh5h5hhh5hhh5hhh5hhh5h555h5h5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd5h5hhhhhhhf55f55fhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5d5hhh5hhh5hhh5hhh5hhh555h555h5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhd5555hhhhhhhffkkkffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5hhhh5hhh5hhh5hhh5hhh55hhh55h5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd555hhhhhhhhfkfkfhhhhhhhhh3hhhhhhhhhhhhhohhhhhhhhhhhhhh5hhh5hhh5hhh5hhh555h555h5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd5h5hhhhhhhh66666hhhhhhhh3jhhhhhhhhhhhh6oohhhhhhhhhhhhh5hhh5hhh5hhh5hhh5h5h5h5h5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhh55hhhhhhhhhf666fhhhhhhf9999uhhhhhhhhhooo6ohhhhhhhhhhhh5hhh5hhh5hhh5hhh5h555h5h5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd55dhhhhhhhhf666fhhhhhf9n99n9uhhhhhhhhhhdhhj6hhhhhhhhhh5hhh5hhh5hhh5hhh5hh5hh5h5hhh
hhh5555555555555555hhhd5hhhhhhhhhhhhhhhhhhhhd5555hhhhhhhhfsssfhhhhh99999999hhhhhhhhhdhh6jjjhhhhhhhh5555555555555555h555555555555
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhkhhd5555hhhhhhhhhshshhhhhh999nn999hhhhhhhhhdhhhhdhhhhhhhkhh5hhh5hhh5hhh5hhh5hh5hh5h5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhh5hhhh5hh555h5hhhhhhhhhshshhhhhhu9n9nn9uhhhhhhhhhddhhhdhh5hhhh5hh5hhh5hhh5hhh5hhh5hh5hh5h5hhh
hhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhh5h5hh5hhhd55hhhhhhhhhh5h5hhhhhhhu9999uhhhhhhhhhhhddhdhhh5h5hh5hh5hhh5hhh5hhh5hhh5hh5hh5h5hhh
222d2222d2222222d2222d222222d2222d222d2222222222d2222d22222d2222d2222d22222d2222d22d2222d2222222d2222d2222222222d2222222d2222d22
222222222222d32322222222d222232222222222d222d32322222222d222222222222222d22222d2222222222222d32322222222d222d3232222d32322222222
22k32232323535332d33223522323j7323332235223535332d33223522332232323322352235323233j32232323535332d332235223535332d3535332d332235
235j3253525j5j53525j335j3353j57635jj335j335j5j53525j335j335j3253525j335j335j52535j5j3253525j5j53525j335j335j5j53525j5j53525j335j
3515j215j5j5j1j5jkj5j5jjj5jj57dd5j55j5jjj5j5j1j5jkj5j5jjj5j5j215j5j5j5jjj5j5j2j5j1j5j215j5j5j1j5jkj5j5jjj5j5j1j5jkj5j1j5jkj5j5jj
7j5j5k5j5j5j5j5j5j5j1j5j5j577dj5j5jj1j5j5j5j5j5j5j5j1j5j5j5j5k5j5j5j1j5j5j5jkj5j5j5j5k5j5j5j5j5j5j5j1j5j5j5j5j5j5j5j5j5j5j5j1j5j
j6j5j5j5j1j5j5j5j1j5j5j515jd6j5j5155j5j515j5j5j5j1j5j5j515j5j5j5j1j5j5j515j5j515j5j5j5j5j1j5j5j5j1j5j5j515j5j5j5j1j5j5j5j1j5j5j5
665j5j5j5j5j5j5j5j5j5j5j5j55d5j1j5jj5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j5j
6dj5j5j5j5j5j5j515j5j5j5j5j5j515j5j5j5j515j5j5j5j5j5j5j515j5j5j5j5j5j515j5j5j5j515j5j5j515j5j5j515j5j5j515j5j5j5j5j5j515j5j5j5j5
dd5j5j515jjj5j51515j5j515jj15151515j5j51515j5j515jjj5j51515j5j515jj15151515j5j51515j5j51515j5j51515j5j51515j5j515jj15151515j5j51
1k15j515151515151515j515151515j5151515151515j515151515151515j515151515j5151515151515151515151515151515151515j515151515j51515j515
5151515151515151k15151515151j15151515151k151515151515151k15151515151j15151515151k1515151k1515151k1515151k15151515151j15151515151
15151j1515h5151515151j1515h515h51515151515151j1515h5151515151j1515h515h51515151515151515151515151515151515151j1515h515h515151j15
h15h5151h1hh5151h1jh5151h1h1h1hh51hh5151h1jh5151h1hh5151h1jh5151h1h1h1hh51hh5151h1jh5151h1jh5151h1jh5151h1jh5151h1h1h1hh51hh5151
hhhhh5hhhhhhh5h5h51hh5hhhhhhh5hh1hhhh5h5h51hh5hhhhhhh5h5h51hh5hhhhhhh5hh1hhhh5h5h51hh5h5h51hh5h5h51hh5h5h51hh5hhhhhhh5hh1hhhh5hh
hhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhh5hhhhhhhhh5hhhhhhhhhhhhhhh5hhhhhhhhhhhhh5hhhhhhhhh5hhhhhhh5hhhhhhh5hhhhhhh5hhhhhhhhhhhhh5hhhhhhh

__gff__
0000000000000000000010101000102000000000000000000000000020002000000222202000000000000000002020000000202020000000000200002000000020202020a0a080800020000000000000202020202022208020200000000000000000000000020080100000000000000010008000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f00000000000000001c0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003c3d00000000000000002c1e00000000000000000000000000000000000000001c00000000000000000000000000000000000000
00000000000000000000000000000000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001d00001a004800002e3d00000000000000000000000000000000001c0000002c2d000000000000000000000000000000000000
00000000000000000000000000445441594500000000000000000000000000000000000000000000000000000000000000000000005800000000480000000000000000000000000000000000002c2d48444042451a001d000000000000000000000000000f0000002c2d002e3d00000000000000000000000000000000000000
0000000000000000000000000062647163610000490000000000000000000000000000000000000000000000000000000044450000000000004454450000000000000000000000000000000044414042525252514340414500000000480000000000002e3d00002e3d0000001d00000000000000000000000000000000000000
0000000000000000000000000000000000000000000000580000000000000000000000000000000000000000001c0000006162000000000000616471000000000000000000000000000000006271626171606271626171600000004459450000000000002c1e00001d0000002c00000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000490000000000000000000000000000000000002c1e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000445252470000000000001d0000002c0000003d00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005800001c00004800000000000000002e3d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000445252526000000000003c3d0000003d0000001d48000000000000000000000000000000000000
0000000000000000000f000000000000000000000000000000000000000000003d0044434500000000000000001d0000000000000000000000000000000000000000000000000000000000000048001a00000000004800004451525063000000486800002c0023001d4844414240450000000000000000000000000000000000
0055555555000000002c000000000000000000000000000000000000000000002c1e617163000f0000234800002c2d0000000000000000004800000000000000000000000000000000001c0044434041414354434143434252525260000044414254414240424241424052627161600000000000000000000000000000000000
00650000660033003c3d0000000000000055555500000000000000000000003c3d00000000001d0044414041453d000000000000000000004900005800003300000000000055555500003d0061636261626364626361616361626200000062606364606361616062616373000000000000000000000000000000000000000000
6565000066662700002c1e0000000000656557666600000000000000000000001d000000003c3d00465053505041450000000000006868686868686868002700000000006565576666002c2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565480066662768481d000023001a486565676666002221004800323100002e3d001a4832002c1e465150505052470022210048444240594240424143452700323100486565676666001d00480068002132006800481a00680000000000481a006800006800486800000000000000480000001a000000000000480048000000
4043425443424159414241434140434241424241404243544142414243424143414042594042414350505250525052434143404152515252535050505256404341424041544043414240434041594043414240434041544043414240434041544043414240414243414240424241424141424042425941424241424042424142
6062616460616062616061606261616161606260606362646060616063606160616062606063626060626160636061606062636163606263606362636162606263606361646062636063626361636062636063626361646062636063626361646062636063606361606361616060636060636161606260636160636161606261
__sfx__
6120000014530195301c53014530195301c53015540195401c54015540195401c540155501a5501e550155501a5501e55014560185601e56014562195621c56214562195621b55212552185521b5420050000500
112000000d7600d7600d7600d7600d7600d7600976009760097600976009760097600676006760067600676006760067600876008760087600876008760087600876008760087600876008760087600176001760
4f2000001865500005186550000518655186550000518655186550000518655000051865518655000051865518655000051865500005186551865500005186551865500005186550000518655186551865518655
812000002521225212252122521225212252122721227212272122821228212282122a2122a2122a2122c2122c2122c2122821228212282122721227212272122521225212252122421224212242120000000000
010800000c262182220c2620c222182620c2220c262182220c262182220c262182220c262182220c262182220c462184220c462184220c462184220c462184220c462184220c462184220c462184220c46218422
011000000c7420c7520c7520c7420c7320c7220c71200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b020000046330e630136300162002615066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
48040000180241902118031190311a031190411a0411b0411a0411b0511c0511b0511c0511d0511c0411b0411c0411b0311a0311b0211a021190211a011190111801018000000010000100001000010000100000
060600001a5311d531205310050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005000050000500
010400002013015100101300010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101
010a0000240502d050300502505027050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910400000c2500c250002000c2500c2500c2500c25000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
91040000183501c3501f3501a3501e350213502635000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300000000000000000
091000000d5500d5500d5550d5000d5500d5550d5000d5450d5500d5500d5550050010550105550f5000f5450f5500f5550d5000d5450d5500d5550c5000c5550d5500d5500d555005000d500005000050000500
040500003253031521305212e5112450131530315312f5212e5210250102501025010250102501025010250102501025010250102501025010250102501025010250102501025010250102501025010250102501
910500001f4501f4511e4511e45502400024001c4501c4511a4511a45502400024001945019451184511843117421174111741117415020000200000000000000000000000000000000000000000000000000000
490900002563025635116000f60008600116541365013650126400f6300b62509600006000b6000660000600006000e60027630266350d60010600106000f6000d6001063411640106400f6300c6300462500600
010700001d253252030e2531a203152030f2030020300203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203002030020300203
050800001c1501c153001001c1501c153001001915019150191501915019155001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000000f112151121211218112151221b122181321e1321b142211421e14224142001021012219122141321c13219132201321c132251322014228142251422014200102191321f1321c132221321f14225142
002000002213228132251422b132281222e122001021e132241322113227132241322a142271422d1422a132301222d12233122001020d13210132191320d13210132191320f13214132181320f1321213218132
1120000008752087520875208752087520875208752087520875208752087520875208c0208752087520875208752087520875208752087520875208752087520875208c02087520875208752087520875208752
1120000008752087520875208752087520875200c0008752087520875208752087520875208752087520875208752087520875200c0001c5201c5201c5201c5201c5201c5208c5208c5208c5208c5208c5208c52
012000000d13210132191320d13210132191320f13214132181320f13212132181320d13210132191320d13210132191320f13214132181320f132121321813210132141321913214122191321c1322012225122
1120000010c5210c5210c5210c5210c5210c520fc520fc520fc520cc520cc520cc520dc520dc520dc520dc520dc520dc5214c5214c5214c5214c5212c5212c520dc520dc520dc520dc5201c5201c5201c5201c52
6120000014c3019c301cc3014c3019c301cc3015c4019c401cc4015c4019c401cc4015c501ac501ec5015c501ac501ec5014c6018c601ec6014c6219c621cc6214c6219c621bc5212c5218c521bc4200c0000c00
3120000019d5319d5219d5219d5219d5219d5219d5319d5219d5219d5319d5219d5219d5219d5219d5219d5319d5219d5219d5319d5219d5219d5219d5219d520000000000000000000000000000000000000000
__music__
00 005f4244
01 00024344
00 00020143
00 00030143
00 41010244
00 020f4344
00 181a4244
00 191b4344
00 1c1d0244
00 1e024344
00 1e020344
00 1e010344
02 1f424344

