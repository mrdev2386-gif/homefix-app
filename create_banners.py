#!/usr/bin/env python3
"""
Banner Image Generator for HomeFix
Creates 4 banner images with gradients and text overlays
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Create banners directory if it doesn't exist
os.makedirs('apps/customer_app/assets/banners', exist_ok=True)

# Banner configurations
banners = [
    {
        'filename': 'apps/customer_app/assets/banners/ac_repair.jpg',
        'title': 'AC Repair',
        'subtitle': '30% OFF',
        'colors': [(6, 182, 212), (0, 150, 180)]  # Cyan gradient
    },
    {
        'filename': 'apps/customer_app/assets/banners/cooler_fan.jpg',
        'title': 'Cooler & Fan',
        'subtitle': 'Starting ₹199',
        'colors': [(245, 158, 11), (217, 119, 6)]  # Amber gradient
    },
    {
        'filename': 'apps/customer_app/assets/banners/referral.jpg',
        'title': 'Referral & Earn',
        'subtitle': 'Get ₹100',
        'colors': [(34, 197, 94), (22, 163, 74)]  # Green gradient
    },
    {
        'filename': 'apps/customer_app/assets/banners/deep_cleaning.jpg',
        'title': 'Deep Cleaning',
        'subtitle': 'Flat 25% OFF',
        'colors': [(236, 72, 153), (219, 39, 119)]  # Pink gradient
    }
]

def create_banner(filename, title, subtitle, colors):
    """Create a banner image with gradient and text"""
    width, height = 1080, 480
    
    # Create image with gradient
    img = Image.new('RGB', (width, height), colors[0])
    draw = ImageDraw.Draw(img)
    
    # Draw gradient
    for y in range(height):
        r = int(colors[0][0] + (colors[1][0] - colors[0][0]) * y / height)
        g = int(colors[0][1] + (colors[1][1] - colors[0][1]) * y / height)
        b = int(colors[0][2] + (colors[1][2] - colors[0][2]) * y / height)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    
    # Add semi-transparent overlay
    overlay = Image.new('RGBA', (width, height), (0, 0, 0, 100))
    img = img.convert('RGBA')
    img = Image.alpha_composite(img, overlay)
    img = img.convert('RGB')
    draw = ImageDraw.Draw(img)
    
    # Add text
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 60)
        subtitle_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 48)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    # Draw title
    draw.text((60, 120), title, fill=(255, 255, 255), font=title_font)
    
    # Draw subtitle
    draw.text((60, 200), subtitle, fill=(255, 255, 255), font=subtitle_font)
    
    # Save image
    img.save(filename, 'JPEG', quality=95)
    print(f"✓ Created: {filename}")

# Generate all banners
for banner in banners:
    create_banner(
        banner['filename'],
        banner['title'],
        banner['subtitle'],
        banner['colors']
    )

print("\n✓ All banner images created successfully!")
