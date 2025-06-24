//
//  Logger.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 20.07.2022.
//

import Foundation


@objc(BDNLogger)
public class Logger: NSObject {
    @objc(BDNLoggerLevel)
    public enum Level: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
        case off = 5
    }

    @objc(BDNLoggerFormat)
    public enum Format: Int {
        case short = 0
        case full = 1
    }

    private static var destinations: Set<AnyLogDestination> = {
        let oslog = OSLogDestination()
        let any = AnyLogDestination(oslog)
        return Set([any])
    }()

    private static let queue = DispatchQueue(label: "com.bidon.logger.queue")

    static func add(_ destination: LogDestination) {
        let any = AnyLogDestination(destination)
        destinations.insert(any)
    }

    @objc public static var level: Level = .off
    @objc public static var format: Format = .short

    public static func verbose(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        send(
            level: .verbose,
            message: message(),
            file: file,
            function: function,
            line: line
        )
    }

    public static func debug(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        send(
            level: .debug,
            message: message(),
            file: file,
            function: function,
            line: line
        )
    }

    public static func info(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        send(
            level: .info,
            message: message(),
            file: file,
            function: function,
            line: line
        )
    }

    public static func warning(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        send(
            level: .warning,
            message: message(),
            file: file,
            function: function,
            line: line
        )
    }

    public static func error(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        send(
            level: .error,
            message: message(),
            file: file,
            function: function,
            line: line
        )
    }

    private static func send(
        level: Logger.Level,
        message: @autoclosure () -> Any,
        file: String,
        function: String,
        line: Int
    ) {
        guard self.level.rawValue <= level.rawValue else { return }
        let resolved = message()

        queue.async {
            _send(
                level: level,
                message: resolved,
                file: file,
                function: function,
                line: line
            )
        }
    }

    private static func _send(
        level: Logger.Level,
        message: Any,
        file: String,
        function: String,
        line: Int
    ) {
        let message = LogFormatter(
            format: format,
            level: level,
            message: message,
            file: file,
            function: function,
            line: line
        ).formatted()

        destinations.forEach { $0.send(level: level, message) }
    }
}
