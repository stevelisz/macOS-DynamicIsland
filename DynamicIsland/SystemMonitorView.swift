import SwiftUI

struct SystemMonitorView: View {
    @State private var cpuCoreUsages: [Double] = Array(repeating: 0, count: 14)
    @State private var gpuUsage: Double = 0
    @State private var gpuUsageHistory: [Double] = Array(repeating: 0, count: 60)
    @State private var ramUsedGB: Double = 0
    @State private var ramAvailableGB: Double = 0
    @State private var ramTotalGB: Double = 0
    @State private var fanSpeed: Double = 0
    @State private var ssdUsage: Double = 0
    @State private var ssdUsedGB: Double = 0
    @State private var ssdTotalGB: Double = 0
    @State private var wattage: Double = 0
    @State private var timer: Timer? = nil
    private let statsHelper = SystemStatsHelper()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // CPU Usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("CPU")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f%%", cpuCoreUsages.reduce(0, +) / Double(cpuCoreUsages.count)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                BarChart(usages: cpuCoreUsages, color: .accentColor, coreTypeProvider: { idx in idx < 10 ? .performance : .efficiency })
                    .frame(height: 40)
            }
            // GPU Usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("GPU")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f%%", gpuUsage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                LineGraph(data: gpuUsageHistory, color: .purple)
                    .frame(height: 32)
            }
            // RAM Usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("RAM")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "Used: %.2f GB", ramUsedGB))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "Available: %.2f GB", ramAvailableGB))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 10) {
                    HorizontalBarChart(used: ramUsedGB, total: ramTotalGB, color: .green)
                        .frame(height: 16)
                    Text(String(format: "%.0f%%", (ramTotalGB > 0 ? (ramUsedGB / ramTotalGB) * 100 : 0)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
            // SSD Usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("SSD")
                        .font(.subheadline)
                    Spacer()
                }
                HStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        HorizontalBarChart(used: ssdUsedGB, total: ssdTotalGB, color: .blue)
                            .frame(height: 16)
                        if ssdTotalGB > 0 {
                            Text(String(format: "%.0f GB", ssdTotalGB))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                                .padding(.vertical, 0)
                        }
                    }
                    Text(ssdTotalGB > 0 ? String(format: "%.0f%%", (ssdUsedGB / ssdTotalGB) * 100) : "0%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            updateStats() // Fetch stats immediately
            startMonitoring()
        }
        .onDisappear { timer?.invalidate() }
    }
    private func updateStats() {
        let cpuUsages = statsHelper.getPerCoreCPUUsage()
        cpuCoreUsages = cpuUsages.count == 14 ? cpuUsages : Array(cpuUsages.prefix(14)) + Array(repeating: 0, count: max(0, 14 - cpuUsages.count))
        getGPUUsageFromPowermetrics { value in
            DispatchQueue.main.async {
                if let value = value {
                    gpuUsage = value
                    gpuUsageHistory.append(value)
                    if gpuUsageHistory.count > 60 { gpuUsageHistory.removeFirst() }
                }
            }
        }
        let ramStats = statsHelper.getRAMStats()
        ramUsedGB = ramStats.usedGB
        ramAvailableGB = ramStats.availableGB
        ramTotalGB = ramStats.totalGB
        // SSD
        let fileURL = URL(fileURLWithPath: "/")
        if let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey]),
           let available = values.volumeAvailableCapacity,
           let total = values.volumeTotalCapacity {
            let used = Double(Int64(total) - Int64(available))
            ssdUsedGB = used / (1024 * 1024 * 1024)
            ssdTotalGB = Double(total) / (1024 * 1024 * 1024)
            ssdUsage = (ssdTotalGB > 0) ? (ssdUsedGB / ssdTotalGB) * 100.0 : 0.0
        } else {
            ssdUsedGB = 0
            ssdTotalGB = 0
            ssdUsage = 0
        }
        // TODO: Replace with real values if available
        fanSpeed = 0
        wattage = 0
    }
    private func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateStats()
        }
    }
} 