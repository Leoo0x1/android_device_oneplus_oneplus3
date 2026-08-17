#!/system/bin/sh
# DEBUG: capture boot hang state (unofficial bring-up)
# Dumps logcat + ps + kernel stacks to /data/debug every 30s until boot
# completes or 60 iterations (~30 min) elapse. Run as root from init.
i=0
while [ $i -lt 60 ]; do
    sleep 30
    i=$((i+1))
    if [ "$(getprop sys.boot_completed)" = "1" ]; then
        exit 0
    fi
    mkdir -p /data/debug
    logcat -d -v threadtime > /data/debug/logcat.$i.txt 2>&1
    ps -A -o PID,NAME > /data/debug/ps.$i.txt 2>&1
    cat /proc/*/stack > /data/debug/stacks.$i.txt 2>&1
done
