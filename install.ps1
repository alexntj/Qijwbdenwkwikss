# GHOST REMOTE - Windows Edition
Clear-Host

# Cores
$GREEN = "`e[32m"
$RED = "`e[31m"
$CYAN = "`e[36m"
$YELLOW = "`e[33m"
$WHITE = "`e[37m"
$PURPLE = "`e[35m"
$NC = "`e[0m"

Write-Host "$GREEN"
Write-Host "  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗"
Write-Host " ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝"
Write-Host " ██║  ███╗███████║██║   ██║███████╗   ██║   "
Write-Host " ██║   ██║██╔══██║██║   ██║╚════██║   ██║   "
Write-Host " ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║   "
Write-Host "  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   "
Write-Host "$WHITE          R E M O T E   S Y S T E M (PC)$NC"
Write-Host "$PURPLE==========================================$NC"
Start-Sleep -Seconds 2

Write-Host "`n$YELLOW[*] Verificando ADB...$NC"
$adbPath = ".\adb.exe"
if (!(Test-Path $adbPath)) {
    Write-Host "$YELLOW[*] Baixando ADB (Platform-Tools)...$NC"
    $url = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    Invoke-WebRequest -Uri $url -OutFile "platform-tools.zip"
    Expand-Archive -Path "platform-tools.zip" -DestinationPath ".\" -Force
    Move-Item -Path ".\platform-tools\adb.exe" -Destination ".\adb.exe" -Force
    Move-Item -Path ".\platform-tools\AdbWinApi.dll" -Destination ".\AdbWinApi.dll" -Force
    Move-Item -Path ".\platform-tools\AdbWinUsbApi.dll" -Destination ".\AdbWinUsbApi.dll" -Force
    Write-Host "$GREEN[+] ADB instalado.$NC"
} else {
    Write-Host "$GREEN[+] ADB OK.$NC"
}

# Verifica celular via USB
$adbState = & $adbPath get-state 2>$null
if ($adbState -notmatch "device") {
    Write-Host "$RED[!] Celular não detectado via USB.$NC"
    Write-Host "$YELLOW[*] Conecte o cabo e ative a Depuração USB.${NC}"
    Write-Host "Pressione ENTER depois de conectar..."
    Read-Host
    $adbState = & $adbPath get-state 2>$null
    if ($adbState -notmatch "device") {
        Write-Host "$RED[!] Falha na conexão. Verifique o cabo e a Depuração USB.$NC"
        Exit
    }
}

# Pega HWID
$HWID = (& $adbPath shell settings get secure android_id).Trim()

Clear-Host
Write-Host "$PURPLE==========================================$NC"
Write-Host "$WHITE             VALIDAÇÃO DE LICENÇA         $NC"
Write-Host "$PURPLE==========================================$NC`n"

$USER_KEY = Read-Host "Insira sua Key de Acesso"
Write-Host "`n$YELLOW[*] Comunicando com o servidor...$NC"

# Ofuscação Base64
$K_API = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("aHR0cHM6Ly9nZXJhZG9yLWtleXMuZGUuZGVwbGV4by5jb20vYXBpL3ZhbGlkYXRl"))
$K_SLG = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("c3RpcmxheC1tb2R6LW0xbngtb2ZpY2lhbA=="))
$K_VER = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("Mi4w"))

$body = @{
    key = $USER_KEY
    hwid = $HWID
    appSlug = $K_SLG
    appVersion = $K_VER
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $K_API -Method Post -Body $body -ContentType "application/json"
} catch {
    Write-Host "$RED[!] Falha na conexão com a API.$NC"
    Exit
}

if ($response.success -ne $true -or $response.status -ne "active") {
    Write-Host "$RED[!] Acesso Negado. Key inválida ou expirada.$NC"
    Start-Sleep -Seconds 3
    Exit
}

$expiresAt = $response.expiresAt / 1000
$now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$diff = $expiresAt - $now

if ($diff -gt 0) {
    $dias = [math]::Floor($diff / 86400)
    $horas = [math]::Floor(($diff % 86400) / 3600)
    Write-Host "$GREEN[+] Acesso Autorizado!$NC"
    Write-Host "$GREEN[+] Expira em: $dias dias e $horas horas.$NC"
    Start-Sleep -Seconds 2
} else {
    Write-Host "$RED[!] Licença expirada.$NC"
    Exit
}

Clear-Host
Write-Host "$PURPLE==========================================$NC"
Write-Host "$WHITE             INJEÇÃO DO MÓDULO            $NC"
Write-Host "$PURPLE==========================================$NC`n"
Write-Host "$WHITE Injete o módulo usando o Zayon no celular."
Write-Host "Após abrir o Free Fire, retorne a esta tela.$NC`n"

do {
    $INJETADO = Read-Host "Módulo injetado e FF aberto? (s/n)"
} while ($INJETADO -notmatch "^[sn]$")

if ($INJETADO -ne "s") {
    Write-Host "$RED[!] Operação cancelada.$NC"
    Exit
}

# ADB Forward (Crucial pro PC)
& $adbPath forward tcp:7755 tcp:7755 | Out-Null

$ESTADO = @{}
1..20 | ForEach-Object { $ESTADO[$_] = 0 }

while ($true) {
    Clear-Host
    Write-Host "$PURPLE==========================================$NC"
    Write-Host "$WHITE              GHOST REMOTE                $NC"
    Write-Host "$PURPLE==========================================$NC`n"
    
    function Show-Status($i) {
        if ($ESTADO[$i] -eq 1) { return "$GREEN[ON]$NC" } else { return "" }
    }

    Write-Host "$CYAN┌── AIMBOTS ─────────────────────────────┐$NC"
    Write-Host "  [1] HS Cabeça (Head Priority)  $(Show-Status 1)"
    Write-Host "  [2] Drag Neck (Pescoço)        $(Show-Status 2)"
    
    Write-Host "`n$CYAN┌── ESP (VISÃO) ─────────────────────────┐$NC"
    Write-Host "  [3] ESP Box (Caixa)            $(Show-Status 3)"
    Write-Host "  [4] ESP Linha (Topo)           $(Show-Status 4)"
    Write-Host "  [5] ESP Nickname               $(Show-Status 5)"
    Write-Host "  [6] ESP Vida (Health)          $(Show-Status 6)"
    Write-Host "  [7] Esqueleto Branco           $(Show-Status 7)"
    Write-Host "  [8] Distância em Metros        $(Show-Status 8)"

    Write-Host "`n$CYAN┌── OUTRAS FUNÇÕES ──────────────────────┐$NC"
    Write-Host "  [9] FOV Perfeito               $(Show-Status 9)"
    Write-Host "  [10] Fast Switch               $(Show-Status 10)"
    Write-Host "  [11] No Recoil (Real)          $(Show-Status 11)"
    Write-Host "$CYAN└────────────────────────────────────────┘$NC"
    
    Write-Host "`n$RED┌── DESCONECTAR / LIMPAR (BYPASS) ───────┐$NC"
    Write-Host "  [99] Limpar arquivos e desinstalar Zayon"
    Write-Host "$RED└────────────────────────────────────────┘$NC"

    Write-Host "`n  [0] Encerrar Sessão`n"
    $FUNC_OPT = Read-Host "  » Selecione"

    if ($FUNC_OPT -eq "99") {
        $CONFIRMA = Read-Host "`n$RED[!] Isso vai desligar tudo e desinstalar o Zayon. Continuar? (s/n)$NC"
        if ($CONFIRMA -eq "s") {
            Write-Host "`n$YELLOW[*] Desativando todas as funções...$NC"
            1..15 | ForEach-Object { 
                try { Invoke-RestMethod -Uri "http://127.0.0.1:7755/item$_/desativar" -TimeoutSec 1 | Out-Null } catch {}
            }

            Write-Host "$YELLOW[*] Fechando Free Fire...$NC"
            & $adbPath shell am force-stop com.dts.freefireth
            
            Write-Host "$YELLOW[*] Apagando arquivos do cheat...$NC"
            $files = "Assembly-CSharp-patch.bytes","xyz.guard","localConfig.json","auth.txt","ffrtc_log.txt","ShaderStripSettings","reportnew.db"
            foreach ($f in $files) {
                & $adbPath shell rm -f "/sdcard/Android/data/com.dts.freefireth/files/$f"
            }
            
            Write-Host "$YELLOW[*] Desinstalando Zayon...$NC"
            & $adbPath shell am force-stop com.zyron
            & $adbPath shell pm uninstall com.zyron
            
            Write-Host "`n$GREEN[+] Bypass concluído com sucesso!$NC"
            Start-Sleep -Seconds 3
            Exit
        }
    }

    $endpoint = ""
    $name = ""
    switch ($FUNC_OPT) {
        "1" { $endpoint = "item1"; $name = "HS Cabeça" }
        "2" { $endpoint = "item5"; $name = "Drag Neck" }
        "3" { $endpoint = "item3"; $name = "ESP Box" }
        "4" { $endpoint = "item2"; $name = "ESP Linha" }
        "5" { $endpoint = "item6"; $name = "ESP Nickname" }
        "6" { $endpoint = "item7"; $name = "ESP Vida" }
        "7" { $endpoint = "item9"; $name = "Esqueleto Branco" }
        "8" { $endpoint = "item10"; $name = "Distância" }
        "9" { $endpoint = "item11"; $name = "FOV Perfeito" }
        "10" { $endpoint = "item14"; $name = "Fast Switch" }
        "11" { $endpoint = "item15"; $name = "No Recoil (Real)" }
        "0" { Clear-Host; Exit }
        default { continue }
    }

    Write-Host "`n$YELLOW[*] Sincronizando...$NC"
    
    if ($ESTADO[$FUNC_OPT] -eq 0) {
        try { Invoke-RestMethod -Uri "http://127.0.0.1:7755/$endpoint" -TimeoutSec 2 | Out-Null } catch {}
        $ESTADO[$FUNC_OPT] = 1
        Write-Host "$GREEN[+] $name : ATIVADO$NC"
    } else {
        try { Invoke-RestMethod -Uri "http://127.0.0.1:7755/$endpoint/desativar" -TimeoutSec 2 | Out-Null } catch {}
        $ESTADO[$FUNC_OPT] = 0
        Write-Host "$RED[-] $name : DESATIVADO$NC"
    }
    Start-Sleep -Seconds 1
}
