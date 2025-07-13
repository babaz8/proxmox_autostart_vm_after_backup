  #!/bin/bash
# === Configuration ===
VMID=100
LOGFILE="/var/log/start_vm_after_backup_${VMID}.log"
LAST_LOG_FILE="/tmp/last_backup_vm_${VMID}.txt"

VZDUMP_LOG="/var/log/vzdump/qemu-${VMID}.log"
MAX_AGE_SECONDS=3600  # 1 hour
TIMEOUT_HOUR=6        # 6:00 AM timeout

# === Logging function ===
log() {
    local LOG_TIME
    LOG_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$LOG_TIME] $1" | tee -a "$LOGFILE"
}

# === Start VM after backup completion ===
# Double-check VM status before starting
STATUS=$(qm status "$VMID" | awk '{print $2}')
if [[ "$STATUS" == "running" ]]; then
    log "🔁 VM $VMID è già accesa (controllo backup)."
else
    log "🚀 Avvio della VM $VMID in corso..."
    if OUTPUT=$(/usr/sbin/qm start "$VMID" 2>&1); then
        log "✅ VM $VMID avviata con successo."
    else
        log "❌ Errore nell'avvio della VM $VMID"
        log "🔎 Output: $OUTPUT"
        exit 1
    fi
fi

# === Save timestamp as processed ===
echo "$FINISHED_TIMESTAMP" > "$LAST_LOG_FILE"
log "📌 Backup marcato come gestito: $FINISHED_TIMESTAMP"

# === Root check ===
if [[ $EUID -ne 0 ]]; then
    echo "❌ Questo script deve essere eseguito come root." >&2
    exit 1
fi

log "--------------------------------------------------"
log "🚀 Script started for VM $VMID"

# === Early check: if VM is already running, exit ===
STATUS=$(qm status "$VMID" | awk '{print $2}')
if [[ "$STATUS" == "running" ]]; then
    log "🔁 VM $VMID è già accesa. Nessuna azione necessaria."
    exit 0
fi

# === Check current time - start VM at 6:00 AM regardless of backup status ===
CURRENT_HOUR=$(date +%H)

if (( CURRENT_HOUR >= TIMEOUT_HOUR )); then
    log "⏰ Ora attuale: $(date +%H:%M) - Timeout raggiunto (>= ${TIMEOUT_HOUR}:00 AM)"
    
    # Double-check VM status before starting
    STATUS=$(qm status "$VMID" | awk '{print $2}')
    if [[ "$STATUS" == "running" ]]; then
        log "🔁 VM $VMID è già accesa (controllo timeout)."
        exit 0
    fi
    
    log "🔄 Avvio VM per timeout..."
    if OUTPUT=$(/usr/sbin/qm start "$VMID" 2>&1); then
        log "✅ VM $VMID avviata con successo per timeout."
    else
        log "❌ Errore nell'avvio della VM $VMID per timeout"
        log "🔎 Output: $OUTPUT"
        exit 1
    fi
    exit 0
fi

# === Continue with normal backup-based logic ===
log "🕐 Ora attuale: $(date +%H:%M) - Controllo stato backup..."

# === Check vzdump log exists ===
if [[ ! -f "$VZDUMP_LOG" ]]; then
    log "❌ Log file non trovato: $VZDUMP_LOG"
    exit 1
fi

# === Check modification time of the vzdump log ===
MODIFIED=$(stat -c %Y "$VZDUMP_LOG")
NOW=$(date +%s)
AGE=$((NOW - MODIFIED))

if (( AGE > MAX_AGE_SECONDS )); then
    log "⏱️ Il log è più vecchio di $MAX_AGE_SECONDS secondi — esco."
    exit 0
fi

# === Extract last "Finished Backup" line ===
FINISHED_LINE=$(grep "INFO: Finished Backup of VM $VMID" "$VZDUMP_LOG" | tail -n 1)

if [[ -z "$FINISHED_LINE" ]]; then
    log "❌ Nessuna riga 'Finished Backup' trovata per VM $VMID"
    exit 0
fi

# === Extract timestamp (format: YYYY-MM-DD HH:MM:SS) ===
FINISHED_TIMESTAMP=$(echo "$FINISHED_LINE" | cut -d' ' -f1,2)
log "📅 Ultimo backup completato: $FINISHED_TIMESTAMP"

# === Check if already processed ===
if [[ -f "$LAST_LOG_FILE" ]] && grep -q "$FINISHED_TIMESTAMP" "$LAST_LOG_FILE"; then
    log "⏩ Backup già gestito (timestamp: $FINISHED_TIMESTAMP)"
    exit 0
fi

# === Start VM after backup completion ===
STATUS=$(qm status "$VMID" | awk '{print $2}')
if [[ "$STATUS" == "running" ]]; then
    log "🔁 VM $VMID è già accesa. Nessuna azione necessaria."
else
    log "🚀 Avvio della VM $VMID in corso..."
    if OUTPUT=$(/usr/sbin/qm start "$VMID" 2>&1); then
        log "✅ VM $VMID avviata con successo."
    else
        log "❌ Errore nell'avvio della VM $VMID"
        log "🔎 Output: $OUTPUT"
        exit 1
    fi
fi

# === Save timestamp as processed ===
echo "$FINISHED_TIMESTAMP" > "$LAST_LOG_FILE"
log "📌 Backup marcato come gestito: $FINISHED_TIMESTAMP"
