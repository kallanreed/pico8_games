pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
 -- grave matters
-- by 😐 kallanreed

music(0,0,7)

-- interactive

-- make an interactive at x,y
function interactive(x,y,w,h,fn)
 return {
  x=x, y=y, w=w, h=h,
  action=fn
 }
end

-- make collectible at map x,y
function collectible(sp,x,y,w,h,on_collect)
 local fn=function(my)
  del(drawable, my.sprite)
  del(inter, my)
  my:on_collect()
 end
 local _i=interactive(x*8,y*8,w*8,h*8,fn)
 _i.sprite=add(drawable,
  sprite(sp,x*8,y*8,w,h)
   :add_mod(bounce))
 _i.on_collect=on_collect
 return _i
end

-- make key at map x,y
function key_collectible(x,y)
 local fn=function(my)
  add(plr.items, "key")
  sfx(14)
  del(gen, my.sparkler)
 end
 local _c=collectible(57,x,y,1,1,fn)
 _c.sparkler=add(gen, sparkler(x*8+4,y*8+4,7,10))
 return _c
end

-- make gem at map x,y
function gem_collectible(x,y)
 local fn=function(my)
  add(plr.items, "gem")
  sfx(14)
  del(gen, my.sparkler)
 end
 local _c=collectible(59,x,y,1,1,fn)
 _c.sparkler=add(gen,
  sparkler(x*8+4,y*8+4,7,14))
 return _c
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
     sprite(62,my.ghst.x,my.ghst.y-10)
      :add_mod(spr_rel(my.ghst),bounce)))
  else
   -- remove trigger
   del(inter, my)
   -- consume gem
   del(plr.items, "gem")
   -- fade
   my.ghst.sp=32
   del_after(1,drawable,my.ghst)
   -- leave a key
   add(inter, key_collectible(x,y))
  end
 end
 local _i=interactive(x*8,y*8,8,8,fn)
 _i.ghst=add(drawable,
  sprite(48,x*8,y*8)
   :add_mod(look,wiggle,bounce))
 return _i
end

function grave(x,y,name,txt)
 return interactive(x*8,y*8,8,8,
  function()
   sfx(15)
   temp_text(x*8,56,"\#0hERE LIES "..name)
   temp_text(x*8,64,"\#0"..txt)
    :add_mod(jitter())
  end)
end

-- add sound trigger at map x,y
function sndtrig(x,y,snd)
 return interactive(x*8,y*8,8,8,
  function() sfx(snd) end)
end


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
 map_max=68*8

 -- game objects
 background={}
 drawable={}
 inter={} -- interactive
 gen={} -- generators
 part={} -- particles
 timer={}
 
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
  x=10, y=96,flp=f,
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
  items={},
  has=function(my, it)
   return count(my.items, it)>0
  end
 }

 -- stars, moon, and clouds
 spr_bg(27,4,18)
 spr_bg(27,75,54)
 spr_bg(27,58,24)
 spr_bg(27,100,8)
 spr_bg(37,32,32,2,2,.98)
 spr_bg(40,30,28,4,1,.8)
 spr_bg(40,74,40,4,1,.8)
 spr_bg(40,130,30,4,1,.8)

 -- pumpkins, lights
 add(timer, map_swap(51,6,11,.2))
 add(timer, map_swap(35,11,13))
 add(timer, map_swap(35,41,10))

 -- interactive
 add(inter, key_collectible(2,7))
 add(inter, locked_door(18,13))
 add(inter, gem_ghost(35,8))
 add(inter, gem_collectible(58,3))
-- add(inter, locked_door(56,13))

 add(inter, grave(22,13,"bELVA",
 "sPOOKED BY A GHOST"))
 add(inter, grave(27,13,"jETHRO",
  "dRAINED BY A VAMPIRE"))
 add(inter, grave(34,13,"eLLIS",
  "fELL LOOKING FOR JEWELS"))
 add(inter, grave(48,13,"aGNES",
  "mAULED BY A WEREWOLF"))
  
 temp_text(64,56,"gRAVE mATTERS",13)
  :add_mod(cam_rel())
 temp_text(64,64,"🅾️=act ❎=jump",13)
  :add_mod(cam_rel())


 add(gen, bubbler(14*8+3,4*8+2,5,10,11))

 -- test rect
 x1r=0 y1r=0 x2r=0 y2r=0
end
-->8
-- update

function player_update()
 if (game.over) return

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

 -- check for death
 -- todo: better hitboxes
 -- for sprites
 if collide(plr,⬇️,4) then
  player_die()
 end
end

function _update()
 if game.over
 and game.faded
 and btn(❎) then
  _init()
  return
 end

 player_update()

 foreach(gen, do_update)
 foreach(timer, do_update)
 update_particles()

 -- camera tracking
 -- plr.x has a lot of jitter so flr
 cam_x=flr(plr.x)-56
 if (cam_x < map_min) cam_x=0
 if (cam_x > map_max-128) cam_x=map_max-128;
end

function player_die()
 game.over=true
 plr.walking=false
 sfx(15)
 game.black=0
end
-->8
-- draw

-- get next sprite
function nxt(i,_min,_max)
 i+=1
 if (i>=_min and i<=_max) return i
 return _min
end

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

 spr(plr.sp,plr.x,plr.y,plr.w/8,plr.h/8,plr.flp)
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
   if (it=="key") sp=57
   if (it=="gem") sp=59
   spr(sp,(i-1)*8+cam_x,1)
 end

 if game.over then
  fade()
  game.game_over:draw()
  if (game.faded) game.x_to_restart:draw() 
 end

-- rect(x1r,y1r,x2r,y2r,7)

 pal({1,2,131,132,5,6,7,136,
  9,135,3,140,13,142,15,
  game.black},1)
end
-->8
-- collision

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
 return {
  x=x, y=y, col1=col1, col2=col2,
  ani=0, mxd=1, rate=.1,
  
  update=function(my)
   if t()-my.ani>my.rate then
    my.ani=t()
    local p=particle(my.x,my.y,
     rnd(.5*my.mxd,my.mxd)*rnd_sign(),
     rnd(.5*my.mxd,my.mxd)*rnd_sign(),
     rnd(8)+8,col)
    p.update=function(_my)
     if (_my.age*1.5>_my.mxage) _my.col=my.col2
    end
    add(part,p)
   end
  end
 }
end

-- generator that emits particles
-- upward from a line
function bubbler(x,y,w,col1,col2)
 return {
  x=x, y=y, w=w,
  col1=col1, col2=col2,
  ani=0, mxd=1, rate=.1,
  
  update=function(my)
   if t()-my.ani>my.rate then
    my.ani=t()
    local p=particle(
     my.x-my.w/2+rnd(w),my.y,
     0,-rnd(my.mxd/2,my.mxd),
     rnd(8)+8,col1)
    p.update=function(_my)
     if (_my.age*1.5>_my.mxage) _my.col=my.col2
    end
    add(part,p)
   end
  end
 }
end

-- update each particle in 'part'
function update_particles()
 -- reverse iter for easy delete
 for i=#part,1,-1 do
  local _p=part[i]
  
  _p.age+=1
  if _p.age>_p.mxage then
   deli(part,i)
   
  else
    if (_p.update) _p:update()
   _p.x+=_p.dx
   _p.y+=_p.dy
  end
 end
end

function draw_particles()
 for i=1,#part do
  local _p=part[i]
  if _p.draw then
   _p:draw()
  else
   pset(_p.x,_p.y,_p.col)
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

function overlaps(a,b)
 local ax2=a.x+a.w
 local ay2=a.y+a.h
 local bx2=b.x+b.w
 local by2=b.y+b.h
 -- no overlap if any true
 return not (ax2<=b.x
          or a.x>=bx2
          or ay2<=b.y
          or a.y>=by2)
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

function str(s)
 return tostring(s)
end
__gfx__
00000000000000000000000000000000000000000000000000000000444000000000000000000000000000000000000000000000000d00006004400660044006
00000000000400000040000000400000004000000004000000040000044400440000000000000000000000000000000000000000000500000642226006422260
0000000000080000000800000008000000080000000800000008000000444440000000000000000000d000d050d00d0500d00d000000d0006042240600422400
00000000044444000444440004444400044444000444440004444400044222000000000000000000000ddd00555dd555055dd550000050000642446066424466
0000000044fff44044fff44044fff44044fff44044fff44044fff4404429b9000004400000000000005858500558585055585855000d00006004400600044000
00000000457557404575574045755740457557404575574045755740002bbbbb044544500dddd550005555500005500050055005000500000685586006855860
00000000f55f55f0f55f55f0f55f55f0f55f55f0f55f55f0f55f55f0002bbb0045545444006d65000055555000000000000000000000d0000055550060555506
00000000ff444ff0ff444ff0ff444ff0ff444ff0ff444ff0ff444ff0002bba0054454455006d6500000505000000000000000000000050000050050000500500
000000000f4f4f000f4f4f000f4f4f000f4f4f000f4f4f000f4f4f00000bb000002ee200000006600080000000000000000000d000d55500000ddd5000000660
000000000666660006666600066666000666660006666600066666000055550002e88f20022260060688000000000000000d0d0800d50500ddd5000400006006
000000000f666f000f666f000f666f000f666f000f666f000f666fff050550500e7888802fe820068886800000000000000dd000000550005050055000b00006
000000000f666f000f666f000f666f00f06660f0f06660f00f6660000505500b2e887f828e87866000d0036000060000000d000000d55d00000550080f990660
000000000fcccf000fcccf000fcccf0000ccc00000ccc0000fccc0000b5555008888fe88288826000d00633300000000dd0d50000d55550000000800fa9a9600
0000000000c0c00000c0c000000cc0000c00c00000c0c00000c0c0000055550028888882006000000d0000d00000000005d550000d555500000000009fafe000
0000000000c0c00000c00c0005cc0000c00c0000000c0c0000c0c000006006000006d00006d006000dd000d000000000005050000555050000000000099e0600
0000000000505000005005000005000050050000000505000050500000880880006d00000000000000dd0d00000000000055000000d550000000000000000000
0060600000030000006666d00000b0000000b0000000066677700000000d50000000000000000000050500000000000000d5500000000d400dd0d00044400660
06060600088030000666666d000b3000000b30000006666666777000000d50000000000000000050505050000000000000d500005dddd000400dddd505006006
00606560028030000655556d0f9999e00f9999e0006d666666666700000d500000000505050005050505050500000000000550dd505005080050005505000006
06560606000030b00656556df9a99a9ef959959e06ddd666556d6670000d50000000505050505050505050505000000000d55d55000500500500050055600660
0060506000003b000666566d999999999999999906d5d66dd56dd670000d50000005050505050505050505050505000000d5555000408040080550005d600600
0606560600b030000666666d999aa9999995599966ddd666ddd66676000d50000050505050505050505050505050505000d55500000000000004000006000000
00606060000555000666666de9a9aa9ee959559e6d55666666dd6776000d50000005050505050505050505050505050500d50500000000000000000000000600
0606060605555550333333330e9999e00e9999e06d5d666776dd6676000d5000000000005050505000005050505050000d555500000000000000000000000000
0067760000003000006666d0000d5000000d50006dddd66776667776000d50000000000400099000090006600008000040ddd00000d550000000066000444000
06777760000308800666666d00d5550000d555006666dd6677777776000d50000000004000900900909060060087800005005dddd0d550000800600600d0d000
07777570000308200655556d05000050050000506666dd6677677766000d5000000004000090090009000006087f8800804005055d5550008780000600050000
075777760b0300000655656d05009050050000500666666776767760000d500056666dd50009900009900660087f880000055000055055007e80066000050000
0777577700b300000665666d05096050050a60500667777777777660000d5000055dd5500009000009000600087e880000080000005555008820060000050000
0777577700030b000666666d050996500509a6500066767777776600000d50005d66ddd50009900009900000088e8200000000000d5550000200000000556000
07777777005550000666666d05098050050890500006776777666000000d500056666dd5000900000000060000882000000000000d550d0000000600005d6000
067077060555555033333333055555500555555000000776666000000055550005dddd50000990000000000000020000000000000d5555d00000000000060000
d2222d2222d2222222222d22d2222d2200022d2222d2200022b3535353535b220000000002d22220000000000000000000000000000000000000000000000000
222d222222222d222db2b2222222222200222222222b2200d23531353515352d00000000d22b2bd2000000000000000000000000000000000000000000000000
5b2b2bb3b22b522b5b5bb2dbb22b2b2b02d22b2b4234b22022bb535353534b22000000002dbbb5b2000000000000000000000000000000000000000000000000
3525b5353bb53bb53535b5253b25b525222bb5253253222222b5353534353b22000000002b5b5352000000000000000000000000000000000000000000000000
532353135353335353135343532153532db1535353531b2d2db15353535313d20000000034353135000000000000000000000000000000000000000000000000
343535353135353535353535354535352b35353535353b222bb5353535353bb20000004003535353000000000000000000000000000000000000000000000000
535153535353515353535313535353132b534313515353b222534313515353220500005001353530000000000000000000000000000000000000000000000000
3535353535353535353535353535353525353535353535b22b353535353535b20505005003035000000000000000000000000000000000000000000000000000
53535353535351535351535353535353222222220d000d00135353530005550002222d202d2222d2000000000000000000000000000000000000000000000000
3515353335753535353535353377753522222222d500d50035373535005050502db2b22222b22222000000000000000000000000000000000000000000000000
53535153567353535353535357575653b22b22240500050053576353005050502b5bb2d22b37b2bb000000000000000000000000000000000000000000000000
353535353dd7343531353515377766313b25b2b505000500357dd535050050052535b522b3576b53000000000000000000000000000000000000000000000000
53135253535d77535353535353766d5353535b515555555577d353530500500553135343357dd535000000000000000000000000000000000000000000000000
3535353535356d3135353535356d65353517773505000500d6353515050555053535353077d35353000000000000000000000000000000000000000000000000
525353135153d35353515343515dd35353737363050005005d5313530555055503535310d6353515000000000000000000000000000000000000000000000000
3535353535353535353535353535353515777665050005003535353505500055000530305d531353000000000000000000000000000000000000000000000000
535353535353515353515353535353535357d6d30500050005000500055505550000000000000000000000000000000000000000000000000000000000000000
3535153335351515151515151314351515151dd50500050005000500050505050000000000000000000000000000000000000000000000000000000000000000
53515151515151515153515151535351513151410500050005000500050555050000000000000000000000000000000000000000000000000000000000000000
15151515151514151315151515151513151515150500050005000500050050050000000000000000000000000000000000000000000000000000000000000000
51315150515151515150515151013151515101515555555555555555055555550000000000000000000000000000000000000000000000000000000000000000
05151010051510131010051005051515005400150500050005000500050050050700070000000000000000000000000000000000000000000000000000000000
00500000005050510050010001000500000500000500050005000500050050057760776000000000000000000000000000000000000000000000000000000000
00000000000000050000050000000000000000000500050005000500050050057665766500000000000000000000000000000000000000000000000000000000
00500050535153530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088822250
00024200151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111155099994450
055444555153515100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022222250aa999455
000444001315151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033335550bbb33330
00524250515d515100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044455550ccc11110
050848051015051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555dd222250
000000000050d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066655550eee22200
000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777ffeee225
__label__
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hh9hh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hh9hh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhh99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5hhh5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5657575h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h56565656575h5h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5656565656565h5h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6ddd656555d567hhh5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6d5d66dd56dd67hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66ddd666ddd66676hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6d55666666dd6776hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6d5d666776dd6676hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6dddd66776667776hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666dd6677777776hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666dd6677677766hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5hhh5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66666677676776hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66777777777766hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h5h5h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh667677777766hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h5h5h5h5h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6776777666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5h5h5h5h5h5h5h5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh776666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5h5h5hhhhh5h5h5h5h5hhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhhhhhhhhhhhhhhhhhhhhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhh99hhhhhhhhhhhhhhhhhdhhhddhhhddhdhdhdddhhhhhdddhhddhdddhdddhdddhddhhhddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhh9hh9hhhhhhhhhhhhhhhhdhhhdhdhdhdhdhdhddhhhhhhdhdhdhdhhdhhhdhhddhhdhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhh9h79hhhhhhhhhhhhhhhhdhdhddhhdddhdddhdhhhhhhhdhdhdddhhdhhhdhhdhhhddhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhh799hhhhhhhhhhhhhhhhhdddhdhdhdhdhhdhhhddhhhhhdhdhdhdhhdhhhdhhhddhdhdhddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhh99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhh9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhh99hhhhhhhhhhhhhhhhdddddhhhhhhdddhhddhdddhhhhhhdddddhhhhhhdddhdhdhdddhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhhddhdddhdhdhdhhhhdhhhhhhddhdhddhdddhhdhhdhdhdddhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhdhddhhhhhdddhdhhhhdhhhhhhdddhdddhhhhhhdhhdhdhdhdhdddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhhddhdddhdhdhdhhhhdhhhhhhddhdhddhdddhhdhhdhdhdhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdddddhhhhhhdhdhhddhhdhhhhhhhdddddhhhhhhddhhhddhdhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhdhohhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddhd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5d55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh6hhh6hhh6hhh6hhh6hhh6hhh6hhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhh65hh65hh65hh65hh65hh65hh65hh65hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhh5hhh5hhh5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55hddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhh5hhh5hhh5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd55d55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhh55555555555555555555555555555555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhh5hhh5hhh5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhh5hhh5hhh5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhh5hhh5hhh5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhhhhhhhhhhhhd5hhhhhhhhhhhkhdddhhhhhd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhhhhhhhhhhhd555hhhhhhhhhhh5hh5ddddhd55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhhhhhhhhhh5hhhh5hhhhhhhhhohkhh5h55d555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhhhhhhhhhh5hh9h5hhhhhhhhhhhh55hhhh55h55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhh55555555hhhhhhhhhhhhhhhh55555555hhhhhhhhh5h96h5hhhhhhhhhhhhohhhhhh5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhhhhhhhhhh5h9965hhhhhhhhhhhhhhhhhhd555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhhhhhhhhhh5h9oh5hhhhhhhhhhhhhhhhhhd55hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhhhhhhhhhh555555hhhhhhhhhhhhhhhhhhd5555dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhhhhhhhhhhhhhhhhhhd55hhhhhhddd5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhhhkhhhhhhhhhhhhhhd5hhhhddd5hhhkhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhhhohhhhhhhhhhhhhhh55hdd5h5hh55hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhkkkkkhhhhhhhhhhhhd55d55hhh55hhohhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
5555555555555555hhhhhhhhhhhhhhhh5555555555555555hhhd5hhhkkfffkkhhhhhhhhhhhd5555hhhhhhohhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhk57557khhhhhhhhhhhd555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhf55f55fhhhhhhhhhhhd5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhffkkkffhhhhhhhhhhd5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhfkfkfhhhhhhhhhhhhd555hhhhhhhhhhhhhh3hhhhhhhhhhhhhhhhhhhhhohhhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhh66666hhhhhhhhhhhhd5h5hhhhhhhhhhhhh3jhhhhhhhhhhhhhhhhhhhh6oohhhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhf666fhhhhhhhhhhhhh55hhhhhhhhhhhh999999hhhhhhhhhhhhhhhhhooo6ohhhhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhhhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhf666fhhhhhhhhhhhhd55dhhhhhhhhhh99599599hhhhhhhhhhhhhhhhhhdhhj6hhhhhhhhh
5555555555555555hhhhhhhhhhhhhhhh5555555555555555hhhd5hhhhfsssfhhhhhhhhhhhd5555hhhhhhhhhh99999999hhhhhhhhhhhhhhhhhdhh6jjjhhhhhhhh
h5hhh5hhh5hhh5hhhhhhhhkhhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhhshshhhhhhhhhkhhd5555hhhhhhhhhh99955999hhhhhhhhhhhhhhhhhdhhhhdhhhhhhhkh
h5hhh5hhh5hhh5hhh5hhhh5hhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhhshshhhh5hhhh5hh555h5hhhhhhhhhh99595599hhhhhhhhhhhhhhhhhddhhhdhh5hhhh5h
h5hhh5hhh5hhh5hhh5h5hh5hhhhhhhhhh5hhh5hhh5hhh5hhhhhd5hhhhh5h5hhhh5h5hh5hhhd55hhhhhhhhhhhh999999hhhhhhhhhhhhhhhhhhhddhdhhh5h5hh5h
d2222d22d2222d2222222d2222222222d2222d2222222d2222d2222222222d2222d2222222222d2222d22222d2222d2222d22222d2222d22d2222d2222222d22
222d2222222222222dj2j22222222222222222222dj2j22222222d222dj2j22222222d222dj2j22222222d222222222222222d22222d2222222222222dj2j222
5j2j2jjkj22j2j2j5j5jj2djj22j222kj22j2j2j5j5jj2djj22j522j5j5jj2djj22j522j5j5jj2djj22j522jj22j2j2jj22j522j5j2j2jjkj22j2j2j5j5jj2dj
k525j5k5kj25j525k5k5j525kj25j2j5kj25j525k5k5j525kjj5kjj5k5k5j525kjj5kjj5k5k5j525kjj5kjj5kj25j525kjj5kjj5k525j5k5kj25j525k5k5j525
5k2k5k1k5k215k5k5k1k5kjk5k5k5j515k215k5k5k1k5kjk5k5kkk5k5k1k5kjk5k5kkk5k5k1k5kjk5k5kkk5k5k215k5k5k5kkk5k5k2k5k1k5k215k5k5k1k5kjk
kkk5k5k5k5j5k5k5k5k5k5k5k51777k5k5j5k5k5k5k5k5k5k1k5k5k5k5k5k5k5k1k5k5k5k5k5k5k5k1k5k5k5k5j5k5k5k1k5k5k5kkk5k5k5k5j5k5k5k5k5k5k5
5k515k5k5k5k5k1k5k5k5k1k5k7k7k6k5k5k5k1k5k5k5k1k5k5k515k5k5k5k1k5k5k515k5k5k5k1k5k5k515k5k5k5k1k5k5k515k5k515k5k5k5k5k1k5k5k5k1k
k5k5k5k5k5k5k5k5k5k5k5k515777665k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5k5
5k5k5k5k5k515k5k5k5k515k5k57d6dk5k5k5k5k5k5k515k5k5k5k5k5k515k5k5k5k515k5k5k5k5k5k5k515k5k5k5k5k5k515k5k5k5k515k5k5k515k5k5k515k
1515151k1515151515k5151515151dd51515151k15k515151515151k1515151515k515151515151k15k515151515151k1515151515k5151515k5151515k51515
5k515151515k515151515151511151k15k515151515151515k515151515k5151515151515k515151515151515k515151515k5151515151515151515151515151
151515151115151515151k15151515151515151515151k15151515151115151515151k151515151515151k15151515151115151515151k1515151k1515151k15
5111515h515h5151515151515151h1515111515h515151515111515h515h5151515151515111515h515151515111515h515h5151515151515151515151515151
h5151h1h1h1hh51hh5151h11hh5khh15h5151h1hh5151h11h5151h1h1h1hh51hh5151h11h5151h1hh5151h11h5151h1h1h1hh51hh5151h11h5151h11h5151h11
hh5hhhhhhh5hh1hhhh5h5h51hhh5hhhhhh5hhhhhhh5h5h51hh5hhhhhhh5hh1hhhh5h5h51hh5hhhhhhh5h5h51hh5hhhhhhh5hh1hhhh5h5h51hh5h5h51hh5h5h51
hhhhhhhhhhhhh5hhhhhhhhh5hhhhhhhhhhhhhhhhhhhhhhh5hhhhhhhhhhhhh5hhhhhhhhh5hhhhhhhhhhhhhhh5hhhhhhhhhhhhh5hhhhhhhhh5hhhhhhh5hhhhhhh5

__gff__
0000000000000000000010101000101000000000000000000000000020002000000222202000000000000000002020000000202020000000000200002000000020202020a0a080800020000000000000202020202022208020200000000000000000000000020080100000000000000010000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000019000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000017380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004454415945000000490000000000000000000000000000000000000000000000000000000044450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000006264636361000000000000580000000000000000000000000000000000000000001c00000060620000000000004454450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000490000000000000000000000000000000000002c1e000000000000444500006064600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005800001c00004800000000000000002e3d00000000000000606200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000001c000000000000000000000000000000000000000000003d0044434500000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0055555555000000002c000000000000000000000000000000000000000000002c1e617163001c0000234800002c2d000000000000000000580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00650000660033003c3d0000000000000055555500000000000000000000003c3d00000d00001d0044414041453d00000000000000000000000000580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565000066662700002c1e0000000000656557666600000000000000000000001d000070003c3d0046505350504145000000000000686868686868686800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565480066662700481d002300001a486565676666002221004800323100002e3d003248001a2c1e465150505052470022210048444240594240424143450000000000481a00000000000000481a00000000000000481a00000000000000481a0000000000000000000000000000000000000000000000000000000000000000
4043425443424159414241434140434241424241404243544142414243424143414042594042414350505250525052434143404152515252535050505256404341424041544043414240434041544043414240434041544043414240434041544043414240000000000000000000000000000000000000000000000000000000
6062616460616062616061606261616161606260606362646060616063606160616062606063626060626160636061606062636163606263606362636162606263606361646062636063626361646062636063626361646062636063626361646062636063000000000000000000000000000000000000000000000000000000
__sfx__
6120000014530195301c53014530195301c53015540195401c54015540195401c540155501a5501e550155501a5501e55014560185601e56014562195621c56214562195621b55212552185521b5420050000500
112000000d7600d7600d7600d7600d7600d7600976009760097600976009760097600676006760067600676006760067600876008760087600876008760087600876008760087600876008760087600176001760
4f2000001865500005186550000518655186550000518655186550000518655000051865518655000051865518655000051865500005186551865500005186551865500005186550000518655186551865518655
812000002521225212252122521225212252122721227212272122821228212282122a2122a2122a2122c2122c2122c2122821228212282122721227212272122521225212252122421224212242120000000000
010800000c262182220c2620c222182620c2220c262182220c262182220c262182220c262182220c262182220c462184220c462184220c462184220c462184220c462184220c462184220c462184220c46218422
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
05050000305602f5512e5512c541225012f5502f5412d5412c5410050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000000f112151121211218112151221b122181321e1321b142211421e14224142001021012219122141321c13219132201321c132251322014228142251422014200102191321f1321c132221321f14225142
002000002213228132251422b132281222e122001021e132241322113227132241322a142271422d1422a132301222d12233122001020d13210132191320d13210132191320f13214132181320f1321213218132
1120000008752087520875208752087520875208752087520875208752087520875208c0208752087520875208752087520875208752087520875208752087520875208c02087520875208752087520875208752
1120000008752087520875208752087520875200c0008752087520875208752087520875208752087520875208752087520875200c0001c5201c5201c5201c5201c5201c5208c5208c5208c5208c5208c5208c52
012000000d13210132191320d13210132191320f13214132181320f13212132181320d13210132191320d13210132191320f13214132181320f132121321813210132141321913214122191321c1322012225122
1120000010c5210c5210c5210c5210c5210c520cc520cc520cc520cc520cc520cc520dc520dc520dc520dc520dc520dc5208c5208c5208c5208c5206c5206c5201c5201c5201c5201c520dc520dc520dc520dc52
6120000014c3019c301cc3014c3019c301cc3015c4019c401cc4015c4019c401cc4015c501ac501ec5015c501ac501ec5014c6018c601ec6014c6219c621cc6214c6219c621bc5212c5218c521bc4200c0000c00
__music__
00 00414244
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
02 1e010344

