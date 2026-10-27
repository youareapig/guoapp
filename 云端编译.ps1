# ============================================================
#  云端编译助手 —— 一条命令把本地改动推到你的 GitHub 并触发编译
#  用法:在项目目录执行  .\云端编译.ps1  然后按提示输入 GitHub 用户名
# ============================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host ""
Write-Host "  ===== 丽哥短剧 · 云端编译助手 =====" -ForegroundColor Cyan
Write-Host ""

# 1. 检查改动
$changed = git status --porcelain
if ([string]::IsNullOrWhiteSpace($changed)) {
    Write-Host "  [!] 没有本地改动,无需推送。" -ForegroundColor Yellow
    exit 0
}
$count = ($changed | Measure-Object -Line).Lines
Write-Host "  [1/4] 检测到 $count 项改动" -ForegroundColor Green

# 2. GitHub 用户名
$user = git config --get github.user
if (-not $user) {
    $user = Read-Host "  请输入你的 GitHub 用户名(就是你 fork 后的账号名)"
}
if (-not $user) { Write-Host "  [!] 缺少用户名,已退出。" -ForegroundColor Red; exit 1 }
$repo = "guoapp"
$remoteUrl = "https://github.com/$user/$repo.git"

# 3. 远程
if (git remote | Where-Object { $_ -eq "mine" }) {
    Write-Host "  [2/4] 更新已有远程 mine" -ForegroundColor Green
    git remote set-url mine $remoteUrl
} else {
    Write-Host "  [2/4] 添加远程 mine -> $remoteUrl" -ForegroundColor Green
    git remote add mine $remoteUrl
}

# 4. 提交并推送
$branch = "my-build"
Write-Host "  [3/4] 提交到分支 $branch" -ForegroundColor Green
git checkout -B $branch
git add -A
$msg = "build: 丽哥短剧自定义版 - 去下载 / 刷剧流 / 改名 / 换图标 / 换包名"
git commit -m $msg 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "  [!] 提交失败(可能没有新改动)。" -ForegroundColor Yellow }

Write-Host "  [4/4] 推送到 GitHub ..." -ForegroundColor Green
git push -u mine $branch 2>&1 | Select-Object -Last 5

Write-Host ""
Write-Host "  ===== 接下来只需要点几下 =====" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1) 打开这个页面:" -ForegroundColor White
Write-Host "     https://github.com/$user/$repo/actions" -ForegroundColor Yellow
Write-Host ""
Write-Host "  2) 左侧点 'Build Android' -> 右上角 'Run workflow'" -ForegroundColor White
Write-Host ""
Write-Host "  3) 等 10~20 分钟,页面底部 Artifacts 下载 'apk-*'" -ForegroundColor White
Write-Host ""
Write-Host "  想用自己的证书签名?去 Settings -> Secrets and variables -> Actions 配 4 个 Secret + 1 个 Variable" -ForegroundColor DarkGray
Write-Host "  不配也能装(会用 runner 自带的 debug 证书)。" -ForegroundColor DarkGray
Write-Host ""