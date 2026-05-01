import AppKit
import AVFoundation
import Foundation
import Vision

struct RecordingSummary {
    let slug: String
    let sourcePath: String
    let duration: Double
    let width: Int
    let height: Int
    let frameCount: Int
}

func sanitizeSlug(_ url: URL) -> String {
    url.deletingPathExtension().lastPathComponent
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: ":", with: "-")
}

func ensureDirectory(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

func writeJPEG(_ image: CGImage, to url: URL, quality: CGFloat = 0.84) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
        throw NSError(domain: "AtlasFrameExtraction", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not encode JPEG"])
    }
    try data.write(to: url)
}

func recognizeText(in image: CGImage) -> [(String, Float)] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.minimumTextHeight = 0.012

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    do {
        try handler.perform([request])
    } catch {
        return []
    }

    return (request.results ?? []).compactMap { observation in
        guard let candidate = observation.topCandidates(1).first else {
            return nil
        }
        return (candidate.string.replacingOccurrences(of: "\t", with: " "), candidate.confidence)
    }
}

func escapedTSV(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
        .replacingOccurrences(of: "\t", with: " ")
}

func extract(url: URL, outputRoot: URL, secondsPerFrame: Double) throws -> RecordingSummary {
    let slug = sanitizeSlug(url)
    let outputDirectory = outputRoot.appendingPathComponent(slug, isDirectory: true)
    let frameDirectory = outputDirectory.appendingPathComponent("frames", isDirectory: true)
    try ensureDirectory(frameDirectory)

    let asset = AVURLAsset(url: url)
    let duration = max(CMTimeGetSeconds(asset.duration), 0)
    let videoTrack = asset.tracks(withMediaType: .video).first
    let naturalSize = videoTrack?.naturalSize ?? .zero
    let transform = videoTrack?.preferredTransform ?? .identity
    let transformedSize = naturalSize.applying(transform)
    let width = Int(abs(transformedSize.width))
    let height = Int(abs(transformedSize.height))

    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
    generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)
    generator.maximumSize = CGSize(width: 720, height: 1280)

    var rows = ["frame_index\ttimestamp_seconds\timage_path\tocr_text\tocr_confidence"]
    var frameIndex = 0
    var timestamp = 0.0

    while timestamp <= duration {
        autoreleasepool {
            let time = CMTime(seconds: timestamp, preferredTimescale: 600)
            do {
                let image = try generator.copyCGImage(at: time, actualTime: nil)
                let frameName = String(format: "frame_%04d_t%07.2f.jpg", frameIndex, timestamp)
                let frameURL = frameDirectory.appendingPathComponent(frameName)
                try writeJPEG(image, to: frameURL)
                let ocrItems = recognizeText(in: image)
                let ocrText = ocrItems.map(\.0).joined(separator: " | ")
                let confidence = ocrItems.isEmpty
                    ? ""
                    : String(format: "%.3f", ocrItems.map(\.1).reduce(0, +) / Float(ocrItems.count))
                rows.append("\(frameIndex)\t\(String(format: "%.2f", timestamp))\t\(frameURL.path)\t\(escapedTSV(ocrText))\t\(confidence)")
                frameIndex += 1
            } catch {
                rows.append("\(frameIndex)\t\(String(format: "%.2f", timestamp))\t\tFRAME_EXTRACTION_FAILED: \(escapedTSV(error.localizedDescription))\t")
                frameIndex += 1
            }
        }
        timestamp += secondsPerFrame
    }

    try rows.joined(separator: "\n").write(
        to: outputDirectory.appendingPathComponent("ocr.tsv"),
        atomically: true,
        encoding: .utf8
    )

    return RecordingSummary(
        slug: slug,
        sourcePath: url.path,
        duration: duration,
        width: width,
        height: height,
        frameCount: frameIndex
    )
}

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count >= 2 else {
    fputs("Usage: swift extract_recording_frames.swift <output-root> <video> [video...]\n", stderr)
    exit(2)
}

let outputRoot = URL(fileURLWithPath: String(arguments.first!), isDirectory: true)
let videos = arguments.dropFirst().map { URL(fileURLWithPath: String($0)) }
try ensureDirectory(outputRoot)

let secondsPerFrame = ProcessInfo.processInfo.environment["ATLAS_FRAME_INTERVAL_SECONDS"]
    .flatMap(Double.init)
    .map { max($0, 0.1) }
    ?? 1.0
var summaries: [RecordingSummary] = []

for video in videos {
    summaries.append(try extract(url: video, outputRoot: outputRoot, secondsPerFrame: secondsPerFrame))
}

let manifestRows = ["slug\tsource_path\tduration_seconds\twidth\theight\tframe_count"]
    + summaries.map {
        "\($0.slug)\t\($0.sourcePath)\t\(String(format: "%.2f", $0.duration))\t\($0.width)\t\($0.height)\t\($0.frameCount)"
    }

try manifestRows.joined(separator: "\n").write(
    to: outputRoot.appendingPathComponent("manifest.tsv"),
    atomically: true,
    encoding: .utf8
)
