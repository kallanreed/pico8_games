pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- bubble trouble
-- by kallanreed

-- todo: waay too many
-- iterations over the board

hi_score=0
hi_score_str=""
music(0,0,7)

function start_level()
 top_off=0
 shot_cnt=0
 shot_max=5
 in_flight=false

 set_level(level)
 
 update_gun()
 next_preview()
 ●:reset()
 next_preview()

 del(drawable,level_text)
 level_text=add(drawable,
  outlined(112,32,
   "lVL "..level,7,13))
end

function _init()
 pal()
 poke(0x5f2e,1)

 game_over=false
 score=0
 level=1
 level_text=nil
 board={}
 gun={
  x1=48,y1=120,
  x2=0,y2=0,
  a=90,r=12,
  ax=0,ay=0
 }
 preview=bub(108,12,0,0,1)
 ●=bub(0,0,0,0,1)
 
 part={}
 gen={}
 timer={}
 drawable={}

 temp_text(64,50," \#c\^t\^wbubble trouble",7)
 temp_text(64,64,"\#c ❎ - launch ",7)
 temp_text(64,72,"\#c 🅾️ - precise aim ",7)

 start_level()
end

-- main update

function _update()
 if game_over then
  if (btnp(❎)) _init()
  return
 end

 local incr=_if(btn(🅾️),1,5)

 if btn(⬆️) then
  gun.a=90
  update_gun()
 end
 if btn(⬅️) then
  gun.a+=incr
  update_gun()
 end
 if btn(➡️) then
  gun.a-=incr
  update_gun()
 end
 
 if btnp(❎)
 and not in_flight then
  sfx(32)
  shot_cnt+=1
  in_flight=true
  ●.dx=gun.ax*4
  ●.dy=gun.ay*4
 end

 ●:update()
 
 foreach(gen, do_update)
 foreach(timer, do_update)
 update_particles()
 
  -- test for win
 if not next(board) then
  -- no bubbles left, advance
  sfx(37)
  explode(48,24,{8,9,10})
  camera_shake(.3)
  level+=1
  start_level()
  return
 end
 
 -- test for lose
 local mk=max_key(board)
 local off_y=top_off/8
 if flr(mk/10)+off_y>12 then
  sfx(38)
  camera_shake(.3)
  game_over=true
  hi_score=max(score,hi_score)
  hi_score_str=fmt_score(hi_score)
 end
end

function update_gun()
 gun.a=mid(20,gun.a,160)
 
 local a=gun.a/360
 gun.ax=cos(a)
 gun.ay=sin(a)
 gun.x2=gun.ax*gun.r+gun.x1
 gun.y2=gun.ay*gun.r+gun.y1
end


-- main draw

function _draw()
 cls()
 
 -- checker board
 for i=0,63 do
  local x,y=i%8,flr(i/8)

  local col=band(i+y,1)
  fillp(∧)
  rectfill(x*16,y*16,x*16+16,y*16+16,col)
  fillp()
 end 
 
 map(0,0,0,0,16,16)
 draw_pusher()
 draw_shots(0,82)
 draw_score(100,42)

 spr(16,36,112,3,2) --gun
 spr(12,60,113,3,3)


 for k,v in pairs(board) do
  local x,y=b2px(k)
  draw_bubble(x,y,v)
 end

 draw_particles()
 foreach(drawable, do_draw)
 
 preview:draw()
 ●:draw()

 line(gun.x1,gun.y1,
  gun.x2,gun.y2,12)
  
 if game_over then
  draw_game_over()
  return
 end
 
 pal({[0]=129,1,2,3,4,5,6,7,
  8,9,10,139,12,13,140,138},1)
end

function draw_score(x,y)
 local s=fmt_score(score)
 draw_outlined(x,y,s,7,13)
end

function draw_shots(x,y)
 for i=1,shot_max do
  local sp=
   _if(i>shot_cnt,10,11)
  spr(sp,x,i*8+y)
 end
end

function draw_pusher()
 local top=top_off-8

 if top>=0 then
  for i=0,top,8 do
   map(16,0,8,i,11,1)
  end

  map(16,1,8,top,11,1)
 end
end

function draw_game_over()
 text(48,32,"\#0❎ to restart",7):draw()
 text(48,40,"\#0high score",7):draw()
 text(48,47,"\#0"..hi_score_str,7):draw()
 pal({[0]=0,0,0,5,5,5,6,7,6,
          6,7,6,7,6,5,6},1)
end


-- board traversal

function get_unrooted()
 local unrooted=keys(board)
 local visited={}
 
 -- test all roots
 for i=0,9 do
  get_ur_rec(i,unrooted,visited)
 end
 return unrooted
end

function get_ur_rec(i,u,v)
 -- already visited?
 if (count(v,i)>0) return
 add(v,i)
 
 if (board[i]==nil) return
 del(u,i) -- reachable

 local ns=neighbors(i)
 for n in all(ns.all) do
  get_ur_rec(n,u,v)
 end
end

-- get all connected matching
function get_matching(i,col)
 local matches={}
 get_mtch_rec(i,col,matches,{})
 return matches
end

function get_mtch_rec(i,col,m,v)
 -- already visited?
 if (count(v,i)>0) return
 add(v,i)
 
 if (board[i]!=col) return
 add(m,i)
 
 local ns=neighbors(i)
 for n in all(ns.all) do
  get_mtch_rec(n,col,m,v)
 end
end

-- handle bubble placement
function place_bubble(i,col)
  board[i]=col
  local matches=
   get_matching(i,col)

  -- bubble removal
  if #matches>2 then
   sfx(35) -- fall
   local multi=1
   -- matching bubbles
   for m in all(matches) do
    local x,y=b2px(m)
    local s=10*multi
    local c=bub_col[col]
    score_float(x,y,c,s)
    score+=s
    multi+=0.1
    
    bub_fall(x,y,col)
    board[m]=nil
   end

   -- unrooted bubbles
   local unrooted=get_unrooted()
   for u in all(unrooted) do
    local x,y=b2px(u)
    local s=10*multi
    local c=bub_col[board[u]]
    score_float(x,y,c,s)
    score+=s
    multi+=0.1
    
    bub_fall(x,y,board[u])
    board[u]=nil
   end
  else
   sfx(34) -- stick
  end
 
 -- update globals
 in_flight=false
 if shot_cnt>=shot_max then
  sfx(36)
  top_off+=8
  shot_cnt=0
  camera_shake(.5)
 end
end

function update_bubble(b)
 -- next position
 local nx=b.x+b.dx
 local ny=b.y+b.dy
 
 -- board bounds
 if nx<8 or nx>84 then
  nx=mid(8,nx,84)
  b.dx=-b.dx
  sfx(33)
 end
 
 -- next board index
 local bi=px2b(nx+4,ny+4)
 
 -- prevent overlap
 -- todo: bounds
 while board[bi]!=nil do
  nx-=b.dx/2
  ny-=b.dy/2
  bi=px2b(nx+4,ny+4)
 end
 
 -- test if collision
 local ns=neighbors(bi)
 local to_test={
  ns.nw, ns.ne, ns.w, ns.e
 }
 
 local hit=false
 for ti in all(to_test) do
  if ti!=nil then
   tx,ty=b2px(ti)
   hit=
    bub_overlap(nx,ny,tx,ty)
    and board[ti]!=nil
  end
  if (hit) break
 end

 -- place bubble if it hits the
 -- top or another bubble
 if ny<=top_off or hit then
  place_bubble(bi,b.col)
  b:reset()
  next_preview()
  return
 end
 
 b.x=nx
 b.y=ny
end

function draw_bubble(x,y,col)
 pal(1,bub_col[col])
 spr(1,x,y)
 pal()
end

function bub(x,y,dx,dy,col)
 return {
  x=x,y=y,dx=dx,dy=dy,col=col,

  update=update_bubble,

  draw=function(my)
   draw_bubble(my.x,my.y,my.col)
  end,

  reset=function(my)
   my.x=gun.x1-4
   my.y=gun.y1
   my.dx=0
   my.dy=0
   my.col=preview.col
  end
 }
end

function next_preview()
 if (not board) return
 -- todo: too expensive
 local k=keys(board)
 preview.col=board[rnd(k)]
end
-->8
-- utils
function do_update(o)
 o:update()
end

function do_draw(o)
 o:draw()
end

function to_cell(x,y)
 return flr(x/8),flr(y/8)
end

function to_pxl(x,y)
 return x*8,y*8
end

function keys(tbl)
 local _keys={}
 for k,_ in pairs(tbl) do
  add(_keys,k)
 end
 return _keys
end

function max_key(tbl)
 local mx=nil
 for k,_ in pairs(tbl) do
  mx=max(k,mx)
 end
 return mx
end

-- in lieu of conditional
function _if(c,vt,vf)
 if (c) return vt
 return vf
end

function fmt_score(s)
 local score_str=tostr(flr(s))
 while #score_str<6 do
  score_str="0"..score_str
 end
 return score_str
end

-- get next sprite
function nxt(i,_min,_max)
 i+=1
 if (i>=_min and i<=_max) return i
 return _min
end

-- board index to pixels
function b2px(i)
 local y=flr(i/10)
 local x=i%10
 local offx=8 -- l edge

 if (band(y,1)==1) offx+=4
 return x*8+offx,y*8+top_off
end

-- pixels to board index
function px2b(x,y)
 local offx=-8 -- l edge
 local y=flr((y-top_off)/8)
 
 if (band(y,1)==1) offx-=4
 local x=flr((x+offx)/8)
 return y*10+x
end

function clamp(val,max_v)
 return mid(-max_v,val,max_v)
end

function map_rng(v,
 min_in,max_in,
 min_out,max_out)
 local d_in=max_in-min_in
 local d_out=max_out-min_out
 return (v-min_in)/d_in*
         d_out+min_out
end

-- test if 2 bubbles with the
-- specified coords overlap
function bub_overlap(ax,ay,bx,by)
 local a={sp=1,x=ax,y=ay,w=8,h=8}
 local b={sp=1,x=bx,y=by,w=8,h=8}
 return overlaps(a,b)
  and pxl_overlap(a,b)
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

function spget(sp,x,y)
 local sx=sp%16*8
 local sy=flr(sp/16)*8
 return sget(sx+x,sy+y)
end

--[[ tile layout
 0 1 2 3 4 5 6 7 8 9
  0 1 2 3 4 5 6 7 8 9
 0 1 2 3 4 5 6 7 8 9
]]

function neighbors(i)
 local y=flr(i/10)
 local x=i%10
 local x2=x+1
 local offx=
  _if(band(y,1)==1,0,-1)
 
 local at=function (_x,_y)
  if _x<0 or _x>9 or _y<0 then
   return nil
  end
  return _y*10+_x
 end

 local ns={all={}}
 local add_n=function(k,v)
  ns[k]=v
  if (v) add(ns.all,v)
 end

 add_n("nw",at(x+offx,y-1))
 add_n("ne",at(x2+offx,y-1))
 add_n("w",at(x-1,y))
 add_n("e",at(x+1,y))
 add_n("sw",at(x+offx,y+1))
 add_n("se",at(x2+offx,y+1))
 
 return ns
end
-->8
-- particles

function explode(x,y,cols)
 for i=0,60 do
  local p=particle(
   x+cos(rnd()),
   y+cos(rnd()),
   cos(rnd())*3,
   sin(rnd())*3-.1,
   rnd(10)+30,rnd(cols))
  p.update=function(my)
   my.dx*=.95
   my.dy+=.05
   if my.age>my.mxage*.8 then
    my.col=5
   end
  end
  p.draw=function(my)
   circfill(my.x,my.y,1,my.col)
  end

  add(part,p)
 end
end

function bub_fall(x,y,col)
 local p=particle(
  x,y,
  cos(rnd()),-.5+rnd(.2),
  rnd(10)+15,col)
 p.update=function(my)
  my.dx*=.95
  my.dy+=.3
 end
 p.draw=function(my)
  draw_bubble(my.x,my.y,my.col)
 end

 add(part,p)
end

function score_float(x,y,col,score)
 local p=particle(
  x,y,
  cos(rnd()),-.2,
  rnd(5)+8,col)
 p.s=tostr(flr(score))
 p.update=function(my)
  my.dx*=.8
 end
 p.draw=function(my)
  draw_outlined(my.x,my.y,
   my.s,my.col,1)
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
-- library

-- drawable

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

function draw_outlined(
 x,y,txt,col,outline_col)
 for i=-1,1 do
  for j=-1,1 do
   print(txt,i+x,j+y,outline_col)
  end
 end
 print(txt,x,y,col)
end

function outlined(x,y,txt,col,col2)
 local it=text(x,y,txt,col)
 it.col2=col2 or 0
 it.draw=function(my)
  my:apply_mods()
  draw_outlined(my.x+my.off_x,
   my.y+my.off_y,my.txt,my.col,my.col2)
 end
 return it
end

-- timer

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

function temp_text(x,y,txt,col)
 it=add(drawable,
   text(x,y,txt,col))
 del_after(3,drawable,it)
 return it
end

function camera_shake(sec)
 ani=0
 done=t()+sec
 return add(drawable,{
  draw=function(my)
   if t()-ani>.03 then
    ani=t()
    camera(ceil(rnd(2))-1,
     ceil(rnd(2))-1)
   end
   if t()>done then
    camera(0,0)
    del(drawable,my)
   end
  end
 })
end
-->8
-- data

function set_level(i)
 board={}
 local l=levels[i]
 
 if not l then
  local bubs=min(10*flr(i/5),70)
  random_level(bubs)
  return
 end
 
 for k,v in pairs(levels[i]) do
  board[k]=_if(v>0,v,nil)
 end
end

bub_col={8,9,11,14}
-- red,yellow,green,blue

function random_level(n)
 for i=0,(n-1) do
  board[i]=ceil(rnd(4))
 end
end

levels={
-- 1-10
{[0]=0,0,0,0,4,4,0,0,0,0,
      0,0,0,4,4,4,0,0,0,0},
{[0]=1,1,1,1,0,0,2,2,2,2},
{[0]=0,0,0,1,1,2,2,0,0,0,
      0,0,1,1,0,2,2,0,0,0,
     0,0,0,3,3,3,3,0,0,0},
{[0]=0,0,3,1,4,4,1,3,0,0,
      0,0,3,1,4,1,3,0,0,0,
     0,0,0,2,2,2,2,0,0,0},
{[0]=1,1,3,0,2,2,0,0,4,2,
      1,2,0,3,4,3,0,3,2,2,
     2,3,0,0,1,1,0,0,4,3}    
}
-->8
-- items
__gfx__
000000000066660066cc66cc67dc66cc66cc66cc000067dc6666666666cc6d7666cc66cc66cc66cc0bb000000660000000000000000000000000000000000000
00000000061111606cc66cc667d66cc66cc66cc6000067d6777777776cc66d766cc66cc66cc66cc6b7f300006765000000000000000000000000000000000000
0070070061171115cc66cc6667d6cc66cc66cc66000067d6ddddddddcc66cd76cc66cc66cc66cc66bfb3000066d5000000000000000000000000000000000000
0007700061711115c66cc66c67dcc66cc66cc66c000067dcc66cc66cc66ccd76c66cc66cc66cc66c133100001551000000000555550000000000000000000000
000770006111111566cc66cc67dc66cc66cc66cc000067dc66cc66cc66cc6d7666cc66cc66cc66cc011000000110000000055555555500000000000000000000
00700700611111156cc66cc667d66cc6dddddddd000067d66cc66cc66cc66d766cc66ccddcc66cc6000000000000000000557775777550000000000000000000
0000000006111150cc66cc6667d6cc6677777777000067d6cc66cc66cc66cd76cc66ccd77d66cc66000000000000000000577777777750000000000000000000
0000000000555500c66cc66c67dcc66c66666666000067dcc66cc66cc66ccd76c66ccd7777dcc66c000000000000000005775777775775000000000000000000
000000000000000000000000000067dc0000000066cc67dc555567dc5555555566cc6d7777dc66cc056665d5d5656650057757a9a75775000000000000000000
000000000000000000000000000067d6000000006cc667d65d5d67d65d5d5d5d6cc66cd77dc66cc605665d5d5d5666500577a799a7a775000000000000000000
000000000000000000000000000067d600000000cc6667d665d567d665d565d5cc66cc6ddc66cc66056565d5d5d5665055677777777765500000000000000000
0000000000eeee0000000000000067dc00000000c66c67dc565667dc56565656c66cc66cc66cc66c0566565d5d56565055567777777655500000000000000000
000000000ecccce000000000666067dc6660666066cc67dc666667dc6666666666cc66cc66cc66cc056665d5d565665005557777777555000000000000000000
00000000ec1111ce00000000000067d6000000006cc667d6555567d6555555556cc66cc66cc66cc605665d5d5d56665000055677765500000000000000000000
0000000ec111111ce0000000000067d600000000cc6667d6565567d656555655cc66cc66cc66cc66056565d5d5d5665000099555559900000000000000000000
000000ec11111111ce000000000067dc00000000c66c67dc555567dc55555555c66cc66cc66cc66c0566565d5d56565000000000000000000000000000000000
00000ec111eeee111ce0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ec111e0000e111ce000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ec111e000000e111ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ec1111e000000e1111ce0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ec11111e000000e11111ce000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ec111111e000000e111111ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ec1111111e0000e1111111ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ec11111111eeee11111111ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh6666hh1h6666hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhh6ssss6hh6ssss61h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhh6ss7sss56ss7sss5hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6s7ssss56s7ssss5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhh6ssssss56ssssss51hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhh6ssssss56ssssss5h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66ccddddddddddddddddddcc66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhh6ssss5hh6ssss5hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66ccd777777777777777777d66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5555hhhh5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccd77666666666666666677dcc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhh6666hhhh6666hh1h6666hh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc6d76hhhhhhhh1hhh1hhh67dc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhh6ssss6hh6ssss61h6ssss61h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66d76hhhhhhhhh1h1h1h167d66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhh6ss7sss56ss7sss56ss7sss5hh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cd76hhhhhhhhhh1hhh1h67d6cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhh6s7ssss56s7ssss56s7ssss5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccd76hhhhhhhhhhhhhhhh67dcc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhh6ssssss56ssssss56ssssss51hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc6d76hhhhhh6666hh1hhh67dc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhh6ssssss56ssssss56ssssss5h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66d76hhhhh6ssss61h1h167d66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhh6ssss5hh6ssss5hh6ssss5hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cd76hhhh6ss7sss5hh1h67d6cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5555hhhh5555hhhh5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccd76hhhh6s7ssss5hhhh67dcc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc6d761hhh6ssssss5hhhh67dc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66d76h1h16ssssss5hhhh67d66cc6
cc66cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cd76hh1hh6ssss5hhhhh67d6cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccd76hhhhhh5555hhhhhh67dcc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc6d761hhh1hhhhhhhhhhh67dc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66d76h1h1h1h1hhhhhhhh67d66cc6
cc66cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cd76hh1hhh1hhhhhhhhh67d6cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccd76hhhhhhhhhhhhhhhh67dcc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc6d77666666666666666677dc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66cd777777777777777777dc66cc6
cc66cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cc6ddddddddddddddddddc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccdddc66cc66cc66ccdddd66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc6d7d6ddddddd66cc6d77d6cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66d7d6d7d7d7d6cc66dd7dcc66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cd7dcd7d7d7dcc66ccd7dc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccd7ddd777d7ddd6ccdd7dd6cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc6d777dd7ddd77dcc6d777dcc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66ddddddddcddddc66dddddc66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66ccddddddddddddddddddddddddd6cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc6d777d777d777d777d777d777dcc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66d7d7d7d7d7d7d7d7d7d7d7d7dc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cd7d7d7d7d7d7d7d7d7d7d7d7d66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66ccd7d7d7d7d7d7d7d7d7d7d7d7d6cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc6d777d777d777d777d777d777dcc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66dddddddddddddddddddddddddc66c
66cc6d76cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66cc
6cc66d76ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66cc6
cc66cd76cc777777cc77cc77cc777777cc777777cc77cccccc777777cccccccccc777777cc777777cccc7777cc77cc77cc777777cc77cccccc777777cc66cc66
c66ccd76cc777777cc77cc77cc777777cc777777cc77cccccc777777cccccccccc777777cc777777cccc7777cc77cc77cc777777cc77cccccc777777cc6cc66c
66cc6d76cc77cc77cc77cc77cc77cc77cc77cc77cc77cccccc77cccccccccccccccc77cccc77cc77cc77cc77cc77cc77cc77cc77cc77cccccc77cccccccc66cc
6cc66d76cc77cc77cc77cc77cc77cc77cc77cc77cc77cccccc77cccccccccccccccc77cccc77cc77cc77cc77cc77cc77cc77cc77cc77cccccc77ccccccc66cc6
cc66cd76cc7777cccc77cc77cc7777cccc7777cccc77cccccc7777cccccccccccccc77cccc7777cccc77cc77cc77cc77cc7777cccc77cccccc7777cccc66cc66
c66ccd76cc7777cccc77cc77cc7777cccc7777cccc77cccccc7777cccccccccccccc77cccc7777cccc77cc77cc77cc77cc7777cccc77cccccc7777cccc6cc66c
66cc6d76cc77cc77cc77cc77cc77cc77cc77cc77cc77cccccc77cccccccccccccccc77cccc77cc77cc77cc77cc77cc77cc77cc77cc77cccccc77cccccccc66cc
6cc66d76cc77cc77cc77cc77cc77cc77cc77cc77cc77cccccc77cccccccccccccccc77cccc77cc77cc77cc77cc77cc77cc77cc77cc77cccccc77ccccccc66cc6
cc66cd76cc777777cccc7777cc777777cc777777cc777777cc777777cccccccccccc77cccc77cc77cc7777cccccc7777cc777777cc777777cc777777cc66cc66
c66ccd76cc777777cccc7777cc777777cc777777cc777777cc777777cccccccccccc77cccc77cc77cc7777cccccc7777cc777777cc777777cc777777cc6cc66c
66cc6d76cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66cc
6cc66d76ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66cc6
cc66cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccccccccccccccccccccccccccccccccccccccccccccccccccchh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhcccccc77777cccccccccccccc7ccc777c7c7c77ccc77c7c7ccccchh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhccccc77c7c77ccccccccccccc7ccc7c7c7c7c7c7c7ccc7c7ccccch167d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhccccc777c777ccccc777ccccc7ccc777c7c7c7c7c7ccc777ccccc1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhccccc77c7c77ccccccccccccc7ccc7c7c7c7c7c7c7ccc7c7ccccchh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhcccccc77777cccccccccccccc777c7c7cc77c7c7cc77c7c7ccccchh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhccccccccccccccccccccccccccccccccccccccccccccccccccccch167d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhcccccc77777cccccccccccccc777c777c777cc77c777cc77c777ccccc777c777c777ccccc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1hccccc77ccc77ccccccccccccc7c7c7c7c7ccc7cccc7cc7ccc7ccccccc7c7cc7cc777ccccc6cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1ccccc77c7c77ccccc777ccccc777c77cc77cc7cccc7cc777c77cccccc777cc7cc7c7ccccccc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhccccc77ccc77ccccccccccccc7ccc7c7c7ccc7cccc7cccc7c7ccccccc7c7cc7cc7c7cccccc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhcccccc77777cccccccccccccc7ccc7c7c777cc77c777c77cc777ccccc7c7c777c7c7ccccc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1hccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
crr6cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
r7q3cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
rqr36d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
13316d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
c116cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66cc66cc66cc66cc66cc66cc66cc6
crr6cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
r7q3cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
rqr36d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
13316d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66cc66cc66cc66cc66cc66cc66cc6
c116cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66cc66cc66cc66cc66cc66cc66cc6
crr6cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
r7q3cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
rqr36d76666h666h666h666h666h666h666h666h666h666hc66h666h666h666h666h666h666h666h666h666h666h67dc66cc66cc66cc66cc66cc66cc66cc66cc
13316d76hhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhc1h1h1h1h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h167d66cc66cc66cc66cc66cc66cc66cc66cc6
c116cd76hhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhch1hhh1hhh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1h67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhchhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1chhhhhhhhhhhhhhhh1h1h1h1h1h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
crr6cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hchhhhhhhhhhhhhhhhh1hhh1hhh1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
r7q3cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhsscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
rqr36d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1hhh1sccccshhhhhhhhhhhhh155555hh1hhh1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
13316d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1h1h1sc11c1cshhhhhhhhhhh555555555h1h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
c116cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1sc111c11cshhhhhhhhh55777577755h1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhsc1111c111cshhhhhhhh57777777775hhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1hhh1sc11166c6111cshhhhhh5775777775775hh1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1h1h1sc1116ssss6111cshhhhh57757a9a75775h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
crr6cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hhh1sc1116ss7sss5111cshhhh577a799a7a7751hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
r7q3cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhsc11116s7ssss51111cshh556777777777655hhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
rqr36d761hhh1hhhhhhhhhhhhhhhhhhh1hhh1sc111116ssssss511111csh555677777776555h1hhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
13316d76h1h1h1h1hhhhhhhhhhhhhhhhh1h1sc1111116ssssss5111111csh5557777777555h1h1h1hhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
c116cd76hh1hhh1hhhhhhhhhhhhhhhhhhh1hsc11111116ssss51111111cshhh556777655hh1hhh1hhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhsc11111111555511111111cshhh995555599hhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c

__map__
0700000000000000000000050804040900001a1b00001a1b0000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050700000317171717171717171717160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050700000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000051806061900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0714141414141414141414130202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010400001875024750187502474018740247400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200001862018620186253560019600116000a60007600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
031800000c033001053c7000c03324625001053c700246250c033246253c7000010524625001053c700246250c033001053c7000c03324625001053c7000c0330c033246253c7000010524625246002462524625
031800003c930009003c930009003c930009003c930249003c930249003c930009003c930009003c9303c9003c930009003c930009003c930009003c930249003c930249003c930009003c930009003c9303c930
011800001012500105001050010500105001051012512125131250010500105001051012500105171250010515125001050010500105001050010510125001051712518125171251512517125151250f12500105
011800001012500105001050010500105001051012512125131251213510135000000f13500000000000000000000000000b13500000000000000012135131351213500000000000f13500000000000b1350f100
1518000004125071250b125041000410004100041000410004125071250b1250410004100041000410004100091250c125101250910009100091000910009100091250c125101250910009100091000910009100
1518000004125071250b125000000410000000041000000004125071250b12500000000000000000000000000b125031250612500000000000000000000000000b12503125061250000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4906000028020230211c0210402100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001375213742007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702
01020000190401c041230313401100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900001f8401e8401c8401a83018820178100080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800
0104000000433004451164012630126301163011630106200f6100e6100c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
491000001312500100131251a1301a135001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010b00002b05528055230551f0551c055130550433500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
__music__
01 08090a44
00 08090b44
00 080a0c44
00 080b0d44
00 08090c44
02 08090d44

