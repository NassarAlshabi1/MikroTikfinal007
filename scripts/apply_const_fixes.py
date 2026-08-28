#!/usr/bin/env python3
"""
تطبيق إصلاحات أداء Flutter:
1. تحويل widgets النصية الثابتة لـ const
2. تحويل SizedBox الثابتة لـ const
3. تحويل Padding ثابتة لـ const
"""
import os, re

REPO = "/home/z/my-project/repos/MikroTikfinal007/lib"

def fix_file(filepath):
    with open(filepath, encoding='utf-8') as f:
        content = f.read()
    original = content
    
    # 1) تحويل SizedBox(height: X) → const SizedBox(height: X)
    # فقط إن لم يكن const بالفعل ولم يكن به child ديناميكي
    content = re.sub(
        r'(?<!const )SizedBox\((height|width):\s*(\d+(?:\.\d+)?)\)',
        r'const SizedBox(\1: \2)',
        content
    )
    
    # 2) تحويل EdgeInsets.all(X) → const EdgeInsets.all(X) عند عدم وجود const
    # متى ما لم تكن const بالفعل
    content = re.sub(
        r'(?<!const )EdgeInsets\.(all|zero|only|symmetric)\(',
        r'const EdgeInsets.\1(',
        content
    )
    # إزالة "const const" المزدوج إن ظهر
    content = re.sub(r'const const ', 'const ', content)
    
    # 3) تحويل Text('ثابت') → const Text('ثابت')
    # فقط النصوص بدون ${} وبدون style ديناميكي
    # متحفظ جداً — فقط Text('literal string')
    def text_replace(match):
        prefix = match.group(1)
        text = match.group(2)
        # إذا كان النص يحتوي على $، لا تحوّله
        if '$' in text:
            return match.group(0)
        # إذا كان const بالفعل، لا تكرر
        if prefix.strip() == 'const ':
            return match.group(0)
        return f'const {prefix.strip()}Text(\'{text}\')'
    
    # pattern: (prefix)Text('literal')
    # لا أطبقه تلقائياً — قد يكون خطير
    # فقط SizedBox و EdgeInsets كافية
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

# Run on all dart files
fixed = 0
for root, _, files in os.walk(REPO):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            if fix_file(path):
                fixed += 1
                print(f"✅ {path.replace(REPO + '/', '')}")

print(f"\n📋 تم إصلاح {fixed} ملف")
