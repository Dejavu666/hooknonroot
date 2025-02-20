#!/bin/bash

# Pindah ke direktori tempat script ini berada
cd "$(dirname "$0")" || exit

# Konfigurasi
BOT_TOKEN="00000000000000000000"
CHAT_ID="00000000"
HOSTNAME="namahostname"  # Ubah sesuai kebutuhan
PID_FILE="/tmp/bot_cmd.pid"

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

# Notifikasi saat bot pertama kali berjalan
send_message "[$HOSTNAME] bot berhasil masuk kandang"

# Simpan PID untuk pemantauan
echo $$ > "$PID_FILE"

# Loop utama untuk menerima perintah dari Telegram
OFFSET=0
while true; do
    # Ambil update terakhir dari bot
    UPDATE_URL="https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$OFFSET&limit=1"
    RESPONSE=$(curl -s "$UPDATE_URL")
    
    # Ambil ID update terbaru
    UPDATE_ID=$(echo "$RESPONSE" | grep -o '"update_id":[0-9]*' | awk -F: '{print $2}')
    MESSAGE=$(echo "$RESPONSE" | grep -o '"text":"[^"]*"' | awk -F'"' '{print $4}')
    
    # Jika ada update baru, proses pesan
    if [[ -n "$UPDATE_ID" ]]; then
        OFFSET=$((UPDATE_ID + 1))  # Perbarui offset agar tidak memproses ulang pesan
        
        # Cek apakah pesan diawali dengan hostname kita
        if [[ "$MESSAGE" == "$HOSTNAME "* ]]; then
            CMD="${MESSAGE#"$HOSTNAME "}"  # Hapus hostname dari perintah

            # Jalankan perintah & ambil output
            OUTPUT=$(eval "$CMD" 2>&1)

            # Kirim hasil eksekusi ke Telegram
            send_message "[$HOSTNAME] Command: <code>$CMD</code>\n\n<pre>$OUTPUT</pre>"
        fi
    fi
    
    # Tunggu 3 detik sebelum loop berikutnya
    sleep 3
done

# Notifikasi jika bot mati
send_message "[$HOSTNAME] bot keluar kandang / lepas"

# Hapus PID file jika script berhenti
rm -f "$PID_FILE"
