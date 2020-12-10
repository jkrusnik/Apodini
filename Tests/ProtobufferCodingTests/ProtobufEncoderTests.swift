//
//  ProtobufEncoderTests.swift
//  
//
//  Created by Moritz Schüll on 29.11.20.
//

import Foundation
import XCTest
@testable import ProtobufferCoding

class ProtobufEncoderTests: XCTestCase {
    func testEncodePositiveInt32() throws {
        let expected = Data([8, 185, 96])
        let number: Int32 = 12345

        let message = ProtoTestMessage(content: number)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodePositiveInt32")
    }

    func testEncodeNegativeInt32() throws {
        let expected = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let number: Int32 = -12345

        let message = ProtoTestMessage(content: number)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeNegativeInt32")
    }

    func testEncodeUInt32() throws {
        let expected = Data([8, 185, 96])
        let number: UInt32 = 12345

        let message = ProtoTestMessage(content: number)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeUInt32")
    }

    func testEncodeBool() throws {
        let expected = Data([8, 1])

        let message = ProtoTestMessage(content: true)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeBool")
    }

    func testEncodeDouble() throws {
        let expected = Data([9, 88, 168, 53, 205, 143, 28, 200, 64])
        let number: Double = 12345.12345

        let message = ProtoTestMessage(content: number)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeDouble")
    }

    func testEncodeFloat() throws {
        let expected = Data([13, 126, 228, 64, 70])
        let number: Float = 12345.12345

        let message = ProtoTestMessage(content: number)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeFloat")
    }

    func testEncodeString() throws {
        let expected = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let content: String = "Hello World"

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeString")
    }

    func testEncodeBytes() throws {
        let expected = Data([10, 6, 1, 2, 3, 253, 254, 255])
        let bytes = Data([1, 2, 3, 253, 254, 255])

        let message = ProtoTestMessage(content: bytes)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeBytes")
    }

    func testEncodeRepeatedBool() throws {
        let expected = Data([10, 3, 1, 0, 1])
        let content = [true, false, true]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedBool")
    }

    func testEncodeRepeatedInt32() throws {
        let expected = Data([10, 5, 1, 2, 3, 4, 5])
        let content: [Int32] = [1, 2, 3, 4, 5]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedInt32")
    }

    func testEncodeRepeatedInt64() throws {
        let expected = Data([
                                10, 30, 195, 144, 236, 143, 247, 35,
                                196, 144, 236, 143, 247, 35, 197, 144,
                                236, 143, 247, 35, 198, 144, 236, 143,
                                247, 35, 199, 144, 236, 143, 247, 35
        ])
        let content: [Int64] = [1234567891011, 1234567891012, 1234567891013, 1234567891014, 1234567891015]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedInt64")
    }

    func testEncodeRepeatedFloat() throws {
        let expected = Data([
                                10, 20, 250, 62, 246, 66, 207, 119,
                                246, 66, 164, 176, 246, 66, 121, 233,
                                246, 66, 78, 34, 247, 66
        ])
        let content: [Float] = [123.123, 123.234, 123.345, 123.456, 123.567]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedFloat")
    }

    func testEncodeRepeatedDouble() throws {
        let expected = Data([
                                10, 24, 117, 107, 126, 84, 52, 111,
                                157, 65, 219, 209, 228, 84, 52, 111,
                                157, 65, 66, 56, 75, 85, 52, 111,
                                157, 65
        ])
        let content: [Double] = [123456789.123456789, 123456789.223456789, 123456789.323456789]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedDouble")
    }

    func testEncodeRepeatedUInt32() throws {
        let expected = Data([10, 5, 1, 2, 3, 4, 5])
        let content: [UInt32] = [1, 2, 3, 4, 5]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedUInt32")
    }

    func testEncodeRepeatedData() throws {
        let expected = Data([10, 2, 1, 2, 10, 2, 3, 4, 10, 2, 5, 6])
        let bytes1: [UInt8] = [1, 2]
        let bytes2: [UInt8] = [3, 4]
        let bytes3: [UInt8] = [5, 6]
        let content: [Data] = [Data(bytes1), Data(bytes2), Data(bytes3)]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedData")
    }

    func testEncodeRepeatedString() throws {
        let expected = Data([10, 4, 101, 105, 110, 115, 10, 4, 122, 119, 101, 105, 10, 4, 100, 114, 101, 105])
        let content = ["eins", "zwei", "drei"]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedString")
    }

    let expectedComplexMessage = Data([
                            8, 199, 159, 255, 255, 255, 255, 255, 255, 255,
                            1, 16, 185, 96, 32, 1, 40, 2, 65, 88, 168, 53,
                            205, 143, 28, 200, 64, 74, 11, 72, 101, 108, 108,
                            111, 32, 87, 111, 114, 108, 100, 82, 6, 1, 2, 3,
                            253, 254, 255, 90, 36, 10, 34, 72, 97, 108, 108, 111,
                            44, 32, 100, 97, 115, 32, 105, 115, 116, 32, 101,
                            105, 110, 101, 32, 83, 117, 98, 45, 78, 97, 99, 104,
                            114, 105, 99, 104, 116, 46, 117, 126, 228, 64, 70
    ])

    let complexMessage = ProtoComplexTestMessage(
        numberInt32: -12345,
        numberUint32: 12345,
        numberBool: true,
        enumValue: 2,
        numberDouble: 12345.12345,
        content: "Hello World",
        byteData: Data([1, 2, 3, 253, 254, 255]),
        nestedMessage: ProtoTestMessage(
            content: "Hallo, das ist eine Sub-Nachricht."
        ),
        numberFloat: 12345.12345
    )

    func testEncodeComplexMessage() throws {
        let encoded = try ProtoEncoder().encode(complexMessage)
        XCTAssertEqual(encoded, expectedComplexMessage, "testEncodeComplexMessage")
    }
}