import AppKit
import Foundation

struct Localised: Decodable { let subtitle: String; let screenshots:[String]; let name:String }
struct Listing: Decodable { let localeData:[String:Localised] }
struct Shot: Decodable { let locale:String;let device:String;let position:Int;let path:String;let sha256:String }
struct AppSlots: Decodable { let slots:[Shot] }
struct Manifest: Decodable { let apps:[String:AppSlots] }

let root="/Volumes/ArvectumSSD/arvectum/repos/arvectum-tools"
let stage=root+"/core/appstore/staged-2026-10-26"
let manifest=try JSONDecoder().decode(Manifest.self,from:Data(contentsOf:URL(fileURLWithPath:stage+"/screenshot_manifest.json")))
let locales:[(String,String)]=[("ru","ru"),("en","en-US"),("es","es-ES"),("fr","fr-FR"),("de","de-DE"),("it","it"),("ja","ja"),("ko","ko"),("pt-BR","pt-BR"),("pt-PT","pt-PT"),("zh-Hans","zh-Hans"),("zh-Hant","zh-Hant")]
let themes:[String:(NSColor,NSColor,NSColor)]=[
 "photo":(NSColor(srgbRed:0.045,green:0.13,blue:0.18,alpha:1),NSColor(srgbRed:0.04,green:0.33,blue:0.39,alpha:1),NSColor(srgbRed:0.24,green:0.93,blue:0.80,alpha:1)),
 "what":(NSColor(srgbRed:0.025,green:0.07,blue:0.20,alpha:1),NSColor(srgbRed:0.10,green:0.21,blue:0.49,alpha:1),NSColor(srgbRed:0.57,green:0.96,blue:0.83,alpha:1)),
 "chickmark":(NSColor(srgbRed:0.12,green:0.06,blue:0.21,alpha:1),NSColor(srgbRed:0.34,green:0.17,blue:0.50,alpha:1),NSColor(srgbRed:0.66,green:0.95,blue:0.81,alpha:1))
]
let appFolders=["photo":"photo-pdf-to-size","what":"what","chickmark":"chickmark"]

func text(_ value:String,x:CGFloat,y:CGFloat,maxWidth:CGFloat,font:CGFloat,color:NSColor,weight:NSFont.Weight = .regular,lines:CGFloat=3) {
 let paragraph=NSMutableParagraphStyle()
 paragraph.lineBreakMode = .byWordWrapping
 let attr:[NSAttributedString.Key:Any] = [.font:NSFont.systemFont(ofSize:font,weight:weight),.foregroundColor:color,.paragraphStyle:paragraph]
 let asText=NSAttributedString(string:value,attributes:attr)
 asText.draw(with:NSRect(x:x,y:y,width:maxWidth,height:font*lines),options:[.usesLineFragmentOrigin,.usesFontLeading])
}
func round(_ rect:NSRect,_ radius:CGFloat,_ color:NSColor) {
 color.setFill()
 NSBezierPath(roundedRect:rect,xRadius:radius,yRadius:radius).fill()
}
func drawScreenshot(_ image:NSImage,rect:NSRect,sourceHeight:CGFloat,topOffset:CGFloat=0) {
 let src=image.size
 let crop=NSRect(x:0,y:max(0,src.height-sourceHeight-topOffset),width:src.width,height:min(sourceHeight,src.height))
 NSGraphicsContext.saveGraphicsState()
 let outline=NSBezierPath(roundedRect:rect,xRadius:27,yRadius:27)
 outline.addClip()
 image.draw(in:rect,from:crop,operation:.sourceOver,fraction:1)
 NSGraphicsContext.restoreGraphicsState()
}
func generate(_ app:String,_ lang:String,_ region:String,_ position:Int) throws {
 let listing=try JSONDecoder().decode(Listing.self,from:Data(contentsOf:URL(fileURLWithPath:stage+"/\(app).json")))
 guard let page=listing.localeData[region] else { throw NSError(domain:"missing",code:2) }
 let s=manifest.apps[app]!.slots
 func file(_ pos:Int)->String {
  s.first(where:{$0.locale==region && $0.device=="ipad-13" && $0.position==pos})!.path
 }
 let companion=app=="what" && position==3 ? 2 : position%4+1
 guard let a=NSImage(contentsOfFile:root+"/"+file(position)),let b=NSImage(contentsOfFile:root+"/"+file(companion)) else {throw NSError(domain:"missing images",code:3)}
 let canvas=NSImage(size:NSSize(width:2064,height:2752))
 canvas.lockFocus()
 let (dark,bright,accent)=themes[app]!
 NSGradient(starting:dark,ending:bright)!.draw(in:NSRect(x:0,y:0,width:2064,height:2752),angle:65)
 round(NSRect(x:106,y:2502,width:350,height:70),35,accent.withAlphaComponent(0.15))
 text("ARVECTUM TOOLS",x:143,y:2518,maxWidth:510,font:31,color:accent,weight:.semibold,lines:1)
 var heading=page.screenshots[position-1]
 if app=="photo" && position==1 {
  heading=page.subtitle
 }
 let wide=heading.range(of:"[\u{3040}-\u{30FF}\u{3400}-\u{9FFF}]",options:.regularExpression) != nil
 let estimated=Double(heading.count)*(wide ? 1.0 : 0.57)
 let fontsize:CGFloat=CGFloat(min(120,max(68,1700.0/max(1.0,estimated))))
 text(heading,x:110,y:2204,maxWidth:1820,font:fontsize,color:.white,weight:.bold,lines:1)
 text(page.name,x:115,y:2090,maxWidth:1780,font:55,color:accent,weight:.medium,lines:1)
 // Genuine native SwiftUI screenshot, cropped but never inventing any controls.
 round(NSRect(x:82,y:916,width:1900,height:1095),40,.white.withAlphaComponent(0.12))
 drawScreenshot(a,rect:NSRect(x:105,y:939,width:1854,height:1055),sourceHeight:1175,topOffset:app=="what" ? (position==1 ? 380 : position==4 ? 690 : 0) : 0)
 let secondCaption=page.screenshots[companion-1]
 let secondWide=secondCaption.range(of:"[\u{3040}-\u{30FF}\u{3400}-\u{9FFF}]",options:.regularExpression) != nil
 let secondFont:CGFloat=CGFloat(min(58,max(40,1570.0/max(1.0,Double(secondCaption.count)*(secondWide ? 1.0 : 0.55)))))
 text(secondCaption,x:125,y:753,maxWidth:1800,font:secondFont,color:.white,weight:.semibold,lines:1)
 round(NSRect(x:204,y:95,width:1656,height:600),34,.white.withAlphaComponent(0.12))
 drawScreenshot(b,rect:NSRect(x:223,y:112,width:1618,height:560),sourceHeight:715,topOffset:app=="what" ? (companion == 4 ? 880 : companion == 1 ? 700 : 0) : 0)
 text("ARVECTUM",x:110,y:13,maxWidth:680,font:24,color:accent,weight:.medium,lines:1)
 canvas.unlockFocus()
 let rep=NSBitmapImageRep(data:canvas.tiffRepresentation!)!
 let out=root+"/"+appFolders[app]!+"/store-assets/appstore/marketing-20261027/"+lang+"/ipad-13/"+String(format:"%02d-hero.jpg",position)
 try FileManager.default.createDirectory(atPath:(out as NSString).deletingLastPathComponent,withIntermediateDirectories:true)
 guard let bytes=rep.representation(using:.jpeg,properties:[.compressionFactor:0.9]) else {throw NSError(domain:"encode",code:4)}
 try bytes.write(to:URL(fileURLWithPath:out))
 print("\(app) \(lang) \(bytes.count)")
}

for app in ["photo","what","chickmark"] {
 for (lang,region) in locales {
  for position in 1...4 { try generate(app,lang,region,position) }
 }
}
