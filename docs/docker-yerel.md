# SonLokma yerel geliştirme ortamı

Bu taslak PostgreSQL 16 ve Node.js 22 backend’ini birlikte çalıştırır. Linux container desteği ve Docker Compose gerekir. Komutlar repo kökünde PowerShell ile çalıştırılır.

## Backend kaynakları

Image için Siret’in backend klasöründeki kilit dosyası, Prisma şeması ve migration’ları, src ve test dizinleri gerekir. PR #27 birleşene kadar Yusuf’un dalında yalnız Compose yapılandırması doğrulanabilir. Birlikte denemek için aşağıdaki komutlar backend dalını ayrı, geçici bir çalışma dizininde açar. Kaynak dal ve aktif dal yerinde kalır.

~~~powershell
$checkout = Join-Path ([IO.Path]::GetTempPath()) ("sonlokma-" + [guid]::NewGuid().ToString("N"))
git worktree add --detach "$checkout" origin/feature/siret-backend-iskeleti
Copy-Item docker-compose.yml,.env.example -Destination $checkout
Copy-Item backend/Dockerfile,backend/.dockerignore -Destination "$checkout/backend"
Push-Location $checkout
~~~

## Kurulum

Kök dizinde .env.example dosyasını .env adıyla kopyalayın. POSTGRES_PASSWORD alanına kişisel, yerel bir değer girin. Örneğin aşağıdaki komut mevcut .env dosyasını korur ve yeni dosya için 32 karakterlik URL-güvenli bir değer üretir.

~~~powershell
if (!(Test-Path .env)) {
  (Get-Content .env.example).Replace('POSTGRES_PASSWORD=', 'POSTGRES_PASSWORD=' + [guid]::NewGuid().ToString('N')) | Set-Content .env -Encoding ascii
}
docker compose config --quiet
docker compose up --build --wait
docker compose ps
~~~

BACKEND_PORT ana makine portudur. Port doluysa .env içinde değiştirin. Container içinde PORT her zaman 3000’dir. DATABASE_URL, Compose tarafından db:5432 ve sonlokma veritabanı için oluşturulur. Parolada harf, rakam veya URL-güvenli işaretler kullanın. .env Git tarafından dışlanır. PostgreSQL parolayı volume ilk kez hazırlanırken kaydeder. Var olan volume için .env değerini değiştirmek veritabanı parolasını güncellemez.

## Başlatma ve kontroller

Build sırasında npm ci kilit dosyasındaki bağımlılıkları kurar ve Prisma Client Linux için üretilir. Prisma CLI geliştirme bağımlılığı olduğu için yerel image’a dahildir. PostgreSQL TCP bağlantısı kabul edince backend, depodaki SQL migration’larını prisma migrate deploy ile uygular. Migration başarısız olursa HTTP sunucusu başlamaz. Her açılışta aynı komut yalnızca bekleyen migration’ları uygular.

~~~powershell
docker compose exec db psql -U sonlokma -d sonlokma -c "SELECT current_database(), version();"
docker compose exec backend ./node_modules/.bin/prisma migrate status
Invoke-RestMethod http://127.0.0.1:3000/health
docker compose logs backend
~~~

HTTP için BACKEND_PORT değiştiyse URL’yi güncelleyin. Beklenen yanıt {"status":"ok"}. Bu uç Express sürecini kontrol eder. Veritabanı bağlantısı ve migration durumu yukarıdaki bağımsız sorgularla doğrulanır. Kaynak kodu veya şema değiştiğinde docker compose up --build --wait komutunu yeniden çalıştırın. Normal kullanım sonunda docker compose down servisleri kapatır ve proje volume’unu saklar.

## Ayrı veritabanıyla test

Test için aynı çalışma dizininde benzersiz bir proje adı ve boş bir yerel port seçin. Proje adı test verisini günlük geliştirme volume’undan ayırır. Backend testindeki veritabanı senaryosu NODE_ENV=test ve DATABASE_URL gerektirir.

~~~powershell
$project = 'sonlokma-test-' + [guid]::NewGuid().ToString('N')
$previousPort = $env:BACKEND_PORT
$env:BACKEND_PORT = '39027'
try {
  docker compose -p $project up --build --wait
  if ($LASTEXITCODE -ne 0) { throw 'Test ortamı başlamadı.' }
  docker compose -p $project exec -T backend env NODE_ENV=test npm test
  if ($LASTEXITCODE -ne 0) { throw 'Backend testleri başarısız.' }
} finally {
  docker compose -p $project down --volumes
  $env:BACKEND_PORT = $previousPort
}
~~~

Geçici worktree kullanıldıysa o dizinde açık normal geliştirme servislerini de docker compose down ile kapatın. Yalnız bu deneme için oluşturduğunuz .env, Compose ve Docker dosyalarını worktree’den kaldırdıktan sonra Pop-Location ve git worktree remove "$checkout" ile geçici dizini kaldırabilirsiniz.
