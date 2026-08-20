#!/system/bin/sh
# DEBUG: capture boot hang state (unofficial bring-up) v5 — freeze-proof
# v5: drop /proc/*/stack reads (hang on freeze). Use per-thread WCHAN via ps -T
# (kernel function each thread is in; does not block). timeout guards every cmd.
# Runs until boot completes or 900 iterations (~30 min).
i=0
dump() {
    mkdir -p /data/debug
    timeout 3 logcat -d -v threadtime -t 3000 > /data/debug/logcat.$1.txt 2>&1
    timeout 3 dmesg > /data/debug/dmesg.$1.txt 2>&1
    timeout 3 ps -A -o PID,PPID,NAME,STAT,WCHAN > /data/debug/ps.$1.txt 2>&1
    # per-thread wchan for the interesting procs (does not hang)
    for p in $(pgrep -f "zygote|system_server|app_process" 2>/dev/null); do
        timeout 3 ps -T -p $p -o TID,NAME,STAT,WCHAN >> /data/debug/threads.$1.txt 2>&1
    done
}
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
