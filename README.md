    # Human-Rated AI

A cross-platform application built with [Skip](https://skip.tools) for rating and evaluating AI systems on both iOS and Android.

## Project Overview

Human-Rated AI allows users to:

- Browse and explore available AI bots and agents
- Create custom AI bots with personalized configurations
- Save favorite AI bots for quick access
- Manage application settings and preferences

The application features Firebase authentication with Apple and Google sign-in methods to protect user-specific functionality.

## Architecture

This project follows a modern SwiftUI architecture that is transpiled to Android using Skip:

- **UI Layer**: TabView-based navigation with four main sections (AI, Create, Favorites, Settings)
- **Data Management**: Environment and Network managers for API communication
- **Authentication**: Firebase-based authentication for secure access to user features
- **Cross-Platform Support**: Conditional compilation to handle platform differences

## Building

This project is both a stand-alone Swift Package Manager module and an Xcode project that builds and transpiles the code into a Kotlin Gradle project for Android using the Skip plugin.

### Prerequisites

Building requires Skip to be installed using [Homebrew](https://brew.sh):

```bash
brew install skiptools/skip/skip
```

This installs the necessary transpiler prerequisites:
- Kotlin
- Gradle
- Android build tools

Installation can be verified by running:

```bash
skip checkup
```

### Firebase Configuration

The app uses Firebase for authentication:

1. Create a project on the [Firebase Console](https://console.firebase.google.com/)
2. Register your iOS app and download the GoogleService-Info.plist to Darwin/ folder
3. Register your Android app and download the google-services.json to Android/app/ folder
4. Configure the Apple and Google sign-in methods in the Firebase console
5. Add the proper URL schemes in your project configuration

## Testing

The module can be tested using:

- Swift tests: `swift test` command
- Xcode tests: Run the test target for macOS in Xcode
- Parity tests: `skip test` to compare results across platforms

## Running

To run the application:

1. Ensure both Xcode and Android Studio are installed
2. Launch an Android emulator from Android Studio's Device Manager
3. Open the project in Xcode and run the HumanRatedAIApp target
4. A build script will automatically deploy to the Android emulator

### Debugging

- iOS logs: Available in the Xcode console
- Android logs: View in Android Studio's logcat tab

## License

This software is free: you can redistribute and/or modify it under the terms of the GNU General Public License 3.0 as published by the Free Software Foundation https://fsf.org

[Social Login Buttons](https://www.figma.com/community/file/945702178038082375) are licensed by [Dakoda](https://www.figma.com/@dakoda) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).