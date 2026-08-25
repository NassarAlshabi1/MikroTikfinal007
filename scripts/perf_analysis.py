#!/usr/bin/env python3
"""تحليل دقيق لـ Flutter performance issues"""
import os, re
from collections import defaultdict

REPO = "/home/z/my-project/repos/MikroTikfinal007/lib"
results = defaultdict(list)

def analyze_file(filepath):
    with open(filepath, encoding='utf-8') as f:
        lines = f.read().split('\n')
    short = filepath.replace(REPO + '/', '')
    
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if 'setState(' in line:
            results['setState_usages'].append((short, i, s[:80]))
        if re.search(r'\bListView\((?!\.)', line):
            results['listview_no_builder'].append((short, i, s[:80]))
        if 'Consumer<' in line:
            results['consumer_no_selector'].append((short, i, s[:80]))
        if 'notifyListeners()' in line:
            results['notify_listeners'].append((short, i, s[:80]))
        # const opportunities
        if re.search(r'\bText\([^${]*\)', line) and 'const Text(' not in line and '$' not in line:
            results['non_const_text'].append((short, i, s[:80]))
        if re.search(r'\bSizedBox\(\s*height:', line) and 'const SizedBox' not in line:
            results['non_const_sizedbox'].append((short, i, s[:80]))
        if re.search(r'\bPadding\(\s*padding: const', line) and 'const Padding(' not in line:
            results['non_const_padding'].append((short, i, s[:80]))

for root, _, files in os.walk(REPO):
    for f in files:
        if f.endswith('.dart'):
            analyze_file(os.path.join(root, f))

print("=" * 70)
print("📊 تقرير تحليل أداء Flutter")
print("=" * 70)

categories = [
    ('setState_usages', '🔴 setState usages (potential excessive rebuilds)'),
    ('listview_no_builder', '🔴 ListView بدون .builder'),
    ('consumer_no_selector', '🟡 Consumer بدون Selector'),
    ('notify_listeners', '🟡 notifyListeners calls'),
    ('non_const_text', '🟡 Text بدون const'),
    ('non_const_sizedbox', '🟡 SizedBox بدون const'),
    ('non_const_padding', '🟡 Padding بدون const'),
]

for key, label in categories:
    items = results[key]
    print(f"\n{label}: {len(items)}")
    for f, l, code in items[:5]:
        print(f"  {f}:{l} → {code}")
    if len(items) > 5:
        print(f"  ... و {len(items) - 5} أخرى")

total = sum(len(v) for v in results.values())
print("\n" + "=" * 70)
print(f"📋 المجموع: {total} قضية أداء محتملة")
print("=" * 70)
