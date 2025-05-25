import SwiftUI

struct LineGraph: View {
    let data: [Double]
    let color: Color
    func normalizedData() -> [Double] {
        guard let min = data.min(), let max = data.max(), max > min else {
            return data.map { _ in 0.5 }
        }
        return data.map { ($0 - min) / (max - min) }
    }
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let points = normalizedData()
                guard points.count > 1 else { return }
                let step = geo.size.width / CGFloat(points.count - 1)
                path.move(to: CGPoint(x: 0, y: geo.size.height * (1 - points[0])))
                for i in 1..<points.count {
                    let x = CGFloat(i) * step
                    let y = geo.size.height * (1 - points[i])
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
} 