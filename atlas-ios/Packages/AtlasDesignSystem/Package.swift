// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AtlasDesignSystem",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AtlasDesignSystem",
            targets: ["AtlasDesignSystem"]
        )
    ],
    targets: [
        .target(
            name: "AtlasDesignSystem"
        )
    ]
)
