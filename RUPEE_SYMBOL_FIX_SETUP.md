# Rupee Symbol (₹) Fix for PDF Invoices

## Problem
The Rupee symbol (₹) was not displaying correctly in generated PDF invoices because the default PDF fonts don't include Unicode support for the Rupee symbol.

## Solution Implemented
The code has been updated to load and use **NotoSans-Regular.ttf**, a Unicode-compliant font that properly supports the Rupee symbol and other special characters.

## Setup Instructions

### 1. Download the Font File

Download **NotoSans-Regular.ttf** from Google Fonts:
- **Google Fonts**: https://fonts.google.com/noto/specimen/Noto+Sans
- Direct Download: https://github.com/notofonts/noto-fonts/raw/main/fonts/NotoSans-Regular.ttf

### 2. Place Font in Project

1. Navigate to your project root directory
2. Go to: `assets/fonts/`
3. Place the downloaded **NotoSans-Regular.ttf** file in this directory

Your project structure should look like:
```
gst-billing-main/
├── assets/
│   └── fonts/
│       └── NotoSans-Regular.ttf
├── lib/
├── pubspec.yaml
└── ...
```

### 3. Verify Setup

- ✅ `pubspec.yaml` already updated with assets configuration
- ✅ `lib/utils/invoice_pdf_helper.dart` already updated to load font
- ✅ All Rupee symbols in PDF now use the Unicode font

### 4. Test PDF Generation

1. Run your Flutter app
2. Create a new invoice or open an existing one
3. Generate the PDF invoice
4. Verify that the Rupee symbol (₹) displays correctly

## Files Modified

1. **pubspec.yaml**
   - Added `assets:` section with `- assets/fonts/`

2. **lib/utils/invoice_pdf_helper.dart**
   - Added import: `import 'package:flutter/services.dart' show rootBundle;`
   - Loads font: `final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");`
   - Creates pw.Font: `final ttf = pw.Font.ttf(fontData);`
   - Applied font to all text styles: `style: pw.TextStyle(font: ttf, ...)`

## Expected Results

✅ Rupee symbol (₹) displays correctly in PDF invoices  
✅ No missing or garbled characters  
✅ Clean and professional invoice PDFs  
✅ Support for international characters if needed in future  

## Troubleshooting

### "File not found: assets/fonts/NotoSans-Regular.ttf"
- Ensure you've downloaded the font file
- Place it exactly at: `assets/fonts/NotoSans-Regular.ttf`
- Run `flutter pub get` to refresh assets

### PDF still showing missing character
- Clear build cache: `flutter clean`
- Rebuild the app: `flutter pub get && flutter run`
- Verify the font file is readable (not corrupted)

### Slow PDF generation
- NotoSans-Regular.ttf is ~560KB, this is normal
- First load caches the font in memory, subsequent PDFs generate faster

## References

- **PDF Package**: https://pub.dev/packages/pdf
- **NotoSans Font**: https://fonts.google.com/noto/specimen/Noto+Sans
- **Unicode Support**: The font includes comprehensive Unicode support for 150+ languages
