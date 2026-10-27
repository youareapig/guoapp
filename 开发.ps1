# ============================================================
#  丽哥短剧 · 本地快速调试
#
#  用法:
#    .\开发.ps1            Web 预览(浏览器,推荐 —— 1 秒热重载,不需要手机/Java)
#    .\开发.ps1 -Device   Android 真机热重载(需要手机插 USB 开 USB 调试)
#    .\开发.ps1 -Rebuild  强制重编 Go 核心
#    .\开发.ps1 -AllSources  编译全站源版 Go 核心
#
#  Web 预览运行中: r=热重载  R=热重启  q=退出
# ============================================================
param([switch]$Device, [switch]$Rebuild, [switch]$AllSources)

$ErrorActionPreference = "Continue"
$tc   = "F:\android_pro\_toolchain"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$env:JAVA_HOME = "D:\jdk17"
$env:ANDROID_HOME = "$tc\android-sdk"
$env:ANDROID_SDK_ROOT = "$tc\android-sdk"
$env:FLUTTER_ROOT = "$tc\flutter"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:GOPROXY = "https://goproxy.cn,direct"
$env:GOSUMDB = "sum.golang.org"
$env:PATH = "$env:JAVA_HOME\bin;$tc\flutter\bin;$tc\go\bin;$tc\android-sdk\platform-tools;$env:PATH"

$flutter = "$tc\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    Write-Host "  [!] Flutter SDK 不在 $tc\flutter" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  ===== 丽哥短剧 · 快速调试 =====" -ForegroundColor Cyan
Write-Host ""

# ---- Go 核心是否需要重编 ----
$jni = "$root\android\app\src\main\jniLibs"
$soFiles = @(Get-ChildItem $jni -Recurse -Filter "libduanju_core.so" -ErrorAction SilentlyContinue)
$newestGo = (Get-ChildItem "$root\native" -Recurse -Include *.go -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
$oldestSo = ($soFiles | Sort-Object LastWriteTime | Select-Object -First 1).LastWriteTime
$needBuild = $Rebuild -or ($soFiles.Count -eq 0) -or ($null -ne $newestGo -and $null -ne $oldestSo -and $newestGo -gt $oldestSo)

if ($needBuild) {
    Write-Host "  [1/3] 编译 Go 核心(3 架构,约 30 秒)..." -ForegroundColor Yellow
    $a = @("scripts\build_native.py", "--platform", "android")
    if ($AllSources) { $a += "--all-sources" }
    & python @a
    if ($LASTEXITCODE -ne 0) { Write-Host "  [!] Go 核心编译失败" -ForegroundColor Red; exit 1 }
    Write-Host "  ✓ Go 核心就绪" -ForegroundColor Green
} else {
    Write-Host "  [1/3] Go 核心未变更,跳过编译" -ForegroundColor DarkGray
}

if ($Device) {
    Write-Host "  [2/3] 查找设备..." -ForegroundColor Yellow
    & $flutter devices 2>&1 | Select-Object -Skip 2 | ForEach-Object { "      $_" }
    Write-Host "  [3/3] 启动真机热重载" -ForegroundColor Yellow
    Write-Host "      r=热重载  R=热重启  q=退出" -ForegroundColor DarkGray
    & $flutter run
} else {
    Write-Host "  [2/3] Web 预览(数据为 mock,不接 Go 核心)" -ForegroundColor Yellow
    Write-Host "  [3/3] 启动 http://127.0.0.1:8080" -ForegroundColor Yellow
    Write-Host "      浏览器打开上面的地址;终端里 r=热重载  R=热重启  q=退出" -ForegroundColor DarkGray
    & $flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1 --target=lib/web_main.dart
}