# AI Content Machine

Create better content faster.

## What This Project Is

`AI Content Machine` is a native SwiftUI iPhone app built as a local-first creator operating system MVP. It includes:

- onboarding with persistent creator preferences
- dashboard with daily prompt, suggested idea, pipeline metrics, and recent projects
- content generation for single ideas, 10-idea batches, and full content packages
- local mock AI generation by default, with an optional real provider scaffold
- saved library with search, filter, sort, favorites, and statuses
- reusable templates
- local planner with weekly assignments and posting streak
- settings for profile defaults, theme, AI mode, export, sample data import, and onboarding reset
- basic XCTest coverage for generator formatting, score logic, planner logic, and language/tone switching

## Requirements

- Xcode 26.4 or newer in this environment
- iOS Simulator SDK installed
- for real device installs: an Apple ID signed into Xcode and a valid Personal Team or Developer account for code signing

## Open In Xcode

1. Open [AIContentMachine.xcodeproj](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine.xcodeproj) in Xcode.
2. Select the `AIContentMachine` scheme.
3. Choose an iPhone simulator or a connected physical iPhone.

The repository also includes [project.yml](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/project.yml), which was used to generate the checked-in Xcode project.

## Run On Simulator

1. Open the project in Xcode.
2. Select an iPhone simulator such as iPhone 16 Pro.
3. Press `Cmd+R`.

The app works offline by default using `MockContentGenerationService`, so no backend or API key is required for the core experience.

## Run On A Physical iPhone

1. Connect your iPhone to the Mac.
2. Open the project in Xcode.
3. Select your iPhone as the run destination.
4. In the target signing settings, choose your team if Xcode prompts for signing.
5. Press `Cmd+R`.

If this is your first device install from Xcode, you may need to trust your developer certificate on the iPhone after installation.

## Offline Default Behavior

Offline mode is the default and fully functional:

- all onboarding and settings persist locally with SwiftData
- all generated projects, planner assignments, favorites, and statuses persist locally
- content generation works immediately through deterministic local prompt logic
- export and sharing work without a backend

## Optional Real AI Mode

The app includes an optional scaffolded `RealAIContentService`.

To enable it:

1. Launch the app.
2. Open `Settings`.
3. Set `Provider mode` to `Custom Endpoint`.
4. Paste your API key into the `API key` field.
5. Paste your endpoint URL into the `Endpoint URL` field.
6. Set the `Model ID` value if your endpoint expects one.
7. Save settings.

Notes:

- the real provider path expects the endpoint to return JSON compatible with the app’s `GeneratedContent` schema
- if decoding fails or the endpoint is invalid, the app surfaces a user-facing error and offline mock mode remains available immediately
- the API key is entered in-app via `Settings > AI Provider`

## Test

Run tests in Xcode with `Cmd+U`, or from Terminal:

```bash
xcodebuild -project AIContentMachine.xcodeproj -scheme AIContentMachine -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

If that specific simulator name is not installed on your machine, choose any available iPhone simulator in Xcode or adjust the command accordingly.

## Project Structure

- [AIContentMachine/AIContentMachineApp.swift](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/AIContentMachineApp.swift)
- [AIContentMachine/Models](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/Models)
- [AIContentMachine/ViewModels](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/ViewModels)
- [AIContentMachine/Views](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/Views)
- [AIContentMachine/Components](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/Components)
- [AIContentMachine/Services](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/Services)
- [AIContentMachine/Persistence](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/Persistence)
- [AIContentMachine/Utilities](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/Utilities)
- [AIContentMachine/Tests](/Users/abeba272rr/Desktop/AbebaIT/XCodeApps/AIContentMachine/Tests)
