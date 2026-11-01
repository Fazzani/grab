#!/usr/bin/env python3
import sys
from xml.parsers import expat


def validate(path, require_programme=False):
    parser = expat.ParserCreate()
    depth = 0
    root_is_tv = False
    has_content = False
    has_programme = False

    def start(name, attributes):
        nonlocal depth, root_is_tv, has_content, has_programme
        if depth == 0:
            root_is_tv = name == "tv"
        elif depth == 1 and name in ("channel", "programme"):
            has_content = True
            has_programme = has_programme or name == "programme"
        depth += 1

    def end(name):
        nonlocal depth
        depth -= 1

    parser.StartElementHandler = start
    parser.EndElementHandler = end
    try:
        with open(path, "rb") as source:
            parser.ParseFile(source)
    except (OSError, expat.ExpatError, LookupError):
        print(f"Invalid XMLTV file {path}: unreadable or malformed XML", file=sys.stderr)
        return False
    if not root_is_tv or not has_content:
        print(f"Invalid XMLTV file {path}: expected tv with channels or programmes", file=sys.stderr)
        return False
    if require_programme and not has_programme:
        print(f"Invalid XMLTV file {path}: no programmes remain after filtering", file=sys.stderr)
        return False
    return True


if __name__ == "__main__":
    sys.exit(0 if validate(sys.argv[1], "--require-programme" in sys.argv[2:]) else 1)
