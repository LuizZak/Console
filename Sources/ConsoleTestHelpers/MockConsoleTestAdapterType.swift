/// Adapter for test assertions raised by `MockConsole`
public protocol MockConsoleTestAdapterType {
    func recordTestFailure(_ message: String, file: StaticString, line: UInt)
}
