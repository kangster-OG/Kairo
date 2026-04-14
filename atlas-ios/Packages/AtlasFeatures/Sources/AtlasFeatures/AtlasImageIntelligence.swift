import AtlasDesignSystem
import AtlasDomain
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(Vision)
import Vision
#endif
#if canImport(UIKit)
import UIKit
#endif

enum AtlasImageAnalysisState: Equatable {
    case idle
    case loading
    case ready(String)
    case failed(String)
}

func atlasNormalizedJPEGData(from data: Data) -> Data? {
    #if canImport(UIKit)
    guard let image = UIImage(data: data) else {
        return nil
    }
    return image.jpegData(compressionQuality: 0.88)
    #else
    return data
    #endif
}

func atlasMealPhotoSuggestion(
    from imageData: Data,
    loggedAt: Date
) async -> AtlasNutritionQuickCaptureSuggestion? {
    let recognizedText = await atlasRecognizedImageText(from: imageData)
    let classificationSummary = await atlasClassifiedImageLabels(from: imageData)?.joined(separator: " ")
    let combined = [recognizedText, classificationSummary]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { $0.isEmpty == false }
        .joined(separator: " ")

    guard combined.isEmpty == false else {
        return nil
    }

    return atlasNutritionQuickCaptureSuggestion(for: combined, loggedAt: loggedAt)
}

func atlasInventoryLabelScanText(from imageData: Data) async -> String? {
    let recognizedText = await atlasRecognizedImageText(from: imageData)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let recognizedText, recognizedText.isEmpty == false else {
        return nil
    }
    return recognizedText
}

private func atlasRecognizedImageText(from imageData: Data) async -> String? {
    #if canImport(Vision)
    guard let cgImage = atlasCGImage(from: imageData) else {
        return nil
    }

    return await withCheckedContinuation { continuation in
        let request = VNRecognizeTextRequest { request, _ in
            let text = (request.results as? [VNRecognizedTextObservation])?
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            continuation.resume(returning: text)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    #else
    return nil
    #endif
}

private func atlasClassifiedImageLabels(from imageData: Data) async -> [String]? {
    #if canImport(Vision)
    guard let cgImage = atlasCGImage(from: imageData) else {
        return nil
    }

    if #available(iOS 16.0, *) {
        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, _ in
                let labels = (request.results as? [VNClassificationObservation])?
                    .filter { $0.confidence > 0.15 }
                    .prefix(4)
                    .map(\.identifier)
                continuation.resume(returning: labels)
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }
    }
    #endif

    return nil
}

private func atlasCGImage(from imageData: Data) -> CGImage? {
    #if canImport(UIKit)
    return UIImage(data: imageData)?.cgImage
    #else
    return nil
    #endif
}

struct AtlasInlinePhotoPreview: View {
    let data: Data
    var height: CGFloat = 180

    var body: some View {
        #if canImport(UIKit)
        Group {
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                AtlasImageFallback()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        #else
        AtlasImageFallback()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        #endif
    }
}

private struct AtlasImageFallback: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(AtlasPalette.surfaceSecondary)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
    }
}
