//
//  XCTest+Extensions.swift
//  Tests-Swift
//
//  Created by Stas Kochkin on 07.12.2023.
//

import Foundation
import XCTest


func XCTAssertNotZero<T: Numeric>(
    _ expression: @autoclosure () throws -> T?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertNotNil(try expression(), message(), file: file, line: line)
    XCTAssertNotEqual(try expression(), 0, message(), file: file, line: line)
}
