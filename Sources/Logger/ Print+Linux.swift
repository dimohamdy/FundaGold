//
//  Print+Linux.swift
//
//
//  Created by BinaryBoy on 12/29/23.
//

import Foundation

internal var STDERR = FileHandleOutputStream(.standardError)
internal var STDOUT = FileHandleOutputStream(.standardOutput)

internal struct FileHandleOutputStream: TextOutputStream {
    private let fileHandle: FileHandle
    let encoding: String.Encoding

    init(_ fileHandle: FileHandle, encoding: String.Encoding = .utf8) {
        self.fileHandle = fileHandle
        self.encoding = encoding
    }

    mutating func write(_ string: String) {
        if let data = string.data(using: encoding) {
            fileHandle.write(data)
        }
    }
}

///
/// Override of the print so it can work with Linux and MAC
/// https://stackoverflow.com/questions/39026752/swift-extending-functionality-of-print-function
public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {

    let output = items.map { "\($0)" }.joined(separator: separator)

    #if os(Linux)
        print(output, to: &STDERR)
    #else
        Swift.print(output, terminator: terminator)
    #endif
}

