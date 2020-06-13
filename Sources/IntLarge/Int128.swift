//
//  Int128.swift
//  IntLarge
//
//  Created by Simon Evans on 06/06/2022.
//  Copyright (c) 2019 - 2020 Simon Evans
//
//  Implementation of Int128.
//

public struct Int128: FixedWidthInteger, SignedInteger {

    public typealias IntegerLiteralType = Int64
    public typealias Magnitude = UInt128
    internal typealias HiSubPart = Int64
    internal typealias LoSubPart = UInt64

    internal let hiBits: HiSubPart
    internal let loBits: LoSubPart

    internal static var negativeOne: Self { Self(hiBits: -1, loBits: LoSubPart.max) }
    internal static var positiveOne: Self { Self(hiBits: 0, loBits: 1) }

    public static var bitWidth: Int { 128 }
    public static var zero: Self { Self(hiBits: 0, loBits: 0) }

    public static var min: Self { Self(hiBits: HiSubPart.min, loBits: 0) }
    public static var max: Self { Self(hiBits: HiSubPart.max, loBits: LoSubPart.max) }


    public init(integerLiteral value: Int64) {
        if value.signum() == -1 {
            loBits = value.magnitude
            hiBits = 0
            self.negate()
        } else {
            loBits = LoSubPart(value)
            hiBits = 0
        }
    }

    public init(_truncatingBits bits: UInt) {
        self.loBits = LoSubPart(bits)
        self.hiBits = 0
    }

    public init(bitPattern value: UInt128) {
        self.loBits = LoSubPart(value.loBits)
        self.hiBits = HiSubPart(bitPattern: value.hiBits)
    }

    public init?(_ description: String) {
        self.init(description, radix: 10)
    }


    public init?<S>(_ text: S, radix: Int = 10) where S: StringProtocol {
        precondition(2...36 ~= radix, "Invalid radix")

        // Skip optional initial '-' / '+'
        let negate = text.hasPrefix("-")
        let index = text.hasPrefix("+") || text.hasPrefix("-") ? text.index(after: text.startIndex) : text.startIndex

        guard index < text.endIndex else { return nil }
        let radixMultiplier = Self(_truncatingBits: UInt(radix))
        let zeroCh = UInt8(ascii: "0")
        let aCh = UInt8(ascii: "a")
        let ACh = UInt8(ascii: "A")

        var value = Self.zero
        for char in text[index...] {
            guard let digit = char.asciiValue else { return nil }
            let (result, overflow) = value.multipliedReportingOverflow(by: radixMultiplier)
            guard !overflow else { return nil }
            value = result

            var tmp = 0
            switch digit {
                case zeroCh...UInt8(ascii: "9"):
                    tmp = Int(digit - zeroCh)

                case aCh...UInt8(ascii: "z"):
                    tmp = Int(digit - aCh) + 10

                case ACh...UInt8(ascii: "Z"):
                    tmp = Int(digit - ACh) + 10

                default:
                    return nil
            }
            guard tmp < radix else { return nil }
            value += Self(hiBits: 0, loBits: LoSubPart(tmp))
        }
        self = negate ? 0 - value : value
    }

    internal init(hiBits: HiSubPart, loBits: LoSubPart) {
        self.hiBits = hiBits
        self.loBits = loBits
    }

    private init(value: Int) {
        precondition(value >= 0)
        self.hiBits = 0
        self.loBits = LoSubPart(value)
    }

    internal init(bit: Int) {
        precondition(bit >= 0 && bit < Self.bitWidth)
        if bit < LoSubPart.bitWidth {
            self.hiBits = 0
            self.loBits = LoSubPart(1) << LoSubPart(bit)
        } else {
            self.hiBits = HiSubPart(1) << HiSubPart(bit - HiSubPart.bitWidth)
            self.loBits = 0
        }
    }

    internal var isZero: Bool { (loBits != 0 || hiBits != 0) ? false : true }

    public var nonzeroBitCount: Int {
        loBits.nonzeroBitCount + hiBits.nonzeroBitCount
    }

    public var leadingZeroBitCount: Int {
        if hiBits == 0 {
            return hiBits.bitWidth + loBits.leadingZeroBitCount
        } else {
            return hiBits.leadingZeroBitCount
        }
    }

    public var trailingZeroBitCount: Int {
        if loBits == 0 {
            return hiBits.trailingZeroBitCount + loBits.bitWidth
        } else {
            return loBits.trailingZeroBitCount
        }
    }

    public var byteSwapped: Self {
        Self(hiBits: HiSubPart(bitPattern: loBits.byteSwapped), loBits: LoSubPart(bitPattern: hiBits.byteSwapped))
    }

    public var magnitude: UInt128 {
        if self == Self.min { return UInt128(bitPattern: Int128.max) + 1 }

        var value = self
        if hiBits.signum() == -1 {
            value.negate()
        }

        return UInt128(hiBits: UInt64(value.hiBits), loBits: value.loBits)
    }

    public var signum: Self {
        if hiBits < 0 { return  Int128.negativeOne }
        else if self.isZero { return Int128.zero }
        else { return Int128.positiveOne }
    }

    public func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let (newLoBits, carry) = loBits.addingReportingOverflow(rhs.loBits)
        var (newHiBits, overflow) = hiBits.addingReportingOverflow(rhs.hiBits)
        if carry {
            var overflow2 = false
            (newHiBits, overflow2) = newHiBits.addingReportingOverflow(1)
            overflow = overflow || overflow2
        }
        return (Self(hiBits: newHiBits, loBits: newLoBits), overflow)
    }

    public func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        var (low, overflow) = self.loBits.subtractingReportingOverflow(rhs.loBits)
        var high = self.hiBits
        var overflow2 = false

        if overflow {
            (high, overflow) = high.subtractingReportingOverflow(1)
        }
        (high, overflow2) = high.subtractingReportingOverflow(rhs.hiBits)

        return (Self(hiBits: high, loBits: low), overflow || overflow2)
    }

    public func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let (high, low) = multipliedFullWidth(by: rhs)
        // Check for overflow by testing the high bit of the low result has been sign extended into the high result.
        var overflow = false
        let partialValue = Self(bitPattern: low)
        if partialValue.hiBits < 0 {
            overflow = (high != Self.negativeOne)
        } else {
            overflow = (high != Self.zero)
        }
        return (partialValue, overflow)
    }

    private func checkForNegative(_ lhs: Int128, _ rhs: Int128) -> (UInt128, UInt128, Bool) {
        var negateResult = false

        if lhs.signum < 0 {
            negateResult.toggle()
        }

        if rhs.signum < 0 {
            negateResult.toggle()
        }
        return (lhs.magnitude, rhs.magnitude, negateResult)
    }

    private func negateFullWidth(high: UInt128, low: UInt128) -> (high: Self, low: Self.Magnitude) {
        // negate a UInt128 to a Int128 converting using 2s complement
        var low = ~low
        var high = ~high

        var overflow = false
        (low, overflow) = low.addingReportingOverflow(Self.Magnitude(1))
        if overflow {
            (high, overflow) = high.addingReportingOverflow(UInt128(1))
            precondition(!overflow)
        }
        return (Int128(bitPattern: high), low)
    }

    public func multipliedFullWidth(by other: Self) -> (high: Self, low: Self.Magnitude) {
        if self.isZero || other.isZero { return (high: Self.zero, low: Self.Magnitude.zero) }

        // multiply the magnitudes of lhs, rhs as UInt128 -> UInt128 result, negagte the result if one of lhs/rhs was negative.
        let (lhs, rhs, negateResult) = checkForNegative(self, other)
        let (high, low) = lhs.multipliedFullWidth(by: rhs)
        if negateResult {
            return negateFullWidth(high: high, low: low)
        } else {
            return (Int128(bitPattern: high), low)
        }
    }

    public func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Self, remainder: Self) {
        // Run some basic checks

        guard !rhs.isZero else { fatalError("Division by zero") }
        guard !self.isZero else { return (.zero, .zero) }
        guard self >= rhs else { return (.zero, self) }

        if rhs.nonzeroBitCount == 1 {
            // Division by power of 2
            let tzbc = rhs.trailingZeroBitCount
            if tzbc == 0 {
                // Division by 1
                return (self, .zero)
            }
            let quotient = self >> Self(value: tzbc)
            let remainder = self & (rhs - 1)
            return (quotient, remainder)
        }

        var quotient = Self.zero
        var remainder = self
        let dlz = rhs.leadingZeroBitCount

        while remainder >= rhs {
            let rlz = remainder.leadingZeroBitCount
            var divisor = rhs
            let shift: Int
            if rlz < dlz {
                shift = (dlz - rlz) - 1
                divisor <<= shift
            } else {
                shift = 0
            }

            let multiple = Self(bit: shift) // The multiple of the divisor that are subtrated in each loop
            while remainder >= divisor {
                remainder -= divisor
                quotient += multiple
            }
        }
        return (quotient, remainder)
    }

    public func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.isZero { return (self, true) }
        let (quotient, _) = self.quotientAndRemainder(dividingBy: rhs)
        return (quotient, false)
    }

    public func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.isZero { return (self, true) }
        let (_, remainder) = self.quotientAndRemainder(dividingBy: rhs)
        return (remainder, false)
    }

    public func dividingFullWidth(_ dividend: (high: Self, low: Self.Magnitude)) -> (quotient: Self, remainder: Self) {
        fatalError("Operation is not supported")
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        let equal = (lhs.loBits == rhs.loBits) && (lhs.hiBits == rhs.hiBits)
        return equal
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let lessThan = (lhs.hiBits < rhs.hiBits) || (lhs.hiBits == rhs.hiBits) && (lhs.loBits < rhs.loBits)
        return lessThan
    }

    mutating public func negate() {
        self = 0 - self
    }

    // Operators
    public static func + (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        if overflow {
            fatalError("Self adding overflow")
        }

        return result
    }

    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.subtractingReportingOverflow(rhs)
        guard !overflow else { fatalError("results in an overflow") }
        return result
    }

    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        guard !overflow else { fatalError("Overflow in multiplication") }
        return result
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    public static func / (lhs: Self, rhs: Self) -> Self {
        let (quotient, _) = lhs.quotientAndRemainder(dividingBy: rhs)
        return quotient
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    public static func % (lhs: Self, rhs: Self) -> Self {
        let (_, remainder) = lhs.quotientAndRemainder(dividingBy: rhs)
        return remainder
    }

    public static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }

    public static func & (lhs: Self, rhs: Self) -> Self {
        return Self(hiBits: lhs.hiBits & rhs.hiBits, loBits: lhs.loBits & rhs.loBits)
    }

    public static func &= (lhs: inout Self, rhs: Self) {
        lhs = lhs & rhs
    }

    public static func | (lhs: Self, rhs: Self) -> Self {
        return Self(hiBits: lhs.hiBits | rhs.hiBits, loBits: lhs.loBits | rhs.loBits)
    }

    public static func |= (lhs: inout Self, rhs: Self) {
        lhs = lhs | rhs
    }

    public static func ^ (lhs: Self, rhs: Self) -> Self {
        return Self(hiBits: lhs.hiBits ^ rhs.hiBits, loBits: lhs.loBits ^ rhs.loBits)
    }

    public static func ^= (lhs: inout Self, rhs: Self) {
        lhs = lhs ^ rhs
    }

    public static func >> (lhs: Self, rhs: Self) -> Self {
        let shift = rhs.loBits
        let subPartBitWidth = LoSubPart(LoSubPart.bitWidth)

        if (rhs.hiBits > 0) || (shift > LoSubPart(bitWidth)) { return Self.zero }
        if rhs.isZero { return lhs }

        if shift > subPartBitWidth {
            let loBits = lhs.hiBits >> (shift - subPartBitWidth)
            return Self(hiBits: 0, loBits: LoSubPart(bitPattern: loBits))
        } else {
            var loBits = lhs.loBits >> shift
            loBits |= LoSubPart(bitPattern: lhs.hiBits << (subPartBitWidth - shift))
            let hiBits = lhs.hiBits >> shift
            return Self(hiBits: hiBits, loBits: loBits)
        }
    }

    public static func >>= (lhs: inout Self, rhs: Int) {
        lhs = lhs >> rhs
    }

    public static func &>> (lhs: Self, rhs: Self) -> Self {
        var rhs = rhs
        if (rhs.hiBits > 0) || (rhs.loBits > LoSubPart(bitWidth)) {
            rhs = Self(hiBits: 0, loBits: rhs.loBits & LoSubPart(bitWidth - 1))
        }
        return lhs >> rhs
    }

    public static func &>>= (lhs: inout Self, rhs: Int) {
        lhs = lhs >> rhs
    }

    public static func << (lhs: Self, rhs: Self) -> Self {
        let shift = rhs.loBits
        let subPartBitWidth = LoSubPart(LoSubPart.bitWidth)

        if (rhs.hiBits > 0) || (shift > LoSubPart(bitWidth)) { return Self.zero }
        if rhs.isZero { return lhs }

        if shift > subPartBitWidth {
            let hiBits = lhs.loBits << (shift - subPartBitWidth)
            return Self(hiBits: HiSubPart(bitPattern: hiBits), loBits: 0)
        } else {
            var hiBits = lhs.hiBits << shift
            hiBits |= HiSubPart(bitPattern: lhs.loBits >> (subPartBitWidth - shift))
            let loBits = lhs.loBits << shift
            return Self(hiBits: hiBits, loBits: loBits)
        }
    }

    public static func <<= (lhs: inout Self, rhs: Int) {
        lhs = lhs << rhs
    }

    public static func &<< (lhs: Self, rhs: Self) -> Self {
        var rhs = rhs
        if (rhs.hiBits > 0 ) || (rhs.loBits > LoSubPart(bitWidth)) {
            rhs = Self(hiBits: 0, loBits: rhs.loBits & LoSubPart(bitWidth - 1))
        }
        return lhs << rhs
    }

    public static func &<<= (lhs: inout Self, rhs: Int) {
        lhs = lhs &<< rhs
    }

    public prefix static func ~ (value: Self) -> Self {
        Self(hiBits: ~value.hiBits, loBits: ~value.loBits)
    }

    public struct Words: RandomAccessCollection {
        public typealias Indices = Range<Int>
        public typealias SubSequence = Slice<UInt128.Words>

        @usableFromInline
        internal var value: Int128

        @inlinable
        public init(_ value: Int128) {
            self.value = value
        }

        @inlinable
        public var count: Int {
            return value.bitWidth / UInt.bitWidth
        }

        @inlinable
        public var startIndex: Int { return 0 }

        @inlinable
        public var endIndex: Int { return count }

        @inlinable
        public var indices: Indices { return startIndex ..< endIndex }

        @_transparent
        public func index(after index: Int) -> Int { return index + 1 }

        @_transparent
        public func index(before index: Int) -> Int { return index - 1 }

        public subscript(position: Int) -> UInt {
            precondition(position >= 0, "Negative word index")
            precondition(position < endIndex, "Word index out of range")

            let wordsPerPart = (LoSubPart.bitWidth / UInt.bitWidth)
            // 64bit, 0: 0[0]  1: 1[0]
            // 32Bit, 0: 0[0]  1: 0[1]  2: 1[0]  3: 1[1]
            let subPart = position / wordsPerPart
            let index = position % wordsPerPart

            switch subPart {
                case 0: return value.loBits.words[index]
                case 1: return value.hiBits.words[index]
                default: fatalError("Invalid index")
            }
        }
    }

    public var words: Words {
        Words(self)
    }
}


extension Int {
    init?(exactly value: Int128) {

        if value.hiBits == 0, let result = Int(exactly: value.loBits), result >= 0 {
            self = result
        } else if value.hiBits == -1, let result = Int(exactly: value.loBits), result < 0 {
            self = result
        } else {
            return nil
        }
    }
}


extension UInt {
    init?(exactly value: Int128) {
        guard value.hiBits == 0, let result = UInt(exactly: value.loBits) else { return nil }
        self = result
    }
}
