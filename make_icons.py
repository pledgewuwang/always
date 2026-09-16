"""生成 AI Platform 的启动图标（5 档密度）。
深色底 + 紫色星芒，和平台暗色 UI 的 accent 对齐。
"""
from PIL import Image, ImageDraw
import os
import math

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "res")


def star(d, cx, cy, outer, inner, points=4, fill=(255, 255, 255, 255)):
    pts = []
    for i in range(points * 2):
        r = outer if i % 2 == 0 else inner
        ang = -math.pi / 2 + i * math.pi / points
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    d.polygon(pts, fill=fill)


def make(size, path):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = int(size * 0.23)
    # 深色圆角底
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=(16, 17, 24, 255))
    # 主色环
    d.rounded_rectangle([int(size * 0.06), int(size * 0.06), size - 1 - int(size * 0.06), size - 1 - int(size * 0.06)],
                        radius=int(size * 0.18), outline=(99, 102, 241, 255), width=max(2, int(size * 0.035)))
    cx = cy = size / 2.0
    star(d, cx, cy, size * 0.30, size * 0.105, 4, (235, 236, 255, 255))
    star(d, cx + size * 0.21, cy - size * 0.21, size * 0.11, size * 0.038, 4, (167, 139, 250, 255))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


for s, name in [(48, "mdpi"), (72, "hdpi"), (96, "xhdpi"), (144, "xxhdpi"), (192, "xxxhdpi")]:
    make(s, os.path.join(BASE, "mipmap-" + name, "ic_launcher.png"))
print("icons ok")
