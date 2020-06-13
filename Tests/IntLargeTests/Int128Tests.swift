//
//  Int128Tests.swift
//  IntLarge
//
//  Created by Simon Evans on 06/06/2020.
//  Copyright (c) 2019 - 2020 Simon Evans
//
//  Tests for Int128.
//

import XCTest
@testable import IntLarge


final class Int128Tests: XCTestCase {

    private func asHex(_ number: UInt64) -> String {
        let hex = String(number, radix: 16)
        return "0x" + String(repeating: "0", count: 16 - hex.count) + hex
    }

    private func asHex(_ hi: Int64, _ lo: UInt64) -> String {
        let hexHi = String(hi, radix: 16)
        let hexLo = String(lo, radix: 16)
        return "0x" + String(repeating: "0", count: 16 - hexHi.count) + hexHi + "_" + String(repeating: "0", count: 16 - hexLo.count) + hexLo
    }

    private func asHex(_ number: Int128) -> String {
        return asHex(number.hiBits, number.loBits)
    }

    private func asBinary(_ number: UInt64) -> String {
        let bin = String(number, radix: 2)
        return "0b" + String(repeating: "0", count: 64 - bin.count) + bin
    }

    private func asBinary(_ hi: Int64, _ lo: UInt64) -> String {
        let binHi = String(hi, radix: 2)
        let binLo = String(lo, radix: 2)
        return "0b" + String(repeating: "0", count: 64 - binHi.count) + binHi + "_" + String(repeating: "0", count: 64 - binLo.count) + binLo
    }

    private func asBinary(_ number: Int128) -> String {
        return asBinary(number.hiBits, number.loBits)
    }


    func testInit() {

        // Input, Radix, Hi, Lo
        let testData: [(String, Int, Int64?, UInt64?)] = [
            ("",                                    10, nil,    nil),
            ("+",                                   10, nil,    nil),
            ("+0",                                  10, 0,      0),
            (":",                                    2, nil,    nil),
            ("a",                                   10, nil,    nil),
            ("a",                                   16, 0,      10),
            ("ëff",                                 16, nil,    nil),
            ("ABCdef",                              16, 0,      11259375),
            ("1ffffffffffffffffffffffffffffffff",   16, nil,    nil),    // Overflow
            ("1",                                   10, 0,      1),
            ("11223344556677889900aabbccddeeff",    16, 0x1122334455667788, 0x9900aabbccddeeff),
            ("abcdefghijklmnopqrstuvwxyz",          36, nil,    nil),
       //     ( "-1" + String(repeating: "0", count: 63) + "1" + String(repeating: "0", count: 63), 2,  -1, 0x80000000_00000000),
        ]

        for data in testData {
            let value = Int128(data.0, radix: data.1)
            XCTAssertEqual(value?.hiBits, data.2, "for input \"\(data.0)\"")
            XCTAssertEqual(value?.loBits, data.3, "for input \"\(data.0)\"")
        }
    }

    func testBitCounts() {
        // Hi, Lo, leadingZeroBitCount, trailingZeroBitCount, nonZeroBitCount
        let testData: [(Int64, UInt64, Int, Int, Int)] = [
            (0x00000000_00000000,   0x00000000_00000000,    128,    128,    0),
            (0x00000000_00000000,   0x00000000_00000001,    127,    0,      1),
            (0x00000000_00000000,   0xffffffff_ffffffff,    64,     0,      64),
            ( -1,   0x00000000_00000000,    0,      64,     64),
         //   (0xffffffff_ffffffff,   0xffffffff_ffffffff,    0,      0,      128),
         //   (0x80000000_00000000,   0x00000000_00000000,    0,      127,    1),
            (0x00000000_00000000,   0x80000000_00000000,    64,     63,     1),
          //  (0x80000000_00000000,   0x00000000_00000001,    0,      0,      2),
            (0x00000000_00000001,   0x80000000_00000000,    63,     63,     2),
          //  (0xaaaaaaaa_aaaaaaaa,   0x55555555_55555555,    0,      0,      64),
        ]

        for data in testData {
            let number = Int128(hiBits: data.0, loBits: data.1)
            XCTAssertEqual(number.leadingZeroBitCount, data.2, "Leading Zero Bit Count of \(asBinary(number)) != \(data.2)")
            XCTAssertEqual(number.trailingZeroBitCount, data.3, "Trailing Zero Bit Count of \(asBinary(number)) != \(data.3)")
            XCTAssertEqual(number.nonzeroBitCount, data.4, "Non-Zero Bit Count of \(asBinary(number)) != \(data.4)")
        }
    }

    func testByteSwapped() {
        // Hi in, Lo in, Hi out, Lo out
        let testData: [(Int64, UInt64, Int64, UInt64)] = [
            (0x1234567890abcdef,    0,                  0,                  0xefcdab9078563412),
            (0,                    0x1234567890abcd10,  0x10cdab9078563412, 0),
            (0x1020304050607080,    0x9000a0b0c0d0e020, 0x20e0d0c0b0a00090, 0x8070605040302010),
            (0x12000000000000ab,    0xcd00000000000034, 0x34000000000000cd, 0xab00000000000012),
            (0x0               ,    0x0               , 0x0               , 0x0               ),
            (-1                ,    0,                  0x0,                0xffffffffffffffff),
        ]

        for data in testData {
            let number = Int128(hiBits: data.0, loBits: data.1).byteSwapped
            XCTAssertEqual(number.hiBits, data.2, "\(String(number.hiBits, radix:16)) != \(String(data.2, radix:16))")
            XCTAssertEqual(number.loBits, data.3, "\(String(number.loBits, radix:16)) != \(String(data.3, radix:16))")
        }
    }


    func testStrings() throws {

        let digits = "123456789abcdef"
        let maxDigits = Int128.bitWidth / 4
        for digit in digits {
            for length in 1..<(maxDigits-1) {
                let string = String(repeating: digit, count: length)
                let value = Int128(string, radix: 16)
                XCTAssertNotNil(value)
                if let value = value {
                    let output = String(value, radix: 16)
                    XCTAssertNotNil(output)
                    XCTAssertEqual(string, output)
                }

                let negativeString = "-" + string
                let negativeValue = Int128(negativeString, radix: 16)
                XCTAssertNotNil(negativeValue)
                if let negativeValue = negativeValue {
                    let output = String(negativeValue, radix: 16)
                    XCTAssertNotNil(output)
                    XCTAssertEqual(negativeString, output)
                }
            }
        }
    }

    func testMiscProperties() throws {

        XCTAssertEqual(Int128.zero.loBits, 0)
        XCTAssertEqual(Int128.zero.hiBits, 0)
        XCTAssertEqual(Int128.zero.description, "0")

        XCTAssertEqual(Int128.positiveOne.loBits, 1)
        XCTAssertEqual(Int128.positiveOne.hiBits, 0)
        XCTAssertEqual(Int128.positiveOne.description, "1")

        XCTAssertEqual(Int128.negativeOne.loBits, 0xffffffff_ffffffff)
        XCTAssertEqual(Int128.negativeOne.hiBits, -1)
        XCTAssertEqual(Int128.negativeOne.description, "-1")

        XCTAssertEqual(Int128(Int64.min).description, Int64.min.description)

        XCTAssertEqual(Int128.zero.signum(), Int128.zero)
        XCTAssertEqual(Int128(1).signum, Int128(1))
        XCTAssertEqual(Int128(Int64.max).signum, Int128(1))
        XCTAssertEqual(Int128(-1).signum.description, "-1")
        XCTAssertEqual(Int128(Int64.min).signum, Int128(-1))

        XCTAssertEqual(Int128(hiBits: -1, loBits: UInt64.max).description, "-1")
        XCTAssertEqual(Int128(Int64.max).description, Int64.max.description)
        XCTAssertEqual((Int128(UInt64.max) + 1).description, "18446744073709551616")
        XCTAssertEqual(Int128.min.description, "-170141183460469231731687303715884105728")
        XCTAssertEqual(String(UInt128(bitPattern: Int128.min), radix: 2), "1" + String(repeating: "0", count: 127))
        XCTAssertEqual(String(Int128.min, radix: 16), "-80000000000000000000000000000000")
        XCTAssertEqual(Int128.max.description, "170141183460469231731687303715884105727")

        XCTAssertGreaterThan(Int128.zero, Int128.min)
        XCTAssertGreaterThan(Int128.max, Int128.min)
        XCTAssertLessThan(Int128.min, Int128.max)
        XCTAssertEqual(Int128.max.leadingZeroBitCount, 1)
        XCTAssertEqual(Int128.max.trailingZeroBitCount, 0)
        XCTAssertEqual(Int128.max.nonzeroBitCount, 127)
        XCTAssertEqual(Int128.bitWidth, 128)

        let ten = Int128(10)
        XCTAssertEqual(ten.loBits, 10)
        XCTAssertEqual(ten.hiBits, 0)
        let shiftedTen = ten << Int128(61)
        XCTAssertEqual(shiftedTen.loBits, 0x4000_0000_0000_0000)
        XCTAssertEqual(shiftedTen.hiBits, 0x0000_0000_0000_0001)

        var u1 = Int128()
        XCTAssertEqual(String(u1, radix: 2), "0")
        u1 += 100
        let u2 = u1 * 10
        let u3 = Int128("1000")
        XCTAssertEqual(u2, u3)


        let maxNumberStr = "340282366920938463463374607431768211455"
        for length in 1..<maxNumberStr.count {
            let subStr = String(maxNumberStr.suffix(length))
            let number = Int128(subStr)
            let str2 = number?.description
            if subStr.hasPrefix("0") {
                XCTAssertEqual(str2, String(subStr.dropFirst()))
            } else {
                XCTAssertEqual(str2, subStr)
            }
        }
    }

    func testAddition() {

        let testData: [(Int64, UInt64, Int64, UInt64, Int64, UInt64, Bool)] = [
         //   (0xffffffff_ffffffff,   0xffffffff_ffffffff,    0x00000000_00000000,    0x00000000_00000001,    0x00000000_00000000,    0x00000000_00000000,    true),
         //   (0xffffffff_ffffffff,   0xffffffff_ffffffff,    0x00000000_00000000,    0x00000000_00000001,    0x00000000_00000000,    0x00000000_00000000,    true),
//            (0xffffffff_ffffffff,   0xffffffff_ffffffff,    0xffffffff_ffffffff,    0xffffffff_ffffffff,    0xffffffff_ffffffff,    0xffffffff_fffffffe,    true),
           // (0xaaaaaaaa_aaaaaaaa,   0x55555555_55555555,    0x55555555_55555555,    0xaaaaaaaa_aaaaaaaa,    0xffffffff_ffffffff,    0xffffffff_ffffffff,    false)
        ]

        for data in testData {
            let number1 = Int128(hiBits: data.0, loBits: data.1)
            let number2 = Int128(hiBits: data.2, loBits: data.3)
            let (sum, carry) = number1.addingReportingOverflow(number2)
            XCTAssertEqual(sum.hiBits, data.4)
            XCTAssertEqual(sum.loBits, data.5)
            XCTAssertEqual(carry, data.6)
        }
    }

    func testSubtraction() {

        let testData: [(Int64, UInt64, Int64, UInt64, Int64, UInt64, Bool)] = [
            (0, 0, 0, 1, -1, 0xffff_ffff_ffff_ffff, false), // 0 - 1
            (0, 0, -1, 0xffff_ffff_ffff_ffff, 0, 1, false),  // 0 - -1
            (0, 0, 0, 0, 0, 0, false), // 0 - 0
            (0, 0, 0x1, 0, -1, 0, false)
        ]

        for data in testData {
            let number1 = Int128(hiBits: data.0, loBits: data.1)
            let number2 = Int128(hiBits: data.2, loBits: data.3)
            let (difference, borrow) = number1.subtractingReportingOverflow(number2)
            XCTAssertEqual(difference.hiBits, data.4)
            XCTAssertEqual(difference.loBits, data.5)
            XCTAssertEqual(borrow, data.6)
        }
    }

    func testMultiplication() {

        let testData: [(Int64, UInt64, Int64, UInt64, Int64, UInt64, UInt64, UInt64, Bool)] = [
            (0x00000000_00000000,   0x00000000_00000001,    0x00000000_00000000,    0x00000000_00000001,    0x00000000_00000000,    0x00000000_00000000, 0,  1, false),
            (-1,   0xffffffff_ffffffff,    0x00000000_00000000,    0x00000000_00000003,    -1,    0xffffffff_ffffffff, 0xffffffff_ffffffff, 0xffffffff_fffffffd, false),
            (0x00000000_00000000,   0x00000000_00000100,    0x00000000_00000000,    0x55555555_aaaaaaaa,    0x00000000_00000000,    0x00000000_00000000, 0x00000000_00000055, 0x555555aa_aaaaaa00, false),
        ]

        for data in testData {
            let factor1 = Int128(hiBits: data.0, loBits: data.1)
            let factor2 = Int128(hiBits: data.2, loBits: data.3)
            let (productHigh, productLow) = factor1.multipliedFullWidth(by: factor2)
            XCTAssertEqual(productHigh.hiBits, data.4)
            XCTAssertEqual(productHigh.loBits, data.5)
            XCTAssertEqual(productLow.hiBits, data.6)
            XCTAssertEqual(productLow.loBits, data.7)

            let (partialValue, overflow) = factor1.multipliedReportingOverflow(by: factor2)
            XCTAssertEqual(partialValue.hiBits, Int64(bitPattern: data.6))
            XCTAssertEqual(partialValue.loBits, data.7)
            XCTAssertEqual(overflow, data.8)

            let product2 = factor1 &* factor2
            XCTAssertEqual(product2.hiBits, Int64(bitPattern: data.6))
            XCTAssertEqual(product2.loBits, data.7)

            var product3 = factor1
            product3 &*= factor2
            XCTAssertEqual(product3.hiBits, Int64(bitPattern: data.6))
            XCTAssertEqual(product3.loBits, data.7)

            guard data.8 == false else { continue }
            let product4 = factor1 * factor2
            XCTAssertEqual(product4.hiBits, Int64(bitPattern: data.6))
            XCTAssertEqual(product4.loBits, data.7)

            var product5 = factor1
            product5 *= factor2
            XCTAssertEqual(product5.hiBits, Int64(bitPattern: data.6))
            XCTAssertEqual(product5.loBits, data.7)
        }
    }
/*
    func testDivision() {

        let testData: [(UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, Bool, UInt64, UInt64, Bool)] = [
            // Dividend Hi           Dividend Lo            Divisor Hi              Divisor Lo,             Quotient Hi             Quotient Lo,        Q Overflow, Remainder Hi            Reminader Lo        R overflow
            (0xffffffff_ffffffff,    0xffffffff_ffffffff,   0x00000000_00000000,    0x00000000_00000000,    0xffffffff_ffffffff,    0xffffffff_ffffffff,    true,   0xffffffff_ffffffff,    0xffffffff_ffffffff,    true),
            (0xffffffff_ffffffff,    0xffffffff_ffffffff,   0x00000000_00000001,    0x00000000_00000000,    0x00000000_00000000,    0xffffffff_ffffffff,    false,  0x00000000_00000000,    0xffffffff_ffffffff,    false),
            (0xffffffff_ffffffff,    0xffffffff_ffffffff,   0x80000000_00000000,    0x00000000_00000000,    0x00000000_00000000,    0x00000000_00000001,    false,  0x7fffffff_ffffffff,    0xffffffff_ffffffff,    false),
            (0xffffffff_ffffffff,    0xffffffff_ffffffff,   0x00000000_00000000,    0x00000000_00000001,    0xffffffff_ffffffff,    0xffffffff_ffffffff,    false,  0x00000000_00000000,    0x00000000_00000000,    false),
            (0x00000000_00000000,    0x00000000_00000001,   0x00000000_00000000,    0x00000000_00000001,    0x00000000_00000000,    0x00000000_00000001,    false,  0x00000000_00000000,    0x00000000_00000000,    false),
            (0x00000000_00000000,    0x00000000_00000000,   0x00000000_00000000,    0x00000000_00000001,    0x00000000_00000000,    0x00000000_00000000,    false,  0x00000000_00000000,    0x00000000_00000000,    false),
        ]

        for test in testData {
            let dividend = Int128(hiBits: test.0, loBits: test.1)
            let divisor = Int128(hiBits: test.2, loBits: test.3)
            let (quotient, qOverflow) = dividend.dividedReportingOverflow(by: divisor)
            XCTAssertEqual(quotient.hiBits, test.4, "\(asHex(dividend)) / \(asHex(divisor)), Quotient Hi: \(asHex(quotient.hiBits)) != \(asHex(test.4))")
            XCTAssertEqual(quotient.loBits, test.5, "\(asHex(dividend)) / \(asHex(divisor)), Quotient Lo: \(asHex(quotient.loBits)) != \(asHex(test.5))")
            XCTAssertEqual(qOverflow, test.6, "\(asHex(dividend)) / \(asHex(divisor)), qOverflow != \(test.6)")

            let (remainder, rOverflow) = dividend.remainderReportingOverflow(dividingBy: divisor)
            XCTAssertEqual(remainder.hiBits, test.7, "\(asHex(dividend)) / \(asHex(divisor)), Remainder Hi: \(asHex(remainder.hiBits)) != \(asHex(test.7))")
            XCTAssertEqual(remainder.loBits, test.8, "\(asHex(dividend)) / \(asHex(divisor)), Remainder Lo: \(asHex(remainder.loBits)) != \(asHex(test.8))")
            XCTAssertEqual(rOverflow, test.9, "\(asHex(dividend)) / \(asHex(divisor)), rOverflow != \(test.9)")

            guard divisor.hiBits != 0 || divisor.loBits != 0 else { continue }

            let quotient2 = dividend / divisor
            XCTAssertEqual(quotient2.hiBits, test.4, "Quotient2 Hi: \(asHex(quotient2.hiBits)) != \(asHex(test.4))")
            XCTAssertEqual(quotient2.loBits, test.5, "Quotient2 Lo: \(asHex(quotient2.loBits)) != \(asHex(test.5))")

            let remainder2 = dividend % divisor
            XCTAssertEqual(remainder2.hiBits, test.7, "Remainder2 Hi: \(asHex(remainder2.hiBits)) != \(asHex(test.7))")
            XCTAssertEqual(remainder2.loBits, test.8, "Remainder2 Lo: \(asHex(remainder2.loBits)) != \(asHex(test.8))")

            var quotient3 = dividend
            quotient3 /= divisor
            XCTAssertEqual(quotient3.hiBits, test.4, "Quotient3 Hi: \(asHex(quotient3.hiBits)) != \(asHex(test.4))")
            XCTAssertEqual(quotient3.loBits, test.5, "Quotient3 Lo: \(asHex(quotient3.loBits)) != \(asHex(test.5))")

            var remainder3 = dividend
            remainder3 %= divisor
            XCTAssertEqual(remainder3.hiBits, test.7, "Remainder3 Hi: \(asHex(remainder3.hiBits)) != \(asHex(test.7))")
            XCTAssertEqual(remainder3.loBits, test.8, "Remainder3 Lo: \(asHex(remainder3.loBits)) != \(asHex(test.8))")
        }
    }
*/
    func testEqualityOperators() {

        let testData: [(Int64, UInt64, Int64, UInt64, Bool, Bool, Bool)] = [
            // LHS Hi               LHS Lo                  RHS Hi                  RHS Lo                  Equal   Less Than   Greater Than
            (0x00000000_00000000,   0x00000000_00000000,    0x00000000_00000000,    0x00000000_00000000,    true,   false,      false),
            (0x00000000_00000000,   0x00000000_00000001,    0x00000000_00000000,    0x00000000_00000000,    false,  false,      true),
            (0x10000000_00000000,   0x00000000_00000000,    0x00000000_00000000,    0x10000000_00000000,    false,  false,      true),
            (0x00000000_00000000,   0x10000000_00000000,    0x00000000_00000001,    0x00000000_00000000,    false,  true,       false),
            (-1,   0x00000000_00000000,    -1,    0x00000000_00000000,    true,   false,      false),
        ]

        for test in testData {
            let lhs = Int128(hiBits: test.0, loBits: test.1)
            let rhs = Int128(hiBits: test.2, loBits: test.3)
            let (equal, lessThan, greaterThan) = (test.4, test.5, test.6)

            if equal {
                XCTAssertEqual(lhs, rhs)
            } else {
                XCTAssertNotEqual(lhs, rhs)
            }

            if lessThan {
                XCTAssertLessThan(lhs, rhs)
                XCTAssertGreaterThanOrEqual(rhs, lhs)
            }

            if greaterThan {
                XCTAssertGreaterThan(lhs, rhs)
                XCTAssertLessThanOrEqual(rhs, lhs)
            }
        }
    }

    func testArithmeticOperators() {
    }

    func testBitOperators() {
        let testData: [(UInt64, UInt64, UInt64, UInt64, (Int128, Int128) -> Int128, UInt64, UInt64, (inout Int128, Int128) -> ())] = [
            (0xaaaaaaaa_aaaaaaaa,   0x55555555_55555555,    0x55555555_55555555,    0xaaaaaaaa_aaaaaaaa, { $0 | $1 },   0xffffffff_ffffffff,    0xffffffff_ffffffff, { $0 |= $1 }),
            (0xaaaaaaaa_aaaaaaaa,   0x00000000_00000000,    0x00000000_00000000,    0x55555555_55555555, { $0 | $1 },   0xaaaaaaaa_aaaaaaaa,    0x55555555_55555555, { $0 |= $1 }),

            (0xaaaaaaaa_aaaaaaaa,   0x55555555_55555555,    0x55555555_55555555,    0xaaaaaaaa_aaaaaaaa, { $0 & $1 },   0x00000000_00000000,    0x00000000_00000000, { $0 &= $1 }),
            (0xaaaaaaaa_aaaaaaaa,   0x00000000_00000000,    0x00000000_00000000,    0x55555555_55555555, { $0 & $1 },   0x00000000_00000000,    0x00000000_00000000, { $0 &= $1 }),
            (0xaaaaaaaa_aaaaaaaa,   0x00000000_00000000,    0xffffffff_ffffffff,    0xffffffff_ffffffff, { $0 & $1 },   0xaaaaaaaa_aaaaaaaa,    0x00000000_00000000, { $0 &= $1 }),

            (0xaaaaaaaa_aaaaaaaa,   0x55555555_55555555,    0x55555555_55555555,    0xaaaaaaaa_aaaaaaaa, { $0 ^ $1 },   0xffffffff_ffffffff,    0xffffffff_ffffffff, { $0 ^= $1 }),
            (0xaaaaaaaa_aaaaaaaa,   0x00000000_00000000,    0x00000000_00000000,    0x55555555_55555555, { $0 ^ $1 },   0xaaaaaaaa_aaaaaaaa,    0x55555555_55555555, { $0 ^= $1 }),
            (0xaaaaaaaa_aaaaaaaa,   0xffffffff_ffffffff,    0xffffffff_ffffffff,    0x55555555_55555555, { $0 ^ $1 },   0x55555555_55555555,    0xaaaaaaaa_aaaaaaaa, { $0 ^= $1 }),
        ]

        for data in testData {
            let number1 = Int128(hiBits: Int64(bitPattern: data.0), loBits: data.1)
            let number2 = Int128(hiBits: Int64(bitPattern: data.2), loBits: data.3)
            let op = data.4
            let result = op(number1, number2)

            XCTAssertEqual(result.hiBits, Int64(bitPattern: data.5))
            XCTAssertEqual(result.loBits, data.6)
            let check = Int128(hiBits: Int64(bitPattern: data.5), loBits: data.6)
            XCTAssertEqual(check, result)
            let op2 = data.7
            var result2 = number1
            op2(&result2, number2)
            XCTAssertEqual(result2.hiBits, Int64(bitPattern: data.5))
            XCTAssertEqual(result2.loBits, data.6)

        }

        // Test ~ (Invert) Operator

        let testInvertData: [(UInt64, UInt64, UInt64, UInt64)] = [
            (0xaaaaaaaa_aaaaaaaa,   0x55555555_55555555,    0x55555555_55555555,    0xaaaaaaaa_aaaaaaaa),
            (0xaaaaaaaa_aaaaaaaa,   0x00000000_00000000,    0x55555555_55555555,    0xffffffff_ffffffff),
            (0xaaaaaaaa_aaaaaaaa,   0x55555555_55555555,    0x55555555_55555555,    0xaaaaaaaa_aaaaaaaa),
            (0x00000000_00000000,   0x00000000_00000000,    0xffffffff_ffffffff,    0xffffffff_ffffffff),
            (0x10000008_80000001,   0x81000000_00000018,    0xeffffff7_7ffffffe,    0x7effffff_ffffffe7),
        ]

        for data in testInvertData {
            let number1 = Int128(hiBits: Int64(bitPattern: data.0), loBits: data.1)
            let result = ~number1

            XCTAssertEqual(result.hiBits, Int64(bitPattern: data.2), "\(asHex(UInt64(bitPattern: result.hiBits))) != \(asHex(data.2))")
            XCTAssertEqual(result.loBits, data.3, "\(asHex(result.loBits)) != \(asHex(data.3))")
        }
    }

    func testShifts() {
    }

    func testWords() {

        if  UInt64.bitWidth == UInt.bitWidth {
            XCTAssertEqual(Int128.zero.words.count, 2)
        } else {
            XCTAssertEqual(Int128.zero.words.count, 4)
        }

        let testData: [(UInt64, UInt64)] = [
            (0x12345678,    0x90abcdef),
            (UInt64.max,    UInt64.min),
            (UInt64.min,    UInt64.max),
        ]

        for data in testData {
            let number = Int128(data.0) << 64 | Int128(data.1)

            var dataWords: [UInt] = []
            for word in data.1.words { dataWords.append(word) }
            for word in data.0.words { dataWords.append(word) }
            XCTAssertEqual(number.words.count, dataWords.count)
            for index in number.words.startIndex..<number.words.endIndex {
                XCTAssertEqual(number.words[index], dataWords[index])
            }
        }
    }


    static var allTests = [
        ("testInit", testInit),
        ("testBitCounts", testBitCounts),
        ("testByteSwapped", testByteSwapped),
        ("testStrings", testStrings),
        ("testMiscProperties", testMiscProperties),
        ("testAddition", testAddition),
        ("testSubtraction", testSubtraction),
        ("testMultiplication", testMultiplication),
 //       ("testDivision", testDivision),
        ("testEqualityOperators", testEqualityOperators),
        ("testArithmeticOperators", testArithmeticOperators),
        ("testBitOperators", testBitOperators),
        ("testBitShifts", testShifts),
        ("testWords", testWords),
    ]
}
