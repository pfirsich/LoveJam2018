import math

from PIL import Image, ImageDraw

animations = {
    'idle': ["idle{}.png", (1, 2), 0.32],
    'run': ["run{}.png", (1, 8), 0.3],
    'sneak': ["sneak{}.png", (1, 6), 0.23],
    'attack_side': ["attack_side.png", (1, 1), 0.30],
    'attack_up': ["attack_up.png", (1, 1), 0.30],
    'attack_down': ["attack_down.png", (1, 1), 0.30],
    'dodge': ["dodge.png", (1, 1), 0.23],
    'jumpsquat': ["jump1.png", (1, 1), 0.34],
    'jump': ["jump2.png", (1, 1), 0.34],
    'fall': ["fall{}.png", (1, 2), 0.35],
    'land': ["land.png", (1, 1), 0.35],
    'climbV': ["climbV{}.png", (1, 4), 0.25],
    'climbH': ["climbH{}.png", (1, 4), 0.23],
    'dash': ["dash.png", (1, 1), 0.23],
}

tileCountX = 8
tileCountY = 5
tileSize = (512, 512)
scaleFactor = 2.25

sheetOrder = ['run', 'sneak', 'idle', 'climbH', 'climbV', 'fall',
    'attack_side', 'attack_up', 'attack_down', 'dodge',
    'jumpsquat', 'jump', 'land', 'dash']

frames = {}

for name, values in animations.items():
    frames[name] = []
    fname = values[0]
    first, last = values[1]
    scale = values[2]
    for i in range(first, last + 1):
        img = Image.open(fname.format(i))
        size = math.floor(img.size[0] * scale * scaleFactor + 0.5)
        scaled = img.resize((size, size), resample=Image.LANCZOS)
        scaled.save("temp/{}{}_scaled.png".format(name, i))
        # round up to nearest even, so we can half properly and never crop too little
        overlapX = math.ceil(max(0, size - tileSize[0]) / 2.0) * 2
        overlapY = math.ceil(max(0, size - tileSize[1]) / 2.0) * 2
        cropped = scaled
        if overlapX > 0 or overlapY > 0:
            cropRegion = (overlapX // 2, overlapY, size - overlapX // 2, size)
            print(name, i, scaled.size, cropRegion)
            #scaled.show()
            cropped = scaled.crop(cropRegion)
            #cropped.show()
            cropped.save("temp/{}{}_cropped.png".format(name, i))
        frames[name].append(cropped)

outImage = Image.new('RGBA', (tileCountX * tileSize[0], tileCountY * tileSize[1]))

tileX, tileY = 0, 0
for name in sheetOrder:
    for frame in frames[name]:
        tileBaseX, tileBaseY = tileX * tileSize[0], tileY * tileSize[1]
        x = tileBaseX + math.floor(tileSize[0]/2 - frame.size[0]/2 + 0.5)
        y = tileBaseY + math.floor(tileSize[1] - frame.size[1] + 0.5)
        outImage.paste(frame, (x, y))

        tileX += 1
        if tileX >= tileCountX:
            tileX = 0
            tileY += 1

if False:
    draw = ImageDraw.Draw(outImage)

    yStart, yEnd = 0, outImage.height
    for x in range(0, outImage.width, tileSize[1]):
        line = ((x, yStart), (x, yEnd))
        draw.line(line, fill='black')

    xStart, xEnd = 0, outImage.width
    for y in range(0, outImage.height, tileSize[0]):
        line = ((xStart, y), (xEnd, y))
        draw.line(line, fill='black')

outImage.save("ninja_sheet.png")
