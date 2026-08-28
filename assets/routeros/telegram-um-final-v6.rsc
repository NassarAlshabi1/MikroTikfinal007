# ============================================================
#  بوت تيليجرام نهائي لميكروتيك — RouterOS v6.45+
#  يدير كروت User Manager (مع بديل تلقائي لكروت الهوتسبوت)
#  الإصدار 2.0 — رسائل عربية، يعمل تلقائياً بعد إعادة التشغيل
#
#  التركيب:
#    1) افتح Winbox ثم New Terminal
#    2) الصق هذا الملف كاملاً واضغط Enter
#    3) أرسل /start للبوت @Tel_mikrotikbot
#
#  تعديل الإعدادات لاحقاً = عدّل القيم في قسم الإعدادات بالأسفل
#  ثم الصق الملف كاملاً من جديد (اللصق المتكرر آمن).
#    TG_UM_CUSTOMER: اسم المشترك في User Manager، اعرفه بالأمر:
#        /tool user-manager customer print
#    TG_UM_PROFILE: بروفايل الكروت الافتراضي، اعرفه بالأمر:
#        /tool user-manager profile print
# ============================================================

# ---------- الإعدادات ----------
:global TG_BOT_TOKEN "REPLACE_WITH_NEW_BOT_TOKEN"
:global TG_ALLOWED_CHAT_ID "5944227208"
:global TG_ALLOWED_USER_ID "5944227208"
:global TG_UM_CUSTOMER "admin"
:global TG_UM_PROFILE "default"
:global TG_DEF_LIMIT "1w"

# ---------- الجزء 1: الإعدادات ودوال القياس والإرسال ----------
:global tgBotLib1 do={

    # إعادة زرع الإعدادات إذا فُقدت بعد إعادة تشغيل الراوتر
    :global TG_BOT_TOKEN
    :if ([:typeof $TG_BOT_TOKEN] != "str") do={ :set TG_BOT_TOKEN "REPLACE_WITH_NEW_BOT_TOKEN" }
    :global TG_ALLOWED_CHAT_ID
    :if ([:typeof $TG_ALLOWED_CHAT_ID] != "str") do={ :set TG_ALLOWED_CHAT_ID "5944227208" }
    :global TG_ALLOWED_USER_ID
    :if ([:typeof $TG_ALLOWED_USER_ID] != "str") do={ :set TG_ALLOWED_USER_ID "5944227208" }
    :global TG_UM_CUSTOMER
    :if ([:typeof $TG_UM_CUSTOMER] != "str") do={ :set TG_UM_CUSTOMER "admin" }
    :global TG_UM_PROFILE
    :if ([:typeof $TG_UM_PROFILE] != "str") do={ :set TG_UM_PROFILE "default" }
    :global TG_DEF_LIMIT
    :if ([:typeof $TG_DEF_LIMIT] != "str") do={ :set TG_DEF_LIMIT "1w" }

    # إرسال رسالة تيليجرام عبر JSON POST (الطريقة الوحيدة التي تدعم العربية على v6)
    :global tgSend do={
        :global TG_BOT_TOKEN
        :local chat [:tostr $1]
        :local t [:tostr $2]
        :if (([:len $chat] = 0) || ([:len $t] = 0)) do={ :return false }
        :local out ""
        :local i 0
        :local L [:len $t]
        :while ($i < $L) do={
            :local ch [:pick $t $i ($i + 1)]
            :if ($ch = "\"") do={
                :set out ($out . "\\" . $ch)
            } else={
                :if ($ch = "\n") do={
                    :set out ($out . "\\n")
                } else={
                    :set out ($out . $ch)
                }
            }
            :set i ($i + 1)
        }
        :local body ("{\"chat_id\":" . $chat . ",\"text\":\"" . $out . "\"}")
        :do {
            /tool fetch url=("https://api.telegram.org/bot" . $TG_BOT_TOKEN . "/sendMessage") http-method=post http-data=$body http-header-field="Content-Type: application/json" check-certificate=no keep-result=no output=none
        } on-error={ :log warning "tg-bot: sendMessage failed" }
        :return true
    }

    # حالة الراوتر
    :global tgStatus do={
        :local identity ""
        :do { :set identity [/system identity get name] } on-error={}
        :local ver ""
        :do { :set ver [/system resource get version] } on-error={}
        :local up ""
        :do { :set up [/system resource get uptime] } on-error={}
        :local cpu ""
        :do { :set cpu [/system resource get cpu-load] } on-error={}
        :local mem ""
        :do { :set mem (([/system resource get free-memory] / 1048576) . " MB") } on-error={}
        :local act ""
        :do { :set act [/ip hotspot active print count-only] } on-error={ :set act "?" }
        :local um ""
        :do { :set um [/tool user-manager user print count-only] } on-error={ :set um "?" }
        :local tmp ""
        :do { :set tmp ("\nالحرارة: " . [/system health get temperature] . " C") } on-error={}
        :return ("حالة الراوتر:\n----------\nالجهاز: " . $identity . "\nالإصدار: " . $ver . "\nمدة التشغيل: " . $up . "\nالمعالج: " . $cpu . " %\nالذاكرة الحرة: " . $mem . "\nالمتصلون الآن: " . $act . "\nكروت User Manager: " . $um . $tmp)
    }

    # المتصلون الآن
    :global tgUsers do={
        :local act "0"
        :do { :set act [/ip hotspot active print count-only] } on-error={ :set act "0" }
        :local msg ("المتصلون الآن: " . $act)
        :local ids ""
        :do { :set ids [/ip hotspot active find] } on-error={ :set ids "" }
        :local shown 0
        :foreach id in=$ids do={
            :if ($shown < 15) do={
                :local nm ""
                :do { :set nm [/ip hotspot active get $id user] } on-error={}
                :local ad ""
                :do { :set ad [/ip hotspot active get $id address] } on-error={}
                :local ut ""
                :do { :set ut [/ip hotspot active get $id uptime] } on-error={}
                :set msg ($msg . "\n" . $nm . " | " . $ad . " | " . $ut)
                :set shown ($shown + 1)
            }
        }
        :return $msg
    }

    # ملخص User Manager
    :global tgUmSummary do={
        :local total "?"
        :do { :set total [/tool user-manager user print count-only] } on-error={ :set total "?" }
        :local prf "?"
        :do { :set prf [:len [/tool user-manager profile find]] } on-error={ :set prf "?" }
        :local act "?"
        :do { :set act [/ip hotspot active print count-only] } on-error={ :set act "?" }
        :local umids ""
        :do { :set umids [/tool user-manager user find] } on-error={ :set umids "" }
        :local live 0
        :foreach id in=$umids do={
            :local dis ""
            :do { :set dis [/tool user-manager user get $id disabled] } on-error={}
            :if (([:tostr $dis] != "true") && ([:tostr $dis] != "yes")) do={ :set live ($live + 1) }
        }
        :return ("ملخص User Manager:\n----------\nإجمالي الكروت: " . $total . "\nكروت سارية: " . $live . "\nالبروفايلات: " . $prf . "\nالمتصلون الآن: " . $act)
    }
    # تاريخ اليوم بصيغة ISO لمقارنة تواريخ الانتهاء
    :global tgTodayISO do={
        :local dt [:tostr [/system clock get date]]
        :local months {jan=01;feb=02;mar=03;apr=04;may=05;jun=06;jul=07;aug=08;sep=09;oct=10;nov=11;dec=12}
        :local mon [:pick $dt 0 3]
        :local day [:pick $dt 4 6]
        :local year [:pick $dt 7 11]
        :if ([:len $day] = 1) do={ :set day ("0" . $day) }
        :local mm ""
        :do { :set mm ($months->$mon) } on-error={}
        :return ($year . "-" . $mm . "-" . $day)
    }

    # قراءة تاريخ انتهاء كرت User Manager من أي حقل متاح
    :global tgUmExpiry do={
        :local id $1
        :local v ""
        :do { :set v [/tool user-manager user get $id expires] } on-error={}
        :if ([:len [:tostr $v]] = 0) do={ :do { :set v [/tool user-manager user get $id expiration] } on-error={} }
        :if ([:len [:tostr $v]] = 0) do={ :do { :set v [/tool user-manager user get $id end-time] } on-error={} }
        :if ([:len [:tostr $v]] = 0) do={ :do { :set v [/tool user-manager user get $id valid-until] } on-error={} }
        :return [:tostr $v]
    }

    # فحص كرت واحد (User Manager أولاً ثم Hotspot)
    :global tgCheckCard do={
        :global tgUmExpiry
        :local card [:tostr $1]
        :if ([:len $card] = 0) do={ :return "اكتب اسم الكرت: /check اسم-الكرت" }
        :local ids ""
        :do { :set ids [/tool user-manager user find where name=$card] } on-error={ :set ids "" }
        :local isum true
        :if ([:len $ids] = 0) do={
            :set isum false
            :do { :set ids [/ip hotspot user find where name=$card] } on-error={ :set ids "" }
        }
        :if ([:len $ids] = 0) do={ :return ("لا يوجد كرت بالاسم: " . $card) }
        :local id [:pick $ids 0]
        :local out ("الكرت: " . $card)
        :if ($isum) do={
            :local used ""
            :do { :set used [/tool user-manager user get $id uptime-used] } on-error={}
            :local lim ""
            :do { :set lim [/tool user-manager user get $id limit-uptime] } on-error={}
            :local dis ""
            :do { :set dis [/tool user-manager user get $id disabled] } on-error={}
            :local prof ""
            :do { :set prof [/tool user-manager user get $id actual-profile] } on-error={}
            :if ([:len [:tostr $prof]] = 0) do={ :do { :set prof [/tool user-manager user get $id profile] } on-error={} }
            :local exp [$tgUmExpiry $id]
            :if ([:len $exp] = 0) do={ :set exp "غير محدد" }
            :set out ($out . "\nالمصدر: User Manager\nالبروفايل: " . $prof . "\nالمستهلك: " . $used . "\nالحد: " . $lim . "\nالانتهاء: " . $exp . "\nالحالة: " . $dis)
        } else={
            :local prof ""
            :do { :set prof [/ip hotspot user get $id profile] } on-error={}
            :local used ""
            :do { :set used [/ip hotspot user get $id uptime] } on-error={}
            :local lim ""
            :do { :set lim [/ip hotspot user get $id limit-uptime] } on-error={}
            :local dis ""
            :do { :set dis [/ip hotspot user get $id disabled] } on-error={}
            :set out ($out . "\nالمصدر: Hotspot\nالبروفايل: " . $prof . "\nالمستهلك: " . $used . "\nالحد: " . $lim . "\nالحالة: " . $dis)
        }
        :return $out
    }

}

# ---------- الجزء 2: دوال إدارة الكروت ومعالجة الأوامر ----------
:global tgBotLib2 do={
    # توليد كروت بالجملة: /gen عدد [بروفايل أو مدة]
    :global tgGenCards do={
        :global TG_CARD_COUNTER
        :global TG_UM_CUSTOMER
        :global TG_UM_PROFILE
        :global TG_DEF_LIMIT
        :local n $1
        :local a2 [:tostr $2]
        :local target $TG_UM_PROFILE
        :local lim $TG_DEF_LIMIT
        :if ([:len $a2] > 0) do={ :set target $a2 ; :set lim $a2 }
        :local msg ("تم إنشاء " . $n . " كرت:\n----------")
        :local fail 0
        :for i from=1 to=$n do={
            :set TG_CARD_COUNTER ($TG_CARD_COUNTER + 1)
            :local ts [:tostr [/system clock get time]]
            :local fm [/system resource get free-memory]
            :local r1 (((($fm / 7) + ($i * 131) + ($TG_CARD_COUNTER * 17)) % 100))
            :local r2 (((($fm / 13) + ($i * 977) + ($TG_CARD_COUNTER * 31)) % 10000))
            :local name ("c" . [:pick $ts 0 2] . [:pick $ts 3 5] . [:pick $ts 6 8] . $TG_CARD_COUNTER . $r1)
            :local pw [:tostr $r2]
            :while ([:len $pw] < 4) do={ :set pw ("0" . $pw) }
            :local ok false
            :do {
                /tool user-manager user create-and-activate-profile customer=$TG_UM_CUSTOMER username=$name password=$pw profile=$target
                :set ok true
            } on-error={}
            :if (!$ok) do={
                :do {
                    /tool user-manager user add customer=$TG_UM_CUSTOMER name=$name password=$pw limit-uptime=$lim
                    :set ok true
                } on-error={}
            }
            :if (!$ok) do={
                :do {
                    /ip hotspot user add name=$name password=$pw profile=$target limit-uptime=$lim comment="tg-bot"
                    :set ok true
                } on-error={}
            }
            :if (!$ok) do={
                :do {
                    /ip hotspot user add name=$name password=$pw limit-uptime=$lim comment="tg-bot"
                    :set ok true
                } on-error={}
            }
            :if ($ok) do={
                :set msg ($msg . "\n----------\nالكرت: " . $name . "\nالرمز: " . $pw . "\nالمدة: " . $target)
                :delay 100ms
            } else={ :set fail ($fail + 1) }
        }
        :if ($fail > 0) do={ :set msg ($msg . "\n----------\nفشل إنشاء " . $fail . " كرت - تحقق من TG_UM_CUSTOMER و TG_UM_PROFILE") }
        :return $msg
    }

    # آخر الكروت
    :global tgListCards do={
        :local rows {}
        :do { :set rows [/tool user-manager user print as-value] } on-error={ :set rows {} }
        :if ([:len $rows] = 0) do={ :do { :set rows [/ip hotspot user print as-value] } on-error={ :set rows {} } }
        :if ([:len $rows] = 0) do={ :return "لا توجد كروت" }
        :local total [:len $rows]
        :local from 0
        :if ($total > 10) do={ :set from ($total - 10) }
        :local msg ("إجمالي الكروت: " . $total . "\nآخر 10 كروت:\n----------")
        :local i 0
        :foreach u in=$rows do={
            :if ($i >= $from) do={
                :local line ("\n" . ($u->"name"))
                :local lu ""
                :do { :set lu ($u->"uptime-used") } on-error={}
                :local ll ""
                :do { :set ll ($u->"limit-uptime") } on-error={}
                :if ([:len [:tostr $lu]] > 0) do={ :set line ($line . " | " . $lu . " / " . $ll) }
                :set msg ($msg . $line)
            }
            :set i ($i + 1)
        }
        :return $msg
    }

    # حذف كرت بالاسم
    :global tgDelCard do={
        :local n [:tostr $1]
        :local done false
        :do {
            :if ([:len [/tool user-manager user find where name=$n]] > 0) do={
                /tool user-manager user remove [find where name=$n]
                :set done true
            }
        } on-error={}
        :if (!$done) do={
            :do {
                :if ([:len [/ip hotspot user find where name=$n]] > 0) do={
                    /ip hotspot user remove [find where name=$n]
                    :set done true
                }
            } on-error={}
        }
        :do { /ip hotspot active remove [find where user=$n] } on-error={}
        :if ($done) do={ :return ("تم حذف الكرت: " . $n) }
        :return ("لم أجد الكرت: " . $n)
    }

    # تقرير المبيعات حسب البروفايلات وأسعارها في User Manager
    :global tgReport do={
        :local profs {}
        :do { :set profs [/tool user-manager profile print as-value] } on-error={ :set profs {} }
        :if ([:len $profs] = 0) do={
            :local hu "?"
            :do { :set hu [/ip hotspot user print count-only] } on-error={ :set hu "?" }
            :return ("تقرير: User Manager غير مثبت أو فارغ\nكروت الهوتسبوت المحلية: " . $hu)
        }
        :local rows {}
        :do { :set rows [/tool user-manager user profile print as-value] } on-error={ :do { :set rows [/tool user-manager user-profile print as-value] } on-error={ :set rows {} } }
        :local msg "تقرير المبيعات:\n----------"
        :local rev 0
        :local sold 0
        :foreach p in=$profs do={
            :local pn ""
            :do { :set pn ($p->"name") } on-error={}
            :local pp ""
            :do { :set pp ($p->"price") } on-error={}
            :if ([:len [:tostr $pn]] > 0) do={
                :local cnt 0
                :foreach b in=$rows do={
                    :local bp ""
                    :do { :set bp ($b->"profile") } on-error={}
                    :if ($bp = $pn) do={ :set cnt ($cnt + 1) }
                }
                :local pv 0
                :do { :set pv [:tonum $pp] } on-error={}
                :if ([:typeof $pv] != "num") do={ :set pv 0 }
                :set msg ($msg . "\n" . $pn . " | عدد: " . $cnt . " | سعر: " . $pp . " | الإجمالي: " . ($pv * $cnt))
                :set rev ($rev + ($pv * $cnt))
                :set sold ($sold + $cnt)
            }
        }
        :local total "?"
        :do { :set total [/tool user-manager user print count-only] } on-error={ :set total "?" }
        :set msg ($msg . "\n----------\nالكروت المبيعة: " . $sold . "\nإجمالي الإيراد: " . $rev . "\nإجمالي الكروت: " . $total)
        :if ($sold = 0) do={ :set msg ($msg . "\nملاحظة: لم يتم تفعيل بروفايلات للكروت بعد") }
        :return $msg
    }

    # الكروت المنتهية - true للمعاينة فقط و false للحذف الفعلي
    :global tgClean do={
        :global tgTodayISO
        :global tgUmExpiry
        :local dry $1
        :local today [$tgTodayISO]
        :local umids ""
        :do { :set umids [/tool user-manager user find] } on-error={ :set umids "" }
        :local doomed [:toarray ""]
        :local count 0
        :foreach id in=$umids do={
            :local expired false
            :local dis ""
            :do { :set dis [/tool user-manager user get $id disabled] } on-error={}
            :if (([:tostr $dis] = "true") || ([:tostr $dis] = "yes")) do={ :set expired true }
            :if (!$expired) do={
                :local lim ""
                :do { :set lim [/tool user-manager user get $id limit-uptime] } on-error={}
                :if ([:len [:tostr $lim]] > 0) do={
                    :local used ""
                    :do { :set used [/tool user-manager user get $id uptime-used] } on-error={}
                    :if ([:len [:tostr $used]] > 0) do={
                        :if ($used >= $lim) do={ :set expired true }
                    }
                }
            }
            :if (!$expired) do={
                :local exp [$tgUmExpiry $id]
                :if ([:len $exp] >= 10) do={
                    :if ([:pick $exp 0 2] = "20") do={
                        :if ([:pick $exp 0 10] < $today) do={ :set expired true }
                    }
                }
            }
            :if ($expired) do={
                :set count ($count + 1)
                :set doomed ($doomed , $id)
            }
        }
        :if (!$dry) do={
            :foreach id in=$doomed do={ :do { /tool user-manager user remove $id } on-error={} }
        }
        :if ($dry) do={ :return ("كروت منتهية جاهزة للحذف: " . $count . "\nللحذف فعلياً أرسل: /confirm_clean") }
        :return ("تم حذف الكروت المنتهية: " . $count)
    }

    # معالجة رسالة تيليجرام واحدة
    :global tgProcess do={
        :global TG_UPDATE_OFFSET
        :global TG_ALLOWED_CHAT_ID
        :global TG_ALLOWED_USER_ID
        :global tgSend
        :global tgStatus
        :global tgUsers
        :global tgUmSummary
        :global tgCheckCard
        :global tgGenCards
        :global tgListCards
        :global tgDelCard
        :global tgReport
        :global tgClean
        :local upd [:tostr $1]
        :local pId [:find $upd "\"update_id\":"]
        :if ([:typeof $pId] != "num") do={ :return }
        :local idEnd [:find $upd "," ($pId + 12)]
        :if ([:typeof $idEnd] != "num") do={ :return }
        :local idv [:tonum [:pick $upd ($pId + 12) $idEnd]]
        :if ([:typeof $idv] = "num") do={ :set TG_UPDATE_OFFSET ($idv + 1) }
        :local pMsg [:find $upd "\"message\":"]
        :if ([:typeof $pMsg] != "num") do={ :return }
        :local pChat [:find $upd "\"chat\":{\"id\":" $pMsg]
        :if ([:typeof $pChat] != "num") do={ :return }
        :local chatEnd [:find $upd "," ($pChat + 13)]
        :if ([:typeof $chatEnd] != "num") do={ :return }
        :local chat [:pick $upd ($pChat + 13) $chatEnd]
        :local pFrom [:find $upd "\"from\":{\"id\":" $pMsg]
        :if ([:typeof $pFrom] != "num") do={ :return }
        :local uEnd [:find $upd "," ($pFrom + 13)]
        :if ([:typeof $uEnd] != "num") do={ :return }
        :local uid [:pick $upd ($pFrom + 13) $uEnd]
        :if (($chat != $TG_ALLOWED_CHAT_ID) || ($uid != $TG_ALLOWED_USER_ID)) do={ :return }
        :local pText [:find $upd "\"text\":\"" $pMsg]
        :if ([:typeof $pText] != "num") do={ :return }
        :local tEnd [:find $upd "\"" ($pText + 8)]
        :if ([:typeof $tEnd] != "num") do={ :return }
        :local text [:pick $upd ($pText + 8) $tEnd]
        :local cmd $text
        :local args ""
        :local sp [:find $cmd " "]
        :if ([:typeof $sp] = "num") do={
            :set args [:pick $cmd ($sp + 1) [:len $cmd]]
            :set cmd [:pick $cmd 0 $sp]
        }
        :local at [:find $cmd "@"]
        :if ([:typeof $at] = "num") do={ :set cmd [:pick $cmd 0 $at] }
        :if (($cmd = "/start") || ($cmd = "/help")) do={
            $tgSend $chat "أوامر البوت:\n/status - حالة الراوتر\n/um - ملخص الكروت\n/users - المتصلون الآن\n/gen عدد [بروفايل أو مدة] - إنشاء كروت\n/list - آخر الكروت\n/check اسم - فحص كرت\n/del اسم - حذف كرت\n/report - تقرير المبيعات\n/clean - معاينة المنتهية ثم /confirm_clean\n/reboot yes - إعادة تشغيل الراوتر\nأمثلة: /gen 10 أو /gen 10 1w أو /gen 10 prof-1w"
            :return
        }
        :if ($cmd = "/status") do={ $tgSend $chat [$tgStatus] ; :return }
        :if ($cmd = "/um") do={ $tgSend $chat [$tgUmSummary] ; :return }
        :if (($cmd = "/users") || ($cmd = "/active")) do={ $tgSend $chat [$tgUsers] ; :return }
        :if (($cmd = "/check") || ($cmd = "/check_card")) do={
            :if ([:len $args] = 0) do={ $tgSend $chat "استخدم: /check اسم-الكرت" } else={ $tgSend $chat [$tgCheckCard $args] }
            :return
        }
        :if ($cmd = "/gen") do={
            :local a1 "5"
            :local a2 ""
            :local sp2 [:find $args " "]
            :if ([:typeof $sp2] = "num") do={
                :set a1 [:pick $args 0 $sp2]
                :set a2 [:pick $args ($sp2 + 1) [:len $args]]
            } else={
                :if ([:len $args] > 0) do={ :set a1 $args }
            }
            :local n [:tonum $a1]
            :if ([:typeof $n] != "num") do={ :set n 5 }
            :if ($n < 1) do={ :set n 1 }
            :if ($n > 20) do={ :set n 20 }
            $tgSend $chat [$tgGenCards $n $a2]
            :return
        }
        :if ($cmd = "/list") do={ $tgSend $chat [$tgListCards] ; :return }
        :if ($cmd = "/del") do={
            :if ([:len $args] = 0) do={ $tgSend $chat "استخدم: /del اسم-الكرت" } else={ $tgSend $chat [$tgDelCard $args] }
            :return
        }
        :if ($cmd = "/report") do={ $tgSend $chat [$tgReport] ; :return }
        :if ($cmd = "/clean") do={ $tgSend $chat [$tgClean true] ; :return }
        :if ($cmd = "/confirm_clean") do={ $tgSend $chat [$tgClean false] ; :return }
        :if ($cmd = "/reboot") do={
            :if ($args = "yes") do={
                $tgSend $chat "جاري إعادة تشغيل الراوتر..."
                :delay 3s
                /system reboot
            } else={ $tgSend $chat "للتأكيد أرسل: /reboot yes" }
            :return
        }
        :if ([:pick $cmd 0 1] = "/") do={ $tgSend $chat "أمر غير معروف - أرسل /help" }
    }

}

# ---------- الجزء 3: الاستطلاع الدوري ----------
:global tgBotPoll do={
    # حالة التشغيل (تُزرع تلقائياً بعد كل إقلاع)
    :global TG_UPDATE_OFFSET
    :global TG_LOCK
    :global TG_CARD_COUNTER
    :if ([:typeof $TG_UPDATE_OFFSET] != "num") do={ :set TG_UPDATE_OFFSET -1 }
    :if ([:typeof $TG_LOCK] != "bool") do={ :set TG_LOCK false }
    :if ([:typeof $TG_CARD_COUNTER] != "num") do={ :set TG_CARD_COUNTER 0 }
    :if ($TG_LOCK) do={ :return }
    # الاستطلاع الدوري للرسائل
    :set TG_LOCK true
    :do {
        # مزامنة الإقلاع: تجاهل الرسائل القديمة المتراكمة قبل التشغيل
        :if ($TG_UPDATE_OFFSET < 0) do={
            :local r ""
            :do {
                :set r [/tool fetch url=("https://api.telegram.org/bot" . $TG_BOT_TOKEN . "/getUpdates?offset=-1&limit=1&timeout=0") check-certificate=no output=user as-value]
            } on-error={ :set r "" }
            :if ([:typeof $r] = "array") do={
                :local d ""
                :do { :set d ($r->"data") } on-error={ :set d "" }
                :local p [:find $d "\"update_id\":"]
                :if ([:typeof $p] = "num") do={
                    :local d2 [:pick $d ($p + 12) [:len $d]]
                    :local e 0
                    :while (($e < [:len $d2]) && ([:typeof [:tonum [:pick $d2 $e ($e + 1)]]] = "num")) do={
                        :set e ($e + 1)
                    }
                    :if ($e > 0) do={ :set TG_UPDATE_OFFSET ([:tonum [:pick $d2 0 $e]] + 1) }
                }
            }
        }
        :local res ""
        :do {
            :set res [/tool fetch url=("https://api.telegram.org/bot" . $TG_BOT_TOKEN . "/getUpdates?offset=" . $TG_UPDATE_OFFSET . "&limit=10&timeout=8") check-certificate=no output=user as-value]
        } on-error={ :set res "" }
        :if ([:typeof $res] = "array") do={
            :local data ""
            :do { :set data ($res->"data") } on-error={ :set data "" }
            :local cur 0
            :local go true
            :while ($go) do={
                :local p [:find $data "\"update_id\":" $cur]
                :if ([:typeof $p] != "num") do={ :set go false } else={
                    :local nxt [:find $data "\"update_id\":" ($p + 12)]
                    :local end [:len $data]
                    :if ([:typeof $nxt] = "num") do={ :set end $nxt }
                    $tgProcess [:pick $data $p $end]
                    :set cur ($p + 12)
                }
            }
        }
        :set TG_LOCK false
    } on-error={ :set TG_LOCK false }
}

# ---------- التثبيت (يستبدل أي نسخة سابقة بأمان) ----------
:do { /system script remove [find name="tg-lib1"] } on-error={}
:do { /system script remove [find name="tg-lib2"] } on-error={}
:do { /system script remove [find name="tg-poll"] } on-error={}
:do { /system scheduler remove [find name="tg-poll-job"] } on-error={}
/system script add name="tg-lib1" policy=read,write,test,policy source={$tgBotLib1}
/system script add name="tg-lib2" policy=read,write,test,policy source={$tgBotLib2}
/system script add name="tg-poll" policy=read,write,test,policy source={$tgBotPoll}
/system scheduler add name="tg-poll-job" start-time=startup interval=10s policy=read,write,test,policy on-event="/system script run tg-lib1; /system script run tg-lib2; /system script run tg-poll"
:do {
    /tool fetch url=("https://api.telegram.org/bot" . $TG_BOT_TOKEN . "/deleteWebhook") check-certificate=no keep-result=no output=none
} on-error={ :log warning "tg-bot: deleteWebhook failed" }
:delay 2s
/system script run tg-lib1
/system script run tg-lib2
/system script run tg-poll
:log warning "tg-bot: تم التثبيت - أرسل /start في تيليجرام"
