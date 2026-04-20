# Font Setup Guide for Rupee Symbol (₹) Support in PDF

## Problem
The app generates invoices with the Rupee symbol (₹), but it requires a font that supports this Unicode character.

## Solution

### Step 1: Add NotoSans Font to Assets

1. **Download the font:**
   - Download "NotoSans-Regular.ttf" from Google Fonts:
     - https://fonts.google.com/noto/specimen/Noto+Sans
   - Or download from this direct link:
     - https://github.com/google/fonts/raw/main/ofl/notosans/NotoSans-Regular.ttf

2. **Create fonts directory (if not exists):**
   ```
   assets/
   └── fonts/
       └── NotoSans-Regular.ttf
   ```

3. **Place the font file:**
   - Copy the downloaded TTF file to: `assets/fonts/NotoSans-Regular.ttf`

### Step 2: Update pubspec.yaml

The pubspec.yaml already has the fonts asset configured:
```yaml
flutter:
  assets:
    - assets/fonts/
```

If you want to register the font for UI use as well, add this:
```yaml
fonts:
  - family: NotoSans
    fonts:
      - asset: assets/fonts/NotoSans-Regular.ttf
```

### Step 3: Verify Installation

1. Run `flutter clean`
2. Run `flutter pub get`
3. Create an invoice and download the PDF
4. The rupee symbol (₹) should now display correctly

## Technical Details

### PDF Generation
- The app uses the `pdf` package to generate invoices
- Custom fonts are loaded from assets using: `rootBundle.load("assets/fonts/NotoSans-Regular.ttf")`
- The font is applied to all text in the PDF: `pw.Text("₹500", style: pw.TextStyle(font: ttf))`

### Fallback Mechanism
- If the font file is missing, the app automatically falls back to `pw.Font.helvetica()`
- While Helvetica doesn't display the rupee symbol perfectly, it prevents PDF generation errors
- **Recommendation:** Always use NotoSans for proper rupee symbol display

## Troubleshooting

### Rupee symbol shows as "?" or doesn't display
1. Verify the font file exists at `assets/fonts/NotoSans-Regular.ttf`
2. Run `flutter clean && flutter pub get`
3. Check for file path errors in the console
4. Make sure the TTF file is valid (not corrupted)

### "Font not found" error
1. Check that `assets/fonts/` directory exists
2. Verify `pubspec.yaml` has the assets configuration
3. Run `flutter pub get` to refresh assets

### PDF download fails
1. Check app console for specific error messages
2. Ensure sufficient storage space on device
3. Try on a different device if possible

## Testing Checklist

- [ ] Font file exists at `assets/fonts/NotoSans-Regular.ttf`
- [ ] `pubspec.yaml` has assets configuration
- [ ] `flutter clean && flutter pub get` executed
- [ ] App compiles without errors
- [ ] Invoice creation works without errors
- [ ] PDF download completes successfully
- [ ] Rupee symbol (₹) displays correctly in PDF

## Additional Resources

- Google Fonts NotoSans: https://fonts.google.com/noto/specimen/Noto+Sans
- Flutter PDF Package: https://pub.dev/packages/pdf
- Flutter Assets Guide: https://flutter.dev/docs/development/ui/assets-and-images
