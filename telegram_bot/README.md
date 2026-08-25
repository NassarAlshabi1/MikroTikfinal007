# Telegram Bot — Direct MikroTik RouterOS API

Telegram Bot is the direct control-plane component. It owns the RouterOS v6 API client; no bridge, integration, subprocess, or RouterOS-to-Telegram control relay is used.

Control path: Telegram -> Bot -> identity/authorization/policy -> command service -> RouterOS API -> MikroTik.
Health path: Bot -> RouterOS API -> router/WAN checks -> Telegram notifications.

Production defaults require RouterOS API-SSL (8729). Exposing plain 8728 is rejected unless `ALLOW_INSECURE_ROUTEROS_API=true` is explicitly set.
