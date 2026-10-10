#!/usr/bin/env python3
"""Validate offline App Store screenshot variants without uploading them."""
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]/'app-store/screenshots'
SETS=[('1.3-export-iphone-1320x2868',(1320,2868),3),('1.3-export-watch-416x496',(416,496),1)]
errors=[]
for directory,(width,height),count in SETS:
 for locale in ('en','ru','es'):
  paths=sorted((ROOT/directory/locale).glob('*.png'))
  if len(paths)!=count:errors.append(f'{directory}/{locale}: expected {count} images, got {len(paths)}')
  for path in paths:
   out=subprocess.check_output(['sips','-g','pixelWidth','-g','pixelHeight',str(path)],text=True)
   if f'pixelWidth: {width}' not in out or f'pixelHeight: {height}' not in out:
    errors.append(f'{path}: incorrect pixels')
   if path.stat().st_size<10_000:errors.append(f'{path}: unexpected small image')
print(f'Store screenshots: {sum(len(list((ROOT/d/l).glob("*.png"))) for d,_,_ in SETS for l in ("en","ru","es"))} PNG assets validated. Errors={errors}')
sys.exit(bool(errors))
