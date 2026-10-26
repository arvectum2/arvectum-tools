#!/usr/bin/env swift
// AppKit marketing frames from verified, real iPhone Simulator UI captures.
// NO synthetic ad creative, no modified UI, no Apple upload.
import AppKit
import Foundation

let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let root = dir.deletingLastPathComponent().deletingLastPathComponent()
let assets = root.appendingPathComponent("store-assets/appstore")
let source = assets.appendingPathComponent("review-20261026/sources")
let destination = assets.appendingPathComponent("review-20261026")
let metadata = dir.appendingPathComponent("metadata-2026-10-26-review.json")
let object = try JSONSerialization.jsonObject(with: Data(contentsOf: metadata)) as! [String: Any]
let locales = object["localeData"] as! [String: [String: Any]]
let requested = Array(CommandLine.arguments.dropFirst())
let selected = requested.isEmpty ? ["ru", "en-US", "en-GB"] : requested

func hex(_ rgb: UInt32) -> NSColor {
    NSColor(calibratedRed: CGFloat((rgb >> 16) & 255) / 255,
            green: CGFloat((rgb >> 8) & 255) / 255,
            blue: CGFloat(rgb & 255) / 255, alpha: 1)
}
let mint = hex(0x35E0C4)
let charcoal = hex(0x081828)
let dark = hex(0x16283C)
let lavender = hex(0xBAA5FA)
let names = ["01-photo-kb", "02-pixel-dimensions", "03-visa-presets", "04-pdf-kb"]

func imageURL(_ index: Int, _ language: String) -> URL {
    if index == 0 {
        return assets.appendingPathComponent(
            language == "ru" ? "iphone-6.9/01-weight.png" : "en/iphone-6.9/01-weight.png"
        )
    }
    if index == 1 {
        return assets.appendingPathComponent(
            language == "ru" ? "iphone-6.9/02-pixels.png" : "en/iphone-6.9/02-pixels.png"
        )
    }
    return source.appendingPathComponent(
        "\(index == 2 ? "03-china" : "04-pdf")-\(language == "ru" ? "ru" : "en").png"
    )
}

func frame(_ locale: String, _ index: Int) throws {
    guard let metadata = locales[locale],
          let captions = metadata["screenshots"] as? [String],
          captions.count == 4 else { throw NSError(domain: "metadata", code: 1) }
    let language = locale == "ru" ? "ru" : "en"
    let inputURL = imageURL(index, language)
    guard let screenshot = NSImage(contentsOf: inputURL) else {
        throw NSError(domain: "missing screenshot \(inputURL.path)", code: 2)
    }
    let w = 1320, h = 2868
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    NSGradient(starting: dark, ending: charcoal)!.draw(
        in: NSRect(x: 0, y: 0, width: w, height: h), angle: 90
    )
    mint.setFill()
    NSBezierPath(roundedRect: NSRect(x: 88, y: 2664, width: 335, height: 7),
                 xRadius: 4, yRadius: 4).fill()
    let eyebrow = "ARVECTUM   ·   TOOLS"
    eyebrow.draw(in: NSRect(x: 88, y: 2722, width: 1100, height: 60),
                 withAttributes: [.font: NSFont.systemFont(ofSize: 37, weight: .bold),
                                  .foregroundColor: mint])
    let labels = locale == "ru"
        ? ["ПО ВЕСУ", "ПО ПИКСЕЛЯМ", "НА ДОКУМЕНТЫ", "PDF"]
        : ["PHOTO COMPRESSION", "PIXEL DIMENSIONS", "DOCUMENT PHOTO", "PDF COMPRESSION"]
    labels[index].draw(in: NSRect(x: 88, y: 2592, width: 1150, height: 56),
                       withAttributes: [.font: NSFont.systemFont(ofSize: 32, weight: .semibold),
                                        .foregroundColor: lavender])
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    let titleFont: CGFloat = captions[index].count > 38 ? 64 : 82
    (captions[index] as NSString).draw(
        in: NSRect(x: 88, y: 2325, width: 1148, height: 245),
        withAttributes: [.font: NSFont.systemFont(ofSize: titleFont, weight: .heavy),
                         .paragraphStyle: paragraph, .foregroundColor: NSColor.white]
    )
    let cut: CGFloat = index < 2 ? 1860 : (index == 2 ? 1850 : 1850)
    let imageW: CGFloat = 1160
    let imageH = cut * imageW / screenshot.size.width
    let top: CGFloat = 2250
    let dest = NSRect(x: (CGFloat(w) - imageW) / 2, y: top - imageH,
                      width: imageW, height: imageH)
    let rounded = NSBezierPath(roundedRect: dest, xRadius: 34, yRadius: 34)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.36)
    shadow.shadowBlurRadius = 25
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    context.saveGraphicsState()
    shadow.set()
    NSColor.white.setFill()
    rounded.fill()
    context.restoreGraphicsState()
    context.saveGraphicsState()
    rounded.addClip()
    screenshot.draw(
        in: dest,
        from: NSRect(x: 0, y: screenshot.size.height - cut,
                     width: screenshot.size.width, height: cut),
        operation: .copy, fraction: 1
    )
    context.restoreGraphicsState()
    let footnote = locale == "ru" ? "Файлы обрабатываются на iPhone" : "Your files stay on your iPhone"
    footnote.draw(in: NSRect(x: 90, y: 120, width: 1130, height: 62),
                  withAttributes: [.font: NSFont.systemFont(ofSize: 40, weight: .medium),
                                   .foregroundColor: mint])
    NSGraphicsContext.current?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    let folder = destination.appendingPathComponent("\(locale)/iphone-6.9")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    guard let jpeg = bitmap.representation(using: .jpeg,
                                           properties: [.compressionFactor: 0.89]) else {
        throw NSError(domain: "jpeg", code: 3)
    }
    try jpeg.write(to: folder.appendingPathComponent(names[index] + ".jpg"), options: .atomic)
}
for locale in selected {
    for i in 0..<4 { try frame(locale, i) }
    print("RENDERED \(locale): 4×1320×2868")
}
