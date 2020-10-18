// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Natalie",
    platforms: [
    	.macOS(.v10_15),
    	.iOS(.v13),
    	.tvOS(.v13)
	],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
        	name: "natalie",
        	targets: ["natalie"]),
        .library(
            name: "NatalieSupport",
            targets: ["NatalieSupport"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/robertgeifman/Aspects.git", .branch("develop")),
//        .package(url: "https://github.com/robertgeifman/FoundationAdditions.git", .branch("develop")),
        .package(path: "~/Projects/Packages/Aspects"),
        .package(path: "~/Projects/Packages/FoundationAdditions")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "natalie",
            dependencies: []),
        .target(
            name: "NatalieSupport",
            dependencies: ["Aspects", "FoundationAdditions"])
    ]
)
