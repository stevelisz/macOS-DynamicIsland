import SwiftUI

struct BarChart: View {
    let usages: [Double] // 0...100
    let color: Color
    var coreTypeProvider: ((Int) -> CoreType)? = nil
    @State private var hoveredIndex: Int? = nil
    
    enum CoreType { case performance, efficiency, gpu }
    
    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let barCount = usages.count
            let barWidth = max((geo.size.width - spacing * CGFloat(barCount - 1)) / CGFloat(barCount), 6)
            
            ZStack {
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(usages.indices, id: \.self) { idx in
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
                        .onHover { isHovering in
                            hoveredIndex = isHovering ? idx : nil
                        }
                    }
                }
                
                // Custom tooltip
                if let hoveredIndex = hoveredIndex {
                    let usage = usages[hoveredIndex]
                    let barWidth = max((geo.size.width - spacing * CGFloat(usages.count - 1)) / CGFloat(usages.count), 6)
                    let barX = CGFloat(hoveredIndex) * (barWidth + spacing) + barWidth / 2
                    
                    VStack(spacing: 2) {
                        Text("\(Int(usage))%")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.8))
                            )
                        
                        // Triangle pointer
                        Triangle()
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 6, height: 3)
                    }
                    .offset(x: barX - geo.size.width / 2, y: -35)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.1), value: hoveredIndex)
                }
            }
        }
    }
}

// Custom triangle shape for tooltip pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
} 