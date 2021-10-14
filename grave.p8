pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- grave matters
-- by 😐

music(0,0,7)

-- animate the map sprite @x,y
function blink(x,y,rate,jit)
 local sp=mget(x,y)
 local r=rate or .5
 local jit=jit or r*.5
 local cur=0 local ani=0
 return function()
   mset(x,y,sp+cur)
   if (time()-ani>r) then
    cur^^=1
    ani=time()+(rnd(2*jit)-jit)
   end
 end
end

-- render sprite in relation camera
function fixed(sp,x,y,w,h,speed)
 return function()
  local w=w or 1
  local h=h or 1
  local speed=speed or 1
  spr(sp,x+cam_x*speed,y,w,h)
  end
end

function _init()
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
  ani=0,
 }
 
 drawable={}
 add(drawable, fixed(37,32,32,2,2,.98))
 add(drawable, fixed(40,30,28,4,1,.8))
 add(drawable, fixed(40,74,40,4,1,.8))

 add(drawable, blink(6,11,.20))
 add(drawable, blink(9,12))
 add(drawable, blink(41,10))
 
 cam_x=0
 map_min=0
 map_max=48*8
 
 x1r=0 y1r=0 x2r=0 y2r=0
end
-->8
-- update

function clamp(val,max_v)
 return mid(-max_v,val,max_v)
end

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

  if collide(plr,⬇️,0) then
   plr.dy=0
   plr.y-=((plr.y+plr.h+1)%8)-1
   plr.falling=false
   plr.landed=true
  end
 elseif plr.dy<0 then
  plr.jumping=true
 end

 if plr.dx>0 then
  if collide(plr,➡️,0) then
   plr.dx=0
  end
 elseif plr.dx<0 then
  if collide(plr,⬅️,0) then
   plr.dx=0
  end
 end

 if abs(plr.dx)<.1 then
  plr.dx=0
  plr.walking=false
 end
 
 plr.dx=clamp(plr.dx,plr.max_dx)
 plr.dy=clamp(plr.dy,plr.max_dy)

 plr.x+=plr.dx
 plr.y+=plr.dy
 
 if plr.x<map_min then
  plr.x=map_min
  plr.dx=0
 end

end

function _update()

 player_update();
 
 if btnp(🅾️) then
  sfx(9)
 end

	-- camera tracking
	-- plr.x has a lot of jitter so flr
 cam_x=flr(plr.x)-56
 if (cam_x < map_min) cam_x=0
 if (cam_x > map_max-128) cam_x=map_max-128;
end
-->8
-- draw

-- get next sprite
function nxt(i,mn,mx)
 i+=1
 if (i>=mn and i<=mx) return i
 return mn
end

function str(s) return tostring(s) end

function draw_player()
 if plr.jumping then
  plr.sp=4
 elseif plr.falling then
  plr.sp=5
 elseif plr.walking then
  if time()-plr.ani>.2 then
   plr.sp=nxt(plr.sp,2,3)
   plr.ani=time()
  end
 else -- idle
  plr.sp=1
 end

 spr(plr.sp,plr.x,plr.y,plr.w/8,plr.h/8,plr.flp)
 --print("s="..plr.sp.." r="..str(plr.walking),plr.x,plr.y-8)
 --print("dx="..plr.dx.."dy="..plr.dy,plr.x,plr.y-8)
 --rect(x1r,y1r,x2r,y2r,7)
end

-- drawable dispatch
function draw_one(d)
 d()
end

-- main draw loop
function _draw()
 cls()
 camera(cam_x,0)
 map(0,0,0,0,128,32,0)
	
 foreach(drawable, draw_one)
 draw_player()

 -- draw foreground
 map(0,0,0,0,128,32,2)
end
-->8
-- collision

function collide(obj,dir,flag)
 local x=obj.x local y=obj.y
 local w=obj.w local h=obj.h
 local x1=0 local y1=0
 local x2=0 local y2=0
 -- need better test for
 -- larger sprites
 if dir==⬅️ then
  x1=x-1 y1=y+3
  x2=x-2 y2=y+h-1
 elseif dir==➡️ then
  x1=x+w   y1=y+3
  x2=x+w+1 y2=y+h-1
 elseif dir==⬇️ then
  x1=x+1   y1=y+h
  x2=x+w-2 y2=y+h+1
 end
 
 x1r=x1 y1r=y1 x2r=x2 y2r=y2

 x1/=8 y1/=8 x2/=8 y2/=8
 
 if fget(mget(x1,y1),flag)
 or fget(mget(x1,y2),flag)
 or fget(mget(x1,y1),flag)
 or fget(mget(x2,y2),flag)
 then return true end
 
 return false
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000040000004000000040000000400000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080000000800000008000000080000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004444400044444000444440004444400044444000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000044fff44044fff44044fff44044fff44044fff4400000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000045755740457557404575574045755740457557400000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000f55f55f0f55f55f0f55f55f0f55f55f0f55f55f00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ff444ff0ff444ff0ff444ff0ff444ff0ff444ff00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000f4f4f000f4f4f000f4f4f000f4f4f000f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006666600066666000666660006666600066666000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd00f666f000f666f000f666f000f666f000f666f000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888888800f666f000f666f000f666f00f06660f0f06660f00000000000000000000000000000000000000000000000000000000000000000000000000000000
222d222200f111f000f111f000f111f0000111000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222d222000101000001011000001100001001000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd000101000001001000511000010010000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000505000005005000005000500500000000505000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000300000066660000003000000030000000066677700000000d50000000000000000000050500000000000000000000000000000000000000000000
00000000022030000666666000033000000330000006666666777000000d50000000000000000050505050000000000000000000000000000000000000000000
dddddddd05203000065555600999999009999990006d666666666700000d50000000050505000505050505050000000000000000000000000000000000000000
66666666000030300656556099a99a999959959906ddd666556d6670000d50000000505050505050505050505000000000000000000000000000000000000000
555d55550000330006665660999999999999999906d5d66dd56dd670000d50000005050505050505050505050505000000000000000000000000000000000000
5555d5550030300006666660999aa9999995599966ddd666ddd66676000d50000050505050505050505050505050505000000000000000000000000000000000
dddddddd000555000666666099a9aa99995955996d55666666dd6776000d50000005050505050505050505050505050500000000000000000000000000000000
00000000055555503333333309999990099999906d5d666776dd6676000d50000000000050505050000050505050500000000000000000000000000000000000
007777000000300000666600000d5000000d50006dddd66776667776000d50000000000000000000000000000000000000000000000000000000000000000000
07777770000302200666666000d5550000d555006666dd6677777776000d50000000000000000000000000000000000000000000000000000000000000000000
07777570000302500655556005000050050000506666dd6677677766000d50000000000000000000000000000000000000000000000000000000000000000000
07577777030300000655656005009050050000500666666776767760000d50000000000000000000000000000000000000000000000000000000000000000000
07775777003300000665666005096050050a60500667777777777660000d50000000000000000000000000000000000000000000000000000000000000000000
077757770003030006666660050996500509a6500066767777776600000d50000000000000000000000000000000000000000000000000000000000000000000
07777777005550000666666005098050050890500006776777666000000d50000000000000000000000000000000000000000000000000000000000000000000
07707707055555503333333305555550055555500000077666600000005555000000000000000000000000000000000000000000000000000000000000000000
d2222d2222d2222222222d22d2222d2200022d2222d2200022355555555553220000000000000000000000000000000000000000000000000000000000000000
222d222222222d222d323222222222220022222222232200d25551555515552d0000000000000000000000000000000000000000000000000000000000000000
5323233532235223535332d33223232302d223233233322022335555555533220000000000000000000000000000000000000000000000000000000000000000
55253555533553355555352553253525222335255253222222355545545553220000000000000000000000000000000000000000000000000000000000000000
552555155555455555155535552155552d3155555555132d2d315555555513d20000000000000000000000000000000000000000000000000000000000000000
54555555515555555555555555355555233555555555532223355555555553320000000000000000000000000000000000000000000000000000000000000000
55515555555551555554551554555515235545155155553222554515515455220000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555255555555555553223555555555555320000000000000000000000000000000000000000000000000000000000000000
55555555555551555551555455555555222222220500050000000000000000000000000000000000000000000000000000000000000000000000000000000000
55155554557555555555555554777555222222225500550000000000000000000000000000000000000000000000000000000000000000000000000000000000
54555155567555555554555557575655322322250500050000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555555dd754555155551557776651532532350500050000000000000000000000000000000000000000000000000000000000000000000000000000000000
55155255555d77555555555555766d55545553515555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555555556d5155555555556d6555551777550500050000000000000000000000000000000000000000000000000000000000000000000000000000000000
525455155155d55555515545515dd455557575650500050000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555157776650500050000000000000000000000000000000000000000000000000000000000000000000000000000000000
555555555555515555515554555555555557d6d50500050005000500000000000000000000000000000000000000000000000000000000000000000000000000
5515555455455555555555555451555555555dd50500050005000500000000000000000000000000000000000000000000000000000000000000000000000000
54555155555555555554555555555455551555450500050005000500000000000000000000000000000000000000000000000000000000000000000000000000
55555555555554555155551555555551555555550500050005000500000000000000000000000000000000000000000000000000000000000000000000000000
55155550555155555550555555051555555505515555555555555555000000000000000000000000000000000000000000000000000000000000000000000000
05555050055550515050055005055555005400550500050005000500000000000000000000000000000000000000000000000000000000000000000000000000
00500000005050550050050005000500000500000500050005000500000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000050000050000000000000000000500050005000500000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006667770000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000666666677700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000006d66666666670000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000006ddd666556d667000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000006d5d66dd56dd67000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000066ddd666ddd6667600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000006d55666666dd677600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000006d5d666776dd667600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000006dddd6677666777600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000006666dd667777777600000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000006666dd667767776600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000066666677676776000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000066777777777766000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000006676777777660000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000677677766600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000007766660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500050005000500000d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
550055005500550000d5550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000500050005000500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000500050005000500905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550509605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000500050005000509965000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000500050005000509805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000500050005000555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500050005000500000d500000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000
0500050005000500000d500000000000000000000000000000000004000000000000000000033000000000000000000000000000000000000000000000000000
0500050005000500000d500000000000000000000000000000000008000000000000000009999990000000000000000000000000000000000000000000000000
0500050005000500000d500000000000000000000000000000000444440000000000000099a99a99000000000000000000000000000000000000000000000000
5555555555555555000d5000000000000000000000000000000044fff44000000000000099999999000000000000000000000000000000000000000000000000
0500050005000500000d5000000000000000000000000000000045755740000000000000999aa999000000000000000000000000000000000000000000000000
0500050005000500000d50000000000000000000000000000000f55f55f000000000000099a9aa99000000000000000000000000000000000000000000000000
0500050005000500000d50000000000000000000000000000000ff444ff000000000000009999990000000000000000000000000000000000000000000000000
0500050005000500000d500000666600000030000066660000000f4f4f00000000022d22d2222d2222d22222d2222d2222d22000000000000000000000000000
0500050005000500000d50000666666000030220066666600000066666000000002222222222222222222d22222d222222232200000000000000000000000000
0500050005000500000d500006555560000302500655556000000f666f00000002d2232332222323322352235323233532333220000000000000000000000000
0500050005000500000d500006565560030300000655656000000f666f0000002223352553223525533553355525355552532222000000000000000000000000
5555555555555555000d500006665660003300000665666000000f111f0000002d3155555521555555554555552555155555132d000000000000000000000000
0500050005000500000d500006666660000303000666666000000010100000002335555555355555515555555455555555555322000000000000000000000000
0500050005000500000d500006666660005550000666666000000010100000002355451554555515555551555551555551555532000000000000000000000000
05000500050005000055550033333333055555503333333300000050500000002555555555555555555555555555555555555532000000000000000000000000
d2222d22d2222d2222222d2222222222d2222d2222222d2222d2222222222d225551555455555555555551555555555555555555d2222d22d2222d2222222d22
222d2222222222222d32322222222222222222222d32322222222d222d3232225555555555155554557555555515555455155554222d2222222222222d323222
5323233532222323535332d33223222532222323535332d332235223535332d355545555545551555675555554555155545551555323233532222323535332d3
552535555322352555553525532532355322352555553525533553355555352551555515555555555dd754555555555555555555552535555322352555553525
55255515552155555515553554555351552155555515553555554555551555355555555555155255555d77555515525555155255552555155521555555155535
5455555555355555555555555517775555355555555555555155555555555555555555555555555555556d515555555555555555545555555535555555555555
555155555455551555545515557575655455551555545515555551555554551555515545525455155155d5555254551552545515555155555455551555545515
55555555555555555555555515777665555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555515554555551555557d6d5555555555555515555555555555155545555515555555555555551555555555555515554555551555555515555555155
55155554555555555545555555555dd5551555545545555555155554555555555545555555155554554555555515555455555555554555555545555555455555
54555155555455555555555555155545545551555555555554555155555455555555555554555155555555555455515555545555555555555555555555555555
55555555515555155555545555555555555555555555545555555555515555155555545555555555555554555555555551555515555554555555545555555455
55155550555055555551555555550551551555505551555555155550555055555551555555155550555155555515555055505555555155555551555555515555
05555050505005500555505100540055055550500555505105555050505005500555505105555050055550510555505050500550055550510555505105555051
00500000005005000050505500050000005000000050505500500000005005000050505500500000005050550050000000500500005050550050505500505055
00000000000005000000000500000000000000000000000500000000000005000000000500000000000000050000000000000500000000050000000500000005

__gff__
0000000000000000000000000000000000000000000000000000000000000000000202000000000000000000000000000000000000000000000000000000000001010101010101010000000000000000010101010102000000000000000000000000000000020000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0055555555000000000000000000000000000000000000000000000000000000000000000000000000230000000000004600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0065000066003300000000000000000055555500000000000000000000000055550000000000000044414045000000554600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565000066662700002300000000006565006666000000000000000000000065650000000000004450505350450000654600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6565000066662700444341404500006565006666002221000000003200000065650000000000445252515050524500654600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4043425443424142525051505040434241424241404243544142414243424143414042414042525050505250525041435100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6062616460616062616061606261616161606260606362646060616063606160616062606063626060626160636061600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
8d0500002373225742227522374221732227221f7221f7101b7101170000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
060600001a5311d531205310050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005000050000500
__music__
00 00414244
01 00024344
00 00020143
00 00020103
02 41010244

