// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AtlasPersistence",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AtlasPersistence",
            targets: ["AtlasPersistence"]
        )
    ],
    dependencies: [
        .package(path: "../../ThirdParty/GRDBLocal"),
        .package(path: "../AtlasDomain"),
        .package(path: "../AtlasPrivacy"),
        .package(path: "../AtlasSystem")
    ],
    targets: [
        .target(
            name: "AtlasPersistence",
            dependencies: [
                "AtlasDomain",
                "AtlasPrivacy",
                "AtlasSystem",
                .product(name: "GRDB", package: "GRDBLocal")
            ]
        )
    ]
)
