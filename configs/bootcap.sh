#!/system/bin/sh
# DEBUG: capture boot hang state (unofficial bring-up)
# Dumps logcat + dmesg + ps + kernel stacks to /data/debug every 5s.
# Immediate first dump (no sleep) so early deaths are caught.
# Captures per-thread stacks + wchan for zygote + system_server (names blocked syscall).
# Runs until boot completes or 360 iterations (~30 min) elapse.
i=0
dump() {
    mkdir -p /data/debug
    logcat -d -v threadtime > /data/debug/logcat.$1.txt 2>&1
    dmesg > /data/debug/dmesg.$1.txt 2>&1
    ps -A -o PID,NAME,STAT,WCHAN > /data/debug/ps.$1.txt 2>&1
    cat /proc/*/stack > /data/debug/stacks.$1.txt 2>&1
    for p in $(pgrep -f "zygote|system_server|surfaceflinger|netd"); do
        for t in $(ls /proc/$p/task/ 2>/dev/null); do
            echo "=== pid $p tid $t $(cat /proc/$p/task/$t/comm 2>/dev/null) wchan=$(cat /proc/$p/task/$t/wchan 2>/dev/null) ===" >> /data/debug/zygote.$1.txt
            cat /proc/$p/task/$t/stack >> /data/debug/zygote.$1.txt 2>&1
        done
    done
}
# immediate first capture
dump 0
i=1
while [ $i -le 360 ]; do
    sleep 5
    if [ "$(getprop sys.boot_completed)" = "1" ]; then
        dump done
        exit 0
    fi
    dump $i
    i=$((i+1))
done
