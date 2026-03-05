#!/usr/bin/env python3
from PIL import Image
import os

os.makedirs('apps/customer_app/assets/banners', exist_ok=True)

banners = [
    ('ac_repair.jpg', (6, 182, 212), (0, 150, 180)),
    ('cooler_fan.jpg', (245, 158, 11), (217, 119, 6)),
    ('referral.jpg', (34, 197, 94), (22, 163, 74)),
    ('deep_cleaning.jpg', (236, 72, 153), (219, 39, 119)),
]

for name, c1, c2 in banners:
    img = Image.new('RGB', (1080, 480), c1)
    pixels = img.load()
    for y in range(480):
        r = int(c1[0] + (c2[0] - c1[0]) * y / 480)
        g = int(c1[1] + (c2[1] - c1[1]) * y / 480)
        b = int(c1[2] + (c2[2] - c1[2]) * y / 480)
        for x in range(1080):
            pixels[x, y] = (r, g, b)
    img.save(f'apps/customer_app/assets/banners/{name}', 'JPEG', quality=95)
    print(f'✓ {name}')
