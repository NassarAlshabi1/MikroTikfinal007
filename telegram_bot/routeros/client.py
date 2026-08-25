from __future__ import annotations
import hashlib
import socket
import ssl
from .protocol import _decode_length, _encode_sentence, _parse_sentence
from ..common import TelegramBotError

class RouterOSV6Client:
    def __init__(self, address: str, user: str, password: str, port: int = 8728,
                 use_ssl: bool = False, ca_file=None, timeout: float = 10.0) -> None:
        self.address = address
        self.user = user
        self.password = password
        self.port = port
        self.use_ssl = use_ssl
        self.ca_file = ca_file
        self.timeout = timeout
        self.sock: socket.socket | None = None
        self.reader = None

    def connect(self) -> None:
        if self.sock is not None:
            return
        sock = socket.create_connection((self.address, self.port), self.timeout)
        if self.use_ssl:
            import ssl
            context = ssl.create_default_context(cafile=str(self.ca_file) if self.ca_file else None)
            sock = context.wrap_socket(sock, server_hostname=self.address)
        sock.settimeout(self.timeout)
        self.sock = sock
        self.reader = sock.makefile("rb")
        try:
            response = self.talk(["/login", f"=name={self.user}", f"=password={self.password}"])
            if any(row.get("!type") == "!trap" for row in response):
                raise TelegramBotError("RouterOS login failed")
            if any("ret" in row for row in response):
                # Compatibility with older RouterOS v6 challenge-response login.
                challenge = next(row["ret"] for row in response if "ret" in row)
                digest = hashlib.md5(b"\x00" + self.password.encode() + bytes.fromhex(challenge)).hexdigest()
                response = self.talk(["/login", f"=name={self.user}", f"=response=00{digest}"])
                if any(row.get("!type") == "!trap" for row in response):
                    raise TelegramBotError("RouterOS challenge login failed")
        except Exception:
            self.close()
            raise

    def close(self) -> None:
        try:
            if self.reader is not None:
                self.reader.close()
        except Exception:
            pass
        try:
            if self.sock is not None:
                self.sock.close()
        except Exception:
            pass
        self.reader = None
        self.sock = None

    def _read_sentence(self) -> list[str]:
        if self.reader is None:
            raise TelegramBotError("RouterOS socket is not connected")
        words: list[str] = []
        while True:
            length = _decode_length(self.reader)
            if length == 0:
                return words
            raw = self.reader.read(length)
            if len(raw) != length:
                raise EOFError("truncated RouterOS word")
            words.append(raw.decode("utf-8", errors="replace"))

    def talk(self, words: list[str]) -> list[dict[str, str]]:
        self.connect_if_needed()
        assert self.sock is not None
        self.sock.sendall(_encode_sentence(words))
        rows: list[dict[str, str]] = []
        while True:
            row = _parse_sentence(self._read_sentence())
            rows.append(row)
            if row.get("!type") in {"!done", "!trap", "!fatal"}:
                if row.get("!type") in {"!trap", "!fatal"}:
                    raise TelegramBotError(row.get("message", "RouterOS command failed"))
                return rows

    def connect_if_needed(self) -> None:
        if self.sock is None:
            self.connect()

    def command(self, path: str, *arguments: str) -> list[dict[str, str]]:
        return self.talk([path, *arguments])