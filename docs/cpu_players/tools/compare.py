"""Join untouched native viewport captures; labels occupy a separate margin."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib
import json
root = Path(__file__).resolve().parents[3]
directory = root / 'docs/cpu_players'
before = Image.open(directory / 'before/01_lobby.png').convert('RGB')
after = Image.open(directory / 'after/00_lobby_default.png').convert('RGB')
assert before.size == after.size == (1920, 1080)
comparison = Image.new('RGB', (3840, 1144), '#101629')
comparison.paste(before, (0, 64))
comparison.paste(after, (1920, 64))
font = ImageFont.truetype(str(root / 'HUD/Sniglet.ttf'), 38)
draw = ImageDraw.Draw(comparison)
draw.text((32, 10), 'BEFORE', font=font, fill='white')
draw.text((1952, 10), 'AFTER', font=font, fill='white')
assert comparison.crop((0, 64, 1920, 1144)).tobytes() == before.tobytes()
assert comparison.crop((1920, 64, 3840, 1144)).tobytes() == after.tobytes()
comparison.save(directory / 'comparisons/01_lobby.png')
manifest = {}
for phase in ['before', 'after']:
    for path in sorted((directory / phase).glob('*.png')):
        manifest[str(path.relative_to(directory))] = {
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
            'size': list(Image.open(path).size),
        }
(directory / 'screenshots.json').write_text(json.dumps(manifest, indent=2) + '\n')
print('Lobby comparison verified pixel-for-pixel; screenshots hashed.')
