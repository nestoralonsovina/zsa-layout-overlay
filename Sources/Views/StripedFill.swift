import SwiftUI

struct StripedFill: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let stripeColor = Color.gray.opacity(0.22)
                let step: CGFloat = 10
                for x in stride(from: -size.height, to: size.width + size.height, by: step) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                    context.stroke(path, with: .color(stripeColor), lineWidth: 4)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
