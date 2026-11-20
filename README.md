# VideoHub Pro — Flutter starter

A single Flutter codebase intended for Android and iOS.

## Included in this starter
- Material 3 interface
- Home, Explore, Downloads, Library, and Settings tabs
- Light and dark appearance
- Three selectable light styles: Classic, Minimal, and Ocean
- Local persistence for theme preferences

## Build an Android APK with GitHub Actions
1. Upload the contents of this ZIP to the root of your GitHub repository.
2. Open the repository's Actions tab.
3. Select **Build VideoHub Pro Android APK** and run the workflow.
4. When the run succeeds, download the **VideoHub-Pro-debug-APK** artifact.

## Development status
This is an initial UI and build foundation, not a finished downloader. The download queue, five-task limit, default two simultaneous downloads, server-supported resume, network preference, and device media scanning still need to be implemented and tested.

Use official platform playback/download mechanisms. Support only content the user owns or is authorized to download; do not bypass DRM, login requirements, paywalls, or platform restrictions.

The included workflow builds Android APKs on GitHub Actions. iOS builds require an Apple-supported macOS/Xcode environment and the required signing setup.
