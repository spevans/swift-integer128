//
//  UInt128Tests.swift
//  Integer128
//
//  Created by Simon Evans on 03/10/2019.
//  Copyright (c) 2019 Simon Evans
//
//  Tests for UInt128.
//

import XCTest
@testable import Integer128

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
            ("abcdefghijklmnopqrstuvwxyz",          36, nil,    nil)
        ]

        for test in testData {
            let value = UInt128(test.0, radix: test.1)
            XCTAssertEqual(value?._hiBits, test.2, "for input \"\(test.0)\"")
            XCTAssertEqual(value?._loBits, test.3, "for input \"\(test.0)\"")
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

        for test in testData {
            let number = UInt128(_hiBits: test.0, _loBits: test.1)
            XCTAssertEqual(number.leadingZeroBitCount, test.2, "Leading Zero Bit Count of \(String(number, radix: 2)) != \(test.2)")
            XCTAssertEqual(number.trailingZeroBitCount, test.3, "Trailing Zero Bit Count of \(String(number, radix: 2)) != \(test.3)")
            XCTAssertEqual(number.nonzeroBitCount, test.4, "Non-Zero Bit Count of \(String(number, radix: 2)) != \(test.4)")
        }
    }

    func testByteSwapped() {
    }

    func testMisc() throws {

        XCTAssertEqual(UInt128.zero._loBits, 0)
        XCTAssertEqual(UInt128.zero._hiBits, 0)
        XCTAssertEqual(UInt128.zero.description, "0")

        XCTAssertEqual(UInt128.zero, UInt128.min)
        XCTAssertGreaterThan(UInt128.max, UInt128.min)
        XCTAssertLessThan(UInt128.min, UInt128.max)


        let (result1, borrow1) = UInt128.zero.subtractingReportingOverflow(UInt128(1))
        XCTAssertTrue(borrow1)
        XCTAssertEqual(result1._hiBits, 0xffff_ffff_ffff_ffff)
        XCTAssertEqual(result1._loBits, 0xffff_ffff_ffff_ffff)

        let (result2, borrow2) = UInt128.zero.subtractingReportingOverflow(result1)
        XCTAssertTrue(borrow2)
        XCTAssertEqual(result2._hiBits, 0)
        XCTAssertEqual(result2._loBits, 1)

        let (result3, borrow3) = UInt128.zero.subtractingReportingOverflow(UInt128(bit: 64))
        XCTAssertTrue(borrow3)
        XCTAssertEqual(result3._hiBits, 0xffff_ffff_ffff_ffff)
        XCTAssertEqual(result3._loBits, 0)


        let ten = UInt128(10)
        XCTAssertEqual(ten._loBits, 10)
        XCTAssertEqual(ten._hiBits, 0)
        let shiftedTen = ten << UInt128(61)
        XCTAssertEqual(shiftedTen._loBits, 0x4000_0000_0000_0000)
        XCTAssertEqual(shiftedTen._hiBits, 0x0000_0000_0000_0001)

        let s1 = "63374607431768211455"
        let uu1 = try XCTUnwrap(UInt128(s1))
        XCTAssertEqual(uu1.description, s1)


        var u1 = UInt128()
        XCTAssertEqual(String(u1, radix: 2), "0")
        u1 += 100
        let u2 = u1 * 10
        let u3 = try XCTUnwrap(UInt128("1000"))
        XCTAssertEqual(u2, u3)


        let maxNumberStr = "340282366920938463463374607431768211455"
        for length in 1..<maxNumberStr.count {
            let subStr = String(maxNumberStr.suffix(length))
            let number = try XCTUnwrap(UInt128(subStr))
            let str2 = number.description
            if subStr.hasPrefix("0") {
                XCTAssertEqual(str2, String(subStr.dropFirst()))
            } else {
                XCTAssertEqual(str2, subStr)
            }
        }

        let maxNumber = try XCTUnwrap(UInt128(maxNumberStr))
        XCTAssertEqual(maxNumber.trailingZeroBitCount, 0)
        XCTAssertEqual(maxNumber.leadingZeroBitCount, 0)
        for word in maxNumber.words {
            XCTAssertEqual(word, UInt.max)
        }


        let str = "10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        let u4 = try XCTUnwrap(UInt128(str, radix: 2))
        let u5 = UInt128(bit: 127)
        XCTAssertEqual(u5._loBits, 0)
        XCTAssertEqual(u5._hiBits, 0x8000_0000_0000_0000)
        XCTAssertEqual(String(u5, radix: 2), str)
        XCTAssertEqual(u4 >> 127, UInt128(1))
        let u6 = ~u5
        XCTAssertEqual(u6._loBits, 0xffff_ffff_ffff_ffff)
        XCTAssertEqual(u6._hiBits, 0x7fff_ffff_ffff_ffff)
    }

    func testAddition() {
    }

    func testSubtraction() {
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
