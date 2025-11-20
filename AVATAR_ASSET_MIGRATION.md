# Avatar Image Asset Migration

## Summary
Successfully migrated avatar storage from device filesystem to Flutter assets folder (`/omic_topup_app/assets/images/avatars`).

## Changes Made

### 1. **UserRepository** (`lib/repositories/user_repository.dart`)
- ✅ Updated `uploadUserAvatar()` to store asset paths in database (format: `assets/images/avatars/avatar_{userId}_{hash}.{ext}`)
- ✅ Added `getAvatarAssetPath()` - retrieves asset paths from database
- ✅ Added `getAvatarImageProvider()` - returns `AssetImage` for use in Flutter widgets
- ✅ Deprecated `getAvatarFile()` - replaced with asset-based approach
- ✅ Simplified `deleteUserAvatar()` - only clears database entry (no filesystem operations)
- ✅ Removed filesystem operations - no more `getApplicationDocumentsDirectory()` usage

### 2. **ProfileScreen** (`lib/screens/profile_screen.dart`)
- ✅ Updated `_loadExistingAvatar()` - simplified to just set loading state (no file I/O needed)
- ✅ Updated `_buildAvatarWidget()` - now uses `AssetImage` for existing avatars from assets folder
- ✅ Removed `_currentAvatarFile` field - no longer needed
- ✅ Maintains priority: newly selected image (FileImage) → existing avatar asset (AssetImage) → placeholder

### 3. **AppDrawer** (`lib/widgets/app_drawer.dart`)
- ✅ Simplified avatar display - removed `FutureBuilder` complexity
- ✅ Updated `_buildAvatarImage()` - now displays asset images directly
- ✅ Removed unused imports (`dart:io`, `UserRepository`)
- ✅ Instant avatar rendering without async operations

### 4. **pubspec.yaml** (Already configured)
- ✅ `assets/images/avatars/` is already registered as an asset directory

## Benefits

| Aspect | Before | After |
|--------|--------|-------|
| **Storage** | Device filesystem | Flutter assets |
| **Portability** | ❌ Device-specific paths | ✅ Portable asset paths |
| **Performance** | ❌ Async file I/O | ✅ Instant asset loading |
| **Simplicity** | ❌ Complex FileImage logic | ✅ Simple AssetImage |
| **Bundling** | ❌ Separate file management | ✅ Packaged with APK/IPA |
| **Distribution** | ❌ Manual avatar management | ✅ Built-in to app release |

## File Structure
```
omic_topup_app/
├── assets/images/avatars/
│   ├── avatar_ADM001_f46ddbc5.webp
│   ├── avatar_CUST002_a1b2c3d4.png
│   └── ...
├── lib/
│   ├── repositories/
│   │   └── user_repository.dart ✨ Updated
│   ├── screens/
│   │   └── profile_screen.dart ✨ Updated
│   ├── widgets/
│   │   └── app_drawer.dart ✨ Updated
│   └── ...
└── pubspec.yaml (assets/images/avatars/ already configured)
```

## Database Storage Format
Avatar paths are now stored as:
```
assets/images/avatars/avatar_{userId}_{timestamp_hash}.{extension}
```

Example:
```
assets/images/avatars/avatar_ADM001_f46ddbc5.webp
```

## Migration Steps for Existing Avatars

1. **Copy existing avatar files** from device storage to `/assets/images/avatars/`
2. **Update database** - rename photo_path entries to start with `assets/`
3. **Test with new upload** - verify new avatars are created as assets

## Usage Examples

### Displaying Avatar in Widget
```dart
// Get asset path
final assetPath = await userRepo.getAvatarAssetPath(user.avatar);
if (assetPath != null) {
  Image.asset(assetPath);
}

// Or use ImageProvider directly
final imageProvider = await userRepo.getAvatarImageProvider(user.avatar);
CircleAvatar(backgroundImage: imageProvider);
```

### Uploading New Avatar
```dart
final photoPath = await userRepo.uploadUserAvatar(selectedFile, userId);
// Returns: "assets/images/avatars/avatar_ADM001_abc12345.webp"
```

## Notes
- All avatar images must be placed in `/omic_topup_app/assets/images/avatars/`
- Assets are automatically packaged with app builds
- No additional permissions needed (unlike filesystem access)
- Supported formats: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`
