//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import SwiftUI

/// Demonstrates the on-device AI Assistant with an MLX language model.
@main
struct MLXAIAssistantExampleApp: App {
    init() {
        // Set your license key before calling any other Nutrient API.
        // Each license is bound to an app bundle ID.
        // Visit https://my.nutrient.io/ to get a demo or commercial license key.
        SDK.setLicenseKey("YOUR_LICENSE_KEY_GOES_HERE")
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ExampleContentView()
                    .navigationTitle("MLX AI Assistant")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

private struct ExampleContentView: View {
    var body: some View {
        #if targetEnvironment(simulator)
        ContentUnavailableView(
            "Requires a Physical Device",
            systemImage: "iphone",
            description: Text("MLX requires a physical device or Apple silicon Mac because the simulator has no supported GPU.")
        )
        #elseif targetEnvironment(macCatalyst) && !arch(arm64)
        ContentUnavailableView(
            "Requires Apple Silicon",
            systemImage: "desktopcomputer",
            description: Text("This example requires an Apple silicon Mac or a physical iOS device with at least 8 GB of memory.")
        )
        #else
        // Devices with 8 GB of memory can report less than 8 GiB, so use a 7 GiB cutoff.
        if ProcessInfo.processInfo.physicalMemory >= 7 * 1_024 * 1_024 * 1_024 {
            MLXOnDeviceAIAssistantView()
        } else {
            ContentUnavailableView(
                "Requires 8 GB of Memory",
                systemImage: "memorychip",
                description: Text("This model requires a device or Apple silicon Mac with at least 8 GB of memory.")
            )
        }
        #endif
    }
}
