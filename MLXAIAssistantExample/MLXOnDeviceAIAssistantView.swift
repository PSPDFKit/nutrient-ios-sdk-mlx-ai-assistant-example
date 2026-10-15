//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Combine
import Foundation
import FoundationModels
import MLXFoundationModels
import MLXLLM // Registers MLX model architectures with the loader.
import MLXLMCommon
import Observation
import PSPDFKit
import PSPDFKitUI
import SwiftUI

/// Displays the sample document and its on-device AI Assistant.
struct MLXOnDeviceAIAssistantView: View {
    @State private var assistant = MLXAssistantLoader()
    @State private var showingAssistant = true

    private let pdfActionEventPublisher = PassthroughSubject<PDFView.ActionEvent, Never>()

    var body: some View {
        PDFView(document: assistant.document, actionEventPublisher: pdfActionEventPublisher)
            .inspector(isPresented: $showingAssistant) {
                assistantContent
                    .navigationTitle("AI Assistant")
                    .presentationDetents([.large])
                    .inspectorColumnWidth(min: 320, ideal: 480, max: 900)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAssistant.toggle()
                    } label: {
                        Label("Toggle AI Assistant", systemImage: "sparkles")
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .onAppear(perform: assistant.start)
            .onDisappear(perform: assistant.tearDown)
    }

    @ViewBuilder
    private var assistantContent: some View {
        switch assistant.phase {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("Downloading and loading Qwen 3 4B…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .ready(let session):
            AIAssistantView(session: session)
                .onDocumentNavigationAction { _, pageIndex, rects in
                    pdfActionEventPublisher.send(.setPageIndexWithHighlights(pageIndex, rects))
                }

        case .failed(let message):
            ContentUnavailableView {
                Label("Model Unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again", action: assistant.retry)
            }
        }
    }
}

@MainActor
@Observable
private final class MLXAssistantLoader {
    enum Phase {
        case loading
        case ready(AIAssistantSession)
        case failed(String)
    }

    private static let modelID = "mlx-community/Qwen3-4B-Instruct-2507-4bit"
    private static let revision = "50d427756c6b1b2fe0c0a10f67fbda1fc8e82c1b"
    private static let contextWindow = 8_192

    private(set) var phase = Phase.loading

    let document: PSPDFKit.Document

    private var languageModel: MLXLanguageModel?
    private var loadTask: Task<Void, Never>?

    init() {
        let documentURL = Bundle.main.url(forResource: "Resource Depletion", withExtension: "pdf")!
        document = Document(url: documentURL)
    }

    func start() {
        guard loadTask == nil, case .loading = phase else { return }
        loadTask = Task { @MainActor in
            await loadModel()
        }
    }

    func retry() {
        guard case .failed = phase else { return }
        loadTask = nil
        phase = .loading
        start()
    }

    func tearDown() {
        if case .ready(let session) = phase {
            session.terminate()
        }
        let loadTask = loadTask
        loadTask?.cancel()
        self.loadTask = nil

        phase = .loading

        let languageModel = languageModel
        self.languageModel = nil
        Task {
            if let loadTask {
                await loadTask.value
            }
            if let languageModel {
                await languageModel.evict()
            }
        }
    }

    private func loadModel() async {
        #if targetEnvironment(simulator)
        phase = .failed("MLX requires a physical device or Apple silicon Mac.")
        #else
        let languageModel = Self.makeLanguageModel()

        do {
            try await languageModel.preload()
            try Task.checkCancellation()

            let model = AIAssistantModel.custom(
                languageModel,
                identifier: "\(Self.modelID)@\(Self.revision):8k",
                contextWindow: Self.contextWindow
            )
            let configuration = AIAssistantModelConfiguration(
                sessionID: "mlx-on-device-ai-assistant-example",
                model: model,
                storesConversationHistory: false
            )
            let session = try AIAssistantSession(
                document: document,
                configuration: configuration
            )
            try Task.checkCancellation()
            self.languageModel = languageModel
            phase = .ready(session)
        } catch is CancellationError {
            await languageModel.evict()
        } catch {
            await languageModel.evict()
            if Task.isCancelled == false {
                phase = .failed(error.localizedDescription)
            }
        }
        #endif
    }

    #if !targetEnvironment(simulator)
    private static func makeLanguageModel() -> MLXLanguageModel {
        makeHuggingFaceLanguageModel(
            configuration: ModelConfiguration(id: modelID, revision: revision),
            capabilities: [.guidedGeneration],
            configurationResolver: QwenModelConfigurationResolver()
        )
    }
    #endif
}

private struct QwenModelConfigurationResolver: ModelConfigurationResolver {
    func resolve(
        _ configuration: ModelConfiguration,
        for _: ModelDescriptor
    ) -> ModelConfiguration {
        var configuration = configuration
        configuration.reasoningConfig = nil
        return configuration
    }
}
