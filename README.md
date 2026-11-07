# VideoHub Pro — Android starter project

This is the first Android UI project for VideoHub Pro. It includes:
- Home, Explore, Downloads, Library and Settings navigation
- Light and Dark appearance
- Three Light styles: Classic, Minimal and Ocean
- A GitHub Actions workflow to build and upload a debug APK

## Build on GitHub using an Android phone
1. Create a **new** GitHub repository named `videohub-pro-android` (do not overwrite the website repository).
2. Upload the contents of this ZIP to the repository root, preserving folders.
3. Open the **Actions** tab and enable workflows if GitHub asks.
4. Run **Build VideoHub Pro APK** using **Run workflow**, or push a commit to `main`.
5. When the workflow finishes, open its run and download the `videohub-pro-debug-apk` artifact.

## Current scope
This is the initial UI/build foundation, not a finished downloader. The download screen is currently an interface placeholder. Actual download support must be implemented and tested only for direct files/content that the user owns or is authorized to download, using permitted source mechanisms. It does not scrape social platforms or bypass DRM, paywalls, login controls, or platform restrictions.

The app currently keeps theme selection in memory for the running session; persistent preferences and local media indexing are planned for the next implementation stage.
