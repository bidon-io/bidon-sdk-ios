//
//  LogFormatter.swift
//  MobileAdvertising
//
//  Created by Bidon Team on 20.07.2022.
//

import Foundation


struct LogFormatter {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()


    var format: Logger.Format
    var level: Logger.Level
    var message: Any
    var file: String
    var function: String
    var line: Int
    var date: String = dateFormatter.string(from: Date())

    func formatted() -> String {
        switch format {
        case .full:
#if DEBUG
            return String(format: "%@ [Bidon] [%@] [Function: %@] [File: %@] [Line: %d] %@", date, level.stringValue, function, file, line, "\(message)")
#else
            return String(format: "%@ [Bidon] [%@] %@", date, level.stringValue, "\(message)")
#endif
        case .short:
            return String(format: "[Bidon] [%@] %@", level.stringValue, "\(message)")
        }
    }
}


extension Logger.Level {
    var stringValue: String {
        switch self {
        case .verbose: return "Verbose"
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .off: return ""
        }
    }
}
