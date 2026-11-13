from PIL import Image, ImageDraw
from pathlib import Path

OUT = Path(__file__).parent
for size in (120, 152, 167, 180, 1024):
    im = Image.new("RGB", (size, size), (224, 35, 52))
    d = ImageDraw.Draw(im)
    m = int(size * .17)
    # Ticket body
    d.rounded_rectangle((m, int(size*.27), size-m, int(size*.73)), radius=int(size*.09), fill="white")
    # Perforated center line
    x = size // 2
    dash = max(2, int(size*.018))
    y = int(size*.34)
    while y < int(size*.66):
        d.rounded_rectangle((x-dash, y, x+dash, y+int(size*.025)), radius=dash, fill=(224,35,52))
        y += int(size*.055)
    # Bold DP monogram
    try:
        from PIL import ImageFont
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(size*.16))
        d.text((size*.5, size*.5), "DP", font=font, fill=(224,35,52), anchor="mm")
    except Exception:
        d.ellipse((size*.42,size*.42,size*.58,size*.58), fill=(224,35,52))
    im.save(OUT / f"AppIcon-{size}.png", optimize=True)
