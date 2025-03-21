#!/bin/bash

# Dark Arch Setup Script
# This script transforms Arch Linux into a Kali-equivalent penetration testing environment
# with professional and aesthetically pleasing customizations called "Dark Arch"

# Exit on any error
set -e

# ANSI color codes for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner function
banner() {
    echo -e "${BLUE}"
    echo -e "╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                                                              ║"
    echo -e "║       █▀▄ ▄▀█ █▀█ █▄▀    ▄▀█ █▀█ █▀▀ █░█                    ║"
    echo -e "║       █▄▀ █▀█ █▀▄ █░█    █▀█ █▀▄ █▄▄ █▀█                    ║"
    echo -e "║                                                              ║"
    echo -e "║       Professional Penetration Testing Environment           ║" 
    echo -e "║                                                              ║"
    echo -e "║                                                              ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Creating Dark Arch: A professional penetration testing environment on Arch Linux${NC}\n"
}

# Function to print section headers
section() {
    echo -e "\n${GREEN}==> ${1}${NC}"
}

# Function to print status messages
status() {
    echo -e "${BLUE}-->${NC} ${1}"
}

# Function to print errors
error() {
    echo -e "${RED}[ERROR] ${1}${NC}"
}

# Check if script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Update system
update_system() {
    section "Updating system"
    status "Syncing package databases..."
    pacman -Syy --noconfirm
    status "Performing system upgrade..."
    pacman -Syu --noconfirm
}

# Install base dependencies
install_base_dependencies() {
    section "Installing base dependencies"
    status "Installing essential packages..."
    pacman -S --needed --noconfirm base-devel git curl wget unzip p7zip \
        python python-pip python-setuptools python-wheel python-virtualenv \
        go rust nodejs npm ruby
}

# Install AUR helper (yay)
install_aur_helper() {
    section "Installing AUR helper (yay)"
    if ! command -v yay &> /dev/null; then
        status "Installing yay AUR helper..."
        
        # Create a temporary directory
        rm -rf /tmp/yay_install
        mkdir -p /tmp/yay_install
        
        # Get the normal user's name from SUDO_USER or fallback to first normal user
        NORMAL_USER=${SUDO_USER:-$(grep -E ":[0-9]{4}:" /etc/passwd | cut -d: -f1 | head -n1)}
        
        # Set permissions for the normal user
        chown -R $NORMAL_USER:$NORMAL_USER /tmp/yay_install
        
        # Create a temporary script to run as the normal user
        cat > /tmp/yay_install/build_yay.sh << 'EOF'
#!/bin/bash
cd /tmp/yay_install
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF
        
        # Make the script executable
        chmod +x /tmp/yay_install/build_yay.sh
        chown $NORMAL_USER:$NORMAL_USER /tmp/yay_install/build_yay.sh
        
        # Run the script as the normal user
        su - $NORMAL_USER -c "/tmp/yay_install/build_yay.sh"
        
        # Clean up
        rm -rf /tmp/yay_install
    else
        status "yay is already installed"
    fi
}

# Install BlackArch repository
install_blackarch_repo() {
    section "Adding BlackArch repository"
    if [ ! -f "/etc/pacman.d/blackarch-mirrorlist" ]; then
        status "Installing BlackArch keyring and mirrorlist..."
        curl -O https://blackarch.org/strap.sh
        chmod +x strap.sh
        ./strap.sh
        rm strap.sh
    else
        status "BlackArch repository is already configured"
    fi
}

# Install Kali-like tools by category
install_information_gathering() {
    section "Installing Information Gathering tools"
    status "Installing network scanners and information gathering tools..."
    pacman -S --needed --noconfirm nmap masscan nikto whatweb amass arp-scan \
        fierce sslscan dnsenum dnsrecon recon-ng gobuster dirb dirbuster wfuzz \
        whois netcat
}

install_vulnerability_analysis() {
    section "Installing Vulnerability Analysis tools"
    status "Installing vulnerability scanners and analysis tools..."
    pacman -S --needed --noconfirm openvas sqlmap burpsuite zaproxy nessus \
        metasploit-framework
}

install_web_application_analysis() {
    section "Installing Web Application Analysis tools"
    status "Installing web application testing tools..."
    pacman -S --needed --noconfirm burpsuite zaproxy sqlmap dirb dirbuster \
        wfuzz skipfish wapiti ffuf
}

install_database_assessment() {
    section "Installing Database Assessment tools"
    status "Installing database assessment tools..."
    pacman -S --needed --noconfirm sqlmap sqlitebrowser
}

install_password_attacks() {
    section "Installing Password Attack tools"
    status "Installing password cracking and brute force tools..."
    pacman -S --needed --noconfirm john hashcat hydra medusa crunch \
        wordlists seclists
}

install_wireless_attacks() {
    section "Installing Wireless Attack tools"
    status "Installing wireless network testing tools..."
    pacman -S --needed --noconfirm aircrack-ng wifite kismet reaver \
        bully cowpatty hostapd
}

install_reverse_engineering() {
    section "Installing Reverse Engineering tools"
    status "Installing reverse engineering tools..."
    pacman -S --needed --noconfirm radare2 ghidra gdb edb-debugger
}

install_exploitation_tools() {
    section "Installing Exploitation tools"
    status "Installing exploitation frameworks and tools..."
    pacman -S --needed --noconfirm metasploit-framework exploitdb beef \
        empire powersploit shellter veil
}

install_sniffing_spoofing() {
    section "Installing Sniffing & Spoofing tools"
    status "Installing network sniffing and spoofing tools..."
    pacman -S --needed --noconfirm wireshark-qt ettercap-gtk dsniff tcpdump \
        mitmproxy bettercap netsniff-ng
}

install_post_exploitation() {
    section "Installing Post Exploitation tools"
    status "Installing post-exploitation tools..."
    pacman -S --needed --noconfirm mimikatz weevely powercat
}

install_forensics() {
    section "Installing Forensics tools"
    status "Installing digital forensics tools..."
    pacman -S --needed --noconfirm autopsy sleuthkit foremost binwalk \
        testdisk scalpel ddrescue
}

install_reporting_tools() {
    section "Installing Reporting tools"
    status "Installing documentation and reporting tools..."
    pacman -S --needed --noconfirm faraday maltego cherrytree keepnote
}

install_popular_kali_tools() {
    section "Installing additional popular Kali tools"
    status "Installing must-have Kali tools..."
    
    # Using AUR (via yay) for tools not in official repos
    sudo -u "$SUDO_USER" yay -S --needed --noconfirm \
        theharvester maltego bloodhound responder crackmapexec \
        enum4linux-ng gobuster oneforall photon sherlock spiderfoot eyewitness
}

# Install and configure desktop environment
install_desktop_environment() {
    section "Installing and configuring XFCE desktop environment"
    status "Installing XFCE..."
    pacman -S --needed --noconfirm xorg xfce4 xfce4-goodies lightdm \
        lightdm-gtk-greeter lightdm-gtk-greeter-settings
    
    status "Enabling display manager..."
    systemctl enable lightdm
}

# Install terminal emulator and configure it to look awesome
install_terminal() {
    section "Installing and configuring terminal"
    status "Installing Alacritty, ZSH, and configuration tools..."
    pacman -S --needed --noconfirm alacritty zsh zsh-completions zsh-syntax-highlighting \
        zsh-autosuggestions neofetch lolcat
    
    # Install Oh My Zsh for the normal user
    status "Installing Oh My Zsh..."
    sudo -u "$SUDO_USER" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install Powerlevel10k theme
    status "Installing Powerlevel10k ZSH theme..."
    sudo -u "$SUDO_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    
    # Install Nerd Fonts
    status "Installing Hack Nerd Font..."
    mkdir -p /tmp/nerd-fonts
    cd /tmp/nerd-fonts
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip
    mkdir -p /usr/share/fonts/nerd-fonts/
    unzip Hack.zip -d /usr/share/fonts/nerd-fonts/
    fc-cache -fv
    cd ~
    
    # Set up terminal configuration files
    status "Configuring Alacritty terminal..."
    
    # Alacritty config
    mkdir -p "$HOME/.config/alacritty"
    cat > "$HOME/.config/alacritty/alacritty.yml" << 'EOF'
window:
  padding:
    x: 10
    y: 10
  opacity: 0.95
  title: Terminal
  class:
    instance: Alacritty
    general: Alacritty

scrolling:
  history: 10000
  multiplier: 3

font:
  normal:
    family: Hack Nerd Font
    style: Regular
  bold:
    family: Hack Nerd Font
    style: Bold
  italic:
    family: Hack Nerd Font
    style: Italic
  bold_italic:
    family: Hack Nerd Font
    style: Bold Italic
  size: 11.0

# Colors (One Dark Pro)
colors:
  primary:
    background: '#1e2127'
    foreground: '#abb2bf'
  cursor:
    text: '#1e2127'
    cursor: '#abb2bf'
  normal:
    black:   '#1e2127'
    red:     '#e06c75'
    green:   '#98c379'
    yellow:  '#d19a66'
    blue:    '#61afef'
    magenta: '#c678dd'
    cyan:    '#56b6c2'
    white:   '#abb2bf'
  bright:
    black:   '#5c6370'
    red:     '#e06c75'
    green:   '#98c379'
    yellow:  '#d19a66'
    blue:    '#61afef'
    magenta: '#c678dd'
    cyan:    '#56b6c2'
    white:   '#ffffff'

cursor:
  style:
    shape: Block
  blinking: On
  blink_interval: 750
  thickness: 0.15

key_bindings:
  - { key: V, mods: Control, action: Paste }
  - { key: C, mods: Control, action: Copy }
  - { key: Insert, mods: Shift, action: PasteSelection }
EOF

    chown -R "$SUDO_USER:$SUDO_USER" "$HOME/.config/alacritty"
    
    # ZSH configuration
    status "Configuring ZSH..."
    
    # P10k configuration
    cat > "$HOME/.p10k.zsh" << 'EOF'
# Generated by Powerlevel10k configuration wizard
# Basic P10k configuration with a customized prompt for pentesters
# For more customization options visit: https://github.com/romkatv/powerlevel10k

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh
  setopt no_unset extended_glob

  # Prompt style
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  
  # Left prompt segments
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    context                 # user@hostname
    dir                     # current directory
    vcs                     # git status
    status                  # previous command status
    command_execution_time  # previous command duration
  )
  
  # Right prompt segments
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    time                    # current time
    ip                      # ip address
    public_ip               # public IP address
    ram                     # free RAM
    load                    # CPU load
  )
  
  # Basic prompt styling
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%F{014}╭─'
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%F{014}├─'
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{014}╰─'
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX='%F{014}─'
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX='%F{014}─'
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX='%F{014}─'
  
  # Context: user@hostname
  typeset -g POWERLEVEL9K_CONTEXT_PREFIX='%F{007}in '
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%F{red}%n%F{007}@%F{yellow}%m'
  
  # Directory
  typeset -g POWERLEVEL9K_DIR_BACKGROUND=none
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=039
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=4
  
  # VCS: Git status
  typeset -g POWERLEVEL9K_VCS_BACKGROUND=none
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=076
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=014
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=011
  
  # Status
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=none
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=009
  
  # Command execution time
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=none
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
  
  # Time
  typeset -g POWERLEVEL9K_TIME_BACKGROUND=none
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=244
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  
  # IP address
  typeset -g POWERLEVEL9K_IP_BACKGROUND=none
  typeset -g POWERLEVEL9K_IP_FOREGROUND=244
  
  # Public IP
  typeset -g POWERLEVEL9K_PUBLIC_IP_BACKGROUND=none
  typeset -g POWERLEVEL9K_PUBLIC_IP_FOREGROUND=244
  
  # RAM
  typeset -g POWERLEVEL9K_RAM_BACKGROUND=none
  typeset -g POWERLEVEL9K_RAM_FOREGROUND=244
  
  # CPU Load
  typeset -g POWERLEVEL9K_LOAD_BACKGROUND=none
  typeset -g POWERLEVEL9K_LOAD_FOREGROUND=244
  
  # Styling for prompt characters
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=076
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=196
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
EOF
    
    # Update .zshrc
    cat > "$HOME/.zshrc" << 'EOF'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  sudo
  docker
  python
  kubectl
  history
  command-not-found
  colored-man-pages
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR='nano'
export VISUAL='nano'

# Aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ip='ip -c'
alias update='sudo pacman -Syu'
alias aur='yay -Sua'
alias netinfo='ip -c a && echo "" && ip -c r'
alias scan='sudo nmap -sC -sV'
alias portscan='sudo nmap -p-'
alias vulnscan='sudo nmap --script vuln'
alias msfconsole='sudo msfconsole'
alias burp='java -jar /usr/bin/burpsuite'
alias webmap='python3 -m webbrowser -t "http://localhost:8000"'
alias zshrc='$EDITOR ~/.zshrc'
alias refresh='source ~/.zshrc'
alias myip='curl ifconfig.me'
alias dirsearch='python3 /usr/share/dirsearch/dirsearch.py'
alias dirb='dirb'
alias sqlmap='sqlmap'
alias john='john'
alias airmon='sudo airmon-ng'
alias airodump='sudo airodump-ng'

# Custom functions
function extract() {
  if [ -z "$1" ]; then
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
  else
    if [ -f $1 ]; then
      case $1 in
        *.tar.bz2)   tar xvjf $1    ;;
        *.tar.gz)    tar xvzf $1    ;;
        *.tar.xz)    tar xvJf $1    ;;
        *.lzma)      unlzma $1      ;;
        *.bz2)       bunzip2 $1     ;;
        *.rar)       unrar x -ad $1 ;;
        *.gz)        gunzip $1      ;;
        *.tar)       tar xvf $1     ;;
        *.tbz2)      tar xvjf $1    ;;
        *.tgz)       tar xvzf $1    ;;
        *.zip)       unzip $1       ;;
        *.Z)         uncompress $1  ;;
        *.7z)        7z x $1        ;;
        *.xz)        unxz $1        ;;
        *.exe)       cabextract $1  ;;
        *)           echo "extract: '$1' - unknown archive method" ;;
      esac
    else
      echo "$1 - file does not exist"
    fi
  fi
}

function webshell() {
  python3 -m http.server
}

function penenv() {
  sudo openvpn --config "$HOME/vpn/pen-${1}.ovpn"
}

function hack-the-box() {
  sudo openvpn --config "$HOME/vpn/htb.ovpn"
}

function try-hack-me() {
  sudo openvpn --config "$HOME/vpn/thm.ovpn"
}

# Welcome message
neofetch | lolcat
echo ""
echo "$(date '+%A, %B %d, %Y %T')" | lolcat
echo "Welcome to Dark Arch - Your Professional Penetration Testing Environment!" | lolcat
echo ""

# Source Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

    # Fix permissions
    chown "$SUDO_USER:$SUDO_USER" "$HOME/.p10k.zsh" "$HOME/.zshrc"
    
    # Set ZSH as default shell for the user
    status "Setting ZSH as default shell..."
    chsh -s /bin/zsh "$SUDO_USER"
}

# Install and configure additional software
install_additional_software() {
    section "Installing additional tools and utilities"
    
    status "Installing browsers and development tools..."
    pacman -S --needed --noconfirm firefox code terminator
    
    status "Installing file managers and utilities..."
    pacman -S --needed --noconfirm thunar thunar-archive-plugin thunar-media-tags-plugin \
        thunar-volman gvfs tumbler ffmpegthumbnailer htop btop neofetch cmatrix lolcat
    
    status "Installing VPN and network utilities..."
    pacman -S --needed --noconfirm openvpn networkmanager-openvpn network-manager-applet \
        wireshark-qt tcpdump inetutils
    
    status "Installing additional security tools..."
    pacman -S --needed --noconfirm rkhunter lynis macchanger proxychains-ng tor torsocks
    
    status "Installing essential programming languages and libraries..."
    pacman -S --needed --noconfirm python-pip python2-pip ruby jdk-openjdk nodejs npm \
        go rust dotnet-sdk php php-gd composer
}

# Set up the desktop environment
configure_desktop() {
    section "Configuring desktop environment"
    
    # Create directory structure
    status "Creating directory structure..."
    mkdir -p "$HOME/.config/xfce4"
    mkdir -p "$HOME/Pictures/Wallpapers"
    mkdir -p "$HOME/Documents/Reports"
    mkdir -p "$HOME/Documents/Scripts"
    mkdir -p "$HOME/Documents/Wordlists"
    mkdir -p "$HOME/Documents/Tools"
    mkdir -p "$HOME/vpn"
    
    # Download wallpaper
    status "Downloading wallpaper..."
    wget "https://wallpapercave.com/wp/wp5998745.jpg" -O "$HOME/Pictures/Wallpapers/dark-arch.jpg"
    
    # Set wallpaper
    status "Setting wallpaper..."
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$HOME/Pictures/Wallpapers/dark-arch.jpg"
    
    # Set theme
    status "Installing and setting Kali-like theme..."
    pacman -S --needed --noconfirm arc-gtk-theme arc-icon-theme papirus-icon-theme
    
    # Apply themes
    xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark"
    
    # Fix permissions
    chown -R "$SUDO_USER:$SUDO_USER" "$HOME/.config" "$HOME/Pictures" "$HOME/Documents" "$HOME/vpn"
}

# Create desktop shortcuts
create_shortcuts() {
    section "Creating desktop shortcuts"
    
    mkdir -p "$HOME/Desktop"
    
    # Create application shortcuts
    status "Creating application shortcuts..."
    
    cat > "$HOME/Desktop/terminal.desktop" << EOF
[Desktop Entry]
Name=Terminal
Comment=Professional Terminal Emulator
Exec=alacritty
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
EOF

    cat > "$HOME/Desktop/firefox.desktop" << EOF
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox %u
Icon=firefox
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

    cat > "$HOME/Desktop/metasploit.desktop" << EOF
[Desktop Entry]
Name=Metasploit Framework
Comment=Advanced Penetration Testing Tool
Exec=terminator -e "sudo msfconsole"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Security;
EOF

    cat > "$HOME/Desktop/burpsuite.desktop" << EOF
[Desktop Entry]
Name=Burp Suite
Comment=Web Application Security Testing
Exec=burpsuite
Icon=burpsuite
Terminal=false
Type=Application
Categories=Security;
EOF

    cat > "$HOME/Desktop/wireshark.desktop" << EOF
[Desktop Entry]
Name=Wireshark
Comment=Network Protocol Analyzer
Exec=wireshark
Icon=wireshark
Terminal=false
Type=Application
Categories=Network;
EOF

    # Fix permissions
    chown -R "$SUDO_USER:$SUDO_USER" "$HOME/Desktop"
    chmod +x "$HOME/Desktop"/*.desktop
}

# Final setup and cleanup
finalize_setup() {
    section "Finalizing setup"
    
    status "Updating database for locate command..."
    updatedb
    
    status "Cleaning up..."
    pacman -Sc --noconfirm
    
    status "Creating README file..."
    cat > "$HOME/README.md" << EOF
# Dark Arch: Professional Penetration Testing Environment

This Arch Linux system has been transformed into Dark Arch - a professional penetration testing platform with all the tools you need for security assessments.

## Key Components

- **Terminal**: Alacritty with Powerlevel10k ZSH theme
- **Desktop Environment**: XFCE with Arc-Dark theme and Papirus icons
- **Security Tools**: Full suite of Kali Linux equivalent tools
- **Development**: Python, Ruby, Go, Rust, PHP, etc.

## Useful Aliases

- \`netinfo\`: Display network information
- \`scan\`: Run an Nmap scan with version detection
- \`portscan\`: Run a full port scan
- \`vulnscan\`: Run a vulnerability scan
- \`webshell\`: Start a simple HTTP server
- \`hack-the-box\`: Connect to Hack The Box VPN
- \`try-hack-me\`: Connect to TryHackMe VPN

## Custom Commands

- \`extract\`: Extract any archive format
- \`penenv\`: Connect to custom pentesting VPN
- \`webshell\`: Start a Python HTTP server

For more information, check the ZSH configuration file (\`~/.zshrc\`).
EOF

    chown "$SUDO_USER:$SUDO_USER" "$HOME/README.md"
    
    status "Creating desktop shortcut to README..."
    cat > "$HOME/Desktop/README.desktop" << EOF
[Desktop Entry]
Name=README
Comment=Read Me First
Exec=xdg-open $HOME/README.md
Icon=text-editor
Terminal=false
Type=Application
Categories=Documentation;
EOF

    chown "$SUDO_USER:$SUDO_USER" "$HOME/Desktop/README.desktop"
    chmod +x "$HOME/Desktop/README.desktop"
}

# Main execution
main() {
    banner
    check_root
    update_system
    install_base_dependencies
    install_aur_helper
    install_blackarch_repo
    
    # Install security tools by category
    install_information_gathering
    install_vulnerability_analysis
    install_web_application_analysis
    install_database_assessment
    install_password_attacks
    install_wireless_attacks
    install_reverse_engineering
    install_exploitation_tools
    install_sniffing_spoofing
    install_post_exploitation
    install_forensics
    install_reporting_tools
    install_popular_kali_tools
    
    # Set up desktop environment
    install_desktop_environment
    install_terminal
    install_additional_software
    configure_desktop
    create_shortcuts
    finalize_setup
    
    section "Installation complete!"
    echo -e "${GREEN}Dark Arch has been set up successfully!${NC}"
    echo -e "${YELLOW}Please reboot your system to apply all changes.${NC}"
    echo -e "${BLUE}After reboot, you'll have a fully functional Dark Arch environment ready for professional penetration testing.${NC}"
}

# Run the script
main
