from __future__ import annotations
import logging,sys,time,threading
from .config import Settings
from .common import TelegramBotError
from .telegram.client import TelegramClient
from .routeros.client import RouterOSV6Client
from .security.policy import TelegramPolicy
from .security.audit import AuditTrail
from .commands.router import CommandRouter
from .monitoring.core import InternetMonitor, TrafficUsageTracker, TrafficMonitor
LOGGER=logging.getLogger("mikrotik_telegram_bot")

def _load_offset(path):
    try:return int(path.read_text().strip()) if path.exists() else None
    except (OSError,ValueError):return None

def _save_offset(path,offset):
    path.parent.mkdir(parents=True,exist_ok=True)
    tmp=path.with_suffix(path.suffix+".tmp")
    tmp.write_text(str(offset),encoding="utf-8")
    tmp.replace(path)

def main() -> int:
    try:
        settings=Settings.from_env()
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
            except Exception as error:
                LOGGER.warning("telegram poll cycle failed: %s",type(error).__name__)
                gateway.close(); time.sleep(settings.poll_seconds)
        monitor.stop(); traffic.stop(); monitor_gateway.close(); traffic_gateway.close(); gateway.close(); return 0
    except Exception as error:
        LOGGER.error("startup failed: %s",type(error).__name__)
        return 2

if __name__ == "__main__": raise SystemExit(main())
