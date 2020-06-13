import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(UInt128Tests.allTests),
        testCase(Int128Tests.allTests),
    ]
}
#endif
