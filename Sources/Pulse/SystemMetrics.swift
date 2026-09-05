import Foundation
import Darwin
import IOKit

class SystemMetrics {

    struct Sample {
        var cpu: Int            // 0–100
        var battery: Int?       // 0–100, nil if no battery present
        var isPluggedIn: Bool   // AC adapter connected
        var downKBps: Double
        var upKBps: Double
    }

    private var prevCPU: (user: UInt32, sys: UInt32, idle: UInt32, nice: UInt32)?
    private var prevNet: (bytesIn: UInt32, bytesOut: UInt32, time: Date)?

    func sample() -> Sample {
        let net = sampleNetwork()
        let bat = readBattery()
        return Sample(
            cpu: sampleCPU(),
            battery: bat?.percent,
            isPluggedIn: bat?.isPluggedIn ?? false,
            downKBps: net.down,
            upKBps: net.up
        )
    }

    // MARK: - CPU

    private func sampleCPU() -> Int {
        guard let ticks = cpuTicks() else { return 0 }
        defer { prevCPU = ticks }
        guard let prev = prevCPU else { return 0 }

        let dUser = Int64(ticks.user) - Int64(prev.user)
        let dSys  = Int64(ticks.sys)  - Int64(prev.sys)
        let dIdle = Int64(ticks.idle) - Int64(prev.idle)
        let dNice = Int64(ticks.nice) - Int64(prev.nice)
        let total = dUser + dSys + dIdle + dNice
        guard total > 0 else { return 0 }
        return Int(max(0, min(100, (dUser + dSys) * 100 / total)))
    }

    private func cpuTicks() -> (user: UInt32, sys: UInt32, idle: UInt32, nice: UInt32)? {
        // HOST_CPU_LOAD_INFO_COUNT = sizeof(host_cpu_load_info) / sizeof(integer_t) = 16/4 = 4
        var count: mach_msg_type_number_t = 4
        var info = host_cpu_load_info()
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }
        return (info.cpu_ticks.0, info.cpu_ticks.1, info.cpu_ticks.2, info.cpu_ticks.3)
    }

    // MARK: - Battery

    private func readBattery() -> (percent: Int, isPluggedIn: Bool)? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var propsRef: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0) == kIOReturnSuccess,
              let props = propsRef?.takeRetainedValue() as? [String: Any]
        else { return nil }

        guard let current = props["CurrentCapacity"] as? Int,
              let max    = props["MaxCapacity"] as? Int,
              max > 0, current >= 0
        else { return nil }

        let isPluggedIn = props["ExternalConnected"] as? Bool ?? false
        let percent = min(100, current * 100 / max)
        return (percent, isPluggedIn)
    }

    // MARK: - Network

    private func sampleNetwork() -> (down: Double, up: Double) {
        let (bytesIn, bytesOut) = netBytes()
        let now = Date()
        let prev = prevNet
        prevNet = (bytesIn, bytesOut, now)

        guard let prev = prev else { return (0, 0) }
        let elapsed = now.timeIntervalSince(prev.time)
        guard elapsed > 0.1 && elapsed < 10 else { return (0, 0) }

        // Guard against UInt32 wraparound — skip this sample if counters rolled over
        guard bytesIn >= prev.bytesIn, bytesOut >= prev.bytesOut else { return (0, 0) }

        let down = Double(bytesIn  - prev.bytesIn)  / elapsed / 1000
        let up   = Double(bytesOut - prev.bytesOut) / elapsed / 1000
        return (max(0, down), max(0, up))
    }

    private func netBytes() -> (bytesIn: UInt32, bytesOut: UInt32) {
        var totalIn:  UInt32 = 0
        var totalOut: UInt32 = 0

        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else { return (0, 0) }
        defer { freeifaddrs(first) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let cur = ptr {
            defer { ptr = cur.pointee.ifa_next }
            let name = String(cString: cur.pointee.ifa_name)
            guard name != "lo0" else { continue }
            guard cur.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK) else { continue }
            if let data = cur.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                totalIn  &+= data.pointee.ifi_ibytes
                totalOut &+= data.pointee.ifi_obytes
            }
        }
        return (totalIn, totalOut)
    }
}
