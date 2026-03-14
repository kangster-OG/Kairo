// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AtlasDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AtlasDomain",
            targets: ["AtlasDomain"]
        )
    ],
    targets: [
        .target(
            name: "AtlasDomain"
        )
    ]
)
