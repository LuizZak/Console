import Foundation

/// Protocol to be implemented by objects that lazily feed data to a console
/// output routine.
/// This can be used to reduce data-to-string overheads on very large data sets.
public protocol ConsoleDataProvider {

    /// Gets the number of items contained within this console data provider
    var count: Int { get }

    /// Gets a header to be displayed just above the items list page
    var header: String { get }

    /// Gets the display titles for the columns contained on top of a given index
    /// of this console data provider
    func displayTitles(forRow row: Int) -> [CustomStringConvertible]
}

/// A basic wrapper on top of a console data provider, which feeds data based on
/// a custom closure
public class AnyConsoleDataProvider: ConsoleDataProvider {

    public let count: Int
    public let header: String
    public let generator: (Int) -> [CustomStringConvertible]

    /// Creates a basic generic data provider over a known index count and
    /// external generator
    public init(count: Int, header: String, generator: @escaping (Int) -> [CustomStringConvertible]) {
        self.count = count
        self.header = header
        self.generator = generator
    }

    public func displayTitles(forRow row: Int) -> [CustomStringConvertible] {
        return generator(row)
    }
}

/// A console data provider that wraps over an array of static elements
public class ArrayConsoleDataProvider: ConsoleDataProvider {

    var rows: [[CustomStringConvertible]]

    /// Gets the number of items contained within this console data provider
    public var count: Int {
        return rows.count
    }

    /// Gets a header to be displayed just above the items list page
    public var header: String

    public init(header: String, items: [CustomStringConvertible]) {
        self.rows = items.map { [$0] }
        self.header = header
    }

    public init(header: String, rows: [[CustomStringConvertible]]) {
        self.rows = rows
        self.header = header
    }

    /// Gets the display titles for the columns contained on top of a given index
    /// of this console data provider
    public func displayTitles(forRow row: Int) -> [CustomStringConvertible] {
        return rows[row]
    }
}
