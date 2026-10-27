# ============================================================
#  丽哥短剧 · 本地快速调试
#  用法:  .\开发.ps1            编译 Go 核心(如有变更) + flutter run 热重载
#         .\开发.ps1 -Web       跑 Flutter Web 预览(mock 数据,需另加 web 入口)
#         .\开发.ps1 -Rebuild   强制重编 Go 核心
#  热重载: 运行中按 r 热重载 / R 热重启 / q 退出
# ============================================================
param([switch]$Rebuild, [switch]$Web, [switch]$AllSources)

$ErrorActionPreference = "Continue"
$tc  = "F:\android_pro\_toolchain"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$env:JAVA_HOME = "D:\jdk17"
$env:ANDROID_HOME = "$tc\android-sdk"
$env:ANDROID_SDK_ROOT = "$tc\android-sdk"
$env:FLUTTER_ROOT = "$tc\flutter"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:GOPROXY = "https://goproxy.cn,direct"
$env:PATH = "$env:JAVA_HOME\bin;$tc\flutter\bin;$tc\go\bin;$tc\android-sdk\platform-tools;$env:PATH"

$flutter = "$tc\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    Write-Host "  [!] Flutter SDK 不在 $tc\flutter,先跑一次 setup_dev.ps1" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  ===== 丽哥短剧 · 快速调试 =====" -ForegroundColor Cyan
Write-Host ""

# ---- 1. Go 核心是否需要重编 ----
$jni = "$root\android\app\src\main\jniLibs"
$soFiles = @(Get-ChildItem $jni -Recurse -Filter "libduanju_core.so" -ErrorAction SilentlyContinue)
$newestGo = (Get-ChildItem "$root\native" -Recurse -Include *.go -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
$oldestSo = ($soFiles | Sort-Object LastWriteTime | Select-Object -First 1).LastWriteTime
$needBuild = $Rebuild -or ($soFiles.Count -eq 0) -or ($null -ne $newestGo -and $null -ne $oldestSo -and $newestGo -gt $oldestSo)

if ($needBuild) {
    Write-Host "  [1/3] 编译 Go 核心(3 架构,约 3-4 分钟)..." -ForegroundColor Yellow
    $args = @("scripts\build_native.py", "--platform", "android")
    if ($AllSources) { $args += "--all-sources" }
    & python @args
    if ($LASTEXITCODE -ne 0) { Write-Host "  [!] Go 核心编译失败" -ForegroundColor Red; exit 1 }
    Write-Host "  ✓ Go 核心就绪" -ForegroundColor Green
} else {
    Write-Host "  [1/3] Go 核心未变更,跳过编译" -ForegroundColor DarkGray
}

# ---- 2. 设备 ----
Write-Host "  [2/3] 查找设备..." -ForegroundColor Yellow
& $flutter devices 2>&1 | Select-Object -Skip 2 | ForEach-Object { "      $_" }

# ---- 3. 运行 ----
if ($Web) {
    Write-Host "  [3/3] 启动 Web 预览(Chrome)" -ForegroundColor Yellow
    & $flutter run -d chrome --web-port 8080
} else {
    Write-Host "  [3/3] 启动热重载(选设备:手机请插 USB 并开 USB 调试)" -ForegroundColor Yellow
    Write-Host "      运行中: r=热重载  R=热重启  q=退出" -ForegroundColor DarkGray
    & $flutter run
}