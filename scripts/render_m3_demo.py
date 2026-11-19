"""Trim the captured demo and add Turkish captions below the app viewport."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', required=True)
    parser.add_argument('--font', default='C:/Windows/Fonts/arial.ttf')
    args = parser.parse_args()
    output = Path(__file__).resolve().parent.parent / 'output' / 'm3-demo'
    markers = json.loads((output / 'markers.json').read_text(encoding='utf-8-sig'))
    start = max(0, markers['ROUTINE'] - 3)
    end = min(43, markers['FINISHED'] + 1)
    duration = end - start
    stages = [
        (0, 'GymGym-A | M3 Android demosu\nYerel Firebase ve örnek antrenman verileri'),
        (markers['ROUTINE'] - start, 'Rutin içeriği görüntülenir.\nStart workout ile antrenman başlatılır.'),
        (markers['GHOSTS'] - start, 'Önceki set: 60 kg × 8 tekrar.\nSoluk değerler henüz kayıt değildir.'),
        (markers['ACCEPTED'] - start, 'Complete set ile önceki değerler onaylanır.\nAntrenman çevrimdışı tamamlanır.'),
        (markers['SUMMARY'] - start, 'Özet: 480 kg toplam hacim, 1 set.\nSüre ve egzersiz sayısı da gösterilir.'),
        (markers['HISTORY'] - start, 'Tamamlanan antrenman History ekranındadır.\nBağlantı gelince sunucuya senkronize edilir.'),
    ]
    # App pixels are scaled proportionally; captions occupy a separate black band.
    shutil.copyfile(args.font, output / 'demo-font.ttf')
    filters = ['setpts=PTS-STARTPTS', 'fps=30', 'scale=540:-2', 'pad=iw:ih+100:0:0:black']
    for index, (begin, caption) in enumerate(stages):
        finish = stages[index + 1][0] if index + 1 < len(stages) else duration
        filename = f'caption-{index}.txt'
        (output / filename).write_text(caption, encoding='utf-8')
        filters.append(
            f"drawtext=fontfile=demo-font.ttf:textfile={filename}:"
            f"fontsize=17:fontcolor=white:line_spacing=4:x=(w-tw)/2:y=h-84:"
            f"enable='gte(t,{begin:.3f})*lt(t,{finish:.3f})'"
        )
    destination = 'GymGym-A_M3_Android_Demo.mp4'
    subprocess.run([
        args.ffmpeg, '-y', '-hide_banner', '-loglevel', 'warning',
        '-ss', f'{start:.3f}', '-i', 'GymGym-A_M3_Android_Demo_raw.mp4',
        '-t', f'{duration:.3f}', '-vf', ','.join(filters),
        '-c:v', 'libx264', '-crf', '20', '-preset', 'fast',
        '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-an', destination,
    ], cwd=output, check=True)
    # Decode the complete result to catch corruption, not just the container header.
    subprocess.run([args.ffmpeg, '-v', 'error', '-i', destination, '-f', 'null', '-'],
                   cwd=output, check=True)
    for index, time in enumerate([1, markers['GHOSTS'] - start + 1,
                                  markers['SUMMARY'] - start + 1,
                                  markers['HISTORY'] - start + 1]):
        subprocess.run([args.ffmpeg, '-y', '-loglevel', 'error', '-ss', f'{time:.3f}',
                        '-i', destination, '-frames:v', '1', f'verify-{index}.png'],
                       cwd=output, check=True)
    print(json.dumps({'file': str(output / destination), 'durationSeconds': round(duration, 2),
                      'bytes': (output / destination).stat().st_size}, ensure_ascii=False))


if __name__ == '__main__':
    main()
