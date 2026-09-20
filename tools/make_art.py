#!/usr/bin/env python3
"""Original editable vector art and small synthesized sounds. No dependencies."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "assets/art"
INK = "#70584c"


def svg(name, body, w=100, h=100):
    (ART / f"{name}.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
        f'viewBox="0 0 {w} {h}"><g stroke="{INK}" stroke-width="2.8" '
        f'stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>\n'
    )


def path(d, fill="none", extra=""):
    return f'<path d="{d}" fill="{fill}" {extra}/>'


def rect(x, y, w, h, fill, r=0, extra=""):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" {extra}/>'


def ellipse(x, y, rx, ry, fill, extra=""):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" {extra}/>'


def group(body, transform):
    return f'<g transform="{transform}">{body}</g>'


def leaf(x=0, y=0, scale=1):
    return group(
        path("M0 34 Q-32 10 -15 -9 Q14 -8 0 34", "#a9ba89")
        + path("M0 34 Q27 12 25 -6 Q0 -9 0 34", "#c3c99b")
        + path("M0 44 L0 17"), f"translate({x} {y}) scale({scale})")


def plant():
    return (leaf(50, 20) + leaf(40, 34, .6)
            + path("M26 60 L33 89 Q50 96 67 89 L75 60 Z", "#d79677")
            + ellipse(50, 60, 25, 6, "#e7ac8c")
            + path("M40 72 L43 85 M57 73 L55 85", extra='opacity=".4"'))


def book(fill="#b2bd98"):
    return (path("M16 21 Q34 15 49 25 Q66 14 85 21 L85 77 Q65 71 49 82 Q34 72 16 78 Z", fill)
            + path("M21 24 Q36 21 49 29 Q64 20 80 24 L80 72 Q62 68 49 77 Q34 68 21 73 Z", "#fff7e6")
            + path("M49 29 L49 77 M28 35 L40 38 M28 44 L40 47 M59 37 L73 32 M59 46 L73 42 M59 55 L70 51", extra='stroke-width="2"')
            + path("M60 23 L60 44 L65 39 L70 41 L70 22", "#dfa291"))


def carrot():
    return (path("M43 35 Q22 28 24 12 Q46 10 48 31 Q42 6 57 7 Q66 21 53 34 Q64 16 77 23 Q74 42 55 42", "#aebc8d")
            + path("M37 33 Q50 27 61 43 Q59 64 28 89 Q24 55 37 33", "#e9ac76")
            + path("M36 47 L45 51 M31 60 L39 64 M45 65 L50 67", extra='stroke="#bf8059"'))


def star():
    return path("M50 10 L62 35 L90 40 L70 60 L74 88 L50 74 L25 88 L30 60 L10 40 L38 35 Z", "#e8bd70")


def mushroom():
    return (path("M40 47 L36 82 Q50 95 65 82 L60 47", "#fff5dd")
            + path("M11 48 Q15 9 49 10 Q85 12 91 49 Q52 66 11 48", "#d4917b")
            + ellipse(35, 30, 7, 6, "#fff3d9", 'stroke="none"')
            + ellipse(65, 35, 10, 7, "#fff3d9", 'stroke="none"'))


def bear(sleep=False):
    # Pip is a hazelnut-colored bear with a leaf tucked behind one ear.
    b = ellipse(91, 146, 66, 13, "#a98a79", 'opacity=".14" stroke="none"')
    b += ellipse(90, 109, 47, 42, "#d1ad88")
    b += ellipse(90, 121, 27, 25, "#f7e6cd", 'stroke="none"')
    b += ellipse(49, 122, 13, 23, "#d1ad88", 'transform="rotate(20 49 122)"')
    b += ellipse(130, 122, 13, 23, "#d1ad88", 'transform="rotate(-20 130 122)"')
    b += ellipse(62, 147, 20, 12, "#d1ad88") + ellipse(115, 147, 20, 12, "#d1ad88")
    b += ellipse(45, 41, 22, 22, "#d1ad88") + ellipse(134, 41, 22, 22, "#d1ad88")
    b += ellipse(45, 41, 12, 12, "#e8b5a4", 'stroke="none"') + ellipse(134, 41, 12, 12, "#e8b5a4", 'stroke="none"')
    b += path("M35 54 Q41 18 88 22 Q139 19 147 59 Q162 100 128 112 Q88 128 48 108 Q20 93 35 54", "#d1ad88")
    b += ellipse(89, 89, 29, 20, "#f9e6c9", 'stroke="none"')
    if sleep:
        b += path("M58 74 Q65 81 72 74 M107 74 Q114 81 121 74", extra='stroke-width="3.5"')
    else:
        b += ellipse(65, 73, 3.5, 5, INK, 'stroke="none"') + ellipse(114, 73, 3.5, 5, INK, 'stroke="none"')
        b += ellipse(66, 71, 1, 1.5, "#fff8e9", 'stroke="none"') + ellipse(115, 71, 1, 1.5, "#fff8e9", 'stroke="none"')
    b += ellipse(48, 88, 11, 6, "#dfa692", 'stroke="none" opacity=".8"') + ellipse(131, 88, 11, 6, "#dfa692", 'stroke="none" opacity=".8"')
    b += path("M82 83 Q90 78 97 83 Q97 91 90 93 Q83 90 82 83", INK)
    b += path("M90 93 L90 97 Q83 104 79 97 M90 97 Q97 104 101 97", extra='stroke-width="2"')
    b += path("M123 32 Q125 9 148 9 Q151 30 123 32", "#a6b680") + path("M123 32 L139 19", extra='stroke-width="2"')
    b += path("M67 114 Q90 125 116 112 L117 126 Q90 137 65 127 Z", "#b1bd97")
    b += path("M107 126 L119 145 L104 148 L97 129", "#b1bd97")
    return b


def room():
    b = '<defs><clipPath id="floor"><path d="M54 381 L786 381 L945 458 L212 548 L54 453 Z"/></clipPath></defs>'
    b += ellipse(495, 539, 457, 38, "#a88b76", 'stroke="none" opacity=".10"')
    # Cutaway walls and soft wooden floor.
    b += path("M54 57 L786 57 L945 135 L945 458 L786 381 L54 381 Z", "#f1dfc9")
    b += path("M786 57 L945 135 L945 458 L786 381 Z", "#e8d1b9")
    for x in range(77, 780, 37):
        b += path(f"M{x} 62 L{x} 377", extra='stroke="#e6cdb6" stroke-width="1.2"')
    for y in range(88, 330, 61):
        for x in range(86, 756, 74):
            b += path(f"M{x} {y-4} Q{x+7} {y} {x} {y+4} Q{x-7} {y} {x} {y-4}", "#dfbea6", 'stroke="none" opacity=".45"')
    b += path("M54 381 L786 381 L945 458 L212 548 L54 453 Z", "#e2bd98")
    b += path("M54 372 L786 372 L945 449 L945 462 L786 388 L54 389 Z", "#f6e7ce")
    b += '<g clip-path="url(#floor)">'
    for y in (407, 431, 458, 487, 518):
        b += path(f"M{54+max(0,y-452)*1.7} {y} L{min(940,800+(y-381)*2)} {y-19}", extra='stroke="#cda782" stroke-width="1.5"')
    for x,y in ((169,409),(402,403),(640,397),(290,438),(559,430),(812,423),(165,474),(440,462),(723,455),(365,495),(635,485),(820,480),(473,520)):
        b += path(f"M{x} {y} l34 23 M{x+53} {y+8} l39 -1", extra='stroke="#cda782" stroke-width="1.2"')
    b += '</g>'
    # Arched window and view into the garden.
    b += path("M267 282 L267 144 Q267 61 359 63 Q451 60 451 145 L451 282 Z", "#d1b998")
    b += path("M277 270 L277 146 Q277 76 359 76 Q440 77 440 146 L440 270 Z", "#ceded5")
    b += ellipse(397, 115, 21, 21, "#fff0c9", 'stroke="none"')
    b += path("M280 232 Q309 196 340 223 Q376 182 438 220 L438 269 L280 269 Z", "#b4c3a0", 'stroke="none"')
    b += path("M280 251 Q326 214 366 246 Q407 226 438 241 L438 269 L280 269 Z", "#91aa85", 'stroke="none"')
    b += path("M359 76 L359 274 M277 175 L440 175", extra='stroke="#eee4c9" stroke-width="9"')
    b += rect(256, 272, 207, 13, "#f9eace", 4)
    b += path("M252 92 Q268 67 294 64 Q304 160 279 247 L245 249 Q266 165 252 92", "#e7b4a5")
    b += path("M424 67 Q445 72 462 94 Q446 170 465 250 L432 247 Q410 160 424 67", "#e7b4a5")
    b += path("M268 98 Q277 154 261 229 M445 104 Q430 168 449 233", extra='stroke="#c8978a" stroke-width="2"')
    b += path("M249 233 L282 237 M431 235 L462 230", extra='stroke="#ad8b6a" stroke-width="4"')
    # Hanging light.
    b += path("M555 58 L555 103") + path("M517 131 Q522 102 555 102 Q588 102 594 131 Z", "#b6b990")
    b += ellipse(555, 131, 38, 6, "#f5dfb1") + ellipse(555, 136, 8, 7, "#f9eacc", 'stroke="none"')
    # Left cabinet with drawers and tiny jars.
    b += path("M91 281 L202 281 L222 294 L222 400 L203 410 L91 402 Z", "#bd9976")
    b += rect(88, 283, 116, 119, "#d4b48f", 5) + rect(79, 275, 134, 13, "#f3d9b4", 4)
    for y in (298, 345):
        b += rect(97, y, 97, 39, "#e4c49e", 4) + ellipse(145, y+20, 4, 3, "#927957")
    b += path("M96 402 L95 417 M192 403 L193 417", extra='stroke-width="7"')
    b += group(plant(), "translate(96 192) scale(.83)")
    b += rect(174, 247, 20, 27, "#eee2c8", 5) + rect(172, 244, 24, 6, "#b4bb94", 3)
    # Small framed botanical and wall shelf.
    b += rect(104, 113, 83, 88, "#bea283", 4) + rect(111, 120, 69, 74, "#fff4de", 2)
    b += group(leaf(), "translate(144 139) scale(.8)")
    b += rect(505, 193, 179, 12, "#d3af86", 3)
    b += path("M524 205 L524 220 M664 205 L664 219", extra='stroke-width="5"')
    b += rect(523, 145, 17, 46, "#b6bc92", 2) + rect(542, 151, 13, 40, "#d1a188", 2) + rect(558, 142, 18, 49, "#b5c3c0", 2)
    b += path("M527 153 L536 153 M561 151 L571 151", extra='stroke="#f6ebd8" stroke-width="2"')
    b += group(mushroom(), "translate(612 143) scale(.48)")
    # Reading chair.
    b += path("M531 326 L675 326 L673 395 L541 403 Z", "#a8b18b")
    b += rect(528, 259, 146, 113, "#c7ccaa", 29)
    b += rect(537, 271, 125, 85, "#d6dabb", 25)
    b += path("M526 349 Q594 327 678 349 L678 379 Q588 393 526 373 Z", "#bcc6a0")
    b += rect(514, 320, 30, 67, "#b3be98", 14) + rect(659, 316, 29, 67, "#b3be98", 14)
    b += path("M540 389 L536 410 M665 386 L670 404", extra='stroke-width="8"')
    b += path("M553 288 Q579 279 603 291 L605 331 Q579 341 554 331 Z", "#f0d3b1")
    b += path("M563 302 L593 322 M593 302 L564 322", extra='stroke="#dab895" stroke-width="1.5"')
    b += path("M620 328 L645 327 L649 386 L620 388 Z", "#d69c86")
    b += path("M625 334 L629 380 M637 334 L641 380", extra='stroke="#ecc5aa" stroke-width="2"')
    # Bookcase on right wall.
    b += path("M726 221 L810 229 L833 242 L833 408 L811 419 L726 406 Z", "#b79978")
    b += rect(721, 222, 92, 185, "#d7b891", 4)
    for y in (233, 289, 348):
        b += rect(730, y, 73, 49, "#ab8d6c", 1)
    for x,y,c,h in ((737,239,"#c1c7a2",42),(752,248,"#e3b39b",33),(769,235,"#b9c7c5",46),(786,244,"#ddc699",37)):
        b += rect(x,y,12,h,c,2) + path(f"M{x+3} {y+8} h6", extra='stroke="#fff0d4" stroke-width="1.5"')
    b += group(book(), "translate(735 297) scale(.63)")
    b += rect(737, 358, 58, 35, "#d8bd98", 6)
    b += path("M740 366 L792 366 M740 374 L792 374 M745 358 L745 390 M756 358 L756 390 M769 358 L769 390 M782 358 L782 390", extra='stroke="#ac8c68" stroke-width="1.3"')
    b += group(plant(), "translate(727 134) scale(.85)")
    # Rug: scalloped fringe and woven lines.
    b += ellipse(448, 457, 202, 62, "#ba9879", 'opacity=".10" stroke="none"')
    for i in range(37):
        a=i*math.tau/37
        x,y=448+194*math.cos(a),452+57*math.sin(a)
        b += path(f"M{x:.1f} {y:.1f} l{10*math.cos(a):.1f} {5*math.sin(a):.1f}", extra='stroke="#be947e" stroke-width="2"')
    b += ellipse(448, 452, 193, 57, "#e8bda5") + ellipse(448, 452, 171, 43, "#f0d0b5", 'stroke="#cda38a" stroke-width="1.5"')
    b += ellipse(448, 452, 160, 37, "none", 'stroke="#dcb396" stroke-width="1.4" stroke-dasharray="3 5"')
    b += path("M314 452 Q446 399 582 452 Q446 505 314 452", "none", 'stroke="#ddb497" stroke-width="1.4"')
    # Low table and teacup.
    b += path("M251 382 L244 424 M328 381 L335 421", extra='stroke-width="7"')
    b += ellipse(288, 376, 62, 21, "#ba9774") + ellipse(288, 370, 64, 20, "#eed3ad")
    b += ellipse(290, 365, 18, 5, "#f6e7cf")
    b += path("M278 345 L280 360 Q290 369 300 360 L303 345 Z", "#f6eedb")
    b += path("M303 347 Q318 345 312 357 Q309 360 302 356")
    b += ellipse(290, 345, 13, 4, "#a99175") + path("M288 334 Q281 329 289 323", extra='stroke="#ae9a82" opacity=".5"')
    # Round basket and soft blanket.
    b += path("M823 433 L830 463 Q860 482 891 462 L897 433 Z", "#d9b58b")
    b += ellipse(860, 433, 37, 12, "#c9a67e")
    b += path("M830 429 Q848 408 870 427 L891 430 L884 449 Q855 458 834 440 Z", "#d5c8d3")
    b += path("M838 430 Q855 441 880 430 M844 423 Q860 433 879 429", extra='stroke="#b3a4b5" stroke-width="2"')
    b += path("M835 448 L837 464 M847 450 L849 469 M861 451 L862 470 M875 450 L875 468 M887 448 L885 463", extra='stroke="#b9946f" stroke-width="1.5"')
    # Foreground slippers and a tiny toy.
    b += path("M639 462 Q652 449 669 460 L676 477 Q660 487 643 478 Z", "#e6d8ba")
    b += path("M674 454 Q688 443 701 453 L710 469 Q695 481 681 472 Z", "#e6d8ba")
    b += path("M646 467 Q657 460 671 467 M682 459 Q693 454 703 460", extra='stroke="#bba586" stroke-width="2"')
    return b


def main():
    ART.mkdir(parents=True, exist_ok=True)
    svg("room", room(), 1000, 590)
    svg("pip", bear(), 180, 166)
    svg("pip_sleep", bear(True), 180, 166)
    svg("icon", rect(3, 3, 174, 174, "#f7ebd8", 40) + group(bear(), "translate(12 19) scale(.87)"), 180, 180)
    svg("plant", plant())
    svg("book", book())
    svg("carrot", carrot())
    svg("leaf", leaf(46, 29, 1.2))
    svg("star", star())
    svg("mushroom", mushroom())
    svg("home", path("M13 46 L50 13 L88 46", "#e3b9a0") + path("M23 40 L23 84 L77 84 L77 40 L50 18 Z", "#f1dfbe") + rect(43, 56, 17, 28, "#b8c49c", 5) + rect(29, 47, 10, 12, "#d0dfd7", 2))
    svg("broom", path("M65 13 L40 65", extra='stroke-width="8" stroke="#bd9a77"') + path("M30 56 L53 68 L51 88 Q25 89 13 70 Z", "#e3c17f") + path("M23 69 L19 76 M33 72 L30 84 M43 75 L40 86", extra='stroke="#b49356" stroke-width="2"'))
    svg("moon", path("M72 16 Q45 9 27 31 Q6 63 39 83 Q64 98 85 69 Q61 75 49 52 Q41 32 59 21 Z", "#e5c688") + group(star(), "translate(56 4) scale(.32)"))
    svg("heart", path("M50 85 Q5 55 13 29 Q26 6 50 30 Q74 6 88 29 Q95 56 50 85", "#d79d8b"))
    svg("coin", ellipse(50, 50, 34, 34, "#ead09c") + ellipse(50, 50, 26, 26, "none", 'stroke="#bd995d" stroke-width="2"') + group(leaf(), "translate(49 31) scale(.65)"))
    svg("bag", rect(19, 29, 62, 58, "#e7c4a1", 9) + path("M34 37 L34 24 Q50 4 65 24 L65 37") + group(leaf(), "translate(50 50) scale(.55)"))
    svg("sound", path("M17 39 L34 39 L54 21 L54 80 L34 63 L17 63 Z", "#c1caa6") + path("M66 35 Q82 50 66 67 M76 25 Q100 50 76 77", extra='stroke-width="4"'))
    svg("settings", ellipse(50, 50, 29, 29, "#d8c8b1") + ellipse(50, 50, 10, 10, "#faf3e5") + "".join(path(f"M{50+29*math.cos(i*math.tau/8):.2f} {50+29*math.sin(i*math.tau/8):.2f} L{50+38*math.cos(i*math.tau/8):.2f} {50+38*math.sin(i*math.tau/8):.2f}", extra='stroke-width="10"') for i in range(8)))
    svg("flower", path("M50 54 L50 86") + leaf(50, 52, .55) + "".join(ellipse(50+16*math.cos(i*math.tau/5), 35+16*math.sin(i*math.tau/5), 12, 13, "#e5b1a5") for i in range(5)) + ellipse(50, 35, 10, 10, "#e6c77d"))
    svg("yarn", ellipse(50, 45, 29, 29, "#c6b4c9") + path("M27 26 Q48 32 72 63 M24 38 Q48 39 66 70 M24 51 Q39 51 54 74 M52 17 Q40 23 33 29 M64 23 Q51 28 44 37 M76 40 Q70 38 64 37 M79 49 Q85 79 67 83 Q51 90 39 80"))
    svg("apple", path("M49 34 Q30 16 17 41 Q9 69 33 87 Q42 90 50 85 Q65 96 80 73 Q96 43 75 30 Q62 25 49 34", "#d99882") + path("M50 35 Q46 18 55 11", extra='stroke-width="4"') + path("M53 24 Q53 9 75 11 Q75 28 53 24", "#acba8b") + path("M26 46 Q20 57 27 64", extra='stroke="#f4c4ae" stroke-width="4"'))
    svg("ball", ellipse(50, 50, 34, 34, "#dab192") + path("M21 32 Q55 47 72 76 M29 78 Q42 46 71 24", extra='stroke="#f6e5c9" stroke-width="7"'))
    svg("lamp", path("M51 39 L51 87 M30 87 L72 87", extra='stroke-width="5"') + path("M30 18 L71 18 L85 53 Q50 63 16 53 Z", "#c5c8a2") + path("M40 23 L33 48 M59 24 L67 49", extra='stroke="#a6af88" stroke-width="2"'))
    svg("cushion", path("M17 23 Q50 15 83 24 Q90 51 83 80 Q50 89 17 81 Q10 51 17 23", "#d5bfd2") + path("M24 32 L75 72 M74 32 L24 72", extra='stroke="#b79eb5" stroke-width="2"') + ellipse(49, 50, 4, 4, "#b59bb1"))
    svg("picture", rect(13, 10, 74, 82, "#c2a17f", 4) + rect(20, 17, 60, 68, "#f9efd9", 2) + group(leaf(), "translate(50 33) scale(.8)"))
    svg("check", path("M23 51 L43 71 L79 28", extra='stroke="#7f946e" stroke-width="8"'))
    svg("arrow", path("M20 50 L78 50 M57 28 L79 50 L57 72", extra='stroke="#918577" stroke-width="6"'))
    # Soft celesta-like tones, bundled as WAV so browser/native playback agrees.
    audio = ROOT / "assets/audio"
    audio.mkdir(exist_ok=True)
    for name, notes in {"tap": [659], "correct": [523, 659, 784], "complete": [523, 659, 784, 1047], "soft": [392, 440], "buy": [659, 784, 988]}.items():
        rate = 22050
        duration = .18 * len(notes) + .45
        frames = []
        for i in range(int(rate * duration)):
            t = i / rate
            value = 0
            for n, hz in enumerate(notes):
                dt = t - n*.15
                if dt >= 0:
                    value += .14 * min(1, dt*100) * math.exp(-dt*7) * (math.sin(math.tau*hz*dt) + .2*math.sin(math.tau*hz*2*dt))
            frames.append(struct.pack("<h", max(-32767, min(32767, int(value*32767)))))
        with wave.open(str(audio / f"{name}.wav"), "wb") as f:
            f.setparams((1, 2, rate, 0, "NONE", "not compressed"))
            f.writeframes(b"".join(frames))
    print(f"Generated {len(list(ART.glob('*.svg')))} original SVG assets and 5 sounds.")


if __name__ == "__main__":
    main()
