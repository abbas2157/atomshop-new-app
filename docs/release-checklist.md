# Android release checklist

Short list. Most of it is automated; the parts that are not are the parts that
have bitten us.

## Before the build

1. Bump the build number in `pubspec.yaml`. The active line is the Android one;
   the iOS line stays commented.
2. If you changed `android/app/src/main/AndroidManifest.xml`, re-read
   [Permissions and the Data Safety form](#permissions-and-the-data-safety-form)
   below before going further.

## Build

```bash
flutter build appbundle --release
```

`tool/verify_release_bundle.py` runs automatically at the end and fails the
build if anything is wrong. It checks the manifest *inside the finished
bundle*, not the source file, because the manifest merger and the
`tools:node="remove"` rules decide what actually ships.

What it checks, and why each one is there:

| Check | Why |
|---|---|
| Advertising ID permissions present | Lost once before, restored in 457c67d. Play zeroes the advertising ID without them and Meta attribution silently dies. |
| Media permissions still absent | `image_picker` pulls them in transitively. Letting them through widens the Data Safety declaration for no benefit. |
| Version matches `pubspec.yaml` | Stops a stale bundle being uploaded as if it were the new one. |
| Signed with the upload key | A bundle signed with anything else cannot be accepted by Play. |

Expected values live in `tool/release_checks.json`. Change them only when a
requirement genuinely changes, and say why in the commit message.

To run it by hand against any bundle:

```bash
python3 tool/verify_release_bundle.py path/to/app-release.aab
```

## Upload

1. Upload the bundle from `build/app/outputs/bundle/release/app-release.aab`.
2. Roll it out to **every** track that currently has an active artifact, not
   just production. See [Track hygiene](#track-hygiene).
3. Confirm the Data Safety form still matches the manifest.

## Permissions and the Data Safety form

The Play Console declaration and the manifest are one unit. Change one, review
the other in the same release.

The app declares that it uses an advertising ID, because the Meta SDK collects
one for attribution. That declaration requires
`com.google.android.gms.permission.AD_ID` in the manifest. If the two disagree
Play warns that the advertising identifier will be zeroed out, which breaks
attribution and analytics without any crash or error to notice.

Do not resolve a mismatch by editing the Data Safety form to say the app does
not use an advertising ID. That silences the warning and breaks attribution,
which is the exact bug the manifest comment warns about.

## Track hygiene

Play evaluates **every active artifact on every track**, not just the newest
production release. An old build left active on an internal or closed testing
track will keep triggering warnings long after production is fixed, and
uploading a new bundle to production alone will not clear them.

After each release, open **Test and release → App bundle explorer** and check
which artifacts are still active. Retire tracks you no longer use instead of
leaving stale builds on them.

This is what caused the September 2026 advertising ID warning. The source
manifest had been correct since May.

## Not covered by the gate

- `flutter build apk` output. The gate reads bundles only, since that is what
  goes to Play. A sideloaded APK for device testing is not checked.
- Anything in App Store Connect. This checklist is Android only.
