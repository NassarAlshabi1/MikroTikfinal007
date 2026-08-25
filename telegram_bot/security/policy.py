from dataclasses import dataclass


@dataclass(frozen=True)
class CommandRule:
    risk: str
    mutating: bool
    confirmation: bool
    admin_only: bool = False


class TelegramPolicy:
    """Closed command allowlist for the direct Telegram → RouterOS control plane."""

    RULES = {
        "/start": CommandRule("READ_ONLY", False, False),
        "/help": CommandRule("READ_ONLY", False, False),
        "/status": CommandRule("READ_ONLY", False, False),
        "/internet": CommandRule("READ_ONLY", False, False),
        "/resources": CommandRule("READ_ONLY", False, False),
        "/uptime": CommandRule("READ_ONLY", False, False),
        "/active": CommandRule("READ_ONLY", False, False),
        "/sessions": CommandRule("READ_ONLY", False, False),
        "/profiles": CommandRule("READ_ONLY", False, False),
        "/users": CommandRule("READ_ONLY", False, False),
        "/interfaces": CommandRule("READ_ONLY", False, False),
        "/checklist": CommandRule("READ_ONLY", False, False),
        "/usage": CommandRule("READ_ONLY", False, False),
        "/card": CommandRule("LOW_RISK", False, False),
        "/card-check": CommandRule("LOW_RISK", False, False),
        "/check": CommandRule("LOW_RISK", False, False),
        "/card-usage": CommandRule("LOW_RISK", False, False),
        "/logs": CommandRule("READ_ONLY", False, False),
        "/print": CommandRule("READ_ONLY", False, False),
        "/report": CommandRule("READ_ONLY", False, False),
        "/sales": CommandRule("READ_ONLY", False, False),
        "/user-manager": CommandRule("READ_ONLY", False, False),
        "/card-create": CommandRule("HIGH_RISK", True, True, True),
        "/c200": CommandRule("HIGH_RISK", True, True, True),
        "/delete-expired": CommandRule("HIGH_RISK", True, True, True),
        "/clean": CommandRule("HIGH_RISK", True, True, True),
        "/reboot": CommandRule("HIGH_RISK", True, True, True),
    }

    def rule_for(self, command: str) -> CommandRule | None:
        return self.RULES.get(command)

    def authorize(
        self,
        *,
        chat_id: str,
        user_id: str,
        allowed_chats: frozenset[str],
        allowed_users: frozenset[str],
        command: str | None = None,
        admin_users: frozenset[str] = frozenset(),
    ) -> bool:
        if chat_id not in allowed_chats or user_id not in allowed_users:
            return False
        rule = self.rule_for(command or "")
        return rule is None or not rule.admin_only or user_id in admin_users
