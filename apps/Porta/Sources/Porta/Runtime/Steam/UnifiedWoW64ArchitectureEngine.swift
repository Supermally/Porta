import Foundation

public final class UnifiedWoW64ArchitectureEngine: ObservableObject, @unchecked Sendable {
    public static let shared = UnifiedWoW64ArchitectureEngine()

    @Published public var isNewWoW64Active: Bool = true
    @Published public var supportsLargeAddressAware: Bool = true
    @Published public var active32BitPECount: Int = 0
    @Published public var active64BitPECount: Int = 0

    public init() {}

    public func buildWoW64Environment() -> [String: String] {
        var env: [String: String] = [:]
        env["WINEARCH"] = "win64"
        env["WINE_NEW_WOW64"] = "1"
        env["WINELOADER64"] = "1"
        env["WINE_LARGE_ADDRESS_AWARE"] = "1"
        env["WINEDLLOVERRIDES"] = "steamclient=n,b;steamclient64=n,b;gameoverlayrenderer=n,b;gameoverlayrenderer64=n,b"
        return env
    }

    public func registerProcess(is64Bit: Bool) {
        DispatchQueue.main.async {
            if is64Bit {
                self.active64BitPECount += 1
            } else {
                self.active32BitPECount += 1
            }
        }
    }
}
