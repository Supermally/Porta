import Foundation
import os

/// MachPOSIXSharedMemoryEngine handles the shared memory mapping between Wine/Chromium processes
/// and native macOS Metal surfaces using POSIX shm and Mach memory entries.
public class MachPOSIXSharedMemoryEngine {
    public static let shared = MachPOSIXSharedMemoryEngine()
    private let logger = Logger(subsystem: "com.macgaming.runtime", category: "SharedMemory")
    
    private init() {}
    
    /// Creates a shared memory region backed by POSIX shm that is compatible with Wine/Chromium IPC.
    public func createSharedRegion(name: String, size: Int) -> UnsafeMutableRawPointer? {
        let fd = shm_open(name, O_CREAT | O_RDWR, 0o666)
        guard fd != -1 else {
            logger.error("Failed to create shared memory region: \(name)")
            return nil
        }
        defer { close(fd) }
        
        ftruncate(fd, off_t(size))
        
        let pointer = mmap(nil, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
        guard pointer != MAP_FAILED else {
            logger.error("Failed to mmap shared memory region: \(name)")
            return nil
        }
        
        logger.info("Created shared memory region '\(name)' of size \(size) bytes.")
        return pointer
    }
    
    /// Enforces macOS CPU cache coherency using OSMemoryBarrier for zero-copy CPU/GPU sharing.
    public func syncMemoryBarrier() {
        OSMemoryBarrier()
    }
}
