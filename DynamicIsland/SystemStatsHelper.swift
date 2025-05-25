import Foundation

class SystemStatsHelper {
    private var prevCpuTicks: [[Int32]]? = nil
    private var numCpus: UInt32 = 0
    private let cpuLock = NSLock()
    init() {
        var ncpu: UInt32 = 0
        var size = MemoryLayout<UInt32>.size
        sysctlbyname("hw.ncpu", &ncpu, &size, nil, 0)
        numCpus = ncpu
    }
    func getPerCoreCPUUsage() -> [Double] {
        var coreUsages: [Double] = []
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo)
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else { return Array(repeating: 0, count: Int(numCpus)) }
        var newTicks: [[Int32]] = []
        for i in 0..<Int(numCPUsU) {
            let offset = i * Int(CPU_STATE_MAX)
            let user = cpuInfo[offset + Int(CPU_STATE_USER)]
            let system = cpuInfo[offset + Int(CPU_STATE_SYSTEM)]
            let nice = cpuInfo[offset + Int(CPU_STATE_NICE)]
            let idle = cpuInfo[offset + Int(CPU_STATE_IDLE)]
            newTicks.append([user, system, nice, idle])
        }
        if let prev = prevCpuTicks, prev.count == newTicks.count {
            for i in 0..<newTicks.count {
                let user = Double(newTicks[i][0] - prev[i][0])
                let system = Double(newTicks[i][1] - prev[i][1])
                let nice = Double(newTicks[i][2] - prev[i][2])
                let idle = Double(newTicks[i][3] - prev[i][3])
                let total = user + system + nice + idle
                let usage = (total > 0) ? ((user + system + nice) / total) * 100.0 : 0.0
                coreUsages.append(usage)
            }
        } else {
            coreUsages = Array(repeating: 0, count: newTicks.count)
        }
        prevCpuTicks = newTicks
        return coreUsages
    }
    func getRAMStats() -> (usedGB: Double, availableGB: Double, totalGB: Double) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0, 0) }
        let pageSize = Double(vm_kernel_page_size)
        var compressed: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("vm.compressor_page_count", &compressed, &size, nil, 0)
        let compressedBytes = Double(compressed) * pageSize
        let used = (Double(stats.active_count + stats.wire_count) * pageSize) + compressedBytes
        let available = Double(stats.free_count + stats.inactive_count) * pageSize
        let total = Double(stats.active_count + stats.inactive_count + stats.wire_count + stats.free_count) * pageSize
        let gb = 1024.0 * 1024.0 * 1024.0
        return (used / gb, available / gb, total / gb)
    }
    func getSSDUsage() -> Double {
        let fileURL = URL(fileURLWithPath: "/")
        if let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey]),
           let available = values.volumeAvailableCapacity,
           let total = values.volumeTotalCapacity {
            let used = Double(Int64(total) - Int64(available))
            return (Double(total) > 0) ? (used / Double(Int64(total))) * 100.0 : 0.0
        }
        return 0
    }
}

func getGPUUsageFromPowermetrics(completion: @escaping (Double?) -> Void) {
    let task = Process()
    task.launchPath = "/usr/bin/sudo"
    task.arguments = ["powermetrics", "--samplers", "gpusched", "-n", "1"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.terminationHandler = { _ in
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
            completion(nil)
            return
        }
        if let match = output.range(of: #"GPU Active:\s*([0-9.]+)%"#, options: .regularExpression) {
            let valueString = output[match].replacingOccurrences(of: "GPU Active:", with: "").replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
            if let value = Double(valueString) {
                completion(value)
                return
            }
        }
        completion(nil)
    }
    do {
        try task.run()
    } catch {
        completion(nil)
    }
} 