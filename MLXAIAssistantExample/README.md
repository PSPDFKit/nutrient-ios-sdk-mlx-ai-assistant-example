# MLX AI Assistant Example

A standalone SwiftUI app that uses the Nutrient on-device AI Assistant with Qwen 3 4B through MLX. The example opens `Resource Depletion.pdf` and displays the document alongside the AI Assistant.

## Run from the monorepo

1. Open `iOS/PSPDFKit.xcworkspace` and select the `MLXAIAssistantExample` scheme in Xcode 27 or later. The workspace builds and links the local `PSPDFKit.framework` and `PSPDFKitUI.framework`.
2. Let Xcode resolve the Swift packages, then review and select **Trust & Enable** for the MLX build plugin and any package macros when prompted. Trust applies to the resolved versions on your Mac; updated versions may require approval again.
3. Replace the license placeholder in `MLXAIAssistantExampleApp.swift` with a license from [My Nutrient](https://my.nutrient.io/) that includes the on-device AI Assistant. Set your development team and a bundle identifier covered by that license in the target's signing settings.
4. Build and run on a physical device with iOS or iPadOS 27 or later and at least 8 GB of memory, or on an Apple silicon Mac with macOS 27 or later using Mac Catalyst. The iOS Simulator can build the app but cannot run MLX inference.
5. Allow approximately 2.2 GB of storage and an internet connection for the first model download. Once downloaded, the model weights are cached. Ask a question about the sample PDF and select a citation to navigate to its source.

## Public distribution

The release process generates a standalone project that uses `PSPDFKit-SP` in place of the workspace frameworks and publishes it to [the public example repository](https://github.com/PSPDFKit/nutrient-ios-sdk-mlx-ai-assistant-example). The MLX package dependencies and bundled sample are preserved. This example is distributed through GitHub and is excluded from the SDK DMG.

The sample code uses a [modified BSD license](LICENSE.md). See [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md) for third-party notices.
