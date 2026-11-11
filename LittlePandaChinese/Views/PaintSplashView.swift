import SpriteKit
import SwiftUI
import UIKit

/// Paint dots for the slapstick beat. The rest of the cut-out animation is SwiftUI.
struct PaintSplashView: UIViewRepresentable {
    var token: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        let scene = SplashScene(size: CGSize(width: 800, height: 600))
        scene.backgroundColor = .clear
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        context.coordinator.scene = scene
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        let size = uiView.bounds.size
        if size.width > 2, size.height > 2 {
            context.coordinator.scene?.size = size
        }
        guard context.coordinator.token != token else { return }
        context.coordinator.token = token
        if token > 0 {
            context.coordinator.scene?.burst()
        }
    }

    final class Coordinator {
        var scene: SplashScene?
        var token = 0
    }
}

final class SplashScene: SKScene {
    func burst() {
        removeAllChildren()
        let colors: [UIColor] = [
            UIColor(red: 0.86, green: 0.23, blue: 0.22, alpha: 1),
            UIColor(red: 0.95, green: 0.74, blue: 0.18, alpha: 1),
            UIColor(red: 0.23, green: 0.46, blue: 0.82, alpha: 1),
            UIColor(red: 0.20, green: 0.60, blue: 0.34, alpha: 1)
        ]
        let origin = CGPoint(x: size.width * 0.30, y: size.height * 0.42)
        for index in 0..<42 {
            let radius = CGFloat.random(in: 7...18)
            let node = SKShapeNode(circleOfRadius: radius)
            node.fillColor = colors[index % colors.count]
            node.strokeColor = .black
            node.lineWidth = 2
            node.position = origin
            addChild(node)
            let dx = CGFloat.random(in: -260...220)
            let dy = CGFloat.random(in: -30...280)
            node.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.72),
                    SKAction.fadeOut(withDuration: 0.72),
                    SKAction.rotate(byAngle: CGFloat.random(in: -2.2...2.2), duration: 0.72)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
