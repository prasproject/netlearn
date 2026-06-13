# Deploy NetLearn ke cPanel

Folder **`netlearn-web/`** berisi build production lengkap (HTML, JS, WASM, assets, icons).

## Langkah upload

1. Login cPanel → **File Manager**
2. Buka **`public_html`** (domain utama) atau folder subdomain Anda
3. Upload **semua isi** folder `netlearn-web/` (bukan foldernya saja, tapi isinya):
   - `index.html`
   - `main.dart.js`
   - `flutter.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`
   - folder `assets/`, `canvaskit/`, `icons/`
   - `.htaccess`, `manifest.json`, `favicon.png`, dll.
4. Pastikan file tersembunyi **`.htaccess`** ikut ter-upload (aktifkan "Show Hidden Files" di File Manager)

## Subfolder (mis. `domain.com/netlearn/`)

Build ulang dengan base path:

```bash
flutter build web --release --base-href /netlearn/
```

Lalu salin lagi ke `deploy/netlearn-web/` dan ubah `RewriteBase` di `.htaccess` menjadi `/netlearn/`.

## Firebase

Di [Firebase Console](https://console.firebase.google.com) → Project Settings → Your apps → Web:

- Tambahkan **Authorized domain** = domain cPanel Anda (mis. `netlearn.domain.com`)
- Aktifkan **Authentication** → Sign-in method yang dipakai (Google, Email, dll.) untuk domain production

## Cek setelah deploy

- Buka URL di browser (HTTPS disarankan)
- Hard refresh: `Ctrl+Shift+R` / `Cmd+Shift+R`
- Jika layar putih: cek error di DevTools → Console; pastikan `.wasm` tidak diblokir dan MIME type benar

## Build ulang

Dari root project:

```bash
flutter build web --release --base-href /
cp -R build/web/* deploy/netlearn-web/
cp build/web/.htaccess deploy/netlearn-web/
```
