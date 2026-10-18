import SwiftUI

/// The same silhouette used by generate_brand.swift for the UhWhat app icon.
/// Drawn as a native Path to stay legible on one-color watch faces, even if
/// WidgetKit applies its own tint. This is NOT an SF microphone symbol.
struct WhatComplicationMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Official UhWhat app icon contour 1.
        p.move(to: CGPoint(x: 376, y: 208))
        p.addLines([
            CGPoint(x: 349, y: 220), CGPoint(x: 331, y: 233), CGPoint(x: 309, y: 258),
            CGPoint(x: 297, y: 285), CGPoint(x: 299, y: 301), CGPoint(x: 310, y: 315),
            CGPoint(x: 323, y: 320), CGPoint(x: 335, y: 319), CGPoint(x: 345, y: 314),
            CGPoint(x: 352, y: 306), CGPoint(x: 356, y: 287), CGPoint(x: 362, y: 275),
            CGPoint(x: 375, y: 266), CGPoint(x: 387, y: 266), CGPoint(x: 396, y: 270),
            CGPoint(x: 405, y: 279), CGPoint(x: 411, y: 295), CGPoint(x: 411, y: 311),
            CGPoint(x: 404, y: 334), CGPoint(x: 395, y: 350), CGPoint(x: 326, y: 435),
            CGPoint(x: 309, y: 462), CGPoint(x: 292, y: 499), CGPoint(x: 282, y: 537),
            CGPoint(x: 279, y: 567), CGPoint(x: 282, y: 611), CGPoint(x: 292, y: 654),
            CGPoint(x: 310, y: 701), CGPoint(x: 330, y: 738), CGPoint(x: 362, y: 781),
            CGPoint(x: 392, y: 810), CGPoint(x: 427, y: 835), CGPoint(x: 457, y: 851),
            CGPoint(x: 505, y: 869), CGPoint(x: 547, y: 879), CGPoint(x: 564, y: 888),
            CGPoint(x: 575, y: 899), CGPoint(x: 583, y: 920), CGPoint(x: 575, y: 990),
            CGPoint(x: 575, y: 1019), CGPoint(x: 579, y: 1033), CGPoint(x: 586, y: 1045),
            CGPoint(x: 604, y: 1060), CGPoint(x: 622, y: 1065), CGPoint(x: 641, y: 1063),
            CGPoint(x: 658, y: 1054), CGPoint(x: 666, y: 1046), CGPoint(x: 677, y: 1023),
            CGPoint(x: 678, y: 993), CGPoint(x: 670, y: 917), CGPoint(x: 680, y: 896),
            CGPoint(x: 693, y: 885), CGPoint(x: 708, y: 878), CGPoint(x: 751, y: 868),
            CGPoint(x: 800, y: 849), CGPoint(x: 852, y: 817), CGPoint(x: 887, y: 785),
            CGPoint(x: 913, y: 753), CGPoint(x: 931, y: 724), CGPoint(x: 951, y: 682),
            CGPoint(x: 967, y: 630), CGPoint(x: 973, y: 592), CGPoint(x: 973, y: 554),
            CGPoint(x: 965, y: 512), CGPoint(x: 953, y: 480), CGPoint(x: 936, y: 449),
            CGPoint(x: 916, y: 421), CGPoint(x: 876, y: 375), CGPoint(x: 853, y: 342),
            CGPoint(x: 843, y: 318), CGPoint(x: 841, y: 298), CGPoint(x: 848, y: 278),
            CGPoint(x: 855, y: 271), CGPoint(x: 865, y: 266), CGPoint(x: 877, y: 266),
            CGPoint(x: 884, y: 269), CGPoint(x: 893, y: 278), CGPoint(x: 902, y: 308),
            CGPoint(x: 915, y: 318), CGPoint(x: 929, y: 320), CGPoint(x: 941, y: 316),
            CGPoint(x: 949, y: 309), CGPoint(x: 955, y: 297), CGPoint(x: 955, y: 282),
            CGPoint(x: 942, y: 256), CGPoint(x: 918, y: 230), CGPoint(x: 902, y: 219),
            CGPoint(x: 873, y: 207), CGPoint(x: 843, y: 204), CGPoint(x: 818, y: 210),
            CGPoint(x: 799, y: 222), CGPoint(x: 786, y: 237), CGPoint(x: 776, y: 260),
            CGPoint(x: 773, y: 281), CGPoint(x: 775, y: 306), CGPoint(x: 782, y: 330),
            CGPoint(x: 800, y: 364), CGPoint(x: 863, y: 449), CGPoint(x: 879, y: 482),
            CGPoint(x: 888, y: 512), CGPoint(x: 894, y: 555), CGPoint(x: 894, y: 588),
            CGPoint(x: 889, y: 626), CGPoint(x: 877, y: 668), CGPoint(x: 858, y: 709),
            CGPoint(x: 834, y: 744), CGPoint(x: 804, y: 775), CGPoint(x: 764, y: 803),
            CGPoint(x: 721, y: 822), CGPoint(x: 680, y: 832), CGPoint(x: 651, y: 835),
            CGPoint(x: 580, y: 833), CGPoint(x: 545, y: 826), CGPoint(x: 511, y: 814),
            CGPoint(x: 477, y: 796), CGPoint(x: 450, y: 776), CGPoint(x: 422, y: 748),
            CGPoint(x: 404, y: 724), CGPoint(x: 385, y: 690), CGPoint(x: 372, y: 657),
            CGPoint(x: 362, y: 616), CGPoint(x: 359, y: 591), CGPoint(x: 359, y: 550),
            CGPoint(x: 369, y: 496), CGPoint(x: 382, y: 463), CGPoint(x: 397, y: 437),
            CGPoint(x: 459, y: 354), CGPoint(x: 472, y: 327), CGPoint(x: 479, y: 298),
            CGPoint(x: 479, y: 272), CGPoint(x: 475, y: 254), CGPoint(x: 466, y: 236),
            CGPoint(x: 450, y: 219), CGPoint(x: 437, y: 211), CGPoint(x: 419, y: 205),
            CGPoint(x: 399, y: 204)
        ])
        p.closeSubpath()
        // Official UhWhat app icon contour 2.
        p.move(to: CGPoint(x: 418, y: 482))
        p.addLines([
            CGPoint(x: 413, y: 492), CGPoint(x: 413, y: 504), CGPoint(x: 422, y: 519),
            CGPoint(x: 440, y: 528), CGPoint(x: 476, y: 530), CGPoint(x: 476, y: 660),
            CGPoint(x: 480, y: 693), CGPoint(x: 495, y: 732), CGPoint(x: 511, y: 755),
            CGPoint(x: 524, y: 768), CGPoint(x: 542, y: 781), CGPoint(x: 578, y: 795),
            CGPoint(x: 598, y: 798), CGPoint(x: 655, y: 798), CGPoint(x: 679, y: 794),
            CGPoint(x: 707, y: 783), CGPoint(x: 725, y: 771), CGPoint(x: 744, y: 752),
            CGPoint(x: 762, y: 724), CGPoint(x: 775, y: 681), CGPoint(x: 776, y: 531),
            CGPoint(x: 778, y: 529), CGPoint(x: 808, y: 529), CGPoint(x: 827, y: 522),
            CGPoint(x: 835, y: 514), CGPoint(x: 840, y: 503), CGPoint(x: 840, y: 492),
            CGPoint(x: 832, y: 479), CGPoint(x: 818, y: 473), CGPoint(x: 802, y: 474),
            CGPoint(x: 793, y: 478), CGPoint(x: 783, y: 490), CGPoint(x: 776, y: 488),
            CGPoint(x: 776, y: 480), CGPoint(x: 477, y: 480), CGPoint(x: 476, y: 489),
            CGPoint(x: 470, y: 490), CGPoint(x: 460, y: 478), CGPoint(x: 447, y: 473),
            CGPoint(x: 428, y: 475)
        ])
        p.closeSubpath()
        // Official UhWhat app icon contour 3.
        p.move(to: CGPoint(x: 477, y: 450))
        p.addLines([
            CGPoint(x: 478, y: 458), CGPoint(x: 776, y: 457), CGPoint(x: 774, y: 442),
            CGPoint(x: 764, y: 419), CGPoint(x: 741, y: 391), CGPoint(x: 710, y: 372),
            CGPoint(x: 693, y: 366), CGPoint(x: 668, y: 363), CGPoint(x: 659, y: 356),
            CGPoint(x: 659, y: 342), CGPoint(x: 672, y: 335), CGPoint(x: 678, y: 326),
            CGPoint(x: 676, y: 311), CGPoint(x: 664, y: 303), CGPoint(x: 589, y: 303),
            CGPoint(x: 581, y: 306), CGPoint(x: 575, y: 315), CGPoint(x: 575, y: 327),
            CGPoint(x: 582, y: 336), CGPoint(x: 593, y: 341), CGPoint(x: 595, y: 345),
            CGPoint(x: 593, y: 357), CGPoint(x: 584, y: 363), CGPoint(x: 564, y: 365),
            CGPoint(x: 545, y: 371), CGPoint(x: 513, y: 390), CGPoint(x: 493, y: 412),
            CGPoint(x: 484, y: 428)
        ])
        p.closeSubpath()
        let scale = min(rect.width, rect.height) / 1254.0
        return p.applying(
            CGAffineTransform(scaleX: scale, y: scale)
                .concatenating(
                    CGAffineTransform(
                        translationX: rect.midX - 627 * scale,
                        y: rect.midY - 627 * scale
                    )
                )
        )
    }
}
