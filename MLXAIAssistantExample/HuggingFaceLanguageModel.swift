//
//  Copyright © 2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import FoundationModels
import HuggingFace
import MLXFoundationModels
import MLXLMCommon
import Tokenizers

/// Creates an MLX language model using Hugging Face for model downloads and tokenization.
func makeHuggingFaceLanguageModel(
    configuration: ModelConfiguration,
    capabilities: [LanguageModelCapabilities.Capability] = [.guidedGeneration],
    configurationResolver: any ModelConfigurationResolver = DefaultConfigurationResolver()
) -> MLXLanguageModel {
    MLXLanguageModel(
        configuration: configuration,
        capabilities: capabilities,
        configurationResolver: configurationResolver,
        weightsLocation: { id in
            let cache = HubCache.default
            guard let repository = Repo.ID(rawValue: id) else {
                return cache.cacheDirectory
            }
            if let commit = cache.resolveRevision(repo: repository, kind: .model, ref: "main"),
               let snapshot = try? cache.snapshotPath(repo: repository, kind: .model, commitHash: commit) {
                return snapshot
            }
            return cache.repoDirectory(repo: repository, kind: .model)
        },
        load: { configuration, progressHandler in
            try await loadModelContainer(
                from: HuggingFaceDownloader(HubClient()),
                using: HuggingFaceTokenizerLoader(),
                configuration: configuration,
                progressHandler: progressHandler
            )
        }
    )
}

private struct HuggingFaceDownloader: MLXLMCommon.Downloader {
    private let client: HubClient

    init(_ client: HubClient) {
        self.client = client
    }

    func download(
        id: String,
        revision: String?,
        matching patterns: [String],
        useLatest: Bool,
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws -> URL {
        guard let repositoryID = Repo.ID(rawValue: id) else {
            throw HuggingFaceError.invalidRepositoryID(id)
        }

        return try await client.downloadSnapshot(
            of: repositoryID,
            revision: revision ?? "main",
            matching: patterns,
            progressHandler: { @MainActor progress in
                progressHandler(progress)
            }
        )
    }
}

private struct HuggingFaceTokenizerLoader: TokenizerLoader {
    func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        let tokenizer = try await AutoTokenizer.from(modelFolder: directory)
        return HuggingFaceTokenizer(tokenizer)
    }
}

private struct HuggingFaceTokenizer: MLXLMCommon.Tokenizer {
    private let tokenizer: any Tokenizers.Tokenizer

    init(_ tokenizer: any Tokenizers.Tokenizer) {
        self.tokenizer = tokenizer
    }

    func encode(text: String, addSpecialTokens: Bool) -> [Int] {
        tokenizer.encode(text: text, addSpecialTokens: addSpecialTokens)
    }

    func decode(tokenIds: [Int], skipSpecialTokens: Bool) -> String {
        tokenizer.decode(tokens: tokenIds, skipSpecialTokens: skipSpecialTokens)
    }

    func convertTokenToId(_ token: String) -> Int? {
        tokenizer.convertTokenToId(token)
    }

    func convertIdToToken(_ id: Int) -> String? {
        tokenizer.convertIdToToken(id)
    }

    var bosToken: String? { tokenizer.bosToken }
    var eosToken: String? { tokenizer.eosToken }
    var unknownToken: String? { tokenizer.unknownToken }

    func applyChatTemplate(
        messages: [[String: any Sendable]],
        tools: [[String: any Sendable]]?,
        additionalContext: [String: any Sendable]?
    ) throws -> [Int] {
        do {
            return try tokenizer.applyChatTemplate(
                messages: messages,
                tools: tools,
                additionalContext: additionalContext
            )
        } catch Tokenizers.TokenizerError.missingChatTemplate {
            throw MLXLMCommon.TokenizerError.missingChatTemplate
        }
    }
}

private enum HuggingFaceError: LocalizedError {
    case invalidRepositoryID(String)

    var errorDescription: String? {
        switch self {
        case .invalidRepositoryID(let id):
            "Invalid Hugging Face repository ID: '\(id)'. Expected format 'namespace/name'."
        }
    }
}
