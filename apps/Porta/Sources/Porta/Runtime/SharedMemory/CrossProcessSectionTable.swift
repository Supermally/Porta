import Foundation

public struct WindowsSectionDescriptor: Identifiable, Codable, Sendable {
    public let id: String
    public let sectionName: String
    public let sizeBytes: Int
    public let protectionMask: String
    public let creatorPID: Int32
    public let isAnonymous: Bool
    public let creationTimestamp: Date

    public init(
        id: String = UUID().uuidString,
        sectionName: String,
        sizeBytes: Int,
        protectionMask: String = "PAGE_READWRITE",
        creatorPID: Int32,
        isAnonymous: Bool = false,
        creationTimestamp: Date = Date()
    ) {
        self.id = id
        self.sectionName = sectionName
        self.sizeBytes = sizeBytes
        self.protectionMask = protectionMask
        self.creatorPID = creatorPID
        self.isAnonymous = isAnonymous
        self.creationTimestamp = creationTimestamp
    }
}

public final class CrossProcessSectionTable: ObservableObject, @unchecked Sendable {
    public static let shared = CrossProcessSectionTable()

    @Published public var registeredSections: [WindowsSectionDescriptor] = []
    private var sectionMap: [String: WindowsSectionDescriptor] = [:]
    private let lock = NSLock()

    public init() {}

    public func registerSection(name: String?, sizeBytes: Int, creatorPID: Int32, protection: String = "PAGE_READWRITE") -> WindowsSectionDescriptor {
        lock.lock()
        defer { lock.unlock() }

        let isAnon = (name == nil || name?.isEmpty == true)
        let resolvedName = isAnon ? "AnonymousSection_\(UUID().uuidString.prefix(8))" : (name ?? "")
        let descriptor = WindowsSectionDescriptor(
            sectionName: resolvedName,
            sizeBytes: sizeBytes,
            protectionMask: protection,
            creatorPID: creatorPID,
            isAnonymous: isAnon
        )

        sectionMap[resolvedName] = descriptor
        DispatchQueue.main.async {
            self.registeredSections = Array(self.sectionMap.values)
        }
        return descriptor
    }

    public func lookupSection(name: String) -> WindowsSectionDescriptor? {
        lock.lock()
        defer { lock.unlock() }
        return sectionMap[name]
    }

    public func unregisterSection(name: String) {
        lock.lock()
        defer { lock.unlock() }
        sectionMap.removeValue(forKey: name)
        DispatchQueue.main.async {
            self.registeredSections = Array(self.sectionMap.values)
        }
    }
}
