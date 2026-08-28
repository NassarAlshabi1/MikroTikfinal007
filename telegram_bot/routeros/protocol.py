from __future__ import annotations
import struct
from typing import Iterable

def _encode_length(length: int) -> bytes:
    if length < 0:
        raise ValueError("negative word length")
    if length < 0x80:
        return bytes([length])
    if length < 0x4000:
        value = length | 0x8000
        return struct.pack(">H", value)
    if length < 0x200000:
        value = length | 0xC00000
        return value.to_bytes(3, "big")
    if length < 0x10000000:
        value = length | 0xE0000000
        return struct.pack(">I", value)
    return b"\xf0" + struct.pack(">I", length)

def _decode_length(reader) -> int:
    first = reader.read(1)
    if not first:
        raise EOFError("unexpected end of RouterOS frame")
    value = first[0]
    if value < 0x80:
        return value
    if value < 0xC0:
        return ((value & 0x3F) << 8) | reader.read(1)[0]
    if value < 0xE0:
        return ((value & 0x1F) << 16) | int.from_bytes(reader.read(2), "big")
    if value < 0xF0:
        return ((value & 0x0F) << 24) | int.from_bytes(reader.read(3), "big")
    return int.from_bytes(reader.read(4), "big")

def _encode_word(word: str) -> bytes:
    data = word.encode("utf-8")
    return _encode_length(len(data)) + data

def _encode_sentence(words: Iterable[str]) -> bytes:
    return b"".join(_encode_word(word) for word in words) + b"\x00"

def _parse_sentence(words: list[str]) -> dict[str, str]:
    result: dict[str, str] = {"!type": words[0] if words else ""}
    for word in words[1:]:
        if word.startswith("=") and "=" in word[1:]:
            key, value = word[1:].split("=", 1)
            result[key] = value
    return result