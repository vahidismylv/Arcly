import Foundation

nonisolated struct ArcJSONStorage: Sendable {
    enum File: String {
        case fasts
        case schedule
        case weight
        case preferences
    }

    private let directory: URL
    private let writeQueue = DispatchQueue(label: "com.arcly.storage", qos: .utility)

    init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // A missing or corrupted file yields nil so the caller can fall back to defaults instead of crashing.
    func load<Value: Decodable>(_ type: Value.Type, from file: File) -> Value? {
        guard let data = try? Data(contentsOf: url(for: file)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func save<Value: Encodable>(_ value: Value, to file: File) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let url = url(for: file)
        writeQueue.async {
            try? data.write(to: url, options: .atomic)
        }
    }

    func waitForPendingWrites() {
        writeQueue.sync {}
    }

    private func url(for file: File) -> URL {
        directory.appending(path: "\(file.rawValue).json")
    }
}
