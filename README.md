# Human-Rated AI

A cross-platform application built with [Skip](https://skip.tools) for rating and evaluating AI systems on both iOS and Android.

## Try It Out

You can test the iOS version of Human-Rated AI using TestFlight:

[![Download on TestFlight](https://developer.apple.com/assets/elements/icons/testflight/testflight-64x64.png)](https://testflight.apple.com/join/AXwUrXMY)

[Join the TestFlight Beta](https://testflight.apple.com/join/AXwUrXMY)

## Project Overview

Human-Rated AI allows users to:

- Browse and explore available AI bots and models
- Chat with AI bots using text or images
- Create custom AI bots with personalized configurations
- Rate AI bots based on user experience
- Save favorite AI bots for quick access
- Manage application settings and preferences

The application features Firebase authentication with Apple and Google sign-in methods to protect user-specific functionality.

## Architecture

This project follows a modern SwiftUI architecture that is transpiled to Android using Skip:

- **UI Layer**: TabView-based navigation with four main sections (AI, Create, Favorites, Settings)
- **Data Management**: Environment and Network managers for API communication
- **Authentication**: Firebase-based authentication with Apple ID and Google
- **Chat System**: Integration with AI models via a secure backend
- **Cross-Platform Support**: Conditional compilation to handle platform differences
- **Reactive State Management**: Using SwiftUI's state management translated to Kotlin

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

### Environment Configuration

The app requires proper environment configuration for API access:

1. Copy the `env.sample` file to a new file named `env` in the same directory: `Sources/HumanRatedAI/Resources/`
2. Update the values in the `env` file with your API keys and configuration

Example of the environment file format (from `env.sample`):

```
# AI Provider setting
AI_PROVIDER="openai"                         # AI Provider (openai or llama)

# Vision capability setting
AI_VISION_ENABLED="true"                     # Enable vision capabilities

# OpenAI settings
AI_KEY=""                    # Pre-md5 AI API Key
AI_MODEL=""                  # AI API Deployment Model
AI_URL=""                    # AI API URL

# OAuth Client ID for client type 3 (see google-services.json)
OAUTH_CLIENT_ID=""           # OAuth Client ID
```

Make sure to set the appropriate `AI_URL`, `AI_KEY`, and other values for your configuration.

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

## Debugging

- iOS logs: Available in the Xcode console
- Android logs: View in Android Studio's logcat tab
- Common issues can be fixed by cleaning build folders and restarting Xcode/Android Studio
- TestFlight builds may behave differently than debug builds - always test thoroughly on both platforms

## License

This software is free: you can redistribute and/or modify it under the terms of the GNU General Public License 3.0 as published by the Free Software Foundation https://fsf.org

[Social Login Buttons](https://www.figma.com/community/file/945702178038082375) are licensed by [Dakoda](https://www.figma.com/@dakoda) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).