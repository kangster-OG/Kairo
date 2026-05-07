import Foundation

public func atlasInventoryMediaDirectoryURL() throws -> URL {
    let base = try atlasApplicationSupportDirectory()
    let directory = base.appendingPathComponent("AtlasInventoryMedia", isDirectory: true)
    if FileManager.default.fileExists(atPath: directory.path) == false {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    return directory
}

public func atlasInventoryPhotoFileURL(relativePath: String) throws -> URL {
    try atlasInventoryMediaDirectoryURL().appendingPathComponent(relativePath)
}

@discardableResult
public func atlasWriteInventoryPhoto(data: Data, id: String) throws -> String {
    let fileName = "vial-\(id.lowercased()).jpg"
    let fileURL = try atlasInventoryPhotoFileURL(relativePath: fileName)
    try data.write(to: fileURL, options: [.atomic])
    return fileName
}
