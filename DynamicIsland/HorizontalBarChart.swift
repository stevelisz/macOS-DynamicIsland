import SwiftUI

struct HorizontalBarChart: View {
    let used: Double
    let total: Double
    let color: Color
    
    init(used: Double, total: Double, color: Color = .green) {
        self.used = used
        self.total = total
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.18))
                    .frame(height: geo.size.height)
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .frame(width: CGFloat(total > 0 ? (used / total) : 0) * geo.size.width, height: geo.size.height)
                    .animation(.easeOut(duration: 0.25), value: used)
            }
        }
    }
} 