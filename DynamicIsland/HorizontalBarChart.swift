import SwiftUI

struct HorizontalBarChart: View {
    let used: Double
    let total: Double
    let color: Color
    let showUsedValueOnBar: Bool
    let usedValueFormatter: (Double) -> String
    
    init(used: Double, total: Double, color: Color = .green, showUsedValueOnBar: Bool = false, usedValueFormatter: @escaping (Double) -> String = { "\(Int($0))" }) {
        self.used = used
        self.total = total
        self.color = color
        self.showUsedValueOnBar = showUsedValueOnBar
        self.usedValueFormatter = usedValueFormatter
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.18))
                    .frame(height: geo.size.height)
                
                // Colored usage bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .frame(width: CGFloat(total > 0 ? (used / total) : 0) * geo.size.width, height: geo.size.height)
                    .animation(.easeOut(duration: 0.25), value: used)
                
                // Used value text at the edge of colored bar
                if showUsedValueOnBar && total > 0 {
                    let usagePercentage = used / total
                    let barWidth = usagePercentage * geo.size.width
                    
                    Text(usedValueFormatter(used))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .background(
                            Text(usedValueFormatter(used))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: 1, y: 1)
                        )
                        .background(
                            Text(usedValueFormatter(used))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: -1, y: -1)
                        )
                        .background(
                            Text(usedValueFormatter(used))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: 1, y: -1)
                        )
                        .background(
                            Text(usedValueFormatter(used))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: -1, y: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 0.1, x: 0, y: 0)
                        .position(
                            x: max(25, min(barWidth - 25, geo.size.width - 25)), // Keep text within bounds with padding
                            y: geo.size.height / 2
                        )
                        .animation(.easeOut(duration: 0.25), value: used)
                }
            }
        }
    }
} 