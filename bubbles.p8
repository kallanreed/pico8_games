pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- bubble trouble
-- by kallanreed

bub_col={8,9,11,14}
hi_score=0

function starting_board()
 for i=1,20 do
  board[i-1]=
   ceil(rnd(#bub_col))
 end
end

function _init()
 music(0,0,7)
 pal()
 poke(0x5f2e,1)

 score=0
 top_off=8
 fired_cnt=0
 in_flight=false
 board={}
 preview=bub(108,12,0,0,1)
 ●=bub(0,0,0,0,1)
 gun={
  x1=48,y1=120,
  x2=0,y2=0,
  a=90,r=12,
  ax=0,ay=0
 }
 part={}
 gen={}

 starting_board()
 update_gun()
 ●:reset()
 next_preview()
end

function update_gun()
 gun.a=mid(20,gun.a,160)
 
 local a=gun.a/360
 gun.ax=cos(a)
 gun.ay=sin(a)
 gun.x2=gun.ax*gun.r+gun.x1
 gun.y2=gun.ay*gun.r+gun.y1
end

function _update()
 if btn(⬅️) then
  gun.a+=2
  update_gun()
 end
 if btn(➡️) then
  gun.a-=2
  update_gun()
 end
 
 if btnp(❎)
 and not in_flight then
  sfx(32)
  fired_cnt+=1
  in_flight=true
  ●.dx=gun.ax*3
  ●.dy=gun.ay*3
 end

 ●:update()
 
 foreach(gen, do_update)
 update_particles()
end

function _draw()
 cls()
 map(0,0,0,0,16,16)
 draw_top()
 spr(16,36,112,3,2)

 for k,v in pairs(board) do
  local x,y=b2px(k)
  draw_bubble(x,y,v)
 end

 draw_particles()
 preview:draw()
 ●:draw()

 line(gun.x1,gun.y1,
  gun.x2,gun.y2,12)
 
 --local dbgi=px2b(●.x+4,●.y+4)
 --local dbgx,dbgy=b2px(dbgi)
 --rect(dbgx,dbgy,dbgx+7,dbgy+7,8)
 
 pal({[0]=129,1,2,3,4,5,6,7,8,9,10,139,12,13,140,132},1)
end

function draw_top()
 local top=top_off-8

 if top>=0 then

  for i=0,top,8 do
   map(16,0,8,i,11,1)
  end

  map(16,1,8,top,11,1)
 end
end

--[[
0 1 2 3 4 5
 0 1 2 3 4 5
0 1 2 3 4 5
]]

-- todo: consolidate neighbor collection
-- todo: collision sideways

function get_up(i)
 local y=flr(i/10)
 local x=i%10
 local x2=x+1
 if (band(y,1)==0) x2=x-1
 y-=1
 
 return y*10+x,y*10+x2
end

function get_unrooted()
 local unrooted=keys(board)
 local visited={}
 for i=0,9 do
  if board[i]!=nil then
   get_ur_rec(i,unrooted,visited)
  end
  if #unrooted<1 then
   return {}
  end
 end
 return unrooted
end

function get_ur_rec(i,u,v)
 -- already visited?
 if (count(v,i)>0) return
 add(v,i)
 del(u,i) -- reachable

 local y=flr(i/10)
 local x=i%10
 local x2=x+1
 if (band(y,1)==0) x2=x-1
 local worklist={}
 
 local add_work=function(_x,_y)
  if _x<0 or _x>10 or _y<0 then
   return
  end
  local _i=_y*10+_x
  if board[_i]!=nil then
   add(worklist, _i)
  end
 end

 -- up
 add_work(x,y-1)
 add_work(x2,y-1)
 -- down
 add_work(x,y+1)
 add_work(x2,y+1)
 -- l/r
 add_work(x-1,y)
 add_work(x+1,y)
 
 for w in all(worklist) do
  get_ur_rec(w,u,v)
 end
end

function get_matching(i,col)
 local matches={}
 if board[i]==col then
  get_mtch_rec(i,col,matches,{})
 end
 return matches
end

function get_mtch_rec(i,col,m,v)
 -- already visited?
 if (count(v,i)>0) return
 add(v,i)
 add(m,i)

 local y=flr(i/10)
 local x=i%10
 local x2=x+1
 if (band(y,1)==0) x2=x-1
 local worklist={}
 
 local add_work=function(_x,_y)
  if _x<0 or _x>9 or _y<0 then
   return
  end
  local _i=_y*10+_x
  if board[_i]==col then
   add(worklist, _i)
  end
 end

 -- up
 add_work(x,y-1)
 add_work(x2,y-1)
 -- down
 add_work(x,y+1)
 add_work(x2,y+1)
 -- l/r
 add_work(x-1,y)
 add_work(x+1,y)
 
 for w in all(worklist) do
  get_mtch_rec(w,col,m,v)
 end
end

function handle_bubble(i,col)
  board[i]=col
  local matches=
   get_matching(i,col)

  if #matches>2 then
   sfx(35) -- fall   
   -- matching bubbles
   for m in all(matches) do
    local x,y=b2px(m)
    bub_fall(x,y,col)
    board[m]=nil
   end
   
   -- unrooted bubbles
   local unrooted=get_unrooted()
   for u in all(unrooted) do
    local x,y=b2px(u)
    bub_fall(x,y,board[u])
    board[u]=nil
   end
  else
   sfx(34) -- stick
  end
 
 -- update globals
 in_flight=false
 if fired_cnt>2 then
  sfx(36)
  top_off+=8
  fired_cnt=0
 end
end

function next_preview()
 -- todo: too expensive 
 local k=keys(board)
 preview.col=board[rnd(k)]
end

-- test if 2 bubbles with the
-- specified coords overlap
function bub_overlap(ax,ay,bx,by)
 
 local a={sp=1,x=ax,y=ay,w=8,h=8}
 local b={sp=1,x=bx,y=by,w=8,h=8}
 
 return overlaps(a,b)
  and pxl_overlap(a,b)
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
 
 -- test if the indexes above
 -- have bubbles already
 local tbi1,tbi2=get_up(bi)
 
 local t1x,t1y=b2px(tbi1)
 local t2x,t2y=b2px(tbi2)
 
 local hit_bubble=
  (bub_overlap(nx,ny,t1x,t1y)
   and board[tbi1] != nil) or
  (bub_overlap(nx,ny,t2x,t2y)
   and board[tbi2] != nil)
   
 if ny<=top_off or hit_bubble then
  handle_bubble(bi,b.col)
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
-->8
-- particles

function explode(x,y,col)
 for i=0,30 do
  local p=particle(
   x,y,
   cos(rnd()),
   sin(rnd()),
   rnd(8)+8,col)
  p.update=function(my)
   my.dx*=.9
   my.dy+=.1
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
__gfx__
000000000066660066cc66cc67dc66cc66cc66cc000067dc6666666666cc6d7666cc66cc66cc66cc006666000000000000666600000000000000000000000000
00000000061111606cc66cc667d66cc66cc66cc6000067d6777777776cc66d766cc66cc66cc66cc6061111600066660006111160000000000000000000000000
0070070061171115cc66cc6667d6cc66cc66cc66000067d6ddddddddcc66cd76cc66cc66cc66cc66611711150611116061771115000000000000000000000000
0007700061711115c66cc66c67dcc66cc66cc66c000067dcc66cc66cc66ccd76c66cc66cc66cc66c617111156177111561111115000000000000000000000000
000770006111111566cc66cc67dc66cc66cc66cc000067dc66cc66cc66cc6d7666cc66cc66cc66cc611111156111111561111115000000000000000000000000
00700700611111156cc66cc667d66cc6dddddddd000067d66cc66cc66cc66d766cc66ccddcc66cc6611111156111111506111150000000000000000000000000
0000000006111150cc66cc6667d6cc6677777777000067d6cc66cc66cc66cd76cc66ccd77d66cc66061111500611115000555500000000000000000000000000
0000000000555500c66cc66c67dcc66c66666666000067dcc66cc66cc66ccd76c66ccd7777dcc66c005555000055550000000000000000000000000000000000
000000000000000000000000000067dc0000000066cc67dc66cc67dc66cc66cc66cc6d7777dc66cc000000000000000000000000000000000000000000000000
000000000000000000000000000067d6000000006cc667d66cc667d66cc66cc66cc66cd77dc66cc6000000000000000000000000000000000000000000000000
000000000000000000000000000067d600000000cc6667d6cc6667d6cc66cc66cc66cc6ddc66cc66000000000000000000000000000000000000000000000000
0000000000eeee0000000000000067dc00000000c66c67dcc66c67dcc66cc66cc66cc66cc66cc66c000000000000000000000000000000000000000000000000
000000000ecccce000000000666067dc6660666066cc67dc66cc67dc66cc66cc66cc66cc66cc66cc000000000000000000000000000000000000000000000000
00000000ec1111ce00000000000067d6000000006cc667d6dddd67d6dddddddd6cc66cc66cc66cc6000000000000000000000000000000000000000000000000
0000000ec111111ce0000000000067d600000000cc6667d6777767d677777777cc66cc66cc66cc66000000000000000000000000000000000000000000000000
000000ec11111111ce000000000067dc00000000c66c67dc666667dc66666666c66cc66cc66cc66c000000000000000000000000000000000000000000000000
00000ec111eeee111ce0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ec11ce0000e111ce000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ec111e000000e111ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ec1111e000000e1111ce0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ec11111e000000e11111ce000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ec111111e000000e111111ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ec1111111e0000e1111111ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ec11111111eeee11111111ce00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
66cc6d76hh6666hhhh6666hhhh6666hhhh6666hhhh6666hhhh6666hhhh6666hhhh6666hhhh6666hhhh6666hhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76h6ssss6hh688886hh688886hh688886hh6rrrr6hh6rrrr6hh6rrrr6hh6rrrr6hh6rrrr6hh688886hhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd766ss7sss56887888568878885688788856rr7rrr56rr7rrr56rr7rrr56rr7rrr56rr7rrr568878885hhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd766s7ssss56878888568788885687888856r7rrrr56r7rrrr56r7rrrr56r7rrrr56r7rrrr568788885hhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d766ssssss56888888568888885688888856rrrrrr56rrrrrr56rrrrrr56rrrrrr56rrrrrr568888885hhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d766ssssss56888888568888885688888856rrrrrr56rrrrrr56rrrrrr56rrrrrr56rrrrrr568888885hhhh67d66cc66ccddddddddddddddddddcc66cc6
cc66cd76h6ssss5hh688885hh688885hh688885hh6rrrr5hh6rrrr5hh6rrrr5hh6rrrr5hh6rrrr5hh688885hhhhh67d6cc66ccd777777777777777777d66cc66
c66ccd76hh5555hhhh5555hhhh5555hhhh5555hhhh5555hhhh5555hhhh5555hhhh5555hhhh5555hhhh5555hhhhhh67dcc66ccd77666666666666666677dcc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666hhhh6666hhhh6666hhhh6666hhhh6666hhhh6666hhhh6666hh67dc66cc6d76hhhhhhhhhhhhhhhh67dc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhh6ssss6hh688886hh6rrrr6hh6ssss6hh6ssss6hh6ssss6hh688886h67d66cc66d76hhhhhhhhhhhhhhhh67d66cc6
cc66cd76hhhhhh9h99hhhh9999hhhh9h99hh6ss7sss5688788856rr7rrr56ss7sss56ss7sss56ss7sss56887888567d6cc66cd76hhhhhhhhhhhhhhhh67d6cc66
c66ccd76hhhhhh9h99hhhh99h9hhhh9hh9hh6s7ssss5687888856r7rrrr56s7ssss56s7ssss56s7ssss56878888567dcc66ccd76hhhhhhhhhhhhhhhh67dcc66c
66cc6d76hhhhhh99hhhhhhhh99hhhh9999hh6ssssss5688888856rrrrrr56ssssss56ssssss56ssssss56888888567dc66cc6d76hhhhhh6666hhhhhh67dc66cc
6cc66d76hhhhhh9999hhhhh9h9hhhhh999hh6ssssss5688888856rrrrrr56ssssss56ssssss56ssssss56888888567d66cc66d76hhhhh6ssss6hhhhh67d66cc6
cc66cd76hhhhhhh999hhhh9999hhhh99h9hhh6ssss5hh688885hh6rrrr5hh6ssss5hh6ssss5hh6ssss5hh688885h67d6cc66cd76hhhh6ss7sss5hhhh67d6cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5555hhhh5555hhhh5555hhhh5555hhhh5555hhhh5555hhhh5555hh67dcc66ccd76hhhh6s7ssss5hhhh67dcc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc6d76hhhh6ssssss5hhhh67dc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh688886hhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66d76hhhh6ssssss5hhhh67d66cc6
cc66cd76hhhhhhhhhhhhhhhhhh99h9hhhhhhhhhhhhhhhhhhhhhhhhhh68878885hhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cd76hhhhh6ssss5hhhhh67d6cc66
c66ccd76hhhhhhhhhhhhhhhhhhh9h9hhhhhhhhhhhhhhhhhhhhhhhhhh68788885hhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccd76hhhhhh5555hhhhhh67dcc66c
66cc6d76hhhhhhhhhhhhhhhhhh9999hhhhhhhhhhhhhhhhhhhhhhhhhh68888885hhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc6d76hhhhhhhhhhhhhhhh67dc66cc
6cc66d76hhhhhhhhhhhhhhhhhh9999hhhhhhhhhhhhhhhhhhhhhhhhhh68888885hhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66d76hhhhhhhhhhhhhhhh67d66cc6
cc66cd76hhhhhhhhhhhhhhhhhh99h9hhhhhhhhhhhhhhhhhhhhhhhhhhh688885hhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cd76hhhhhhhhhhhhhhhh67d6cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh5555hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66ccd76hhhhhhhhhhhhhhhh67dcc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc6d77666666666666666677dc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cd777777777777777777dc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc6ddddddddddddddddddc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhchhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhscsshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhsccccshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhscscsscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhscssscsscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhscsssscssscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhscsss66c6ssscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhscsss699996ssscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhscsss69979995ssscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhscssss69799995sssscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c
66cc6d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhhscsssss69999995ssssscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dc66cc66cc66cc66cc66cc66cc66cc66cc
6cc66d76hhhhhhhhhhhhhhhhhhhhhhhhhhhhscssssss69999995sssssscshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d66cc66cc66cc66cc66cc66cc66cc66cc6
cc66cd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhcssssssss699995sssssssschhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67d6cc66cc66cc66cc66cc66cc66cc66cc66
c66ccd76hhhhhhhhhhhhhhhhhhhhhhhhhhhhssssssssss5555sssssssssshhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh67dcc66cc66cc66cc66cc66cc66cc66cc66c

__map__
0700000000000000000000050804040902020202020202020202150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0714141414141414141414130202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000050202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
010600002d0302b031210210b01100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001375213742007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702
01020000190401c041230313401100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900001f8401e8401c8401a83018820178100080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800
0104000000433004451164012630126301163011630106200f6100e6100c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 08090a44
00 08090b44
00 080a0c44
00 080b0d44
00 08090c44
02 08090d44

