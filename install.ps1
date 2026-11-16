# GHOST REMOTE - Windows Edition
Clear-Host

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "            GHOST REMOTE SYSTEM           " -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
Start-Sleep -Seconds 1

# 1. Verifica e baixa o ADB
Write-Host "`n[*] Verificando ADB..." -ForegroundColor Yellow
$adbPath = ".\adb.exe"

if (!(Test-Path $adbPath)) {
    Write-Host "[*] Baixando ADB (Platform-Tools)..." -ForegroundColor Yellow
    $url = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    Invoke-WebRequest -Uri $url -OutFile "platform-tools.zip"
    Expand-Archive -Path "platform-tools.zip" -DestinationPath ".\" -Force
    
    Copy-Item -Path ".\platform-tools\adb.exe" -Destination ".\adb.exe" -Force
    Copy-Item -Path ".\platform-tools\AdbWinApi.dll" -Destination ".\AdbWinApi.dll" -Force
    Copy-Item -Path ".\platform-tools\AdbWinUsbApi.dll" -Destination ".\AdbWinUsbApi.dll" -Force
    Remove-Item -Path "platform-tools.zip" -Force
    Remove-Item -Path ".\platform-tools" -Recurse -Force
    Write-Host "[+] ADB instalado." -ForegroundColor Green
} else {
    Write-Host "[+] ADB OK." -ForegroundColor Green
}

# 2. Verifica dispositivo
$adbState = & $adbPath get-state 2>$null
if ($adbState -notmatch "device") {
    Write-Host "`n[!] Celular não detectado via USB." -ForegroundColor Red
    Write-Host "[*] Ative a Depuração USB e conecte o cabo." -ForegroundColor Yellow
    Write-Host "Pressione ENTER para tentar de novo..." -ForegroundColor White
    Read-Host | Out-Null
    
    $adbState = & $adbPath get-state 2>$null
    if ($adbState -notmatch "device") {
        Write-Host "[!] Falha na conexão. Verifique o cabo e a autorização." -ForegroundColor Red
        Exit
    }
}

# 3. Pega HWID
Write-Host "[*] Coletando Hardware ID..." -ForegroundColor Yellow
$HWID = (& $adbPath shell settings get secure android_id).Trim()

# 4. Valida a Key
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "             VALIDAÇÃO DE LICENÇA         " -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$USER_KEY = Read-Host "Insira sua Key de Acesso"
Write-Host "`n[*] Comunicando com o servidor..." -ForegroundColor Yellow

# Desofuscação (Base64)
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
    Write-Host "[!] Falha na conexão com a API." -ForegroundColor Red
    Exit
}

if ($response.success -ne $true -or $response.status -ne "active") {
    Write-Host "[!] Acesso Negado. Key inválida ou expirada." -ForegroundColor Red
    Start-Sleep -Seconds 3
    Exit
}

$expiresAt = $response.expiresAt / 1000
$now = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$diff = $expiresAt - $now

if ($diff -gt 0) {
    $dias = [math]::Floor($diff / 86400)
    $horas = [math]::Floor(($diff % 86400) / 3600)
    Write-Host "[+] Acesso Autorizado!" -ForegroundColor Green
    Write-Host "[+] Expira em: $dias dias e $horas horas." -ForegroundColor Green
    Start-Sleep -Seconds 2
} else {
    Write-Host "[!] Licença expirada." -ForegroundColor Red
    Exit
}

# 5. Injeção
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "             INJEÇÃO DO MÓDULO            " -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Abra o Zayon no celular, conecte o cabo USB e clique em INJETAR."
Write-Host "Após o Free Fire abrir, retorne ao PC."
Write-Host ""
do {
    $INJETADO = Read-Host "Módulo injetado e FF aberto? (s/n)"
} while ($INJETADO -notmatch "^[sn]$")

if ($INJETADO -ne "s") {
    Write-Host "[!] Operação cancelada." -ForegroundColor Red
    Exit
}

# Mágica do PC: Túnel reverso do ADB
& $adbPath forward tcp:7755 tcp:7755 | Out-Null
$ESTADO = @{}
1..20 | ForEach-Object { $ESTADO[$_] = 0 }

# 6. Menu Principal
while ($true) {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "              GHOST REMOTE                " -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor Cyan
    
    function Show-Status($i) {
        if ($ESTADO[$i] -eq 1) { return "[ON]" } else { return "" }
    }

    Write-Host "--- AIMBOTS ---" -ForegroundColor White
    Write-Host "  [1] HS Cabeça (Head Priority)  $(Show-Status 1)"
    Write-Host "  [2] Drag Neck (Pescoço)        $(Show-Status 2)"
    
    Write-Host "`n--- ESP (VISÃO) ---" -ForegroundColor White
    Write-Host "  [3] ESP Box (Caixa)            $(Show-Status 3)"
    Write-Host "  [4] ESP Linha (Topo)           $(Show-Status 4)"
    Write-Host "  [5] ESP Nickname               $(Show-Status 5)"
    Write-Host "  [6] ESP Vida (Health)          $(Show-Status 6)"
    Write-Host "  [7] Esqueleto Branco           $(Show-Status 7)"
    Write-Host "  [8] Distância em Metros        $(Show-Status 8)"

    Write-Host "`n--- OUTRAS FUNÇÕES ---" -ForegroundColor White
    Write-Host "  [9] FOV Perfeito               $(Show-Status 9)"
    Write-Host "  [10] Fast Switch               $(Show-Status 10)"
    Write-Host "  [11] No Recoil (Real)          $(Show-Status 11)"
    
    Write-Host "`n--- DESCONECTAR / LIMPAR (BYPASS) ---" -ForegroundColor Red
    Write-Host "  [99] Limpar arquivos e desinstalar Zayon"
    
    Write-Host "`n  [0] Encerrar Sessão"
    Write-Host ""
    $FUNC_OPT = Read-Host "  » Selecione"

    if ($FUNC_OPT -eq "99") {
        Write-Host "`n[!] AVISO: Isso vai desligar tudo e desinstalar o Zayon do celular." -ForegroundColor Red
        $CONFIRMA = Read-Host "Tem certeza? (s/n)"
        
        if ($CONFIRMA -eq "s") {
            Write-Host "`n[*] Desativando todas as funções..." -ForegroundColor Yellow
            1..15 | ForEach-Object { 
                try { Invoke-RestMethod -Uri "http://127.0.0.1:7755/item$_/desativar" -TimeoutSec 1 | Out-Null } catch {}
            }

            Write-Host "[*] Fechando Free Fire..." -ForegroundColor Yellow
            & $adbPath shell am force-stop com.dts.freefireth
            
            Write-Host "[*] Apagando arquivos do cheat..." -ForegroundColor Yellow
            $files = "Assembly-CSharp-patch.bytes","xyz.guard","localConfig.json","auth.txt","ffrtc_log.txt","ShaderStripSettings","reportnew.db"
            foreach ($f in $files) {
                & $adbPath shell rm -f "/sdcard/Android/data/com.dts.freefireth/files/$f"
            }
            
            Write-Host "[*] Desinstalando Zayon..." -ForegroundColor Yellow
            & $adbPath shell am force-stop com.zyron
            & $adbPath shell pm uninstall com.zyron
            
            Write-Host "`n[+] Bypass concluído com sucesso!" -ForegroundColor Green
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
        "11" { $endpoint = "item15"; $name = "No Recoil" }
        "0" { Clear-Host; Exit }
        default { continue }
    }

    Write-Host "`n[*] Sincronizando com o módulo..." -ForegroundColor Yellow
    
    if ($ESTADO[$FUNC_OPT] -eq 0) {
        try { Invoke-RestMethod -Uri "http://127.0.0.1:7755/$endpoint" -TimeoutSec 2 | Out-Null } catch {}
        $ESTADO[$FUNC_OPT] = 1
        Write-Host "[+] $name : ATIVADO" -ForegroundColor Green
    } else {
        try { Invoke-RestMethod -Uri "http://127.0.0.1:7755/$endpoint/desativar" -TimeoutSec 2 | Out-Null } catch {}
        $ESTADO[$FUNC_OPT] = 0
        Write-Host "[-] $name : DESATIVADO" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}
