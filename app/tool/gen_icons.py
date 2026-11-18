# Sinh icon iOS/Android từ ảnh xuất Figma (Brand/App Icon 82:2418–82:2423).
# Dùng: python3 tool/gen_icons.py . (chạy trong thư mục app/; cần Pillow). Ảnh nguồn ở assets/icon/.
import json, os, sys
from PIL import Image

app = sys.argv[1]
src = os.path.join(app, 'assets/icon')
bg = Image.open(f'{src}/app_icon_android_background.png').convert('RGBA')
print('background corners/centre:', {bg.getpixel(p) for p in [(0,0),(431,431),(216,216)]})

# iOS: icon không được có alpha (App Store từ chối) → dán lên nền lime đặc.
ios = Image.open(f'{src}/app_icon_ios.png').convert('RGBA')
flat = Image.new('RGB', ios.size, ios.getpixel((0, 0))[:3])
flat.paste(ios, mask=ios.split()[3])
iconset = os.path.join(app, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
for img in json.load(open(f'{iconset}/Contents.json'))['images']:
    w = float(img['size'].split('x')[0]) * int(img['scale'][0])
    flat.resize((round(w), round(w)), Image.LANCZOS).save(f"{iconset}/{img['filename']}")

# Android: adaptive (foreground + monochrome 108dp) và icon cũ 48dp ghép sẵn.
res = os.path.join(app, 'android/app/src/main/res')
fg = Image.open(f'{src}/app_icon_android_foreground.png').convert('RGBA')
mono = Image.open(f'{src}/app_icon_android_monochrome.png').convert('RGBA')
legacy = bg.copy(); legacy.alpha_composite(fg)
for d, k in {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}.items():
    os.makedirs(f'{res}/mipmap-{d}', exist_ok=True)
    fg.resize((round(108 * k),) * 2, Image.LANCZOS).save(f'{res}/mipmap-{d}/ic_launcher_foreground.png')
    mono.resize((round(108 * k),) * 2, Image.LANCZOS).save(f'{res}/mipmap-{d}/ic_launcher_monochrome.png')
    # Icon cũ: vùng 72/108 ở giữa của lớp ghép, thu về 48dp.
    crop = legacy.crop((72, 72, 360, 360))
    crop.resize((round(48 * k),) * 2, Image.LANCZOS).save(f'{res}/mipmap-{d}/ic_launcher.png')
print('ok')
