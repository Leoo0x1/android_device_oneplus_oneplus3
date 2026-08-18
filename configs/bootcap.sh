#!/system/bin/sh
# DEBUG: capture boot hang state (unofficial bring-up)
# Dumps logcat + dmesg + ps + kernel stacks to /data/debug every 10s.
# Immediate first dump (no sleep) so early deaths are caught.
# Runs until boot completes or 180 iterations (~30 min) elapse.
i=0
dump() {
    mkdir -p /data/debug
    logcat -d -v threadtime > /data/debug/logcat.$1.txt 2>&1
    dmesg > /data/debug/dmesg.$1.txt 2>&1
    ps -A -o PID,NAME > /data/debug/ps.$1.txt 2>&1
    cat /proc/*/stack > /data/debug/stacks.$1.txt 2>&1
}
# immediate first capture
dump 0
i=1
while [ $i -le 180 ]; do
    sleep 10
    if [ "$(getprop sys.boot_completed)" = "1" ]; then
        dump done
        exit 0
    fi
    dump $i
    i=$((i+1))
done
