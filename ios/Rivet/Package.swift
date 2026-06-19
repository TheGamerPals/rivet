// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Rivet",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "RivetApp", targets: ["RivetApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.3")
    ],
    targets: [
        .target(
            name: "RivetApp",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")]
        ),
        .testTarget(name: "RivetTests", dependencies: ["RivetApp"])
    ]
)
