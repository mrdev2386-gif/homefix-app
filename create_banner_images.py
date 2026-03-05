#!/usr/bin/env python3
"""Generate banner JPG images for HomeFix"""
import os
from PIL import Image, ImageDraw

os.makedirs('apps/customer_app/assets/banners', exist_ok=True)

banners = [
    ('ac_repair.jpg', 'AC Repair', '30% OFF', (6, 182, 212), (0, 150, 180)),
    ('cooler_fan.jpg', 'Cooler & Fan', 'Starting ₹199', (245, 158, 11), (217, 119, 6)),
    ('referral.jpg', 'Referral & Earn', 'Get ₹100', (34, 197, 94), (22, 163, 74)),
    ('deep_cleaning.jpg', 'Deep Cleaning', 'Flat 25% OFF', (236, 72, 153), (219, 39, 119)),
]

for filename, title, subtitle, c1, c2 in banners:
    img = Image.new('RGB', (1080, 480), c1)
    draw = ImageDraw.Draw(img)
    
    for y in range(480):
        r = int(c1[0] + (c2[0] - c1[0]) * y / 480)
        g = int(c1[1] + (c2[1] - c1[1]) * y / 480)
        b = int(c1[2] + (c2[2] - c1[2]) * y / 480)
        draw.line([(0, y), (1080, y)], fill=(r, g, b))
    
    overlay = Image.new('RGBA', (1080, 480), (0, 0, 0, 100))
    img = img.convert('RGBA')
    img = Image.alpha_composite(img, overlay)
    img = img.convert('RGB')
    
    path = f'apps/customer_app/assets/banners/{filename}'
    img.save(path, 'JPEG', quality=95)
    print(f'✓ {filename}')

print('Done!')
