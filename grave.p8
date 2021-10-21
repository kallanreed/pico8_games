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

 -- test rect
 x1r=0 y1r=0 x2r=0 y2r=0
end
-->8
-- update

function player_update()
 if (plr.dead) return

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
 plr.dead=true
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

-- generator that emits particles
-- outward from a single point
function sparkler(x,y,col1,col2)
 return {
  x=x, y=y, col1=col1, col2=col2,
  ani=0, mxd=1, rate=.1,
  
  update=function(my)
   if t()-my.ani>my.rate then
    my.ani=t()
    add(part,{
     x=my.x, y=my.y, col=col1,
     dx=rnd(.5*my.mxd,my.mxd)*rnd_sign(),
     dy=rnd(.5*my.mxd,my.mxd)*rnd_sign(),
     age=0, mxage=rnd(8)+8,
     
     update=function(_my)
      if (_my.age*1.5>_my.mxage) _my.col=my.col2
     end
    })
    
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000400000040000000400000004000000004000000040000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000800000008000000080000000800000008000000080000000000000000000000000000000000000000000000000000000000000000000000000000
00000000044444000444440004444400044444000444440004444400000000000000000000000000000000000000000000000000000000000000000000000000
0000000044fff44044fff44044fff44044fff44044fff44044fff440000000000000000000000000000000000000000000000000000000000000000000000000
00000000457557404575574045755740457557404575574045755740000000000000000000000000000000000000000000000000000000000000000000000000
00000000f55f55f0f55f55f0f55f55f0f55f55f0f55f55f0f55f55f0000000000000000000000000000000000000000000000000000000000000000000000000
00000000ff444ff0ff444ff0ff444ff0ff444ff0ff444ff0ff444ff0000000000000000000000000000000000000000000000000000000000000000000000000
000000000f4f4f000f4f4f000f4f4f000f4f4f000f4f4f000f4f4f000000000000000000000000000080000000000000000000d000d55500000ddd5000000000
000000000666660006666600066666000666660006666600066666000000000000000000000000000688000000000000000d0d0800d50500ddd5000400000000
000000000f666f000f666f000f666f000f666f000f666f000f666fff0000000000000000000000008886800000000000000dd000000550005050055000000000
000000000f666f000f666f000f666f00f06660f0f06660f00f66600000000000000000000000000000d0036000060000000d000000d55d000005500800000000
000000000fcccf000fcccf000fcccf0000ccc00000ccc0000fccc0000000000000000000000000000d00633300000000dd0d50000d5555000000080000000000
0000000000c0c00000c0cc00000cc0000c00c00000c0c00000c0c0000000000000000000000000000d0000d00000000005d550000d5555000000000000000000
0000000000c0c00000c00c0005cc0000c00c0000000c0c0000c0c0000000000000000000000000000dd000d00000000000505000055505000000000000000000
0000000000505000005005000005000050050000000505000050500000000000000000000000000000dd0d00000000000055000000d550000000000000000000
0060600000030000006666000000b0000000b0000000066677700000000d50000000000000000000050500000000000000d5500000000d400dd0d00000000000
060606000880300006666660000b3000000b30000006666666777000000d50000000000000000050505050000000000000d500005dddd000400dddd500000000
0060656002803000065555600999999009999990006d666666666700000d500000000505050005050505050500000000000550dd505005080050005500000000
06560606000030b00656556099a99a999959959906ddd666556d6670000d50000000505050505050505050505000000000d55d55000500500500050000000000
0060506000003b0006665660999999999999999906d5d66dd56dd670000d50000005050505050505050505050505000000d55550004080400805500000000000
0606560600b0300006666660999aa9999995599966ddd666ddd66676000d50000050505050505050505050505050505000d55500000000000004000000000000
00606060000555000666666099a9aa99995955996d55666666dd6776000d50000005050505050505050505050505050500d50500000000000000000000000000
06060606055555503333333309999990099999906d5d666776dd6676000d5000000000005050505000005050505050000d555500000000000000000000000000
007777000000300000666600000d5000000d50006dddd66776667776000d50004544445400099000090006600008000040ddd00000d550000000066000000000
07777770000308800666666000d5550000d555006666dd6677777776000d50000450054000900900909060060087800005005dddd0d550000800600600000000
07777570000308200655556005000050050000506666dd6677677766000d5000040000400090090009000006087f8800804005055d5550008780000600000000
075777770b0300000655656005009050050000500666666776767760000d5000045005400009900009900660087f880000055000055055007e80066000000000
0777577700b300000665666005096050050a60500667777777777660000d5000454444540009000009000600087e880000080000005555008820060000000000
0777577700030b0006666660050996500509a6500066767777776600000d5000040000400009900009900000088e8200000000000d5550000200000000000000
07777777005550000666666005098050050890500006776777666000000d500004000040000900000000060000882000000000000d550d000000060000000000
077077070555555033333333055555500555555000000776666000000055550004000040000990000000000000020000000000000d5555d00000000000000000
d2222d2222d2222222222d22d2222d2200022d2222d2200022345454545453220000000000000000000000000000000000000000000000000000000000000000
222d222222222d222d323222222222220022222222232200d24541454515452d0000000000000000000000000000000000000000000000000000000000000000
5323233432235223535332d33223232302d223233233322022335454545433220000000000000000000000000000000000000000000000000000000000000000
45253545433543354545352543253525222335254253222222354545444553220000000000000000000000000000000000000000000000000000000000000000
542454145454445454145434542154542d3154545454132d2d315454545413d20000000000000000000000000000000000000000000000000000000000000000
44454545414545454545454545354545233545454545432223354545454543320000004000000000000000000000000000000000000000000000000000000000
54515454545451545454541454545414235444145154543222544414515454220500005000000000000000000000000000000000000000000000000000000000
45454545454545454545454545454545254545454545453223454545454545320505005000000000000000000000000000000000000000000000000000000000
54545454545451545451545454545454222222220600060054145454000555000000000000000000000000000000000000000000000000000000000000000000
45154544457545454545454544777545222222226500650045454745005050500000000000000000000000000000000000000000000000000000000000000000
54545154567454545454545457575654322322240500050054545764005050500000000000000000000000000000000000000000000000000000000000000000
454545454dd744454145451547776641432532350500050045457dd5050050050000000000000000000000000000000000000000000000000000000000000000
54145254545d77545454545454766d5454545351555555555477d454050050050000000000000000000000000000000000000000000000000000000000000000
4545454545456d4145454545456d6545451777450500050015d64545050555050000000000000000000000000000000000000000000000000000000000000000
525454145154d45454515444515dd4545474746405000500545d5414055505550000000000000000000000000000000000000000000000000000000000000000
45454545454545454545454545454545157776650500050045454545055000550000000000000000000000000000000000000000000000000000000000000000
545454545454515454515454545454545457d6d40500050005000500055505550000000000000000000000000000000000000000000000000000000000000000
1515151415451515151515151411151515151dd50500050005000500050505050000000000000000000000000000000000000000000000000000000000000000
54515151515151515154515151515451511151410500050005000500050555050000000000000000000000000000000000000000000000000000000000000000
15151515151514151115151515151511151515150500050005000500050050050000000000000000000000000000000000000000000000000000000000000000
51115150515151515150515151011151515101515555555555555555055555550000000000000000000000000000000000000000000000000000000000000000
05151010051510111010051005051515005400150500050005000500050050050700070000000000000000000000000000000000000000000000000000000000
00500000005050510050010001000500000500000500050005000500050050057760776000000000000000000000000000000000000000000000000000000000
00000000000000050000050000000000000000000500050005000500050050057665766500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088822250
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111155099994450
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022222250aa999455
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033335550bbb33330
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044455550ccc11110
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555dd222250
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066655550eee22200
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777ffeee225
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
0000000000000000000000000000000000000000000000000000000020002000000222202000000000000000002020000000202020000000200200002000000020202020a0a080800000000000000000202020202022208000000000000000000000000000020080100000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c00000060620000000000004454450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c1e000000000000444500006064600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001c00004800000000000000002e3d00000000000000606200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000001c000000000000000000000000000000000000000000003d0044434500000000000000001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0055555555000000002c000000000000000000000000000000000000000000002c1e616263001c0000234800002c2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00650000660033003c3d0000000000000055555500000000000000000000003c3d00000000001d0044414041453d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565000066662700002c1e0000000000656557666600000000000000000000001d000000003c3d0046505350504145000000000000686868686868686800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565480066662700481d002300001a486565676666002221004800323100002e3d003248001a2c1e465150505052470022210048444240414240424143450000000000481a00000000000000481a00000000000000481a00000000000000481a0000000000000000000000000000000000000000000000000000000000000000
4043425443424142414241434140434241424241404243544142414243424143414042414042414350505250525052434143404152515252535050505251404341424041544043414240434041544043414240434041544043414240434041544043414240000000000000000000000000000000000000000000000000000000
6062616460616062616061606261616161606260606362646060616063606160616062606063626060626160636061606062636163606263606362636164606263606361646062636063626361646062636063626361646062636063626361646062636063000000000000000000000000000000000000000000000000000000
__sfx__
6120000014530195301c53014530195301c53015540195401c54015540195401c540155501a5501e550155501a5501e55014560185601e56014562195621c56214562195621b55212552185521b5420000000000
132000000d7600d7600d7600d7600d7600d7600976009760097600976009760097600676006760067600676006760067600876008760087600876008760087600876008760087600876008760087600176001760
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000000f112151121211218112151221b122181321e1321b142211421e14224142001021012219122141321c13219132201321c132251322014228142251422014200102191321f1321c132221321f14225142
002000002213228132251422b142281422e142001021e132241322113227132241322a142271422d1422a142301422d14233142001020d13210132191320d13210132191320f13214132181320f1321213218132
012000000873208732087320873208732087320873208732087320873208732087320870008732087320873208732087320873208732087320873208732087320873208700087320873208732087320873208732
012000000873208732087320873208732087320000008732087320873208732087320873208732087320873208732087320873200000017320173201732017320173201732087320873208732087320873208732
0020000010132141321913214122191321c1320d12200100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
012000000173201732017320173201732017320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00414244
01 00024344
00 00020143
00 00030143
00 41010244
00 020f4344
00 181a4244
00 191b4344
02 1c1d0244

