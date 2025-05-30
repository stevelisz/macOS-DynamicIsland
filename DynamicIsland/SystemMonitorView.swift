import SwiftUI

struct SystemMonitorView: View {
    @State private var cpuCoreUsages: [Double] = []
    @State private var cpuInfo: (totalCores: Int, performanceCores: Int, efficiencyCores: Int) = (0, 0, 0)
    @State private var gpuUsage: Double = 0
    @State private var gpuUsageHistory: [Double] = Array(repeating: 0, count: 60)
    @State private var ramStats: (usedGB: Double, availableGB: Double, totalGB: Double, pressureLevel: String) = (0, 0, 0, "Unknown")
    @State private var ssdStats: (usedGB: Double, totalGB: Double, percentage: Double) = (0, 0, 0)
    @State private var timer: Timer? = nil
    
    private let statsHelper = SystemStatsHelper()
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            cpuSection
            gpuSection
            ramSection
            ssdSection
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            setupInitialState()
            updateStats()
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    // MARK: - CPU Section
    private var cpuSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("CPU")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f%%", averageCPUUsage))
                        .font(DesignSystem.Typography.captionSemibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(cpuInfo.performanceCores)P + \(cpuInfo.efficiencyCores)E cores")
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            
            BarChart(
                usages: cpuCoreUsages,
                color: .accentColor,
                coreTypeProvider: { coreIndex in
                    coreIndex < cpuInfo.performanceCores ? .performance : .efficiency
                }
            )
            .frame(height: 40)
        }
    }
    
    // MARK: - GPU Section
    private var gpuSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("GPU")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text(String(format: "%.1f%%", gpuUsage))
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            LineGraph(data: gpuUsageHistory, color: .purple)
                .frame(height: 32)
        }
    }
    
    // MARK: - RAM Section
    private var ramSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("RAM")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Used: \(String(format: "%.1f", ramStats.usedGB)) GB")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Circle()
                            .fill(memoryPressureColor)
                            .frame(width: 6, height: 6)
                    }
                    
                    Text("Available: \(String(format: "%.1f", ramStats.availableGB)) GB")
                        .font(DesignSystem.Typography.micro)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                HorizontalBarChart(used: ramStats.usedGB, total: ramStats.totalGB, color: memoryPressureColor)
                    .frame(height: 16)
                
                Text(String(format: "%.0f%%", ramUsagePercentage))
                    .font(DesignSystem.Typography.micro)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }
    
    // MARK: - SSD Section
    private var ssdSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("SSD")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(String(format: "%.0f", ssdStats.totalGB)) GB")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                HorizontalBarChart(used: ssdStats.usedGB, total: ssdStats.totalGB, color: .blue)
                    .frame(height: 16)
                
                Text(String(format: "%.0f%%", ssdStats.percentage))
                    .font(DesignSystem.Typography.micro)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var averageCPUUsage: Double {
        guard !cpuCoreUsages.isEmpty else { return 0 }
        return cpuCoreUsages.reduce(0, +) / Double(cpuCoreUsages.count)
    }
    
    private var ramUsagePercentage: Double {
        guard ramStats.totalGB > 0 else { return 0 }
        return (ramStats.usedGB / ramStats.totalGB) * 100
    }
    
    private var memoryPressureColor: Color {
        switch ramStats.pressureLevel {
        case "Normal":
            return .green
        case "Yellow":
            return .yellow
        case "Red":
            return .red
        default:
            return .gray
        }
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        cpuInfo = statsHelper.getCPUInfo()
        cpuCoreUsages = Array(repeating: 0, count: cpuInfo.totalCores)
        gpuUsageHistory = Array(repeating: 0, count: 60)
    }
    
    private func updateStats() {
        // Update CPU usage
        cpuCoreUsages = statsHelper.getPerCoreCPUUsage()
        
        // Update GPU usage
        gpuUsage = statsHelper.getGPUUsage()
        gpuUsageHistory.append(gpuUsage)
        if gpuUsageHistory.count > 60 {
            gpuUsageHistory.removeFirst()
        }
        
        // Update RAM stats
        ramStats = statsHelper.getRAMStats()
        
        // Update SSD stats
        ssdStats = statsHelper.getSSDUsage()
    }
    
    private func startMonitoring() {
        stopMonitoring() // Ensure we don't have multiple timers
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateStats()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
} 