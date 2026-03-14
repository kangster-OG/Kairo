// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AtlasFeatures",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AtlasFeatures",
            targets: ["AtlasFeatures"]
        )
    ],
    dependencies: [
        .package(path: "../AtlasDesignSystem"),
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasPersistence"),
        .package(path: "../AtlasPrivacy"),
        .package(path: "../AtlasSystem")
    ],
    targets: [
        .target(
            name: "AtlasFeatures",
            dependencies: [
                "AtlasDesignSystem",
                "AtlasDomain",
                "AtlasPersistence",
                "AtlasPrivacy",
                "AtlasSystem"
            ]
        )
    ]
)
