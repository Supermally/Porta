import Foundation

public final class SharedMemoryManagementService: ObservableObject, @unchecked Sendable {
    public static let shared = SharedMemoryManagementService()

    public let engine: MachPOSIXSharedMemoryEngine
    public let sectionTable: CrossProcessSectionTable
    public let lifetimeCoordinator: SharedHandleLifetimeCoordinator
    public let syncGovernor: SharedMemorySyncGovernor

    public init(
        engine: MachPOSIXSharedMemoryEngine = .shared,
        sectionTable: CrossProcessSectionTable = .shared,
        lifetimeCoordinator: SharedHandleLifetimeCoordinator = .shared,
        syncGovernor: SharedMemorySyncGovernor = .shared
    ) {
        self.engine = engine
        self.sectionTable = sectionTable
        self.lifetimeCoordinator = lifetimeCoordinator
        self.syncGovernor = syncGovernor
    }

    public func createSection(name: String?, sizeBytes: Int, creatorPID: Int32, protection: String = "PAGE_READWRITE") -> WindowsSectionDescriptor {
        let descriptor = sectionTable.registerSection(name: name, sizeBytes: sizeBytes, creatorPID: creatorPID, protection: protection)
        _ = engine.createSharedMemoryRegion(name: descriptor.sectionName, sizeBytes: descriptor.sizeBytes)
        lifetimeCoordinator.retainHandle(sectionName: descriptor.sectionName)
        return descriptor
    }

    public func openSection(name: String) -> WindowsSectionDescriptor? {
        guard let descriptor = sectionTable.lookupSection(name: name) else { return nil }
        lifetimeCoordinator.retainHandle(sectionName: descriptor.sectionName)
        return descriptor
    }

    public func mapSection(name: String) -> (descriptor: WindowsSectionDescriptor, alignedSize: Int)? {
        guard let descriptor = sectionTable.lookupSection(name: name) else { return nil }
        lifetimeCoordinator.retainMappedView(sectionName: name)
        let aligned = engine.alignSizeToHardwarePages(size: descriptor.sizeBytes)
        syncGovernor.executeMemoryBarrier()
        return (descriptor, aligned)
    }

    public func closeHandle(name: String) {
        let shouldUnlink = lifetimeCoordinator.releaseHandle(sectionName: name)
        if shouldUnlink {
            if let desc = sectionTable.lookupSection(name: name) {
                let aligned = engine.alignSizeToHardwarePages(size: desc.sizeBytes)
                engine.releaseSharedMemoryRegion(alignedSize: aligned)
            }
            sectionTable.unregisterSection(name: name)
        }
    }

    public func unmapView(name: String) {
        let shouldUnlink = lifetimeCoordinator.releaseMappedView(sectionName: name)
        if shouldUnlink {
            if let desc = sectionTable.lookupSection(name: name) {
                let aligned = engine.alignSizeToHardwarePages(size: desc.sizeBytes)
                engine.releaseSharedMemoryRegion(alignedSize: aligned)
            }
            sectionTable.unregisterSection(name: name)
        }
    }
}
