"""Place untouched gameplay screenshots beside each other; labels sit outside them."""
from pathlib import Path
from hashlib import sha256
from PIL import Image, ImageDraw, ImageFont

base = Path(__file__).resolve().parents[1]
font = ImageFont.truetype(str(base.parents[1] / 'HUD/MPLUSRounded1c.ttf'), 28)
checksums = []
for name in ('01_normal.png', '02_star_power.png', '03_hud.png'):
    paths = [base / phase / name for phase in ('before', 'after')]
    frames = [Image.open(path).convert('RGB') for path in paths]
    assert frames[0].size == frames[1].size == (1920, 1080)
    width, height = frames[0].size
    canvas = Image.new('RGB', (width * 2 + 16, height + 56), '#eeeae1')
    draw = ImageDraw.Draw(canvas)
    for index, (frame, label) in enumerate(zip(frames, ('BEFORE', 'AFTER'))):
        x = index * (width + 16)
        draw.text((x + 20, 8), label, font=font, fill='#171c30')
        canvas.paste(frame, (x, 56))
        assert canvas.crop((x, 56, x + width, 56 + height)).tobytes() == frame.tobytes()
    canvas.save(base / 'comparisons' / name)
    for path in paths:
        checksums.append(f'{sha256(path.read_bytes()).hexdigest()}  {path.relative_to(base)}')
(base / 'screenshots.sha256').write_text('\n'.join(checksums) + '\n')
