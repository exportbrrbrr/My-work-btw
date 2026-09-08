# Medicine Reminder App — On-Device Architecture

A Flutter app for Android & iOS that is **100% local-first**: no backend
server, no custom API, no Firebase/Supabase, no cloud ML calls. Every
photo, schedule, and verification code lives in the app's own sandboxed
storage on the phone.

## How the pieces fit together

```
lib/
├── main.dart                      # app entry + bottom-nav shell (main/calendar/setting)
├── models/
│   ├── medicine.dart / .g.dart    # Hive object: one medicine record
│   └── dose_log.dart / .g.dart    # Hive object: one scheduled dose occurrence
├── services/
│   ├── storage_service.dart       # all Hive reads/writes — the only persistence code
│   ├── vision_service.dart        # on-device pill photo -> cropped pill image
│   ├── label_ocr_service.dart     # on-device label photo -> Medicine draft
│   ├── barcode_service.dart       # decode + verify QR/barcode payloads
│   └── notification_service.dart # local alarm scheduling (flutter_local_notifications)
├── screens/                       # one file per screen in your screenshots
└── widgets/
    ├── draggable_pill.dart        # Draggable pill icon
    └── time_slot_target.dart      # DragTarget bucket (เช้า/กลางวัน/เย็น)
```

### Data flow for the two "add medicine" paths

1. **Manual** (`manual_add_screen.dart`): user fills name / type / quantity
   / time period / end date, optionally snaps a photo. The photo goes
   through `VisionService.extractPill()` (on-device object-detection
   bounding box + local crop — no upload) before being shown as the
   pill's icon. The cropped pill can also be **dragged** onto a
   เช้า/กลางวัน/เย็น bucket via `pill_sort_screen.dart` instead of using
   the dropdown, per the drag-and-drop requirement.
2. **Photo / label scan** (`photo_scan_screen.dart`): user photographs
   the printed label; `LabelOcrService` runs ML Kit text recognition
   on-device and heuristically extracts name/type/quantity/time slots,
   skipping the manual form entirely and writing straight into storage
   + today's `DoseLog` entries (which is what the calendar tab reads).

### Scan-to-dismiss anti-cheat

- When a medicine is first saved, `BarcodeRegisterScreen` asks the user
  to scan the QR/barcode stuck on the physical bottle once, storing the
  payload in `Medicine.verificationCode`.
- `NotificationService` schedules a **local, exact, repeating** alarm
  per time slot using `flutter_local_notifications` + `timezone`, with
  `fullScreenIntent: true` on Android so the alarm can open
  `ReminderAlarmScreen` even over the lock screen.
- On the alarm screen, tapping "กินแล้ว ✓" does **not** mark the dose
  taken — it opens the live camera (`mobile_scanner`). Only a scan whose
  payload matches the stored `verificationCode` calls
  `StorageService.markTaken()`, ending on the green-check "บันทึกเรียบร้อย"
  confirmation screen from your screenshot. A mismatch loops back to
  scanning instead of silently succeeding.

## Required packages (see `pubspec.yaml`)

| Purpose | Package | Notes |
|---|---|---|
| Local NoSQL storage | `hive`, `hive_flutter` | boxes live under `getApplicationDocumentsDirectory()` |
| File paths | `path_provider` | |
| Camera capture | `camera`, `image_picker` | |
| Local image crop | `image` | pure Dart, no native/cloud dependency |
| Pill extraction | `google_mlkit_object_detection` | on-device bounding box; see note below |
| Label OCR | `google_mlkit_text_recognition` | on-device text recognition |
| Barcode/QR | `mobile_scanner` | live scanning UI, on-device decode |
| Local alarms | `flutter_local_notifications`, `timezone` | no push service involved |
| State/util | `provider`, `uuid`, `intl` | |

**On segmentation vs. cropping:** true pixel-level "cut the pill out of
the background" (ML Kit Subject/Selfie Segmentation) currently only
ships a *selfie* segmenter in the Flutter ML Kit plugins. `VisionService`
instead uses the on-device Object Detector's bounding box and crops with
the `image` package — same "no cloud" guarantee, simpler dependency. If
you later bundle a custom TFLite segmentation model, only
`VisionService.extractPill()` needs to change; every screen that calls
it is unaffected.

## Platform setup you'll need to add

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>ใช้กล้องเพื่อถ่ายรูปยาและสแกนบาร์โค้ดยืนยันการกินยา</string>
```
Note: iOS cannot force a full-screen UI from a notification the way
Android's `fullScreenIntent` can — the user must tap the notification to
open `ReminderAlarmScreen`. This is an OS-level restriction, not a gap
in this codebase.

## Regenerating Hive adapters

`medicine.g.dart` and `dose_log.g.dart` are included hand-written (matching
exactly what `build_runner` would output) so the project is complete
without a build step. If you add/remove/reorder `@HiveField`s, regenerate
with:
```
flutter pub run build_runner build --delete-conflicting-outputs
```

## Running it

```
flutter pub get
flutter run
```

No API keys, `.env` files, or account sign-up required anywhere in this
project — that's the point.
