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
        .executable(
        	name: "natalie",
        	targets: ["natalie"]),
        .library(
            name: "NatalieSupport",
            targets: ["NatalieSupport"]),
    ],
    dependencies: [
        .package(name: "Aspects", url: "https://github.com/robertgeifman/Aspects", .branch("rc-1")),
        .package(name: "FoundationAdditions", url: "https://github.com/robertgeifman/FoundationAdditions", .branch("rc-1")),
    ],
    targets: [
        .target(
            name: "natalie",
            dependencies: []),
        .target(
            name: "NatalieSupport",
            dependencies: ["FoundationAdditions",
            	"Aspects",
			]
		)
    ]
)
