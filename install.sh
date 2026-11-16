#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

clear

echo -e "${GREEN}"
cat << "EOF"
  ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
 ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
 ██║  ███╗███████║██║   ██║███████╗   ██║   
 ██║   ██║██╔══██║██║   ██║╚════██║   ██║   
 ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║   
  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   
EOF
echo -e "${WHITE}          R E M O T E   S Y S T E M${NC}"
echo -e "${PURPLE}==========================================${NC}"
sleep 2

echo -e "\n${YELLOW}[*] Verificando dependências do sistema...${NC}"

if ! command -v adb &> /dev/null || ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}[*] Instalando pacotes necessários (android-tools, curl)...${NC}"
    pkg update -y &> /dev/null
    pkg install android-tools curl -y &> /dev/null
    echo -e "${GREEN}[+] Dependências instaladas com sucesso.${NC}"
else
    echo -e "${GREEN}[+] Dependências OK (adb e curl encontrados).${NC}"
fi

echo -e "\n${YELLOW}[*] Instalando interface de controle...${NC}"

cat > /data/data/com.termux/files/usr/bin/ghost << 'GHOST_EOF'
#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

declare -A ESTADO
for i in {1..20}; do ESTADO[$i]=0; done

clear
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}            AUTENTICAÇÃO GHOST            ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

ADB_STATE=$(adb get-state 2>/dev/null | tr -d '\r\n')

if [ "$ADB_STATE" == "device" ]; then
    echo -e "${GREEN}[+] Sistema ADB já conectado.${NC}"
    sleep 1
else
    echo -e "${WHITE}Etapa 1: Conexão com o Dispositivo${NC}"
    echo -e "${YELLOW}O ADB não está conectado. Vamos configurar agora.${NC}\n"
    
    # Lendo o input de forma forçada pra não bugar no Termux
    echo -n "IP:PORTA de PAREAMENTO: "
    read -r PAIR_ADDR < /dev/tty
    
    echo -n "Código de 6 dígitos: "
    read -r PAIR_CODE < /dev/tty
    
    echo -e "\n${YELLOW}[*] Pareando dispositivos...${NC}"
    adb pair $PAIR_ADDR $PAIR_CODE
    
    echo -n "IP:PORTA de CONEXÃO: "
    read -r CONN_ADDR < /dev/tty
    
    echo -e "${YELLOW}[*] Estabelecendo conexão segura...${NC}"
    adb connect $CONN_ADDR
    sleep 1
    
    if [ "$(adb get-state 2>/dev/null | tr -d '\r\n')" != "device" ]; then
        echo -e "${RED}[!] Falha na conexão. Verifique os dados e tente novamente.${NC}"
        exit 1
    fi
fi

HWID=$(adb shell settings get secure android_id 2>/dev/null | tr -d '\r\n')
if [ -z "$HWID" ] || [ "$HWID" == "null" ]; then
    echo -e "${RED}[!] Falha ao obter o Hardware ID. Verifique o ADB.${NC}"
    exit 1
fi

clear
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}             VALIDAÇÃO DE LICENÇA         ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

echo -n "Insira sua Key de Acesso: "
read -r USER_KEY < /dev/tty

echo -e "\n${YELLOW}[*] Comunicando com o servidor...${NC}"

K_API=$(echo "aHR0cHM6Ly9nZXJhZG9yLWtleXMuZGUuZGVwbGV4by5jb20vYXBpL3ZhbGlkYXRl" | base64 -d)
K_SLG=$(echo "c3RpcmxheC1tb2R6LW0xbngtb2ZpY2lhbA==" | base64 -d)
K_VER=$(echo "Mi4w" | base64 -d)

RESPONSE=$(curl -s -X POST "$K_API" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"key\":\"$USER_KEY\",\"hwid\":\"$HWID\",\"appSlug\":\"$K_SLG\",\"appVersion\":\"$K_VER\"}")

SUCCESS=$(echo "$RESPONSE" | grep -o '"success":[^,]*' | cut -d':' -f2 | tr -d ' ')
STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
EXPIRES_AT=$(echo "$RESPONSE" | grep -o '"expiresAt":[^,]*' | cut -d':' -f2 | tr -d ' ')

if [ "$SUCCESS" != "true" ] || [ "$STATUS" != "active" ]; then
    echo -e "${RED}[!] Acesso Negado. Key inválida ou expirada.${NC}"
    sleep 3
    exit 1
fi

NOW=$(date +%s)
EXPIRES_SEC=$((EXPIRES_AT / 1000))
DIFF=$((EXPIRES_SEC - NOW))

if [ $DIFF -gt 0 ]; then
    DIAS=$((DIFF / 86400))
    HORAS=$(((DIFF % 86400) / 3600))
    echo -e "${GREEN}[+] Acesso Autorizado!${NC}"
    echo -e "${GREEN}[+] Expira em: ${DIAS} dias e ${HORAS} horas.${NC}"
    sleep 2
else
    echo -e "${RED}[!] Licença expirada.${NC}"
    sleep 3
    exit 1
fi

clear
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}             INJEÇÃO DO MÓDULO            ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"
echo -e "${WHITE}Abra o Zayon, conecte o ADB e clique em INJETAR."
echo -e "Após abrir o Free Fire, retorne a esta tela.${NC}\n"
echo -n "Módulo injetado e FF aberto? (s/n): "
read -r INJETADO < /dev/tty

if [ "$INJETADO" != "s" ]; then
    echo -e "${RED}[!] Operação cancelada.${NC}"
    exit 1
fi

while true; do
    clear
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${WHITE}              GHOST REMOTE                ${NC}"
    echo -e "${PURPLE}==========================================${NC}\n"
    
    status() {
        if [ "${ESTADO[$1]}" -eq 1 ]; then echo -e "${GREEN}[ON]${NC}"; fi
    }

    echo -e "${CYAN}┌── AIMBOTS ─────────────────────────────┐${NC}"
    echo -e "  [1] HS Cabeça (Head Priority)  $(status 1)"
    echo -e "  [2] Drag Neck (Pescoço)        $(status 2)"
    
    echo -e "\n${CYAN}┌── ESP (VISÃO) ─────────────────────────┐${NC}"
    echo -e "  [3] ESP Box (Caixa)            $(status 3)"
    echo -e "  [4] ESP Linha (Topo)           $(status 4)"
    echo -e "  [5] ESP Nickname               $(status 5)"
    echo -e "  [6] ESP Vida (Health)          $(status 6)"
    echo -e "  [7] Esqueleto Branco           $(status 7)"
    echo -e "  [8] Distância em Metros        $(status 8)"

    echo -e "\n${CYAN}┌── OUTRAS FUNÇÕES ──────────────────────┐${NC}"
    echo -e "  [9] FOV Perfeito               $(status 9)"
    echo -e "  [10] Fast Switch               $(status 10)"
    echo -e "  [11] No Recoil (Real)          $(status 11)"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"
    
    echo -e "\n  [0] Encerrar Sessão"
    echo -e ""
    echo -n "  » Selecione: "
    read -r FUNC_OPT < /dev/tty

    case $FUNC_OPT in
        1) ENDPOINT="item1"; NAME="HS Cabeça" ;;
        2) ENDPOINT="item5"; NAME="Drag Neck" ;;
        3) ENDPOINT="item3"; NAME="ESP Box" ;;
        4) ENDPOINT="item2"; NAME="ESP Linha" ;;
        5) ENDPOINT="item6"; NAME="ESP Nickname" ;;
        6) ENDPOINT="item7"; NAME="ESP Vida" ;;
        7) ENDPOINT="item9"; NAME="Esqueleto Branco" ;;
        8) ENDPOINT="item10"; NAME="Distância" ;;
        9) ENDPOINT="item11"; NAME="FOV Perfeito" ;;
        10) ENDPOINT="item14"; NAME="Fast Switch" ;;
        11) ENDPOINT="item15"; NAME="No Recoil (Real)" ;;
        0) clear; exit 0 ;;
        *) continue ;;
    esac

    echo -e "\n${YELLOW}[*] Sincronizando com o módulo...${NC}"
    sleep 0.2
    
    if [ "${ESTADO[$FUNC_OPT]}" -eq 0 ]; then
        curl -s --max-time 2 "http://127.0.0.1:7755/$ENDPOINT" > /dev/null
        ESTADO[$FUNC_OPT]=1
        echo -e "${GREEN}[+] $NAME: ATIVADO${NC}"
    else
        curl -s --max-time 2 "http://127.0.0.1:7755/$ENDPOINT/desativar" > /dev/null
        ESTADO[$FUNC_OPT]=0
        echo -e "${RED}[-] $NAME: DESATIVADO${NC}"
    fi
    sleep 0.8
done
GHOST_EOF

chmod +x /data/data/com.termux/files/usr/bin/ghost

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}    INSTALAÇÃO CONCLUÍDA COM SUCESSO!     ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo -e "\n${WHITE}Para abrir o painel a qualquer momento, digite:${NC}"
echo -e "${CYAN}ghost${NC}\n"

ghost
