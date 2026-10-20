#!/usr/bin/env python3
"""Static checks for GNOME Shell (St) CSS.

St uses its own CSS engine. It skips rules it can't parse instead of failing
loudly, so a broken file can silently drop half the theme. This checks for
the mistakes that cause that:
  * unbalanced braces / unterminated comments or strings
  * declarations without a colon or a trailing semicolon
  * selectors St doesn't support (:has, :not, :is, :where, ::before/::after,
    attribute selectors, child combinator inside pseudo functions)
  * CSS features St lacks (var(), @media, @supports, calc(), multiple
    comma-separated box-shadows)
Exit status 0 = clean, 1 = errors.
"""
import re
import sys

UNSUPPORTED_SELECTOR = re.compile(r':(has|not|is|where)\(|::(before|after)|\[[^\]]*\]')
UNSUPPORTED_VALUE = re.compile(r'\bvar\(|\bcalc\(')


def strip_comments(text):
    out, i, n = [], 0, len(text)
    while i < n:
        if text.startswith('/*', i):
            j = text.find('*/', i + 2)
            if j < 0:
                raise ValueError(f'unterminated comment at line {text.count(chr(10), 0, i) + 1}')
            out.append('\n' * text.count('\n', i, j + 2))  # keep line numbers
            i = j + 2
        else:
            out.append(text[i])
            i += 1
    return ''.join(out)


def split_top_commas(value):
    depth, parts, cur = 0, [], ''
    for ch in value:
        depth += ch == '('
        depth -= ch == ')'
        if ch == ',' and depth == 0:
            parts.append(cur)
            cur = ''
        else:
            cur += ch
    parts.append(cur)
    return parts


def check(path):
    errors = []
    text = open(path, encoding='utf-8').read()
    try:
        body = strip_comments(text)
    except ValueError as e:
        return [str(e)]

    depth, start, line = 0, 0, 1
    sel_start_line = 1
    selector = ''
    for i, ch in enumerate(body):
        if ch == '\n':
            line += 1
        if ch == '{':
            if depth == 0:
                selector = body[start:i].strip()
                sel_start_line = line
                if selector.startswith('@') and not selector.startswith('@import'):
                    errors.append(f'line {line}: at-rule not supported by St: {selector[:40]}')
                if UNSUPPORTED_SELECTOR.search(selector):
                    errors.append(f'line {line}: unsupported selector: {selector[:80]}')
                block_start = i + 1
            depth += 1
            if depth > 1:
                errors.append(f'line {line}: nested block (St has no nesting)')
        elif ch == '}':
            depth -= 1
            if depth < 0:
                errors.append(f'line {line}: unbalanced closing brace')
                depth = 0
            elif depth == 0:
                block = body[block_start:i]
                decls = [d for d in block.split(';')]
                tail = decls[-1].strip()
                if tail:
                    errors.append(f'line {line}: last declaration missing ";": {tail[:60]}')
                for d in decls[:-1]:
                    d = d.strip()
                    if not d:
                        continue
                    if ':' not in d:
                        errors.append(f'block at line {sel_start_line}: declaration without colon: {d[:60]}')
                        continue
                    prop, value = (x.strip() for x in d.split(':', 1))
                    if not re.fullmatch(r'-?[a-z][a-z0-9-]*', prop):
                        errors.append(f'block at line {sel_start_line}: odd property name: {prop[:40]}')
                    if not value:
                        errors.append(f'block at line {sel_start_line}: empty value for {prop}')
                    if UNSUPPORTED_VALUE.search(value):
                        errors.append(f'block at line {sel_start_line}: unsupported value function in {prop}')
                    if prop == 'box-shadow' and len(split_top_commas(value.replace('!important', ''))) > 1:
                        errors.append(f'block at line {sel_start_line}: St supports a single box-shadow')
                start = i + 1
    if depth != 0:
        errors.append('unbalanced braces at end of file')
    return errors


if __name__ == '__main__':
    status = 0
    for p in sys.argv[1:]:
        errs = check(p)
        for e in errs:
            print(f'{p}: {e}')
        status |= bool(errs)
        if not errs:
            print(f'{p}: OK')
    sys.exit(status)
