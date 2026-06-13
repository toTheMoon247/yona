//
//  URLHelpersTests.swift
//  YonaTests
//

import Testing
@testable import Yona

struct URLHelpersTests {

    // MARK: - normalized

    @Test func prependsHTTPSWhenSchemeMissing() {
        #expect(URLHelpers.normalized("netflix.com") == "https://netflix.com")
        #expect(URLHelpers.normalized("www.netflix.com/browse") == "https://www.netflix.com/browse")
    }

    @Test func keepsExistingScheme() {
        #expect(URLHelpers.normalized("https://netflix.com") == "https://netflix.com")
        #expect(URLHelpers.normalized("http://example.com") == "http://example.com")
    }

    @Test func trimsWhitespace() {
        #expect(URLHelpers.normalized("  netflix.com  ") == "https://netflix.com")
        #expect(URLHelpers.normalized("") == "")
    }

    // MARK: - domain

    @Test func extractsDomainStrippingWWWAndPath() {
        #expect(URLHelpers.domain(from: "https://www.netflix.com/browse") == "netflix.com")
        #expect(URLHelpers.domain(from: "netflix.com") == "netflix.com")
        #expect(URLHelpers.domain(from: "https://github.com/toTheMoon247/yona") == "github.com")
    }

    @Test func lowercasesAndKeepsSubdomains() {
        #expect(URLHelpers.domain(from: "https://AppleID.apple.com") == "appleid.apple.com")
        #expect(URLHelpers.domain(from: "https://bankleumi.co.il") == "bankleumi.co.il")
    }

    @Test func returnsNilForUnparseableInput() {
        #expect(URLHelpers.domain(from: "") == nil)
    }
}
