#!/usr/bin/env swift
// Creates App Store marketing screenshots from actual (unmodified UI) app screenshots.
// Localized headlines sit outside the app UI; the ad panel below the captured UI is cropped.
// Never uploads or submits anything to App Store Connect.
import AppKit
import Foundation

let current = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let appRoot = current.deletingLastPathComponent().deletingLastPathComponent()
let json = try Data(contentsOf: current.appendingPathComponent("metadata-2026-10-10.json"))
let obj = try JSONSerialization.jsonObject(with: json) as! [String:Any]
let localized = obj["localeData"] as! [String:[String:Any]]
let destination = appRoot.appendingPathComponent("store-assets/appstore/aso")
let fm = FileManager.default
let width = 1320
let height = 2868

func color(_ rgb: UInt32) -> NSColor {
    return NSColor(calibratedRed: CGFloat((rgb >> 16) & 255)/255,
                   green: CGFloat((rgb >> 8) & 255)/255,
                   blue: CGFloat(rgb & 255)/255, alpha: 1)
}
let charcoal=color(0x111827), deep=color(0x17283C), mint=color(0x35E0C4), lavender=color(0xB69AFF)
let fileNames=["01-weight", "02-pixels", "03-documents"]
let previewNames=["01-weight.png","02-pixels.png","03-documents.png"]

func create(locale: String, caption: String, name: String, index: Int) throws {
    let primary = (locale == "ru")
    let old = appRoot.appendingPathComponent("store-assets/appstore/" + (primary ? "iphone-6.9/" : "en/iphone-6.9/") + (primary ? (index == 2 ? "03-passport.png" : previewNames[index]) : previewNames[index]))
    guard let input = NSImage(contentsOf: old) else {throw NSError(domain:"Image",code:1,userInfo:[NSLocalizedDescriptionKey:"Missing "+old.path])}
    guard let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.calibratedRGB,bytesPerRow:0,bitsPerPixel:0) else {fatalError("Bitmap")}
    NSGraphicsContext.saveGraphicsState()
    let context=NSGraphicsContext(bitmapImageRep:bitmap)!
    context.imageInterpolation = .high
    NSGraphicsContext.current=context
    let canvas=NSRect(x:0,y:0,width:width,height:height)
    NSGradient(starting:deep, ending:charcoal)!.draw(in:canvas,angle:90)
    mint.setFill()
    NSBezierPath(roundedRect:NSRect(x:75,y:2672,width:320,height:7),xRadius:3,yRadius:3).fill()
    let eyebrow = "ARVECTUM  ·  TOOLS"
    eyebrow.draw(in:NSRect(x:85,y:2730,width:1120,height:65),
                 withAttributes:[.font:NSFont.systemFont(ofSize:37,weight:.heavy),.foregroundColor:mint,.kern:5])
    let para=NSMutableParagraphStyle();para.alignment = .left;para.lineBreakMode = .byWordWrapping
    let cjk = ["ja","ko","hi"].contains(locale)
    let capFont = NSFont.systemFont(ofSize:cjk ? 76:83,weight:.bold)
    (caption as NSString).draw(in:NSRect(x:85,y:2370,width:1150,height:260),
                withAttributes:[.font:capFont,.foregroundColor:NSColor.white,.paragraphStyle:para])
    (name as NSString).draw(in:NSRect(x:85,y:2285,width:1150,height:65),
                withAttributes:[.font:NSFont.systemFont(ofSize:40,weight:.medium),.foregroundColor:lavender])
    // Image region: only real app UI; bottom ad and footer are not used.
    let imageX:CGFloat=66, imageY:CGFloat=345, imageW:CGFloat=1188
    let cutH:CGFloat = index == 2 ? 2000:1950
    let imageH=cutH*(imageW/CGFloat(input.size.width))
    let shown=NSRect(x:imageX,y:imageY,width:imageW,height:imageH)
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow=NSShadow()
    shadow.shadowColor=NSColor.black.withAlphaComponent(0.40)
    shadow.shadowOffset=NSSize(width:0,height:-15)
    shadow.shadowBlurRadius=26
    shadow.set()
    color(0xFAFCFF).setFill()
    NSBezierPath(roundedRect:shown,xRadius:40,yRadius:40).fill()
    NSGraphicsContext.current?.restoreGraphicsState()
    NSGraphicsContext.current?.saveGraphicsState()
    NSBezierPath(roundedRect:shown,xRadius:40,yRadius:40).addClip()
    input.draw(in:shown, from:NSRect(x:0,y:input.size.height-cutH,width:input.size.width,height:cutH),operation:.copy,fraction:1)
    NSGraphicsContext.current?.restoreGraphicsState()
    let footer = "100 KB      ·      500 KB      ·      1 MB      ·      PDF"
    let font=NSFont.systemFont(ofSize:38,weight:.semibold)
    footer.draw(in:NSRect(x:86,y:177,width:1140,height:65),
                withAttributes:[.font:font,.foregroundColor:mint])
    let label="Local processing  ·  by Arvectum"
    label.draw(in:NSRect(x:86,y:101,width:1140,height:50),
                withAttributes:[.font:NSFont.systemFont(ofSize:30),.foregroundColor:NSColor.white.withAlphaComponent(0.68)])
    NSGraphicsContext.current?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    let dir=destination.appendingPathComponent(locale).appendingPathComponent("iphone-6.9")
    try fm.createDirectory(at:dir,withIntermediateDirectories:true)
    let target=dir.appendingPathComponent(fileNames[index]+".jpg")
    guard let jpeg=bitmap.representation(using:.jpeg,properties:[.compressionFactor:0.84]) else{fatalError("encode")}
    try jpeg.write(to:target,options:.atomic)
}

let requested = Array(CommandLine.arguments.dropFirst())
var count=0
for locale in localized.keys.sorted() where requested.isEmpty || requested.contains(locale) {
    guard let attrs=localized[locale],let titles=attrs["screenshots"] as? [String],let name=attrs["name"] as? String else{continue}
    for i in 0..<3 {try create(locale:locale,caption:titles[i],name:name,index:i); count += 1}
}
print("CREATED \(count) staged localized JPEG screenshots at \(destination.path) (not uploaded)")
