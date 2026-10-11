#if DEBUG
import Foundation
import UIKit

/// Deterministic, synthetic documents for UI automation only.
/// Not bundled into, or reachable from, production builds.
enum QAFixtures {
    static func photoData() -> Data {
        let size = CGSize(width: 1200, height: 1600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            for row in 0..<45 {
                let factor = CGFloat(row) / 45
                UIColor(red: 0.1 + factor * 0.5, green: 0.65 - factor * 0.2,
                        blue: 0.70, alpha: 1).setFill()
                context.fill(CGRect(x: 0, y: CGFloat(row) * 35,
                                    width: size.width, height: 17))
            }
            UIColor.white.setFill()
            context.fill(CGRect(x: 140, y: 260, width: 920, height: 900))
            let label = "ARVECTUM QA"
            label.draw(at: CGPoint(x: 225, y: 600),
                       withAttributes: [
                        .font: UIFont.boldSystemFont(ofSize: 80),
                        .foregroundColor: UIColor.darkGray
                       ])
        }
        return image.jpegData(compressionQuality: 0.92)!
    }

    static func pdfData() -> Data {
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let photo = UIImage(data: photoData())!
        return UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            for index in 1...3 {
                context.beginPage()
                UIColor.white.setFill()
                context.fill(bounds)
                ("Sample document — page \(index)" as NSString).draw(
                    at: CGPoint(x: 38, y: 26),
                    withAttributes: [.font: UIFont.boldSystemFont(ofSize: 24)]
                )
                photo.draw(in: CGRect(x: 50, y: 120, width: 495, height: 660))
            }
        }
    }
}
#endif
