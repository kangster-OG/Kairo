// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AtlasSystem",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AtlasSystem",
            targets: ["AtlasSystem"]
        )
    ],
    dependencies: [
        .package(path: "../AtlasDomain")
    ],
    targets: [
        .target(
            name: "AtlasSystem",
            dependencies: ["AtlasDomain"]
        )
    ]
)
