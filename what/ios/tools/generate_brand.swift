import AppKit
import CoreGraphics
import Foundation
let contours = ["M376,208 349,220 331,233 309,258 297,285 299,301 310,315 323,320 335,319 345,314 352,306 356,287 362,275 375,266 387,266 396,270 405,279 411,295 411,311 404,334 395,350 326,435 309,462 292,499 282,537 279,567 282,611 292,654 310,701 330,738 362,781 392,810 427,835 457,851 505,869 547,879 564,888 575,899 583,920 575,990 575,1019 579,1033 586,1045 604,1060 622,1065 641,1063 658,1054 666,1046 677,1023 678,993 670,917 680,896 693,885 708,878 751,868 800,849 852,817 887,785 913,753 931,724 951,682 967,630 973,592 973,554 965,512 953,480 936,449 916,421 876,375 853,342 843,318 841,298 848,278 855,271 865,266 877,266 884,269 893,278 902,308 915,318 929,320 941,316 949,309 955,297 955,282 942,256 918,230 902,219 873,207 843,204 818,210 799,222 786,237 776,260 773,281 775,306 782,330 800,364 863,449 879,482 888,512 894,555 894,588 889,626 877,668 858,709 834,744 804,775 764,803 721,822 680,832 651,835 580,833 545,826 511,814 477,796 450,776 422,748 404,724 385,690 372,657 362,616 359,591 359,550 369,496 382,463 397,437 459,354 472,327 479,298 479,272 475,254 466,236 450,219 437,211 419,205 399,204Z","M418,482 413,492 413,504 422,519 440,528 476,530 476,660 480,693 495,732 511,755 524,768 542,781 578,795 598,798 655,798 679,794 707,783 725,771 744,752 762,724 775,681 776,531 778,529 808,529 827,522 835,514 840,503 840,492 832,479 818,473 802,474 793,478 783,490 776,488 776,480 477,480 476,489 470,490 460,478 447,473 428,475Z","M477,450 478,458 776,457 774,442 764,419 741,391 710,372 693,366 668,363 659,356 659,342 672,335 678,326 676,311 664,303 589,303 581,306 575,315 575,327 582,336 593,341 595,345 593,357 584,363 564,365 545,371 513,390 493,412 484,428Z"]
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let S = 1024
func makeContext() -> CGContext {
    CGContext(data:nil, width:S, height:S, bitsPerComponent:8, bytesPerRow:0,
              space:CGColorSpaceCreateDeviceRGB(),
              bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
}
func glyph(_ ctx:CGContext) {
    ctx.saveGState()
    ctx.translateBy(x:0,y:CGFloat(S))
    ctx.scaleBy(x:CGFloat(S)/1254,y:-CGFloat(S)/1254)
    let path=CGMutablePath()
    for shape in contours {
        let pts=shape.dropFirst().dropLast().split(separator:" ")
        for (i,point) in pts.enumerated() {
            let xy=point.split(separator:",")
            let pos=CGPoint(x:Double(xy[0])!, y:Double(xy[1])!)
            if i==0 { path.move(to:pos) } else { path.addLine(to:pos) }
        }
        path.closeSubpath()
    }
    ctx.addPath(path);ctx.clip()
    let col=[CGColor(red:0.69,green:1.0,blue:0.82,alpha:1),
             CGColor(red:0.62,green:1.0,blue:0.81,alpha:1)] as CFArray
    let gr=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),colors:col,locations:[0,1])!
    ctx.drawLinearGradient(gr,start:CGPoint(x:420,y:200),end:CGPoint(x:850,y:1040),options:[])
    ctx.restoreGState()
}
func save(_ ctx:CGContext,_ rel:String) {
    let url=root.appendingPathComponent(rel)
    try! FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
    let img=NSBitmapImageRep(cgImage:ctx.makeImage()!)
    try! img.representation(using:.png,properties:[:])!.write(to:url,options:.atomic)
    print("GENERATED",rel)
}
let alpha=makeContext();glyph(alpha)
save(alpha,"WhatIOS/Assets.xcassets/WhatGlyph.imageset/WhatGlyph.png")
let icon=makeContext()
let bg=CGGradient(colorsSpace:CGColorSpaceCreateDeviceRGB(),
  colors:[CGColor(red:0.004,green:0.075,blue:0.20,alpha:1),
          CGColor(red:0.010,green:0.13,blue:0.30,alpha:1),
          CGColor(red:0.003,green:0.055,blue:0.16,alpha:1)] as CFArray,
  locations:[0,0.52,1])!
icon.drawRadialGradient(bg,startCenter:CGPoint(x:520,y:570),startRadius:0,
 endCenter:CGPoint(x:512,y:512),endRadius:760,options:[])
glyph(icon)
save(icon,"WhatIOS/Assets.xcassets/AppIcon.appiconset/WhatAppIcon.png")
save(icon,"WhatWatch/Assets.xcassets/AppIcon.appiconset/WhatWatchIcon.png")
save(icon,"WhatWatchComplication/Assets.xcassets/WhatComplicationIcon.imageset/WhatComplicationIcon.png")
