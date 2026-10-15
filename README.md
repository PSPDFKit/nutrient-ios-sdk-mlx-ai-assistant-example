# Nutrient iOS SDK — MLX AI Assistant Example

This SwiftUI app uses the [Nutrient iOS SDK](https://www.nutrient.io/sdk/ios) AI Assistant with a custom Qwen 3 4B model running on-device through MLX. It opens a sample PDF, answers questions about the document, and navigates to cited passages.

## Requirements

- Xcode 27 or later.
- A physical iPhone or iPad running iOS or iPadOS 27 or later, or an Apple silicon Mac running macOS 27 or later using Mac Catalyst.
- At least 8 GB of memory. MLX inference is not supported in the iOS Simulator.
- An internet connection and approximately 2.2 GB of available storage for the initial model download. Model weights are cached for subsequent launches.
- A Nutrient iOS SDK license that includes the on-device AI Assistant and matches the app's bundle identifier.

The example uses `mlx-community/Qwen3-4B-Instruct-2507-4bit` at a pinned revision with an 8,192-token context window. Document processing and inference run on-device.

## Getting started

1. Clone this repository and open `MLXAIAssistantExample.xcodeproj`.
2. Let Xcode resolve the Swift packages. When prompted, review and select **Trust & Enable** for the MLX package's build plugin and any package macros. This is a one-time setup for the resolved package versions on your Mac; updated versions may require approval again.
3. In `MLXAIAssistantExampleApp.swift`, replace the license placeholder with a key from [My Nutrient](https://my.nutrient.io/).
4. Select the `MLXAIAssistantExample` target, set your development team, and use a bundle identifier covered by your license.
5. Select a supported physical device or **My Mac (Mac Catalyst)**, then build and run the `MLXAIAssistantExample` scheme.
6. Wait for Qwen to download and load, then ask a question about the sample document in the AI Assistant. Select a citation to navigate to its source on the page.

## Additional resources

- [Nutrient iOS SDK guides](https://www.nutrient.io/guides/ios/)
- [Nutrient iOS SDK API reference](https://www.nutrient.io/api/ios/)
- [Nutrient technical support](https://www.nutrient.io/support/request/)

## License

The sample code is licensed under a [modified BSD license](LICENSE). See [third-party acknowledgements](MLXAIAssistantExample/ACKNOWLEDGEMENTS.md) for the dependencies' licenses.
