#!/usr/bin/env python3
# 扫描 assets/ 下所有含 PNG 的子目录，自动重写 pubspec.yaml 的 flutter assets 声明。
# 背景：pubspec 里 "- assets/" 只包含 assets 根目录下的直接文件，不递归子目录；
# 本项目 PNG 全在 assets/<动作>/ 子目录里，导致 AssetManifest 为空、0 张图入包。
# 本脚本在 CI 的 flutter create / pub get 之后、build 之前运行，确定性生成全部目录声明。
import os

PUBSPEC = 'pubspec.yaml'
ASSETS_ROOT = 'assets'

dirs = []
for root, _, files in os.walk(ASSETS_ROOT):
    if any(f.lower().endswith('.png') for f in files):
        rel = root.replace('\\', '/').rstrip('/') + '/'
        dirs.append(rel)
dirs = sorted(set(dirs))

block = 'flutter:\n'
block += '  uses-material-design: true\n'
block += '  assets:\n'
for d in dirs:
    block += '    - %s\n' % d

s = open(PUBSPEC, encoding='utf-8').read()
idx = s.find('\nflutter:')
if idx == -1:
    head = s.rstrip() + '\n\n'
else:
    head = s[:idx + 1]

open(PUBSPEC, 'w', encoding='utf-8').write(head + block)

png_total = sum(
    len([f for f in fs if f.lower().endswith('.png')])
    for _, _, fs in os.walk(ASSETS_ROOT)
)
print('declared %d asset dirs, %d png files total' % (len(dirs), png_total))
for d in dirs:
    print('  -', d)
