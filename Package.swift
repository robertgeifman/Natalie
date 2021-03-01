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
        .package(path: "../Aspects"),
        .package(path: "../FoundationAdditions")
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
