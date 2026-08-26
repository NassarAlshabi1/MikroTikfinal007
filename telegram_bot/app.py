from __future__ import annotations
import logging,os,sys,time,threading
from .config import Settings, load_env_file
from .common import TelegramBotError
from .telegram.client import TelegramClient
from .routeros.client import RouterOSV6Client
from .security.policy import TelegramPolicy
from .security.audit import AuditTrail
from .commands.router import CommandRouter
from .monitoring.core import InternetMonitor, TrafficUsageTracker, TrafficMonitor
LOGGER=logging.getLogger("mikrotik_telegram_bot")

def _configure_logging() -> None:
    if logging.getLogger().handlers:
        return
    level_name=os.getenv("LOG_LEVEL", "INFO").strip().upper()
    level=getattr(logging, level_name, logging.INFO)
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        stream=sys.stdout,
    )

def _selftest(settings: Settings) -> int:
    """Verify the bot can actually run: Telegram token + RouterOS login.

    Sends a real Telegram message to every allowed chat so the operator sees
    a live confirmation. Returns a process exit code (0 = healthy)."""
    ok = True
    telegram = TelegramClient(settings.telegram_token)
    try:
        me = telegram.call("getMe", {})
        LOGGER.info("Telegram token OK: bot @%s", (me or {}).get("username", "?"))
    except Exception as error:
        LOGGER.error("Telegram token check FAILED: %s", error)
        return 2
    gateway = RouterOSV6Client(
        settings.mikrotik_address, settings.mikrotik_user, settings.mikrotik_password,
        settings.mikrotik_port, settings.mikrotik_use_ssl, settings.mikrotik_ca_file)
    try:
        rows = gateway.command("/system/resource/print", "=.proplist=uptime,version")
        info = next((r for r in rows if r.get("!type") == "!re"), {})
        LOGGER.info("RouterOS login OK: version=%s uptime=%s",
                    info.get("version", "?"), info.get("uptime", "?"))
    except Exception as error:
        LOGGER.error("RouterOS connection FAILED: %s", error)
        ok = False
    finally:
        gateway.close()
    message = ("\u2705 فحص Telegram Bot ناجح: التوكن والاتصال بـ MikroTik يعملان."
               if ok else
               "\u26a0\ufe0f فحص Telegram Bot: التوكن يعمل لكن الاتصال بـ MikroTik فشل. راجع العنوان/المنفذ/TLS.")
    for chat_id in settings.allowed_chat_ids:
        try:
            telegram.send_message(chat_id, message)
        except Exception as error:
            LOGGER.warning("could not send selftest message to %s: %s", chat_id, error)
            ok = False
    return 0 if ok else 2


def _load_offset(path):
    try:return int(path.read_text().strip()) if path.exists() else None
    except (OSError,ValueError):return None

def _save_offset(path,offset):
    path.parent.mkdir(parents=True,exist_ok=True)
    tmp=path.with_suffix(path.suffix+".tmp")
    tmp.write_text(str(offset),encoding="utf-8")
    tmp.replace(path)

def main(argv: list[str] | None = None) -> int:
    _configure_logging()
    argv = list(sys.argv[1:] if argv is None else argv)
    load_env_file()
    try:
        settings=Settings.from_env()
    except TelegramBotError as error:
        LOGGER.error("startup failed: %s", error)
        return 2
    if "--selftest" in argv:
        return _selftest(settings)
    try:
        telegram=TelegramClient(settings.telegram_token)
        gateway=RouterOSV6Client(settings.mikrotik_address,settings.mikrotik_user,settings.mikrotik_password,settings.mikrotik_port,settings.mikrotik_use_ssl,settings.mikrotik_ca_file)
        monitor_gateway=RouterOSV6Client(settings.mikrotik_address,settings.mikrotik_user,settings.mikrotik_password,settings.mikrotik_port,settings.mikrotik_use_ssl,settings.mikrotik_ca_file)
        traffic_gateway=RouterOSV6Client(settings.mikrotik_address,settings.mikrotik_user,settings.mikrotik_password,settings.mikrotik_port,settings.mikrotik_use_ssl,settings.mikrotik_ca_file)
        usage=TrafficUsageTracker(traffic_gateway,settings.traffic_interface,settings.traffic_state_file)
        policy=TelegramPolicy(); audit=AuditTrail(settings.audit_file)
        router=CommandRouter(
            gateway, telegram, usage, policy=policy, audit=audit,
            admin_user_ids=settings.admin_user_ids,
            recovery_target=settings.monitor_target,
            recovery_attempts=settings.reboot_recovery_attempts,
            recovery_interval_seconds=settings.reboot_recovery_interval_seconds,
            user_manager_customer=settings.user_manager_customer,
        )
        monitor=InternetMonitor(monitor_gateway,telegram,settings.allowed_chat_ids,settings.monitor_target,settings.monitor_interval_seconds)
        traffic=TrafficMonitor(usage,telegram,settings.allowed_chat_ids,settings.traffic_interval_seconds,settings.daily_report_time)
        threading.Thread(target=monitor.run_forever,daemon=True,name="router-health").start()
        threading.Thread(target=traffic.run_forever,daemon=True,name="traffic-monitor").start()
        offset=_load_offset(settings.offset_file)
        LOGGER.info("Telegram Bot started in direct RouterOS API mode")
        for chat_id in settings.allowed_chat_ids:
            try: telegram.send_message(chat_id, "\U0001f7e2 Telegram Bot يعمل الآن وجاهز لاستقبال الأوامر.")
            except Exception as error: LOGGER.warning("startup notice to %s failed: %s", chat_id, error)
        while True:
            try:
                updates=telegram.updates(offset)
                for update in updates:
                    update_id=int(update["update_id"])
                    callback=update.get("callback_query")
                    if callback:
                        message=callback.get("message") or {}; chat=message.get("chat") or {}
                        chat_id=str(chat.get("id","")); user=str((callback.get("from") or {}).get("id",""))
                        if policy.authorize(chat_id=chat_id,user_id=user,allowed_chats=settings.allowed_chat_ids,allowed_users=settings.allowed_user_ids):
                            try: router.handle_callback(chat_id,user,str(callback.get("id","")),str(callback.get("data","")))
                            except Exception as error:
                                LOGGER.warning("callback failed: %s",type(error).__name__)
                                try: telegram.send_message(chat_id,"تعذر تنفيذ التأكيد بأمان.")
                                except Exception: pass
                        _save_offset(settings.offset_file,update_id+1); offset=update_id+1; continue
                    message=update.get("message") or {}; chat=message.get("chat") or {}
                    chat_id=str(chat.get("id","")); user=str((message.get("from") or {}).get("id","")); text=str(message.get("text","")).strip()
                    command = text.split(maxsplit=1)[0].lower().split("@", 1)[0] if text else ""
                    authorized = text and policy.authorize(chat_id=chat_id,user_id=user,allowed_chats=settings.allowed_chat_ids,allowed_users=settings.allowed_user_ids,command=command,admin_users=settings.admin_user_ids)
                    if authorized:
                        try: router.handle(chat_id,user,text)
                        except Exception as error:
                            LOGGER.warning("command failed: %s",type(error).__name__)
                            try: telegram.send_message(chat_id,f"تعذر تنفيذ الطلب بأمان: {type(error).__name__}")
                            except Exception: pass
                    elif text and chat_id in settings.allowed_chat_ids and user in settings.allowed_user_ids:
                        try: telegram.send_message(chat_id,"ليس لديك صلاحية تنفيذ هذا الأمر.")
                        except Exception: pass
                    _save_offset(settings.offset_file,update_id+1); offset=update_id+1
            except KeyboardInterrupt: break
            except TelegramBotError as error:
                LOGGER.warning("telegram poll cycle failed: %s", error)
                gateway.close(); time.sleep(settings.poll_seconds)
            except Exception as error:
                LOGGER.warning("telegram poll cycle failed: %s",type(error).__name__)
                gateway.close(); time.sleep(settings.poll_seconds)
        monitor.stop(); traffic.stop(); monitor_gateway.close(); traffic_gateway.close(); gateway.close(); return 0
    except TelegramBotError as error:
        # Configuration/safety errors carry an actionable, secret-free message.
        LOGGER.error("startup failed: %s", error)
        return 2
    except Exception as error:
        LOGGER.exception("startup failed: %s", type(error).__name__)
        return 2

if __name__ == "__main__": raise SystemExit(main())
