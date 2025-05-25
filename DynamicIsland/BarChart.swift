import SwiftUI

struct BarChart: View {
    let usages: [Double] // 0...100
    let color: Color
    var coreTypeProvider: ((Int) -> CoreType)? = nil
    enum CoreType { case performance, efficiency, gpu }
    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let barCount = usages.count
            let barWidth = max((geo.size.width - spacing * CGFloat(barCount - 1)) / CGFloat(barCount), 6)
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(usages.indices, id: \ .self) { idx in
                    let usage = usages[idx]
                    let barHeight = geo.size.height
                    let usageHeight = max(barHeight * CGFloat(usage / 100), 4)
                    let coreType = coreTypeProvider?(idx) ?? .gpu
                    let bgColor: Color = {
                        switch coreType {
                        case .performance: return Color.blue.opacity(0.18)
                        case .efficiency: return Color.teal.opacity(0.18)
                        case .gpu: return Color.purple.opacity(0.18)
                        }
                    }()
                    let fgColor: Color = {
                        switch coreType {
                        case .performance: return Color.blue
                        case .efficiency: return Color.teal
                        case .gpu: return Color.purple
                        }
                    }()
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(bgColor)
                            .frame(width: barWidth, height: barHeight)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(fgColor)
                            .frame(width: barWidth, height: usageHeight)
                            .animation(.easeOut(duration: 0.25), value: usage)
                    }
                    .frame(width: barWidth, height: barHeight)
                    .help("\(Int(usage))%")
                }
            }
        }
    }
} 