//
//  UInt128Tests.swift
//  IntLarge
//
//  Created by Simon Evans on 03/10/2019.
//  Copyright (c) 2019 Simon Evans
//
//  Tests for UInt128.
//

import XCTest
@testable import IntLarge

final class UInt128Tests: XCTestCase {

    func testInit() throws {

        // Input, Radix, Hi, Lo
        let testData: [(String, Int, UInt64?, UInt64?)] = [
            ("",                                    10, nil,    nil),
            ("+",                                   10, nil,    nil),
            ("+0",                                  10, 0,      0),
            (":",                                    2, nil,    nil),
            ("a",                                   10, nil,    nil),
            ("a",                                   16, 0,      10),
            ("1ffffffffffffffffffffffffffffffff",   16, nil,    nil),    // Overflow
            ("1",                                   10, 0,      1),
            ("11223344556677889900aabbccddeeff",    16, 0x1122334455667788, 0x9900aabbccddeeff),
            ("abcdefghijklmnopqrstuvwxyz",          36, nil,    nil),
            ( "1" + String(repeating: "0", count: 63) + "1" + String(repeating: "0", count: 63), 2,  0x80000000_00000000, 0x80000000_00000000),
        ]

        for data in testData {
            let value = UInt128(data.0, radix: data.1)
            XCTAssertEqual(value?._hiBits, data.2, "for input \"\(data.0)\"")
            XCTAssertEqual(value?._loBits, data.3, "for input \"\(data.0)\"")
        }
    }

    func testBitCounts() throws {

        // Hi, Lo, leadingZeroBitCount, trailingZeroBitCount, nonZeroBitCount
        let testData: [(UInt64, UInt64, Int, Int, Int)] = [
            (0,                     0,                      128,    128,    0),
            (0,                     1,                      127,    0,      1),
            (0,                     UInt64.max,             64,     0,      64),
            (UInt64.max,            0,                      0,      64,     64),
            (UInt64.max,            UInt64.max,             0,      0,      128),
            (1 << 63,               0,                      0,      127,    1),
            (0,                     1 << 63,                64,     63,     1),
            (1 << 63,               1,                      0,      0,      2),
            (1,                     1 << 63,                63,     63,     2),
            (0xaaaaaaaa_aaaaaaaa,   0x55555555_55555555,    0,      0,      64),
        ]

        for data in testData {
            let number = UInt128(_hiBits: data.0, _loBits: data.1)
            XCTAssertEqual(number.leadingZeroBitCount, data.2, "Leading Zero Bit Count of \(String(number, radix: 2)) != \(data.2)")
            XCTAssertEqual(number.trailingZeroBitCount, data.3, "Trailing Zero Bit Count of \(String(number, radix: 2)) != \(data.3)")
            XCTAssertEqual(number.nonzeroBitCount, data.4, "Non-Zero Bit Count of \(String(number, radix: 2)) != \(data.4)")
        }
    }

    func testByteSwapped() {
        // Hi in, Lo in, Hi out, Lo out
        let testData: [(UInt64, UInt64, UInt64, UInt64)] = [
            (0x1234567890abcdef,    0,                  0,                  0xefcdab9078563412),
            (0x0,                   0x1234567890abcdef, 0xefcdab9078563412, 0),
            (0x1020304050607080,    0x9000a0b0c0d0e0f0, 0xf0e0d0c0b0a00090, 0x8070605040302010),
            (0x12000000000000ab,    0xcd00000000000034, 0x34000000000000cd, 0xab00000000000012),
            (0x0               ,    0x0               , 0x0               , 0x0               ),
            (0xffffffffffffffff,    0xffffffffffffffff, 0xffffffffffffffff, 0xffffffffffffffff),
        ]

        for data in testData {
            let number = UInt128(_hiBits: data.0, _loBits: data.1).byteSwapped
            XCTAssertEqual(number._hiBits, data.2, "\(String(number._hiBits, radix:16)) != \(String(data.2, radix:16))")
            XCTAssertEqual(number._loBits, data.3, "\(String(number._loBits, radix:16)) != \(String(data.3, radix:16))")
        }
    }

    func testMisc() throws {

        XCTAssertEqual(UInt128.zero._loBits, 0)
        XCTAssertEqual(UInt128.zero._hiBits, 0)
        XCTAssertEqual(UInt128.zero.description, "0")

        XCTAssertEqual(UInt128.zero, UInt128.min)
        XCTAssertGreaterThan(UInt128.max, UInt128.min)
        XCTAssertLessThan(UInt128.min, UInt128.max)
        XCTAssertEqual(UInt128.max.leadingZeroBitCount, 0)
        XCTAssertEqual(UInt128.max.trailingZeroBitCount, 0)
        XCTAssertEqual(UInt128.max.nonzeroBitCount, 128)
        XCTAssertEqual(UInt128.bitWidth, 128)

        let ten = UInt128(10)
        XCTAssertEqual(ten._loBits, 10)
        XCTAssertEqual(ten._hiBits, 0)
        let shiftedTen = ten << UInt128(61)
        XCTAssertEqual(shiftedTen._loBits, 0x4000_0000_0000_0000)
        XCTAssertEqual(shiftedTen._hiBits, 0x0000_0000_0000_0001)

        var u1 = UInt128()
        XCTAssertEqual(String(u1, radix: 2), "0")
        u1 += 100
        let u2 = u1 * 10
        let u3 = UInt128("1000")
        XCTAssertEqual(u2, u3)


        let maxNumberStr = "340282366920938463463374607431768211455"
        for length in 1..<maxNumberStr.count {
            let subStr = String(maxNumberStr.suffix(length))
            let number = UInt128(subStr)
            let str2 = number?.description
            if subStr.hasPrefix("0") {
                XCTAssertEqual(str2, String(subStr.dropFirst()))
            } else {
                XCTAssertEqual(str2, subStr)
            }
        }
    }

    func testAddition() {
    }

    func testSubtraction() {


        let testData: [(UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, Bool)] = [
            (0, 0, 0, 1, 0xffff_ffff_ffff_ffff, 0xffff_ffff_ffff_ffff, true),
            (0, 0, 0xffff_ffff_ffff_ffff, 0xffff_ffff_ffff_ffff, 0, 1, true),
            (0, 0, 0x1, 0, 0xffff_ffff_ffff_ffff, 0, true)
        ]

        for data in testData {
            let number1 = UInt128(_hiBits: data.0, _loBits: data.1)
            let number2 = UInt128(_hiBits: data.2, _loBits: data.3)
            let (difference, borrow) = number1.subtractingReportingOverflow(number2)
            XCTAssertEqual(difference._hiBits, data.4)
            XCTAssertEqual(difference._loBits, data.5)
            XCTAssertEqual(borrow, data.6)
        }
    }

    func testMultiplication() {
    }

    func testDivision() {
    }

    func testEqualityOperators() {
    }

    func testArithmeticOperators() {
    }

    func testBitOperators() {
    }

    func testShifts() {
    }

    func testWords() {

        if  UInt64.bitWidth == UInt.bitWidth {
            XCTAssertEqual(UInt128.zero.words.count, 2)
        } else {
            XCTAssertEqual(UInt128.zero.words.count, 4)
        }

        let testData: [(UInt64, UInt64)] = [
            (0x12345678,    0x90abcdef),
            (UInt64.max,    UInt64.min),
            (UInt64.min,    UInt64.max),
        ]

        for data in testData {
            let number = UInt128(_hiBits: data.0, _loBits: data.1)
            if UInt64.bitWidth == UInt.bitWidth {
                XCTAssertEqual(number.words[0], data.1.words[0])
                XCTAssertEqual(number.words[1], data.0.words[0])
            } else {
                XCTAssertEqual(number.words[0], data.1.words[0])
                XCTAssertEqual(number.words[1], data.0.words[1])
                XCTAssertEqual(number.words[2], data.1.words[0])
                XCTAssertEqual(number.words[3], data.0.words[1])
            }
        }
    }


    static var allTests = [
        ("testInit", testInit),
        ("testBitCounts", testBitCounts),
        ("testByteSwapped", testByteSwapped),
        ("testMiscProperties", testMisc),
        ("testAddition", testAddition),
        ("testSubtraction", testSubtraction),
        ("testMultiplication", testMultiplication),
        ("testDivion", testDivision),
        ("testEqualityOperators", testEqualityOperators),
        ("testArithmeticOperators", testArithmeticOperators),
        ("testBitOperators", testBitOperators),
        ("testBitShifts", testShifts),
        ("testWords", testWords),
    ]
}
