#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Render one KinoVector view from SysML v2 to PNG.

The model is the only source of the drawing: OpenSysML writes Graphviz DOT,
this script removes the technical Cameo frame header, marks the include and
extend connectors of the use case view, and Graphviz rasterises the result.
Mockups keep the pixel coordinates and colours stated by DiagramLayout.
"""
import os
import re
import subprocess
import sys
import tempfile

SYSML = os.environ.get('SYSML', 'sysml')
MODEL = os.environ.get('MODEL', 'docs/design/kinovector.sysml')

USE_CASES = [
    'Просматривать каталог',
    'Искать и фильтровать фильмы',
    'Открывать карточку фильма',
    'Ставить оценку',
    'Писать рецензию',
    'Вести историю просмотров',
    'Получать персональные рекомендации',
    'Указывать предпочтения',
    'Отправлять жалобу на рецензию',
    'Модерировать рецензии',
    'Управлять каталогом и импортировать TMDB',
    'Выгружать и удалять персональные данные',
    'Смотреть аналитику',
]


def sysml_dot(view):
    out = subprocess.run(
        [SYSML, '-render', 'KinoVector::' + view, '-render-form', 'dot',
         '-render-style', 'cameo', MODEL],
        capture_output=True, text=True, check=True).stdout
    return out[out.index('digraph'):]


def clean(dot):
    """Drop the technical frame header, keep the frame border."""
    dot = dot.replace('&#39;', "'")
    lines = dot.splitlines()
    for i, line in enumerate(lines):
        if line.strip().startswith('subgraph "cluster_frame"'):
            j = i + 1
            while j < len(lines) and not lines[j].strip():
                j += 1
            if j < len(lines) and lines[j].strip().startswith('label='):
                lines[j] = '    label="";'
            break
    return '\n'.join(lines)


def node_labels(dot):
    labels = {}
    for m in re.finditer(r'"(n\d+)"\s*\[(.*?)\];', dot):
        nid, body = m.groups()
        lm = re.search(r'label=<<b>(.*?)</b>>', body)
        if lm:
            labels[nid] = lm.group(1)
    return labels


def annotate_use_case(dot):
    """Label include/extend edges and stack use cases into one column."""
    labels = node_labels(dot)
    uc_ids = {nid for nid, name in labels.items() if name in USE_CASES}
    out = []
    for line in dot.splitlines():
        m = re.match(r'(\s*"(n\d+)"\s*->\s*"(n\d+)"\s*\[)(.*)(\];)\s*$', line)
        if m and m.group(2) in uc_ids and m.group(3) in uc_ids:
            src, tgt = labels[m.group(2)], labels[m.group(3)]
            attrs = m.group(4).replace('arrowhead=none', 'arrowhead=vee')
            if src == 'Получать персональные рекомендации':
                line = m.group(1) + attrs + ', label="«include»", style=dashed, color="#5B5B59"' + m.group(5)
            elif src == 'Модерировать рецензии' and tgt == 'Отправлять жалобу на рецензию':
                line = m.group(1) + attrs + ', label="«extend»", style=dashed, color="#5B5B59"' + m.group(5)
        out.append(line)
    dot = '\n'.join(out)

    labels = node_labels(dot)
    ids = [nid for name in USE_CASES for nid, label in labels.items() if label == name]
    chain = ''.join('\n  "%s" -> "%s" [style=invis];' % (a, b)
                    for a, b in zip(ids, ids[1:]))
    return dot.rstrip()[:-1] + chain + '\n}\n'


def render(view, out_png, mockup=False):
    dot = clean(sysml_dot(view))
    if view == 'UseCaseView':
        dot = annotate_use_case(dot)
    os.makedirs(os.path.dirname(out_png) or '.', exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='kinovector-') as tmp:
        dot_path = os.path.join(tmp, view + '.dot')
        with open(dot_path, 'w', encoding='utf-8') as f:
            f.write(dot)
        if mockup:
            cmd = ['neato', '-n', '-Tpng', '-Gmargin=0', '-Gpad=0', dot_path, '-o', out_png]
        elif view == 'UseCaseView':
            # tight vertical spacing keeps the tall scenario tree readable on one page
            cmd = ['dot', '-Tpng', '-Gmargin=0', '-Gnodesep=0.35', '-Granksep=0.2',
                   dot_path, '-o', out_png]
        else:
            cmd = ['dot', '-Tpng', '-Gmargin=0', '-Gnodesep=0.45', '-Granksep=0.6',
                   dot_path, '-o', out_png]
        subprocess.run(cmd, check=True)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        sys.exit('usage: render.py <View> <out.png> [mockup]')
    render(sys.argv[1], sys.argv[2], mockup=(len(sys.argv) > 3 and sys.argv[3] == 'mockup'))
