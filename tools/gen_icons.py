"""Regenerate SkyRing's icon atlases only.

Normal VS Code builds use the bundled icons and need no extra software.
Optional: install Python Pillow and Inkscape, then run py tools/gen_icons.py.
All watch-face TEXT is rendered with Garmin's native vector fonts at runtime.
"""
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "resources", "fonts") + "/"
SS = 4
metrics = {}

def pack(glyphs, pad=1, maxw=256):
    x=y=rowh=0
    placed=[]
    for g in glyphs:
        w,h=g['img'].size
        if x+w+pad>maxw:
            x=0; y+=rowh+pad; rowh=0
        placed.append((x,y)); x+=w+pad; rowh=max(rowh,h)
    H=y+rowh
    Hp=1
    while Hp<H: Hp*=2
    return placed, maxw, max(Hp,8)

def write_fnt(name, face, size, lineh, base, glyphs):
    placed,W,H=pack(glyphs)
    atlas=Image.new('RGBA',(W,H),(255,255,255,0))
    lines=[f'info face="{face}" size={size} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1 outline=0',
           f'common lineHeight={lineh} base={base} scaleW={W} scaleH={H} pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4',
           f'page id=0 file="{name}.png"', f'chars count={len(glyphs)}']
    for g,(px,py) in zip(glyphs,placed):
        a=g['img']
        if a.size[0]>0 and a.size[1]>0:
            rgba=Image.merge('RGBA',[Image.new('L',a.size,255)]*3+[a])
            atlas.paste(rgba,(px,py))
        lines.append(f"char id={g['id']} x={px} y={py} width={a.size[0]} height={a.size[1]} xoffset={g['xo']} yoffset={g['yo']} xadvance={g['adv']} page=0 chnl=15")
    atlas.save(OUT+name+".png")
    open(OUT+name+".fnt","w").write("\n".join(lines)+"\n")
def find_inkscape():
    found = shutil.which("inkscape")
    if found:
        return found
    # Common Windows install location (no shell invocation or PATH changes).
    for env in ("ProgramFiles", "ProgramFiles(x86)"):
        root = os.environ.get(env)
        if root:
            candidate = Path(root) / "Inkscape" / "bin" / "inkscape.exe"
            if candidate.is_file():
                return str(candidate)
    raise SystemExit("Inkscape is required only to regenerate icons; normal builds use the bundled atlases.")


def svg_icon(body, px, sw):
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{px}" height="{px}" viewBox="0 0 24 24"><g fill="none" stroke="#fff" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>'
    with tempfile.TemporaryDirectory(prefix="skyring-icon-") as temp:
        source = Path(temp) / "icon.svg"
        target = Path(temp) / "icon.png"
        source.write_text(svg, encoding="utf-8")
        subprocess.run([INKSCAPE, str(source), "--export-type=png",
                        "--export-area-page", f"--export-width={px * SS}",
                        f"--export-height={px * SS}",
                        f"--export-filename={target}"],
                       check=True, stdout=subprocess.DEVNULL,
                       stderr=subprocess.PIPE)
        with Image.open(target) as im:
            return im.convert("RGBA").getchannel("A").reduce(SS)

ICONS20={
 '?' : '<circle cx="12" cy="12" r="8.5"/><path d="M9.5 9a2.5 2.5 0 0 1 5 0c0 2-2.5 2-2.5 4M12 16v.1"/>',
 'H':'<path d="M12 20.2s-7.6-4.5-7.6-10.2A4.3 4.3 0 0 1 12 7.3a4.3 4.3 0 0 1 7.6 2.7c0 5.7-7.6 10.2-7.6 10.2z"/>',
 'V':'<path d="M2 13h4l2-5 3.5 11L14 6l2 7h6"/>',
 'S':'<path d="M7.5 3.5c-1.9 0-3 2.2-3 4.8 0 2.1 1 3.5 3 3.5s3-1.4 3-3.5c0-2.6-1.1-4.8-3-4.8zM5.5 15.2c0 1.5.9 2.3 2 2.3s2-.8 2-2.3M16.5 6.5c-1.9 0-3 2.2-3 4.8 0 2.1 1 3.5 3 3.5s3-1.4 3-3.5c0-2.6-1.1-4.8-3-4.8zM14.5 18.2c0 1.5.9 2.3 2 2.3s2-.8 2-2.3"/>',
 'I':'<path d="M5 6.5l5.5 5.5L5 17.5M12.5 6.5l5.5 5.5-5.5 5.5"/>',
 'K':'<path d="M12 3c.8 3.3 5.2 5.6 5.2 10.2a5.2 5.2 0 0 1-10.4 0c0-2.6 1.4-4.2 2.6-5.3.2 1.9 1.1 3 2.5 3.4C11.2 8.8 12.2 6.2 12 3z"/>',
 'F':'<path d="M3 20h5v-5h5v-5h5V5h3"/>',
 'R':'<circle cx="12" cy="13.5" r="7.5"/><path d="M12 9.8v3.9l2.6 1.8M9.5 3h5M12 3v2.5"/>',
 'T':'<rect x="2.5" y="7.5" width="17" height="10" rx="2"/><path d="M22 11v3"/>',
 'D':'<path d="M12 3.5c3.2 4.2 5.6 7.2 5.6 10.4a5.6 5.6 0 0 1-11.2 0C6.4 10.7 8.8 7.7 12 3.5z"/>',
 'M':'<path d="M2.5 19.5 9.2 8.5l4.3 7 2.3-3.3 5.7 7.3z"/>',
 'P':'<path d="M10 14.5V5a2 2 0 0 1 4 0v9.5a4 4 0 1 1-4 0z"/>',
 'c':'<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8"/>',
 'n':'<path d="M19.5 14.5A8 8 0 1 1 9.5 4.5a6.5 6.5 0 0 0 10 10z"/>',
 'p':'<path d="M8 2.5v1.5M2.5 8H4M4.1 4.1l1 1M11.9 4.1l-1 1M5.6 10.4A3.2 3.2 0 1 1 10.9 7"/><path d="M9.5 20h8a3.5 3.5 0 0 0 .4-7 4.8 4.8 0 0 0-9.1 1.1A3 3 0 0 0 9.5 20z"/>',
 'q':'<path d="M12 8.5A5.5 5.5 0 1 1 6.5 2.5a4.5 4.5 0 0 0 5.5 6z"/><path d="M9.5 20h8a3.5 3.5 0 0 0 .4-7 4.8 4.8 0 0 0-9.1 1.1A3 3 0 0 0 9.5 20z"/>',
 'C':'<path d="M7.2 18.5h9.6a4.2 4.2 0 0 0 .5-8.4 5.6 5.6 0 0 0-10.7 1.3 3.6 3.6 0 0 0 .6 7.1z"/>',
 'r':'<path d="M7.2 14.5h9.6a4.2 4.2 0 0 0 .5-8.4 5.6 5.6 0 0 0-10.7 1.3 3.6 3.6 0 0 0 .6 7.1zM9 17.5l-1 3M13 17.5l-1 3M17 17.5l-1 3"/>',
 's':'<path d="M7.2 14.5h9.6a4.2 4.2 0 0 0 .5-8.4 5.6 5.6 0 0 0-10.7 1.3 3.6 3.6 0 0 0 .6 7.1z"/><path d="M9 18.5v.1M13 20.5v.1M17 18.5v.1" stroke-width="2.6"/>',
 't':'<path d="M7.2 14.5h9.6a4.2 4.2 0 0 0 .5-8.4 5.6 5.6 0 0 0-10.7 1.3 3.6 3.6 0 0 0 .6 7.1zM12.5 15.5l-2 3.2h3l-2 3.3"/>',
 'f':'<path d="M4 8h16M6 12h12M4 16h16M7 20h10"/>',
 'w':'<path d="M3 9h11a3 3 0 1 0-3-3M3 15h15a3 3 0 1 1-3 3M3 12h7"/>',
 'u':'<path d="M3 12.5a9 9 0 0 1 18 0zM12 12.5v6a2 2 0 0 1-4 0"/>',
 'X':'<path d="M3.5 16a8.5 8.5 0 0 1 17 0"/><path d="M12 16l4.6-5.6"/><circle cx="12" cy="16" r="1.3"/>',
}
ICONS14={
 # Lunar horizon events: a lavender crescent and a separately coloured arrow.
 'l':'<path d="M12.5 16a6.5 6.5 0 1 1-6-10.5A5 5 0 0 0 12.5 16z"/>',
 'j':'<path d="M18.5 17V6M16 8.5 18.5 6 21 8.5"/>',
 'k':'<path d="M18.5 6v11M16 14.5l2.5 2.5 2.5-2.5"/>',
 # Two-layer sunrise/set artwork: coloured arrow/horizon, yellow sun arc.
 'a':'<path d="M4 18h16M12 3.5v6M9.5 6l2.5-2.5L14.5 6"/>',
 'z':'<path d="M4 18h16M12 3.5v6M9.5 7l2.5 2.5L14.5 7"/>',
 'o':'<path d="M7.5 18a4.5 4.5 0 0 1 9 0"/>',
 'A':'<path d="M4 18h16M7.5 18a4.5 4.5 0 0 1 9 0M12 3.5v6M9.5 6l2.5-2.5L14.5 6"/>',
 'Z':'<path d="M4 18h16M7.5 18a4.5 4.5 0 0 1 9 0M12 3.5v6M9.5 7l2.5 2.5L14.5 7"/>',
 'U':'<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8"/>',
 'W':'<path d="M19.5 12a7.5 7.5 0 1 1-2.2-5.3M19.5 4v4h-4"/>',
 'P':'<path d="M3 19h18M5 19a7 7 0 0 1 14 0"/><circle cx="12" cy="6.5" r="2.6"/>',
 'L':'<path d="M4 19h16M4 19 17 7"/><path d="M11 19a7 7 0 0 0-2-4.9"/>',
 'm':'<path d="M2.5 19.5 9.2 8.5l4.3 7 2.3-3.3 5.7 7.3z"/>',
}
def icon_font(name, icons, px, sw):
    glyphs=[]
    for ch,body in icons.items():
        glyphs.append(dict(id=ord(ch),img=svg_icon(body,px,sw),xo=0,yo=0,adv=px))
    write_fnt(name,"SkyRingIcons",px,px,px,glyphs)
    metrics[name]=px

def main():
    global INKSCAPE
    INKSCAPE = find_inkscape()
    os.makedirs(OUT, exist_ok=True)
    icon_font("icons22", ICONS20, 26, 1.7)
    icon_font("icons16", ICONS14, 20, 2.0)
    xml = ['<fonts>',
           '    <!-- Text uses Garmin native vector fonts; only icon glyphs are bundled. -->',
           '    <font id="F_icons22" filename="icons22.fnt" antialias="true" />',
           '    <font id="F_icons16" filename="icons16.fnt" antialias="true" />',
           '</fonts>']
    Path(OUT, "fonts.xml").write_text("\n".join(xml) + "\n", encoding="utf-8")
    print("Regenerated icons22 and icons16. Text uses native Garmin fonts.")

if __name__ == "__main__":
    main()
