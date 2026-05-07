import Foundation

func atlasProgressEvidenceDirectoryURL() throws -> URL {
    let base = try atlasApplicationSupportDirectory()
    let directory = base.appendingPathComponent("AtlasProgressEvidence", isDirectory: true)
    if FileManager.default.fileExists(atPath: directory.path) == false {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    return directory
}

func atlasProgressPhotoFileURL(relativePath: String) throws -> URL {
    try atlasProgressEvidenceDirectoryURL().appendingPathComponent(relativePath)
}

@discardableResult
func atlasWriteProgressPhoto(data: Data, id: String) throws -> String {
    let fileName = "photo-\(id.lowercased()).jpg"
    let fileURL = try atlasProgressPhotoFileURL(relativePath: fileName)
    try data.write(to: fileURL, options: [.atomic])
    return fileName
}

func atlasApplicationSupportDirectory() throws -> URL {
    guard let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
        throw CocoaError(.fileNoSuchFile)
    }
    if FileManager.default.fileExists(atPath: directory.path) == false {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    return directory
}
