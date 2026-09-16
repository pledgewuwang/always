# always.apk 构建脚本（手工链：aapt2 → javac → d8 → zipalign → apksigner）
# 用法：把本仓库 clone 到任意目录，调整下方 SDK/JDK 路径后运行 .\build-apk.ps1
# 产物：..\always.apk（相对本仓库目录，即 clone 目录的上一级）
$ErrorActionPreference = 'Stop'

# ── 按本机环境调整以下三个路径 ──
$sdk   = "$env:LOCALAPPDATA\Android\Sdk"            # Android SDK 根目录
$jdk   = "$env:JAVA_HOME"                            # JDK 17 根目录
# ────────────────────────────────────────────────

$bt    = "$sdk\build-tools\34.0.0"
$plat  = "$sdk\platforms\android-34\android.jar"
$proj  = $PSScriptRoot
$env:JAVA_HOME = $jdk
$env:PATH = "$jdk\bin;$env:PATH"

# 签名密钥（不随仓库分发；首次构建自动生成）
$ksPass  = 'always2026'
$ksAlias = 'always'

Write-Host '== [0] icons =='
& python "$proj\make_icons.py"
if ($LASTEXITCODE -ne 0) { throw 'icon generation failed' }

Write-Host '== [1] aapt2 compile + link =='
New-Item -ItemType Directory -Force -Path "$proj\build\gen", "$proj\build\obj" | Out-Null
& "$bt\aapt2.exe" compile --dir "$proj\res" -o "$proj\build\res.zip"
if ($LASTEXITCODE -ne 0) { throw 'aapt2 compile failed' }
& "$bt\aapt2.exe" link -o "$proj\build\base.apk" -I $plat --manifest "$proj\AndroidManifest.xml" --java "$proj\build\gen" --auto-add-overlay "$proj\build\res.zip"
if ($LASTEXITCODE -ne 0) { throw 'aapt2 link failed' }

Write-Host '== [2] javac =='
& "$jdk\bin\javac.exe" -source 8 -target 8 -encoding UTF-8 `
  -classpath $plat `
  -d "$proj\build\obj" `
  "$proj\java\com\aiplatform\app\MainActivity.java" `
  "$proj\build\gen\com\aiplatform\app\R.java"
if ($LASTEXITCODE -ne 0) { throw 'javac failed' }

Write-Host '== [3] d8 dex =='
$classes = Get-ChildItem "$proj\build\obj" -Recurse -Filter *.class | ForEach-Object { $_.FullName }
& "$bt\d8.bat" --release --min-api 24 --lib $plat --output "$proj\build" @classes
if ($LASTEXITCODE -ne 0) { throw 'd8 failed' }
if (-not (Test-Path "$proj\build\classes.dex")) { throw 'classes.dex missing' }

Write-Host '== [4] add classes.dex into apk =='
& python "$proj\add_dex.py"
if ($LASTEXITCODE -ne 0) { throw 'dex add failed' }

Write-Host '== [5] zipalign =='
$outApk = "$proj\build\always-unsigned-aligned.apk"
& "$bt\zipalign.exe" -f 4 "$proj\build\base.apk" $outApk
if ($LASTEXITCODE -ne 0) { throw 'zipalign failed' }

Write-Host '== [6] keystore + sign =='
$ks = "$proj\always.keystore"
if (-not (Test-Path $ks)) {
  & "$jdk\bin\keytool.exe" -genkeypair -keystore $ks -storepass $ksPass -keypass $ksPass `
    -alias $ksAlias -keyalg RSA -keysize 2048 -validity 10000 `
    -dname "CN=always, O=always, C=CN"
  if ($LASTEXITCODE -ne 0) { throw 'keytool failed' }
}
$final = Join-Path (Split-Path $proj -Parent) 'always.apk'
& "$bt\apksigner.bat" sign --ks $ks --ks-pass "pass:$ksPass" --key-pass "pass:$ksPass" --out $final $outApk
if ($LASTEXITCODE -ne 0) { throw 'apksigner failed' }

Write-Host '== [7] verify =='
& "$bt\apksigner.bat" verify --print-certs $final
if ($LASTEXITCODE -ne 0) { throw 'verify failed' }
Write-Host ("DONE: " + $final + "  " + [math]::Round((Get-Item $final).Length/1KB) + " KB")
