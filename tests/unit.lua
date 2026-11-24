-- Run via python3 tests/lua_coverage.py from the repository root.
local base="games/kalender2026/scripts/"
local hits={}
debug.sethook(function(_,line)
    local file=debug.getinfo(2,"S").source:sub(2)
    if file:match("^games/kalender2026/") then
        hits[file]=hits[file] or {};hits[file][line]=true
    end
end,"l")
dofile(base.."rules.lua"); dofile(base.."network.lua")
local H=Hall
local first=1796079600
for d=1,24 do
    local instant=first+(d-1)*86400
    assert(H.due(instant-1)==d-1 and H.due(instant)==d and H.due(instant+1)==d)
    local x,z,ix,iz=H.door(d);assert(H.near_door(x,z,.5)==d and ix*ix+iz*iz==1)
end
assert(H.due(first+60*86400)==24 and not H.near_door(0,0,4))
local x,z=H.move(0,0,0,0,0);assert(z==2.25)
x,z=H.move(.2,.1,0,0,0);assert(math.abs(x*x+z*z-2.25^2)<.001)
x,z=H.move(0,0,100,-100,1);assert(x==7.5 and z==-7.5)
MissionPacks={};dofile("tests/fixture/missions/day_01.lua")
local enters,exits=0,0
MissionPacks[1].enter=function() enters=enters+1 end
MissionPacks[1].exit=function() exits=exits+1 end
local r=H.new(0);local p=H.join(r,1);local q=H.join(r,2);local spectator=H.join(r,3)
assert(not H.enter(r,p,1,MissionPacks))
p.x,p.z=H.door(1);q.x,q.z=p.x,p.z
assert(not H.enter(r,p,1,MissionPacks) and p.notice:find("December"))
r.hours=1;assert(not H.enter(r,p,1,{}) and p.notice:find("preparation"))
assert(H.enter(r,p,1,MissionPacks))
assert(not H.objective(r,spectator,MissionPacks))
p.z=0;assert(H.objective(r,p,MissionPacks) and r.instances[1].progress==1)
assert(H.enter(r,q,1,MissionPacks) and r.instances[1].progress==1)
q.z=0;assert(H.objective(r,q,MissionPacks) and r.instances[1].done)
assert(p.awards==1 and q.awards==1 and spectator.awards==0 and not H.objective(r,q,MissionPacks))
assert(H.back(r,p) and r.wave==2 and r.instances[1].members==1)
assert(H.back(r,q) and r.wave==2 and not r.instances[1] and not H.back(r,q))
assert(enters==2 and exits==2)
assert(not H.practice(r))
for _,m in pairs(r.mobs) do m.hp=0 end
assert(H.practice(r) and r.wave==3)
H.leave(r,8); H.leave(r,2); H.leave(r,3)
r.time=12
for i=1,5 do
    local m=r.mobs[i];local oldX,oldZ=m.x,m.z
    p.x,p.z=m.x,m.z;H.step(r,.05)
    assert(m.x~=oldX or m.z~=oldZ)
    assert(H.walk_speed(r,p)>0 and H.walk_speed(r,p)<H.speed)
end
p.x,p.z=20,20
for _=1,9 do H.step(r,.2) end
assert(H.walk_speed(r,p)==H.speed)
for k=1,5 do
    local a=H.new(24);local shooter=H.join(a,1)
    for _,m in pairs(a.mobs) do m.hp=0 end
    local t=H.targets[1];shooter.x,shooter.z=t[1],t[3]+3
    assert(H.fire(a,shooter,1,k,0,.08,-1))
    assert(#a.shots==(k==2 and 3 or 1))
    assert(not H.fire(a,shooter,1,k,0,0,-1))
    assert(not H.fire(a,shooter,2,k,0,0,-1))
    for _=1,8 do H.step(a,.1) end
    assert(a.hits==1,"bell hit by "..k)
    assert(not H.fire(a,shooter,2,6,0,0,1))
    assert(not H.fire(a,shooter,2,k,0,0,0))
    if k==4 then
        shooter.x,shooter.z=23.4,5
        H.fire(a,shooter,3,k,1,0,0);H.step(a,.15)
        assert(a.shots[1].vx<0 and a.shots[1].bounces==2)
        a.shots[1].z=23.8;a.shots[1].y=0;H.step(a,.01);assert(a.shots[1].bounces==1)
    end
end
local ar=H.new(24); local shooter=H.join(ar,1); shooter.x,shooter.z=5,5
ar.time=10
for i,m in pairs(ar.mobs) do m.x=5+(i-1)*.5;m.z=2;m.hp=1 end
H.fire(ar,shooter,1,5,0,-.1,-1);H.step(ar,.25);assert(ar.clears>=2)
H.wave(ar);ar.time=20;ar.mobs[1].x,ar.mobs[1].z,ar.mobs[1].hp=5,4,1
H.fire(ar,shooter,2,1,0,-.2,-1);ar.time=22;H.fire(ar,shooter,3,1,0,-.2,-1);H.step(ar,.10)
assert(ar.mobs[1].hp==0)
for i=1,8 do assert(Service.receive(i,"HELLO lantern-1 room",first)=="WELCOME "..i) end
assert(Service.receive(9,"HELLO lantern-1 room",first)=="ERROR Room full")
assert(Service.receive(9,"invalid",first):find("ERROR"))
local rr=Service.rooms.room;Service.step(.2,first)
for _,line in ipairs({"P 1 15 10","P x 17 10","P 999 888 0","F 1 3 0 0 -1","F bad 3 0 0 -1","ENTER 40","ENTER 1","BELL","USE","BACK",string.rep("x",256)}) do
    Service.receive(1,line,first)
end
assert(rr.players[1].yaw==10)
rr.players[1].x,rr.players[1].z=H.door(1)
Service.receive(1,"ENTER 1",first);rr.players[1].z=0;Service.receive(1,"USE",first)
assert(Net.read(Service.snapshot(1)).instances[1].progress==1)
rr.players[1].z=7;Service.receive(1,"BACK",first);assert(rr.players[1].space==0)
assert(Net.read(Service.snapshot(1)).wave==2)
assert(not Net.read("bad") and not Net.read("S 1 bad") and not Net.read("S 1 1 1 1 1"))
assert(Service.snapshot(20)=="")
for i=1,8 do Service.disconnect(i) end
assert(not Service.rooms.room)
-- Exercise the presentation and controls as a unit with the external engine boundary replaced.
local events,positions,save,keys,pressed={},{},{},{},{}
local function noop() end
local function id() events[#events+1]=1;return #events end
eng={scene={spawn=id,set_pos=function(e,a,b,c)positions[e]={a,b,c}end,get_pos=function(e)return unpack(positions[e])end,
 set_mesh=noop,set_rot_deg=noop,set_pocket=noop,set_scale=noop,register_pocket=id},
 asset={load_mesh=id,load_texture=id,box=id,voxel_ascii=id},camera={set=noop,look_at=noop,
 fps_steer=function(y,p,s,dt)return y,p,0,keys.up and -s*dt or 0 end},
 render={draw_sprite=noop,draw_text=noop,set_sky=noop,add_light=id},portal={link=noop},
 input={down=function(k)return keys[k]end,pressed=function(k)return pressed[k]end},
 save={read=function(k)return save[k]end,write=function(k,v)save[k]=v;return true end}}
bit={bor=function(a,b)local r,n=0,1;while a+b>0 do if a%2+b%2>0 then r=r+n end;a,b,n=math.floor(a/2),math.floor(b/2),n*2 end;return r end}
game={};HostUTC=first
dofile(base.."world.lua");dofile(base.."main.lua"); MissionPacks[1].build=noop
init();local g=game.state
keys.fire,keys.up=true,true
for i=1,5 do pressed["tool"..i]=true;update(.22);pressed={};assert(g.weapon==i) end
assert(host_sound():find("throw"));assert(host_sound()=="")
pressed.cycle=true;pressed.practice=true;update(.1);assert(g.weapon==1);pressed={}
draw(); assert(host_hud():find("Snowball Pistol"))
g.menu=true;update(.2);g.menu=false
host_xr(true,.1,0,.2,0,0,-1,30);update(.2);assert(g.xr.yaw)
host_xr(false);assert(not g.xr)
g.x,g.z=H.door(1);g.doorGuard=0;keys={};update(.1);assert(g.space==1)
assert(host_hud():find("objective"));g.z=0;pressed.interact=true;update(.1);update(.1)
assert(g.awards==1 and host_hud():find("Ornament earned"))
g.doorGuard=0;g.z=7;update(.1);assert(g.space==0);draw()
HostWeb=true;World.prepared[1]=false;g.x,g.z=H.door(1);g.doorGuard=0
update(.1);assert(host_pack_request()==1 and host_pack_request()==0 and host_hud():find("Loading door"))
host_pack_ready(1,false);assert(host_hud():find("retry"));g.noteUntil=0;g.doorGuard=0
update(.1);assert(host_pack_request()==1);host_pack_ready(1,true);HostWeb=false
g.x,g.z=H.door(1);assert(host_hud():find("replay"));g.x,g.z=H.door(2);assert(host_hud():find("Opens"))
g.room.hours=2;assert(host_hud():find("preparation"))
g.x,g.z=0,-13;update(.01);pressed={};g.room.players[1].slow=g.room.time+2;assert(host_hud():find("briefly"))
for _,v in pairs(g.room.mobs) do v.hp=0 end
assert(host_hud():find("Hall clear"))
g.room.hits,g.room.clears=10,8;update(.02);assert(host_sound():find("bell"))
local originalWrite=eng.save.write;eng.save.write=function()return false end
g.room.players[1].awards=3;update(.01);assert(host_hud():find("Could not save"));eng.save.write=originalWrite
local remote=H.new(1);H.join(remote,1);H.join(remote,2)
host_receive("WELCOME 2");update(.1);assert(g.awaiting and g.online)
host_receive(Net.snapshot(remote));update(.05);assert(not g.awaiting and host_drain():find("P "))
host_receive("invalid");host_weapon(5);keys.fire=true;g.nextFire=0;update(.2);assert(host_drain():find("F "))
host_receive("DISCONNECTED");assert(not g.online and g.space==0)
host_receive("ERROR Room full");assert(host_hud():find("Room full"))
for i=2,#arg do dofile(arg[i]) end
local f=assert(io.open(arg[1],"w"))
for path,seen in pairs(hits) do for line in pairs(seen) do f:write(path," ",line,"\n") end end
f:close();print("Calendar, all five snowcasters, five visitors, rooms, missions, saves, controls and presentation passed.")
