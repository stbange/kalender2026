"""Build the original loose GLB, pixel-art and audio files for The Lantern Hall."""
import json
import math
import random
import struct
import wave
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "games/kalender2026/assets"
OUT.mkdir(exist_ok=True, parents=True)
rng = random.Random(20261201)
colors = ["141e30","28374a","43566a","8495a6","cad3ce","f8eacb","50312a","764836",
          "ab7451","c99a68","38262b","7f2831","b93c41","ee6959","97713e","cc9350",
          "ffd37a","fff2a5","183833","245844","367656","529569","88b887","162d40",
          "25526b","3c8294","79c5d0","c8f2e8","392c4c","755375","bb8eab","f4f4eb"]

def png(path,w,h,pixels):
    def chunk(k,v):
        return struct.pack(">I",len(v))+k+v+struct.pack(">I",zlib.crc32(k+v)&0xffffffff)
    raw=b"".join(b"\0"+bytes(pixels[y*w*4:(y+1)*w*4]) for y in range(h))
    path.write_bytes(b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",w,h,8,6,0,0,0))+
                     chunk(b"IDAT",zlib.compress(raw,9))+chunk(b"IEND",b""))

png(OUT/"palette.png",32,1,[v for c in colors for v in (*[round(255*(ch/255)**1.85) for ch in bytes.fromhex(c)],255)])
for name in ("ember","snow","spark"):
    pixels=[]
    for y in range(16):
        for x in range(16):
            dx,dy=x-7.5,y-7.5
            if name=="ember":
                radius=(6-abs(dy)*.48)*(1+dy*.06)
                col=(255,210 if abs(dx)<2 else 132,65,245 if abs(dx+.18*dy)<radius and y>1 else 0)
            else:
                on=abs(dx)<1 or abs(dy)<1 or (abs(abs(dx)-abs(dy))<1 and abs(dx)<4)
                col=(185,227,242,215 if on and abs(dx)+abs(dy)<8 else 0)
            pixels.extend(col)
    png(OUT/(name+".png"),16,16,pixels)

class Model:
    def __init__(self):
        self.verts=[]
        self.transform=None
    def face(self,points,c):
        if self.transform: points=[self.transform(*p) for p in points]
        a,b,d=points[:3]
        ab=[b[i]-a[i] for i in range(3)]
        ac=[d[i]-a[i] for i in range(3)]
        n=[ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0]]
        length=math.sqrt(sum(x*x for x in n)) or 1
        for i in range(1,len(points)-1):
            for p in (points[0],points[i],points[i+1]):
                self.verts.append((*p,*(v/length for v in n),(c+.5)/32,.5))
    def box(self,x,y,z,w,h,d,c):
        a,b=x-w/2,x+w/2
        l,u=y-h/2,y+h/2
        f,k=z-d/2,z+d/2
        v=[(a,l,f),(b,l,f),(b,u,f),(a,u,f),(a,l,k),(b,l,k),(b,u,k),(a,u,k)]
        for ids in ((3,2,1,0),(4,5,6,7),(0,4,7,3),(1,2,6,5),(3,7,6,2),(0,1,5,4)):
            self.face([v[i] for i in ids],c)
    def cone(self,x,y,z,r1,r2,h,c,n=10):
        low=[(x+r1*math.sin(i*2*math.pi/n),y,z+r1*math.cos(i*2*math.pi/n)) for i in range(n)]
        high=[(x+r2*math.sin(i*2*math.pi/n),y+h,z+r2*math.cos(i*2*math.pi/n)) for i in range(n)]
        for i in range(n):
            j=(i+1)%n
            self.face([low[i],low[j],high[j],high[i]],c)
        if r2: self.face(high,c)
        self.face(low[::-1],c)
    def beam(self,a,b,width,c):
        x,y,z=a; dx,dy,dz=[b[i]-a[i] for i in range(3)]
        mag=math.sqrt(dx*dx+dy*dy+dz*dz)
        if not mag: return
        dx,dy,dz=dx/mag,dy/mag,dz/mag
        ux,uy,uz=(1,0,0) if abs(dy)>.98 else (0,1,0)
        sx,sy,sz=dy*uz-dz*uy,dz*ux-dx*uz,dx*uy-dy*ux
        mag=math.sqrt(sx*sx+sy*sy+sz*sz)
        sx,sy,sz=sx/mag,sy/mag,sz/mag
        ux,uy,uz=sy*dz-sz*dy,sz*dx-sx*dz,sx*dy-sy*dx
        rings=[]
        for p in (a,b):
            rings.append([tuple(p[i]+width*.5*(u*(ux,uy,uz)[i]+v*(sx,sy,sz)[i]) for i in range(3))
                          for u,v in ((1,1),(1,-1),(-1,-1),(-1,1))])
        for i in range(4):
            j=(i+1)%4
            self.face([rings[0][i],rings[1][i],rings[1][j],rings[0][j]],c)
    def save(self,name):
        n=len(self.verts)
        data=b"".join(struct.pack("<8f",*v) for v in self.verts)
        doc={"asset":{"version":"2.0"},"buffers":[{"byteLength":len(data)}],
             "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":len(data),"byteStride":32}],
             "accessors":[{"bufferView":0,"byteOffset":offset,"componentType":5126,"count":n,"type":kind}
                          for offset,kind in ((0,"VEC3"),(12,"VEC3"),(24,"VEC2"))],
             "meshes":[{"primitives":[{"attributes":{"POSITION":0,"NORMAL":1,"TEXCOORD_0":2}}]}],
             "nodes":[{"mesh":0}],"scenes":[{"nodes":[0]}],"scene":0}
        desc=json.dumps(doc,separators=(",",":")).encode()
        desc+=b" "*(-len(desc)%4)
        (OUT/(name+".glb")).write_bytes(struct.pack("<4sII",b"glTF",2,28+len(desc)+len(data))+
          struct.pack("<I4s",len(desc),b"JSON")+desc+struct.pack("<I4s",len(data),b"BIN\0")+data)

digits=["111101101101111","010110010010111","111001111100111","111001111001111","101101111001001",
        "111100111001111","111100111101111","111001010010010","111101111101111","111101111001111"]
hall=Model()
b=hall.box
# Checkered stone, two woven aisles, and inlaid borders.
for i in range(16):
    for j in range(16):
        b(i*3-22.5,-.12,j*3-22.5,3,.22,3,1+((i+j)%2))
b(0,.012,0,5.6,.035,47.6,11); b(0,.035,0,47.6,.035,4.5,11)
for side in (-1,1):
    b(side*2.48,.042,0,.12,.03,47.6,15); b(0,.064,side*1.95,47.6,.03,.12,15)
for i in range(-10,11):
    b(0,.07,i*2.15,.22,.035,.22,16)
for wing,rotation in enumerate((90,0,-90,180)):
    angle=math.radians(rotation); cs,sn=round(math.cos(angle)),round(math.sin(angle))
    hall.transform=lambda x,y,z,c=cs,s=sn:(c*x+s*(z-24),y,-s*x+c*(z-24))
    color=(11,19,24,28)[wing]
    b(0,6.8,-.2,48,5,.65,color); b(0,8.9,.14,48,.3,.65,14)
    b(0,4.8,.15,48,.25,.55,8)
    for i in range(6):
        x=(i-2.5)*7; d=wing*6+i+1
        for side in (-1,1):
            b(x+side*2.49,2.2,0,2.1,4.4,.6,6)
            b(x+side*2.66,1.25,.32,1.15,1.65,.15,color)
            b(x+side*1.52,1.55,.36,.44,3.1,.55,8)
            b(x+side*1.52,.25,.38,.7,.5,.73,14)
        # Faceted arched lintel and a brass keystone.
        for j in range(8):
            t1=math.pi*j/8; t2=math.pi*(j+1)/8
            hall.beam((x+1.51*math.cos(t1),2.8+1.5*math.sin(t1),.42),
                      (x+1.51*math.cos(t2),2.8+1.5*math.sin(t2),.42),.40,8 if j%2 else 9)
        b(x,4.32,.49,.48,.5,.55,15)
        b(x,3.28,.22,1.37,.81,.17,10)
        for g,ch in enumerate(f"{d:02}"):
            for k,on in enumerate(digits[int(ch)]):
                if on=="1": b(x+(g*4+k%3-3)*.143,3.55-(k//3)*.133,.325,.134,.124,.06,16)
        # Snowy clerestory, mullions and garlands.
        b(x,6.43,.21,3.1,2.25,.14,23); b(x,6.43,.31,2.79,2.02,.1,25)
        b(x,6.43,.39,.12,2.05,.12,14); b(x,6.40,.39,2.85,.1,.12,14)
        for j in range(9):
            xx=x+(j-4)*.77; yy=5.08+.68*((j-4)/4)**2
            hall.cone(xx,yy-.22,.57,.41,.27,.44,18+j%3,6)
            if j%2: b(xx,yy-.27,.87,.18,.20,.18,(12,16)[j%3==0])
    for x in (-22.8,22.8):
        b(x,3.4,.3,.75,6.8,.85,7)
hall.transform=None
# Tall timber roof with trusses and hanging lanterns.
for side in (-1,1):
    for strip in range(24):
        inner=side*strip; outer=side*(strip+1)
        a=14.1-strip*.223; btm=a-.223
        quad=[(inner,a,-24),(outer,btm,-24),(outer,btm,24),(inner,a,24)]
        hall.face(quad if side==1 else quad[::-1],6 if strip%4 else 7)
    for z in (-24,24):
        tri=[(0,8.85,z),(side*24,8.85,z),(0,14.1,z)]
        hall.face(tri,6); hall.face(tri[::-1],6)
for z in (-20,-12,-4,4,12,20):
    for sign in (-1,1):
        hall.beam((sign*24,8.2,z),(0,13.8,z),.52,7)
        hall.beam((sign*17,8.2,z),(sign*10,11.4,z),.33,8)
    b(0,8.3,z,47.8,.32,.40,6)
for x in (-18,-10,0,10,18): b(x,13.6-abs(x)*.23,0,.4,.35,48,7)
for z in (-13,10):
    b(0,8.3,z,.10,3,.10,14); hall.cone(0,6.55,z,2.0,2.0,.14,15,12)
    for k in range(8):
        ang=math.pi*k/4; x,dz=1.95*math.cos(ang),1.95*math.sin(ang)
        b(x,6.9,z+dz,.18,.47,.18,5); b(x,7.18,z+dz,.13,.16,.13,16)
# Voxel spruce assembled on a square grid; alternating snow-capped boughs.
hall.cone(0,0,0,2.28,2.28,.39,14,16)
b(0,1,0,.78,2,.78,7)
for k in range(15):
    y=1+k*.40; rad=(15-k)*.205*(1 if k%3!=2 else .86)
    for ix in range(-7,8):
        for iz in range(-7,8):
            x,z=ix*.45,iz*.45
            if x*x+z*z<=rad*rad and (abs(x)+.44)**2+(abs(z)+.44)**2>=max(0,rad-.8)**2:
                b(x,y,z,.46,.44,.46,19+(ix+iz+k)%3)
                if (ix*7+iz*5+k)%5==0: b(x,y+.21,z,.45,.08,.45,27)
for k in range(46):
    y=1.2+5.1*k/46; radius=(7-y)*.54
    x,z=radius*math.cos(k*.59),radius*math.sin(k*.59)
    hall.cone(x,y,z,.12,.095,.17,(12,16,30,26)[k%4],6)
for side in (0,math.pi):
    star=[]
    for j in range(10):
        ang=math.pi/2+j*math.pi/5; rad=.67 if j%2==0 else .28
        star.append((math.cos(ang)*rad,7.37+math.sin(ang)*rad,.03*math.cos(side)))
    for j in range(10): hall.face([(0,7.37,.18*math.cos(side)),star[j],star[(j+1)%10]],16)
for k in range(13):
    a=k*2.4; x,z=2.45*math.cos(a),2.45*math.sin(a); size=.43+(k%3)*.15
    b(x,size/2,z,size,size,size,(11,19,24,28)[k%4]); b(x,size/2,z,size*.20,size+.04,size+.04,15)
# Hearth, workshop train, frosted conservatory and clock gallery.
for y in range(4):
    for z in range(5): b(-21.9,y*.36+.18,-2+z*.77+(.22 if y%2 else 0),.58,.33,.73,7+y%2)
b(-21.5,1.52,0,1.35,.22,4.7,9)
for i in range(4):
    b(-7+i*1.4,4.95,-22.8,1.24,.60,.72,(12,15,20,24)[i])
    for j in (-1,1): b(-7+i*1.4+j*.38,4.62,-22.4,.3,.28,.13,0)
for i in range(7): hall.cone(22.4,0,(i-3)*1.05,.5,0,1.4+(i%3)*.38,26,5)
hall.transform=lambda x,y,z:(-x,y,23.3-z)
hall.cone(0,5.8,0,1,1,.10,15)
for i in range(12):
    a=i*math.pi/6; b(math.sin(a)*.9,6.2+math.cos(a)*.9,.16,.12,.20,.1,16)
hall.beam((0,6.2,.22),(.52,6.6,.22),.10,5); hall.beam((0,6.2,.22),(-.15,6.91,.22),.08,5)
hall.transform=None
for x,y,z in ((-5,1.8,-14),(-2.6,2.45,-16),(0,1.85,-15),(2.6,2.45,-16),(5,1.8,-14)):
    b(x,.58,z,.19,1.16,.19,8); b(x,.09,z,.92,.16,.7,7)
hall.save("great-hall")

for kind in ("snowman","gingerbread","penguin","guard","wisp","friend"):
    m=Model(); b=m.box
    if kind=="snowman":
        m.cone(0,-.92,0,.52,.44,.75,27); m.cone(0,-.2,0,.40,.34,.54,31)
        m.cone(0,.32,0,.35,.28,.46,31); b(0,.82,0,.78,.12,.65,0); b(0,1.01,0,.57,.34,.50,1)
        b(0,.25,0,.78,.15,.69,12); b(.22,.02,.31,.20,.36,.13,12); b(0,.51,.37,.14,.14,.32,15)
    elif kind=="gingerbread":
        b(0,.0,0,.62,.83,.28,8); b(0,.59,0,.62,.52,.29,9); b(0,.33,.16,.61,.06,.04,5)
        for s in (-1,1):
            m.beam((s*.2,-.33,0),(s*.36,-.90,0),.24,8); m.beam((s*.30,.16,0),(s*.65,.34,0),.23,9)
        for y in (0,.16): b(0,y,.17,.1,.1,.05,12)
    elif kind=="penguin":
        m.cone(0,-.78,0,.41,.31,1.2,0); m.cone(0,.39,0,.35,.27,.40,0)
        b(0,-.14,.28,.48,.78,.16,5); b(0,.41,.38,.27,.12,.22,15)
        for s in (-1,1): b(s*.30,-.86,.13,.38,.16,.65,15); m.beam((s*.3,.15,0),(s*.58,-.40,0),.20,1)
    elif kind in ("guard","friend"):
        for s in (-1,1): b(s*.18,-.62,0,.24,.62,.29,1); b(s*.36,-.02,0,.19,.60,.24,12)
        b(0,.01,0,.55,.74,.37,11 if kind=="guard" else 20); b(0,.45,0,.43,.4,.39,9)
        b(0,.85,0,.54,.45,.50,1 if kind=="guard" else 20); b(0,.67,.03,.59,.10,.55,15)
        for j in range(3): b(0,j*.14,.21,.10,.08,.06,16)
    else:
        m.cone(0,-.58,0,.04,.46,.55,25,6); m.cone(0,-.03,0,.46,.20,.59,26,6)
        m.cone(0,.56,0,.20,0,.4,27,6)
        for s in (-1,1): m.beam((s*.23,.12,0),(s*.66,.5,0),.14,27)
    for s in (-1,1): b(s*.13,.54 if kind!="wisp" else .22,.32 if kind!="wisp" else .38,.09,.09,.075,0 if kind!="penguin" else 31)
    m.save(kind)

for i,name in enumerate(("pistol","fan","spinner","bank","rocket")):
    m=Model(); col=(12,20,25,28,11)[i]
    m.box(0,-.11,.06,.12,.21,.14,7); m.box(0,0,-.03,.22,.18,.39,col)
    count=(1,3,3,1,1)[i]
    for j in range(count):
        x=(j-(count-1)/2)*.105; width=.105 if count>1 else (.29 if i==4 else .15)
        m.box(x,.025,-.30,width,.14+i*.014,.41,col)
        m.box(x,.025,-.46,width+.034,.18+i*.014,.095,15)
        m.box(x,.025,-.514,width*.61,.09,.025,0)
    m.box(0,.109,-.02,.095,.040,.2,16)
    m.box(0,.104,.10,.20,.036,.065,14)
    m.box(0,.138,-.39,.034,.052,.045,17)
    m.box(0,-.13,.12,.15,.12,.17,19)
    for n in range(3): m.box(0,-.10+n*.036,.155,.17,.024,.10,20)
    m.save(name)
bell=Model(); bell.cone(0,-.36,0,.54,.27,.50,15); bell.cone(0,.14,0,.27,.13,.22,16)
bell.cone(0,-.48,0,.1,.12,.15,9); bell.save("bell")
orb=Model(); orb.cone(0,-.13,0,.05,.15,.11,26,8); orb.cone(0,-.02,0,.15,.06,.16,31,8); orb.save("snowball")

for name,freq in (("throw",480),("bell",784),("poof",185)):
    with wave.open(str(OUT/(name+".wav")),"wb") as f:
        f.setparams((1,2,22050,0,"NONE","not compressed"))
        frames=[]
        for i in range(11025):
            t=i/22050
            s=math.sin(2*math.pi*(freq*t+(0 if name=="bell" else -freq*.7*t*t)))
            overtone=math.sin(2*math.pi*freq*2.7*t)
            frames.append(struct.pack("<h",int(11500*(s+.25*overtone)*math.exp(-t*(8 if name=="bell" else 21)))))
        f.writeframes(b"".join(frames))
