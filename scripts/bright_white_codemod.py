from pathlib import Path
import re
import subprocess

root = Path('/Users/victor/Documents/work/ReadinessTracker/ReadinessTracker')
files = list(root.rglob('*.swift'))
changed = []
kept_white = []

accent_bg = re.compile(
    r'\.background\(\s*(Color\.green|Color\.blue|Color\.red|Color\.orange|Color\.accentColor|RTColor\.(optimal|good|caution|warning|sleep|hrv|recovery|strain|consistency))',
    re.M
)

for path in files:
    text = path.read_text()
    if 'foregroundStyle(.white)' not in text and 'foregroundColor(.white)' not in text:
        continue
    lines = text.splitlines(keepends=True)
    out = []
    i = 0
    file_changes = 0
    while i < len(lines):
        line = lines[i]
        if re.search(r'foreground(Style|Color)\(\.white\)', line):
            window = ''.join(lines[i:i+9])
            if accent_bg.search(window):
                out.append(line)
                kept_white.append(f'{path.name}:{i+1}')
            else:
                newline = line.replace('foregroundStyle(.white)', 'foregroundStyle(RTColor.primaryText)')
                newline = newline.replace('foregroundColor(.white)', 'foregroundColor(RTColor.primaryText)')
                out.append(newline)
                file_changes += 1
        else:
            out.append(line)
        i += 1
    if file_changes:
        path.write_text(''.join(out))
        changed.append((str(path.relative_to(root.parent)), file_changes))

print('Changed files:')
for p, n in sorted(changed):
    print(f'  {p}: {n}')
print(f'Total replacements: {sum(n for _, n in changed)}')
print('Kept white (accent bg ahead):')
for k in kept_white:
    print(f'  {k}')
r = subprocess.run(
    ['rg', '-n', r'foreground(Style|Color)\(\.white\)', 'ReadinessTracker', '--glob', '*.swift'],
    cwd='/Users/victor/Documents/work/ReadinessTracker',
    capture_output=True,
    text=True,
)
print('Remaining white foregrounds:')
print(r.stdout)
