#!/usr/bin/env python3
"""Generate banner images for HomeFix app"""
from PIL import Image, ImageDraw, ImageFont
import os

# Create directory
os.makedirs('apps/customer_app/assets/banners', exist_ok=True)

banners = [
    ('ac_repair.jpg', 'AC Repair', '30% OFF', (6, 182, 212), (0, 150, 180)),
    ('cooler_fan.jpg', 'Cooler & Fan', 'Starting ₹199', (245, 158, 11), (217, 119, 6)),
    ('referral.jpg', 'Referral & Earn', 'Get ₹100', (34, 197, 94), (22, 163, 74)),
    ('deep_cleaning.jpg', 'Deep Cleaning', 'Flat 25% OFF', (236, 72, 153), (219, 39, 119)),
]

for filename, title, subtitle, color1, color2 in banners:
    # Create image with gradient
    img = Image.new('RGB', (1080, 480), color1)
    draw = ImageDraw.Draw(img)
    
    # Draw gradient
    for y in range(480):
        r = int(color1[0] + (color2[0] - color1[0]) * y / 480)
        g = int(color1[1] + (color2[1] - color1[1]) * y / 480)
        b = int(color1[2] + (color2[2] - color1[2]) * y / 480)
        draw.line([(0, y), (1080, y)], fill=(r, g, b))
    
    # Add semi-transparent overlay
    overlay = Image.new('RGBA', (1080, 480), (0, 0, 0, 100))
    img = img.convert('RGBA')
    img = Image.alpha_composite(img, overlay)
    img = img.convert('RGB')
    draw = ImageDraw.Draw(img)
    
    # Add text
    try:
        font_title = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", 60)
        font_subtitle = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", 48)
    except:
        font_title = ImageFont.load_default()
        font_subtitle = ImageFont.load_default()
    
    draw.text((60, 120), title, fill=(255, 255, 255), font=font_title)
    draw.text((60, 200), subtitle, fill=(255, 255, 255), font=font_subtitle)
    
    # Save
    path = f'apps/customer_app/assets/banners/{filename}'
    img.save(path, 'JPEG', quality=95)
    print(f'✓ Created: {path}')

print('\n✓ All banners created!')
