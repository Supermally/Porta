import Foundation
import CoreAudio
import AudioToolbox

public final class MacAudioManager: ObservableObject, @unchecked Sendable {
    public static let shared = MacAudioManager()

    @Published public var defaultOutputDeviceName: String = "Built-in Output"
    @Published public var nominalSampleRate: Double = 48000.0
    @Published public var bufferFrameSize: UInt32 = 256
    @Published public var estimatedLatencyMs: Double = 5.33

    public init() {
        inspectDefaultOutputDevice()
    }

    public func inspectDefaultOutputDevice() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceId: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceId
        )

        if status == noErr && deviceId != 0 {
            // Get Name
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var unmanagedName: Unmanaged<CFString>?
            var stringSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            if AudioObjectGetPropertyData(deviceId, &nameAddress, 0, nil, &stringSize, &unmanagedName) == noErr, let name = unmanagedName?.takeRetainedValue() {
                self.defaultOutputDeviceName = name as String
            }

            // Get Sample Rate
            var rateAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyNominalSampleRate,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var sampleRate: Float64 = 48000.0
            var rateSize = UInt32(MemoryLayout<Float64>.size)
            if AudioObjectGetPropertyData(deviceId, &rateAddress, 0, nil, &rateSize, &sampleRate) == noErr {
                self.nominalSampleRate = sampleRate
            }

            // Get Buffer Frame Size
            var bufferAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyBufferFrameSize,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var frames: UInt32 = 256
            var frameSize = UInt32(MemoryLayout<UInt32>.size)
            if AudioObjectGetPropertyData(deviceId, &bufferAddress, 0, nil, &frameSize, &frames) == noErr {
                self.bufferFrameSize = frames
                if sampleRate > 0 {
                    self.estimatedLatencyMs = (Double(frames) / sampleRate) * 1000.0
                }
            }
        }
    }
}
