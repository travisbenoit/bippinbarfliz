# App Icons and Splash Screen Setup

This guide explains how to set up app icons and splash screens for Barfliz.

## Prerequisites

1. Install ImageMagick or use an online SVG-to-PNG converter
2. Have Flutter SDK installed

## Step 1: Convert SVG to PNG

The SVG source files are located in `assets/icons/`:

- `app_icon.svg` - Main app icon (convert to 1024x1024 PNG)
- `app_icon_foreground.svg` - Android adaptive icon foreground (convert to 1024x1024 PNG)
- `splash_logo.svg` - Splash screen logo (convert to 512x512 PNG)
- `splash_branding.svg` - Splash screen branding text (convert to 400x80 PNG)

### Using ImageMagick:

```bash
cd flutter_app/assets/icons

# Convert main app icon
convert -density 300 -resize 1024x1024 app_icon.svg app_icon.png

# Convert foreground for adaptive icons
convert -density 300 -resize 1024x1024 -background none app_icon_foreground.svg app_icon_foreground.png

# Convert splash logo
convert -density 300 -resize 512x512 -background none splash_logo.svg splash_logo.png

# Convert branding
convert -density 300 -resize 400x80 -background none splash_branding.svg splash_branding.png
```

### Using Online Tools:

1. Go to https://cloudconvert.com/svg-to-png
2. Upload each SVG file
3. Set the output size as specified above
4. Download the PNG files to `assets/icons/`

## Step 2: Generate App Icons

After creating the PNG files, run:

```bash
cd flutter_app
flutter pub get
dart run flutter_launcher_icons
```

This will generate all required icon sizes for:
- Android (regular and adaptive icons)
- iOS
- Web
- Windows
- macOS

## Step 3: Generate Splash Screen

Run:

```bash
dart run flutter_native_splash:create
```

This will generate splash screens for:
- Android (including Android 12+ splash)
- iOS
- Web

## Icon Specifications

| Platform | Size | File |
|----------|------|------|
| iOS App Store | 1024x1024 | app_icon.png |
| Android Play Store | 512x512 | app_icon.png |
| Android Adaptive Foreground | 432x432 (safe zone) | app_icon_foreground.png |
| Splash Logo | 512x512 | splash_logo.png |
| Splash Branding | 400x80 | splash_branding.png |

## Color Palette

- Primary: #E91E63 (Pink)
- Primary Dark: #B0003A
- Secondary: #FF6B6B (Coral)
- Accent: #FFB74D (Orange/Amber)

## Quick PNG Generation Script

Save this as `generate_icons.sh` in the flutter_app folder:

```bash
#!/bin/bash

# Requires ImageMagick
cd assets/icons

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "ImageMagick not found. Install with: brew install imagemagick"
    exit 1
fi

echo "Converting SVG files to PNG..."

convert -density 300 -resize 1024x1024 app_icon.svg app_icon.png
convert -density 300 -resize 1024x1024 -background none app_icon_foreground.svg app_icon_foreground.png
convert -density 300 -resize 512x512 -background none splash_logo.svg splash_logo.png
convert -density 300 -resize 400x80 -background none splash_branding.svg splash_branding.png

echo "PNG files generated!"
echo ""
echo "Now run:"
echo "  flutter pub get"
echo "  dart run flutter_launcher_icons"
echo "  dart run flutter_native_splash:create"
```

## Troubleshooting

### Icons not showing on Android
- Clean and rebuild: `flutter clean && flutter pub get && flutter run`
- Make sure adaptive icon background color matches brand (#E91E63)

### Splash screen issues on iOS
- Check that the images don't have transparency issues
- Run `flutter clean` and rebuild

### Web icons not updating
- Clear browser cache
- Check that `web/icons/` folder was generated
