"""生成 1024x1024 的 App 图标：纯黑底 + 一勾淡月。

用法：python tools/make_icon.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = (
    Path(__file__).resolve().parent.parent
    / "Sources"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
    / "AppIcon-1024.png"
)

# 纯黑底，加一层极淡的晕，免得大屏上一块死黑
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
glow = Image.new("L", (SIZE, SIZE), 0)
ImageDraw.Draw(glow).ellipse([40, 40, SIZE - 40, SIZE - 40], fill=30)
glow = glow.filter(ImageFilter.GaussianBlur(200))
img = Image.composite(Image.new("RGB", (SIZE, SIZE), (28, 28, 32)), img, glow)

# 月牙 = 大圆减去一个偏右上的圆
mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
md.ellipse([238, 250, 762, 774], fill=255)
md.ellipse([400, 196, 924, 720], fill=0)
mask = mask.filter(ImageFilter.GaussianBlur(2))

img = Image.composite(Image.new("RGB", (SIZE, SIZE), (224, 224, 228)), img, mask)
img = img.convert("RGB")
img.save(OUT, "PNG", optimize=True)
print("wrote", OUT, img.size)
