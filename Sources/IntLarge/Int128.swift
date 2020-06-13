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

    internal let _hiBits: HiSubPart
    internal let _loBits: LoSubPart

    internal static var negativeOne: Self { Self(_hiBits: -1, _loBits: LoSubPart.max) }
    internal static var positiveOne: Self { Self(_hiBits: 0, _loBits: 1) }

    public static var bitWidth: Int { 128 }
    public static var zero: Self { Self(_hiBits: 0, _loBits: 0) }

    public static var min: Self { Self(_hiBits: HiSubPart.min, _loBits: 0) }
    public static var max: Self { Self(_hiBits: HiSubPart.max, _loBits: LoSubPart.max) }


    public init(integerLiteral value: Int64) {
        if value.signum() == -1 {
            _loBits = value.magnitude
            _hiBits = 0
            self.negate()
        } else {
            _loBits = LoSubPart(value)
            _hiBits = 0
        }
    }

    public init(_truncatingBits bits: UInt) {
        self._loBits = LoSubPart(bits)
        self._hiBits = 0
    }

    public init(bitPattern x: UInt128) {
        self._loBits = LoSubPart(x._loBits)
        self._hiBits = HiSubPart(bitPattern: x._hiBits)
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
        let _radix = Self(_truncatingBits: UInt(radix))
        let zeroCh = UInt8(ascii: "0")
        let aCh = UInt8(ascii: "a")
        let ACh = UInt8(ascii: "A")

        var value = Self.zero
        for ch in text[index...] {
            guard let ch = ch.asciiValue else { return nil }
            let (result, overflow) = value.multipliedReportingOverflow(by: _radix)
            guard !overflow else { return nil }
            value = result

            var tmp = 0
            switch ch {
                case zeroCh...UInt8(ascii: "9"):
                    tmp = Int(ch - zeroCh)

                case aCh...UInt8(ascii: "z"):
                    tmp = Int(ch - aCh) + 10

                case ACh...UInt8(ascii: "Z"):
                    tmp = Int(ch - ACh) + 10

                default:
                    return nil
            }
            guard tmp < radix else { return nil }
            value += Self(_hiBits: 0, _loBits: LoSubPart(tmp))
        }
        self = negate ? 0 - value : value
    }

    internal init(_hiBits: HiSubPart, _loBits: LoSubPart) {
        self._hiBits = _hiBits
        self._loBits = _loBits
    }

    private init(value: Int) {
        precondition(value >= 0)
        self._hiBits = 0
        self._loBits = LoSubPart(value)
    }

    internal init(bit: Int) {
        precondition(bit >= 0 && bit < Self.bitWidth)
        if bit < LoSubPart.bitWidth {
            self._hiBits = 0
            self._loBits = LoSubPart(1) << LoSubPart(bit)
        } else {
            self._hiBits = HiSubPart(1) << HiSubPart(bit - HiSubPart.bitWidth)
            self._loBits = 0
        }
    }

    internal var isZero: Bool { (_loBits != 0 || _hiBits != 0) ? false : true }

    public var nonzeroBitCount: Int {
        _loBits.nonzeroBitCount + _hiBits.nonzeroBitCount
    }

    public var leadingZeroBitCount: Int {
        if _hiBits == 0 {
            return _hiBits.bitWidth + _loBits.leadingZeroBitCount
        } else {
            return _hiBits.leadingZeroBitCount
        }
    }

    public var trailingZeroBitCount: Int {
        if _loBits == 0 {
            return _hiBits.trailingZeroBitCount + _loBits.bitWidth
        } else {
            return _loBits.trailingZeroBitCount
        }
    }

    public var byteSwapped: Self {
        Self(_hiBits: HiSubPart(bitPattern: _loBits.byteSwapped), _loBits: LoSubPart(bitPattern: _hiBits.byteSwapped))
    }

    public var magnitude: UInt128 {
        if self == Self.min { return UInt128(bitPattern: Int128.max) + 1 }

        var value = self
        if _hiBits.signum() == -1 {
            value.negate()
        }

        return UInt128(_hiBits: UInt64(value._hiBits), _loBits: value._loBits)
    }

    public var signum: Self {
        if _hiBits < 0 { return  Int128.negativeOne }
        else if self.isZero { return Int128.zero }
        else { return Int128.positiveOne }
    }

    public func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let (loBits, carry) = _loBits.addingReportingOverflow(rhs._loBits)
        var (hiBits, overflow) = _hiBits.addingReportingOverflow(rhs._hiBits)
        if carry {
            var overflow2 = false
            (hiBits, overflow2) = hiBits.addingReportingOverflow(1)
            overflow = overflow || overflow2
        }
        return (Self(_hiBits: hiBits, _loBits: loBits), overflow)
    }

    public func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        var (_lo, overflow) = self._loBits.subtractingReportingOverflow(rhs._loBits)
        var _hi = self._hiBits
        var overflow2 = false

        if overflow {
            (_hi, overflow) = _hi.subtractingReportingOverflow(1)
        }
        (_hi, overflow2) = _hi.subtractingReportingOverflow(rhs._hiBits)

        return (Self(_hiBits: _hi, _loBits: _lo), overflow || overflow2)
    }

    public func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let (high, low) = multipliedFullWidth(by: rhs)
        // Check for overflow by testing the high bit of the low result has been sign extended into the high result.
        var overflow = false
        let partialValue = Self(bitPattern: low)
        if partialValue._hiBits < 0 {
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
        var _low = ~low
        var _high = ~high

        var overflow = false
        (_low, overflow) = _low.addingReportingOverflow(Self.Magnitude(1))
        if overflow {
            (_high, overflow) = _high.addingReportingOverflow(UInt128(1))
            precondition(!overflow)
        }
        return (Int128(bitPattern: _high), _low)
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

            let m = Self(bit: shift)
            while remainder >= divisor {
                remainder -= divisor
                quotient += m
            }
        }
        return (quotient, remainder)
    }

    public func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.isZero { return (self, true) }
        let (q, _) = self.quotientAndRemainder(dividingBy: rhs)
        return (q, false)
    }

    public func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.isZero { return (self, true) }
        let (_, r) = self.quotientAndRemainder(dividingBy: rhs)
        return (r, false)
    }

    public func dividingFullWidth(_ dividend: (high: Self, low: Self.Magnitude)) -> (quotient: Self, remainder: Self) {
        fatalError("Operation is not supported")
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        let equal = (lhs._loBits == rhs._loBits) && (lhs._hiBits == rhs._hiBits)
        return equal
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let lessThan = (lhs._hiBits < rhs._hiBits) || (lhs._hiBits == rhs._hiBits) && (lhs._loBits < rhs._loBits)
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
        return Self(_hiBits: lhs._hiBits & rhs._hiBits, _loBits: lhs._loBits & rhs._loBits)
    }

    public static func &= (lhs: inout Self, rhs: Self) {
        lhs = lhs & rhs
    }

    public static func | (lhs: Self, rhs: Self) -> Self {
        return Self(_hiBits: lhs._hiBits | rhs._hiBits, _loBits: lhs._loBits | rhs._loBits)
    }

    public static func |= (lhs: inout Self, rhs: Self) {
        lhs = lhs | rhs
    }

    public static func ^ (lhs: Self, rhs: Self) -> Self {
        return Self(_hiBits: lhs._hiBits ^ rhs._hiBits, _loBits: lhs._loBits ^ rhs._loBits)
    }

    public static func ^= (lhs: inout Self, rhs: Self) {
        lhs = lhs ^ rhs
    }

    public static func >> (lhs: Self, rhs: Self) -> Self {
        let shift = rhs._loBits
        let _bitWidth = LoSubPart(bitWidth)
        let _subPartBitWidth = LoSubPart(LoSubPart.bitWidth)

        if (rhs._hiBits > 0) || (shift > _bitWidth) { return Self.zero }
        if rhs.isZero { return lhs }

        if shift > _subPartBitWidth {
            let loBits = lhs._hiBits >> (shift - _subPartBitWidth)
            return Self(_hiBits: 0, _loBits: LoSubPart(bitPattern: loBits))
        } else {
            var loBits = lhs._loBits >> shift
            loBits |= LoSubPart(bitPattern: lhs._hiBits << (_subPartBitWidth - shift))
            let hiBits = lhs._hiBits >> shift
            return Self(_hiBits: hiBits, _loBits: loBits)
        }
    }

    public static func >>= (lhs: inout Self, rhs: Int) {
        lhs = lhs >> rhs
    }

    public static func &>> (lhs: Self, rhs: Self) -> Self {
        var rhs = rhs
        if (rhs._hiBits > 0) || (rhs._loBits > LoSubPart(bitWidth)) {
            rhs = Self(_hiBits: 0, _loBits: rhs._loBits & LoSubPart(bitWidth - 1))
        }
        return lhs >> rhs
    }

    public static func &>>= (lhs: inout Self, rhs: Int) {
        lhs = lhs >> rhs
    }

    public static func << (lhs: Self, rhs: Self) -> Self {
        let shift = rhs._loBits
        let _bitWidth = LoSubPart(bitWidth)
        let _subPartBitWidth = LoSubPart(LoSubPart.bitWidth)

        if (rhs._hiBits > 0) || (shift > _bitWidth) { return Self.zero }
        if rhs.isZero { return lhs }

        if shift > _subPartBitWidth {
            let hiBits = lhs._loBits << (shift - _subPartBitWidth)
            return Self(_hiBits: HiSubPart(bitPattern: hiBits), _loBits: 0)
        } else {
            var hiBits = lhs._hiBits << shift
            hiBits |= HiSubPart(bitPattern: lhs._loBits >> (_subPartBitWidth - shift))
            let loBits = lhs._loBits << shift
            return Self(_hiBits: hiBits, _loBits: loBits)
        }
    }

    public static func <<= (lhs: inout Self, rhs: Int) {
        lhs = lhs << rhs
    }

    public static func &<< (lhs: Self, rhs: Self) -> Self {
        var rhs = rhs
        if (rhs._hiBits > 0 ) || (rhs._loBits > LoSubPart(bitWidth)) {
            rhs = Self(_hiBits: 0, _loBits: rhs._loBits & LoSubPart(bitWidth - 1))
        }
        return lhs << rhs
    }

    public static func &<<= (lhs: inout Self, rhs: Int) {
        lhs = lhs &<< rhs
    }

    public prefix static func ~ (x: Self) -> Self {
        Self(_hiBits: ~x._hiBits, _loBits: ~x._loBits)
    }

    public struct Words: RandomAccessCollection {
        public typealias Indices = Range<Int>
        public typealias SubSequence = Slice<UInt128.Words>

        @usableFromInline
        internal var _value: Int128

        @inlinable
        public init(_ value: Int128) {
            self._value = value
        }

        @inlinable
        public var count: Int {
            return _value.bitWidth / UInt.bitWidth
        }

        @inlinable
        public var startIndex: Int { return 0 }

        @inlinable
        public var endIndex: Int { return count }

        @inlinable
        public var indices: Indices { return startIndex ..< endIndex }

        @_transparent
        public func index(after i: Int) -> Int { return i + 1 }

        @_transparent
        public func index(before i: Int) -> Int { return i - 1 }

        public subscript(position: Int) -> UInt {
            get {
                precondition(position >= 0, "Negative word index")
                precondition(position < endIndex, "Word index out of range")

                let wordsPerPart = (LoSubPart.bitWidth / UInt.bitWidth)
                // 64bit, 0: 0[0]  1: 1[0]
                // 32Bit, 0: 0[0]  1: 0[1]  2: 1[0]  3: 1[1]
                let subPart = position / wordsPerPart
                let index = position % wordsPerPart

                switch subPart {
                    case 0: return _value._loBits.words[index]
                    case 1: return _value._hiBits.words[index]
                    default: fatalError("Invalid index")
                }
            }
        }
    }

    public var words: Words {
        Words(self)
    }
}


extension Int {
    init?(exactly n: Int128) {

        if n._hiBits == 0, let x = Int(exactly: n._loBits), x >= 0 {
            self = x
        } else if n._hiBits == -1, let x = Int(exactly: n._loBits), x < 0 {
            self = x
        } else {
            return nil
        }
    }
}


extension UInt {
    init?(exactly n: Int128) {
        guard n._hiBits == 0, let x = UInt(exactly: n._loBits) else { return nil }
        self = x
    }
}
