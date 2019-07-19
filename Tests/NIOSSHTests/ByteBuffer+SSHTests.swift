//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
import NIO
@testable import NIOSSH


final class ByteBufferSSHTests: XCTestCase {
    func testGettingBoolFromByteBuffer() {
        var buffer = ByteBufferAllocator().buffer(capacity: 3)
        buffer.writeInteger(UInt8(0))
        buffer.writeInteger(UInt8(1))
        buffer.writeInteger(UInt8(62))

        XCTAssertFalse(buffer.getSSHBoolean(at: 0)!)
        XCTAssertTrue(buffer.getSSHBoolean(at: 1)!)
        XCTAssertTrue(buffer.getSSHBoolean(at: 2)!)
        XCTAssertNil(buffer.getSSHBoolean(at: 3))
    }

    func testReadingBoolFromByteBuffer() {
        var buffer = ByteBufferAllocator().buffer(capacity: 3)
        buffer.writeInteger(UInt8(0))
        buffer.writeInteger(UInt8(1))
        buffer.writeInteger(UInt8(62))

        XCTAssertFalse(buffer.readSSHBoolean()!)
        XCTAssertTrue(buffer.readSSHBoolean()!)
        XCTAssertTrue(buffer.readSSHBoolean()!)

        let previousReaderIndex = buffer.readerIndex
        XCTAssertNil(buffer.readSSHBoolean())
        XCTAssertEqual(buffer.readerIndex, previousReaderIndex)
    }

    func testGettingSSHStringFromByteBuffer() {
        var buffer = ByteBufferAllocator().buffer(capacity: 1024)
        buffer.writeBytes([0, 0, 0, 0])  // SSH empty string

        let helloWorldLength = 12
        buffer.writeInteger(UInt32(helloWorldLength))
        buffer.writeBytes("hello world!".utf8)  // Simple utf8 string

        buffer.writeInteger(UInt32(5))
        buffer.writeBytes(repeatElement(0, count: 5))  // All nulls string

        buffer.writeInteger(UInt32(5))
        buffer.writeBytes(repeatElement(42, count: 3))  // Short string

        XCTAssertEqual(buffer.getSSHString(at: 0)?.array, [])
        XCTAssertEqual(buffer.getSSHString(at: 4)?.array, Array("hello world!".utf8))
        XCTAssertEqual(buffer.getSSHString(at: 4 + 4 + helloWorldLength)?.array, [0, 0, 0, 0, 0])
        XCTAssertNil(buffer.getSSHString(at: 4 + 4 + helloWorldLength + 4 + 5))  // String is short.

        buffer.clear()
        buffer.writeInteger(UInt16(5))  // Short length
        XCTAssertNil(buffer.getSSHString(at: 0))
    }

    func testReadingSSHStringFromByteBuffer() {
        var buffer = ByteBufferAllocator().buffer(capacity: 1024)
        buffer.writeBytes([0, 0, 0, 0])  // SSH empty string

        let helloWorldLength = 12
        buffer.writeInteger(UInt32(helloWorldLength))
        buffer.writeBytes("hello world!".utf8)  // Simple utf8 string

        buffer.writeInteger(UInt32(5))
        buffer.writeBytes(repeatElement(0, count: 5))  // All nulls string

        buffer.writeInteger(UInt32(5))
        buffer.writeBytes(repeatElement(42, count: 3))  // Short string

        XCTAssertEqual(buffer.readSSHString()?.array, [])
        XCTAssertEqual(buffer.readSSHString()?.array, Array("hello world!".utf8))
        XCTAssertEqual(buffer.readSSHString()?.array, [0, 0, 0, 0, 0])

        var previousReaderIndex = buffer.readerIndex
        XCTAssertNil(buffer.readSSHString())  // String is short.
        XCTAssertEqual(buffer.readerIndex, previousReaderIndex)

        buffer.clear()
        buffer.writeInteger(UInt16(5))  // Short length

        previousReaderIndex = buffer.readerIndex
        XCTAssertNil(buffer.readSSHString())
        XCTAssertEqual(buffer.readerIndex, previousReaderIndex)
    }
}


extension ByteBuffer {
    fileprivate var array: [UInt8] {
        return self.getBytes(at: self.readerIndex, length: self.readableBytes)!
    }
}