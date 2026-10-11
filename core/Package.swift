// swift-tools-version: 5.9
import PackageDescription
let package = Package(
 name: "ArvectumCore",
 platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
 products: [.library(name: "ArvectumCore", targets: ["ArvectumCore"])],
 targets: [
 .target(name: "ArvectumCore", path: "packages", exclude: ["README.md","ArvectumDesignTokens/README.md","ArvectumDiagnostics/README.md","ArvectumPersistence/README.md"],
 sources: ["ArvectumDesignTokens/ArvectumPalette.swift","ArvectumDiagnostics/ArvectumDiagnostics.swift","ArvectumPersistence/ArvectumJSONCodec.swift"]),
 .testTarget(name: "ArvectumCoreTests", dependencies: ["ArvectumCore"], path: "tests")
 ])
