// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AtlasPrivacy",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AtlasPrivacy",
            targets: ["AtlasPrivacy"]
        )
    ],
    dependencies: [
        .package(path: "../AtlasDomain")
    ],
    targets: [
        .target(
            name: "AtlasPrivacy",
            dependencies: ["AtlasDomain"]
        )
    ]
)
