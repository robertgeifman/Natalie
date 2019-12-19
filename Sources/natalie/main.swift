//
//  main.swift
//  Natalie
//
//  Created by Marcin Krzyzanowski on 07/08/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

func printUsage() {
    print("Usage:")
    print("natalie <storyboard-path or directory>")
}

if CommandLine.arguments.count == 1 {
    printUsage()
    exit(1)
}

var filePaths: [String] = []
let storyboardSuffix = ".storyboard"

for arg in CommandLine.arguments.dropFirst() {
    if arg == "--help" {
        printUsage()
        exit(0)
    } else if arg.hasSuffix(storyboardSuffix) {
        filePaths.append(arg)
    } else if let s = findStoryboards(rootPath: arg, suffix: storyboardSuffix) {
        filePaths.append(contentsOf: s)
    }
}

let storyboardFiles = filePaths.compactMap { try? StoryboardFile(filePath: $0) }

let output = Natalie.process(storyboards: storyboardFiles)
print(output.joined(separator: "\n"))

// swi ftlint:disable:next line_length
let natalieBase64String = """
"""

do {
	if let natalieBase64Data = try Base64.decode(natalieBase64String),
		let string = String(data: natalieBase64Data, encoding: .utf8) {
		print(string)
	}
} catch {}
exit(0)
