"""
Генерирует иконки приложения и уведомлений из calculator_icon.png.
Запуск: python generate_icons.py
"""
from PIL import Image
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'calculator_icon.png')

# Android mipmap sizes: name -> (size, suffix)
ANDROID_MIPMAP = {
    'mdpi': (48, ''),
    'hdpi': (72, ''),
    'xhdpi': (96, ''),
    'xxhdpi': (144, ''),
    'xxxhdpi': (192, ''),
}

# iOS icon sizes from Contents.json
IOS_ICONS = [
    ('Icon-App-20x20@1x.png', 20),
    ('Icon-App-20x20@2x.png', 40),
    ('Icon-App-20x20@3x.png', 60),
    ('Icon-App-29x29@1x.png', 29),
    ('Icon-App-29x29@2x.png', 58),
    ('Icon-App-29x29@3x.png', 87),
    ('Icon-App-40x40@1x.png', 40),
    ('Icon-App-40x40@2x.png', 80),
    ('Icon-App-40x40@3x.png', 120),
    ('Icon-App-50x50@1x.png', 50),
    ('Icon-App-50x50@2x.png', 100),
    ('Icon-App-72x72@1x.png', 72),
    ('Icon-App-72x72@2x.png', 144),
    ('Icon-App-76x76@1x.png', 76),
    ('Icon-App-76x76@2x.png', 152),
    ('Icon-App-83.5x83.5@2x.png', 167),
    ('Icon-App-1024x1024@1x.png', 1024),
]

# Notification icon sizes (single color, no alpha for Android notification shade)
NOTIF_SIZES = {
    'drawable': (24, 'ic_notification.png'),
    'drawable-nodpi': (96, 'ic_notification.png'),
}

# macOS icon sizes
MACOS_ICONS = [
    ('app_icon_16.png', 16),
    ('app_icon_32.png', 32),
    ('app_icon_64.png', 64),
    ('app_icon_128.png', 128),
    ('app_icon_256.png', 256),
    ('app_icon_512.png', 512),
    ('app_icon_1024.png', 1024),
]

# Web icon sizes
WEB_ICONS = [
    ('web/icons/Icon-192.png', 192),
    ('web/icons/Icon-512.png', 512),
    ('web/icons/Icon-maskable-192.png', 192),
    ('web/icons/Icon-maskable-512.png', 512),
    ('web/favicon.png', 32),
]

def make_icon(src_img, size, mask=True):
    img = src_img.copy()
    img = img.resize((size, size), Image.LANCZOS)
    if mask and img.mode == 'RGBA':
        # Apply rounded-rect mask (iOS-style squircle)
        mask = Image.new('L', (size, size), 0)
        from PIL import ImageDraw
        draw = ImageDraw.Draw(mask)
        radius = int(size * 0.22)
        draw.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
        img.putalpha(mask)
    return img

def make_notification_icon(src_img, size):
    """Notification icon: white silhouette on transparent (Android requirement)."""
    img = src_img.copy().convert('RGBA')
    img = img.resize((size, size), Image.LANCZOS)
    # Convert to grayscale mask, then make white with alpha
    gray = img.convert('L')
    # Threshold: keep shapes, make background transparent
    data = list(gray.getdata())
    alpha = [255 if v > 30 else 0 for v in data]
    white = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    white.putalpha(Image.new('L', (size, size)))
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    pixels = result.load()
    for i in range(size * size):
        x, y = i % size, i // size
        if alpha[i] > 0:
            pixels[x, y] = (255, 255, 255, alpha[i])
    return result

def main():
    src = Image.open(SRC).convert('RGBA')
    print(f'Source: {SRC} ({src.width}x{src.height})')

    # Android mipmap
    for name, (size, _) in ANDROID_MIPMAP.items():
        d = os.path.join(ROOT, 'android/app/src/main/res/mipmap-' + name)
        icon = make_icon(src, size)
        icon.save(os.path.join(d, 'ic_launcher.png'))
        print(f'  mipmap-{name}/ic_launcher.png ({size}x{size})')

    # Android notification
    for dirname, (size, fname) in NOTIF_SIZES.items():
        d = os.path.join(ROOT, 'android/app/src/main/res/' + dirname)
        icon = make_notification_icon(src, size)
        icon.save(os.path.join(d, fname))
        print(f'  {dirname}/{fname} ({size}x{size})')

    # Android play store
    play = make_icon(src, 512)
    play.save(os.path.join(ROOT, 'android/app/src/main/ic_launcher-playstore.png'))
    print('  ic_launcher-playstore.png (512x512)')

    # iOS
    ios_dir = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    for fname, size in IOS_ICONS:
        icon = make_icon(src, size)
        icon.save(os.path.join(ios_dir, fname))
        print(f'  iOS {fname} ({size}x{size})')

    # macOS
    macos_dir = os.path.join(ROOT, 'macos/Runner/Assets.xcassets/AppIcon.appiconset')
    for fname, size in MACOS_ICONS:
        icon = make_icon(src, size)
        icon.save(os.path.join(macos_dir, fname))
        print(f'  macOS {fname} ({size}x{size})')

    # Web
    for rel_path, size in WEB_ICONS:
        icon = make_icon(src, size)
        full = os.path.join(ROOT, rel_path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        icon.save(full)
        print(f'  {rel_path} ({size}x{size})')

    # assets/icon/app_icon.png (1024x1024)
    src.save(os.path.join(ROOT, 'assets/icon/app_icon.png'))
    print('  assets/icon/app_icon.png (1024x1024)')

    print('\nDone — all icons generated from calculator_icon.png')

if __name__ == '__main__':
    main()
