import Foundation

public struct SharedHandleRecord: Identifiable, Sendable {
    public let id: String
    public let sectionName: String
    public var handleRefCount: Int
    public var activeMappedViews: Int

    public var totalReferences: Int {
        return handleRefCount + activeMappedViews
    }
}

public final class SharedHandleLifetimeCoordinator: ObservableObject, @unchecked Sendable {
    public static let shared = SharedHandleLifetimeCoordinator()

    @Published public var activeHandles: [String: Int] = [:]
    private var records: [String: SharedHandleRecord] = [:]
    private let lock = NSLock()

    public init() {}

    public func retainHandle(sectionName: String) {
        lock.lock()
        defer { lock.unlock() }

        var record = records[sectionName] ?? SharedHandleRecord(id: UUID().uuidString, sectionName: sectionName, handleRefCount: 0, activeMappedViews: 0)
        record.handleRefCount += 1
        records[sectionName] = record
        updatePublishedState()
    }

    public func retainMappedView(sectionName: String) {
        lock.lock()
        defer { lock.unlock() }

        var record = records[sectionName] ?? SharedHandleRecord(id: UUID().uuidString, sectionName: sectionName, handleRefCount: 0, activeMappedViews: 0)
        record.activeMappedViews += 1
        records[sectionName] = record
        updatePublishedState()
    }

    public func releaseHandle(sectionName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard var record = records[sectionName] else { return true }
        if record.handleRefCount > 0 {
            record.handleRefCount -= 1
        }
        records[sectionName] = record
        let shouldUnlink = (record.totalReferences == 0)
        if shouldUnlink {
            records.removeValue(forKey: sectionName)
        }
        updatePublishedState()
        return shouldUnlink
    }

    public func releaseMappedView(sectionName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard var record = records[sectionName] else { return true }
        if record.activeMappedViews > 0 {
            record.activeMappedViews -= 1
        }
        records[sectionName] = record
        let shouldUnlink = (record.totalReferences == 0)
        if shouldUnlink {
            records.removeValue(forKey: sectionName)
        }
        updatePublishedState()
        return shouldUnlink
    }

    private func updatePublishedState() {
        var map: [String: Int] = [:]
        for (k, v) in records {
            map[k] = v.totalReferences
        }
        DispatchQueue.main.async {
            self.activeHandles = map
        }
    }
}
