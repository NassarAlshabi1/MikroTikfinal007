import glob
import os

def check_tokens(path):
    with open(path, "r", encoding="utf-8") as f:
        src = f.read()
    
    i = 0
    n = len(src)
    stack = []
    
    while i < n:
        # line comment
        if src[i:i+2] == "//":
            i = src.find("\n", i)
            if i == -1:
                break
            continue
        # block comment
        if src[i:i+2] == "/*":
            end = src.find("*/", i+2)
            if end == -1:
                break
            i = end + 2
            continue
        # raw triple strings
        if src[i:i+4] in ('r"""', "r'''"):
            q = src[i+1:i+4]
            end = src.find(q, i+4)
            if end == -1:
                break
            i = end + 3
            continue
        # triple strings
        if src[i:i+3] in ('"""', "'''"):
            q = src[i:i+3]
            end = src.find(q, i+3)
            if end == -1:
                break
            i = end + 3
            continue
        # raw single strings
        if src[i:i+2] in ('r"', "r'"):
            q = src[i+1]
            end = src.find(q, i+2)
            if end == -1:
                break
            i = end + 1
            continue
        # single/double quoted strings
        if src[i] in ('"', "'"):
            q = src[i]
            i += 1
            while i < n:
                if src[i] == '\\':
                    i += 2
                    continue
                if src[i] == q:
                    i += 1
                    break
                if src[i] == '\n':
                    break
                i += 1
            continue
        
        ch = src[i]
        if ch in ('(', '{', '['):
            stack.append((ch, i))
        elif ch in (')', '}', ']'):
            if not stack:
                line_no = src[:i].count('\n') + 1
                return f"Unexpected closing {ch} at line {line_no}"
            open_ch, open_idx = stack.pop()
            matches = {('(', ')'), ('{', '}'), ('[', ']')}
            if (open_ch, ch) not in matches:
                line_no = src[:i].count('\n') + 1
                return f"Mismatched {open_ch} (from line {src[:open_idx].count(chr(10))+1}) and {ch} at line {line_no}"
        i += 1
        
    if stack:
        open_ch, idx = stack[-1]
        line_no = src[:idx].count('\n') + 1
        return f"Unclosed {open_ch} opened at line {line_no}"
    return None

files = glob.glob("lib/**/*.dart", recursive=True) + glob.glob("test/**/*.dart", recursive=True)
errs = []
for f in files:
    err = check_tokens(f)
    if err:
        errs.append(f"{f}: {err}")

if errs:
    for e in errs:
        print("ERROR:", e)
else:
    print(f"SUCCESS: All {len(files)} Dart files are syntactically well-formed!")
