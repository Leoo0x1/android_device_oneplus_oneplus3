#!/system/bin/sh
# DEBUG: capture boot hang state (unofficial bring-up) v3
# Dumps every 2s (freeze window ~12-15s). Captures ALL proc stacks with pid headers
# + per-thread wchan for zygote/system_server/app_process (names the blocked syscall).
i=0
dump() {
    mkdir -p /data/debug
    logcat -d -v threadtime > /data/debug/logcat.$1.txt 2>&1
    dmesg > /data/debug/dmesg.$1.txt 2>&1
    ps -A -o PID,PPID,NAME,STAT,WCHAN > /data/debug/ps.$1.txt 2>&1
    for p in /proc/[0-9]*; do
        pid=${p#/proc/}
        echo "=== pid $pid comm=$(cat $p/comm 2>/dev/null) cmdline=$(tr "\0" " " < $p/cmdline 2>/dev/null) stat=$(cat $p/stat 2>/dev/null | awk "{print \\\$3}") wchan=$(cat $p/wchan 2>/dev/null) ===" >> /data/debug/stacks.$1.txt
        cat $p/stack >> /data/debug/stacks.$1.txt 2>&1
    done
    for p in $(pgrep -f "zygote|system_server|app_process"); do
        for t in $(ls /proc/$p/task/ 2>/dev/null); do
            echo "=== pid $p tid $t $(cat /proc/$p/task/$t/comm 2>/dev/null) wchan=$(cat /proc/$p/task/$t/wchan 2>/dev/null) ===" >> /data/debug/zygote.$1.txt
            cat /proc/$p/task/$t/stack >> /data/debug/zygote.$1.txt 2>&1
        done
    done
}
# immediate first capture
dump 0
i=1
while [ $i -le 900 ]; do
    sleep 2
    if [ "$(getprop sys.boot_completed)" = "1" ]; then
        dump done
        exit 0
    fi
    dump $i
    i=$((i+1))
done
