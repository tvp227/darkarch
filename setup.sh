#!/bin/bash
#
# Dark Arch - Kali-like environment for Arch Linux
# Author: Claude
# Date: March 21, 2025
#
# This script transforms an Arch Linux installation into a penetration testing
# environment similar to Kali Linux, with additional UI tweaks.

set -e # Exit on error

# ANSI color codes for colorful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colorful messages
print_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root!"
    exit 1
fi

# Function to check if a package exists in official repositories or AUR
package_exists() {
    pacman -Si "$1" &>/dev/null || yay -Si "$1" &>/dev/null
}

# Function to install packages
install_packages() {
    for pkg in "$@"; do
        if pacman -Q "$pkg" &>/dev/null; then
            print_info "Package $pkg is already installed."
        elif package_exists "$pkg"; then
            print_info "Installing $pkg..."
            pacman -S --noconfirm "$pkg" || yay -S --noconfirm "$pkg" || {
                print_error "Failed to install $pkg"
                return 1
            }
        else
            print_warning "Package $pkg not found. Skipping."
        fi
    done
}

# Check for internet connection
check_internet() {
    print_info "Checking internet connection..."
    if ! ping -c 1 archlinux.org &>/dev/null; then
        print_error "No internet connection! Please connect to the internet and try again."
        exit 1
    fi
    print_success "Internet connection verified."
}

# Make sure system is up to date before proceeding
update_system() {
    print_info "Updating system packages..."
    pacman -Syu --noconfirm || {
        print_error "Failed to update system packages!"
        exit 1
    }
    print_success "System updated successfully."
}

# Install yay AUR helper if not installed
install_yay() {
    if ! command -v yay &>/dev/null; then
        print_info "Installing yay AUR helper..."
        
        # Dependencies for building packages
        pacman -S --needed --noconfirm git base-devel || {
            print_error "Failed to install git and base-devel!"
            exit 1
        }
        
        # Create temporary directory for building yay
        temp_dir=$(mktemp -d)
        cd "$temp_dir" || {
            print_error "Failed to create temporary directory!"
            exit 1
        }
        
        # Clone and build yay
        git clone https://aur.archlinux.org/yay.git || {
            print_error "Failed to clone yay repository!"
            exit 1
        }
        
        cd yay || {
            print_error "Failed to access yay directory!"
            exit 1
        }
        
        # Build and install yay
        makepkg -si --noconfirm || {
            print_error "Failed to build and install yay!"
            exit 1
        }
        
        # Clean up
        cd / && rm -rf "$temp_dir"
        
        print_success "yay installed successfully."
    else
        print_info "yay is already installed."
    fi
}

# Install desktop environment (XFCE with extra tweaks)
install_desktop_environment() {
    print_info "Installing XFCE desktop environment..."
    
    # Core XFCE packages
    install_packages xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
    
    # Enable lightdm service
    systemctl enable lightdm.service
    
    print_success "Desktop environment installed."
}

# Install and configure terminal emulator (Alacritty with tmux)
install_terminal() {
    print_info "Installing terminal environment..."
    
    # Install Alacritty, tmux, and zsh
    install_packages alacritty tmux zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search
    
    # Install oh-my-zsh
    print_info "Setting up oh-my-zsh..."
    
    # Create directory for user configs
    mkdir -p /etc/skel/.config/alacritty
    
    # Configure Alacritty
    cat > /etc/skel/.config/alacritty/alacritty.yml << 'EOF'
window:
  padding:
    x: 10
    y: 10
  opacity: 0.95
  decorations: full
  dynamic_title: true

scrolling:
  history: 10000
  multiplier: 3

font:
  normal:
    family: MesloLGS NF
    style: Regular
  bold:
    family: MesloLGS NF
    style: Bold
  italic:
    family: MesloLGS NF
    style: Italic
  size: 11.0

draw_bold_text_with_bright_colors: true

colors:
  primary:
    background: '#1e1e2e'
    foreground: '#d9e0ee'
  cursor:
    text: '#1e1e2e'
    cursor: '#f5e0dc'
  normal:
    black:   '#6e6c7c'
    red:     '#f28fad'
    green:   '#abe9b3'
    yellow:  '#fae3b0'
    blue:    '#96cdfb'
    magenta: '#f5c2e7'
    cyan:    '#89dceb'
    white:   '#d9e0ee'
  bright:
    black:   '#988ba2'
    red:     '#f28fad'
    green:   '#abe9b3'
    yellow:  '#fae3b0'
    blue:    '#96cdfb'
    magenta: '#f5c2e7'
    cyan:    '#89dceb'
    white:   '#d9e0ee'

shell:
  program: /bin/zsh

working_directory: None

live_config_reload: true

mouse:
  hide_when_typing: true
EOF

    # Install Nerd Fonts
    print_info "Installing Nerd Fonts..."
    yay -S --noconfirm ttf-meslo-nerd
    
    # Set up tmux configuration
    cat > /etc/skel/.tmux.conf << 'EOF'
# Improve colors
set -g default-terminal "screen-256color"

# Set scrollback buffer to 10000
set -g history-limit 10000

# Set prefix to Ctrl-Space
unbind C-b
set -g prefix C-Space
bind Space send-prefix

# Reload config file
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Split windows using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Enable mouse mode
set -g mouse on

# Don't rename windows automatically
set-option -g allow-rename off

# Start window numbering at 1
set -g base-index 1
set -g pane-base-index 1

# Theme
set -g status-bg black
set -g status-fg white
set -g status-interval 60
set -g status-left-length 30
set -g status-left '#[fg=green](#S) #(whoami)'
set -g status-right '#[fg=yellow]#(cut -d " " -f 1-3 /proc/loadavg)#[default] #[fg=white]%H:%M#[default]'
EOF

    # Set up zsh configuration with Oh-My-Zsh
    print_info "Setting up zsh configuration..."
    
    # Create a script to install oh-my-zsh for the user
    cat > /usr/local/bin/setup-zsh << 'EOF'
#!/bin/bash

# Check if Oh-My-Zsh is already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install Powerlevel10k theme
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    
    # Configure zshrc
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' $HOME/.zshrc
    
    # Add plugins
    sed -i 's/plugins=(git)/plugins=(git colored-man-pages sudo tmux history extract)/' $HOME/.zshrc
    
    # Add .p10k.zsh configuration
    curl -o $HOME/.p10k.zsh https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-lean.zsh
    
    # Add custom configurations
    cat >> $HOME/.zshrc << 'EOFINNER'

# Aliases for security tools
alias nmap="sudo nmap"
alias wifite="sudo wifite"
alias airgeddon="sudo airgeddon"
alias airodump-ng="sudo airodump-ng"
alias aireplay-ng="sudo aireplay-ng"
alias aircrack-ng="sudo aircrack-ng"
alias sqlmap="python3 /usr/bin/sqlmap"

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Improved file operations
alias ls="ls --color=auto"
alias ll="ls -la"
alias la="ls -a"
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -iv"
alias mkdir="mkdir -pv"

# Source p10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Source syntax highlighting if installed
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Source autosuggestions if installed
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Source history substring search if installed
[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ] && source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# Add Darkarch ASCII art to terminal startup
echo '
   ▓█████▄  ▄▄▄       ██▀███   ██ ▄█▀    ▄▄▄       ██▀███   ▄████▄   ██░ ██ 
   ▒██▀ ██▌▒████▄    ▓██ ▒ ██▒ ██▄█▒    ▒████▄    ▓██ ▒ ██▒▒██▀ ▀█  ▓██░ ██▒
   ░██   █▌▒██  ▀█▄  ▓██ ░▄█ ▒▓███▄░    ▒██  ▀█▄  ▓██ ░▄█ ▒▒▓█    ▄ ▒██▀▀██░
   ░▓█▄   ▌░██▄▄▄▄██ ▒██▀▀█▄  ▓██ █▄    ░██▄▄▄▄██ ▒██▀▀█▄  ▒▓▓▄ ▄██▒░▓█ ░██ 
   ░▒████▓  ▓█   ▓██▒░██▓ ▒██▒▒██▒ █▄    ▓█   ▓██▒░██▓ ▒██▒▒ ▓███▀ ░░▓█▒░██▓
    ▒▒▓  ▒  ▒▒   ▓▒█░░ ▒▓ ░▒▓░▒ ▒▒ ▓▒    ▒▒   ▓▒█░░ ▒▓ ░▒▓░░ ░▒ ▒  ░ ▒ ░░▒░▒
    ░ ▒  ▒   ▒   ▒▒ ░  ░▒ ░ ▒░░ ░▒ ▒░     ▒   ▒▒ ░  ░▒ ░ ▒░  ░  ▒    ▒ ░▒░ ░
    ░ ░  ░   ░   ▒     ░░   ░ ░ ░░ ░      ░   ▒     ░░   ░ ░         ░  ░░ ░
      ░          ░  ░   ░     ░  ░            ░  ░   ░     ░ ░       ░  ░  ░
    ░                                                      ░                 
'
EOFINNER
fi
EOF

    chmod +x /usr/local/bin/setup-zsh
    
    # Add to .profile to auto-configure ZSH on first login
    cat > /etc/skel/.profile << 'EOF'
# If this is the first login, set up ZSH
if [ ! -d "$HOME/.oh-my-zsh" ] && [ -f "/usr/local/bin/setup-zsh" ]; then
    /usr/local/bin/setup-zsh
fi
EOF

    # Set ZSH as default shell for new users
    sed -i 's/SHELL=\/bin\/bash/SHELL=\/bin\/zsh/' /etc/default/useradd
    
    print_success "Terminal environment configured."
}

# Install theme and visual tweaks
install_theme() {
    print_info "Installing theme and visual tweaks..."
    
    # Install themes and icons
    install_packages arc-gtk-theme arc-icon-theme papirus-icon-theme lxappearance kvantum-qt5
    
    # Install Nordic theme from AUR
    yay -S --noconfirm nordic-theme-git
    
    # Download and set wallpaper
    print_info "Setting up wallpaper..."
    mkdir -p /usr/share/backgrounds/darkarch
    wget -O /usr/share/backgrounds/darkarch/wallpaper.jpg "https://wallpapercave.com/wp/wp5998745.jpg" || {
        print_warning "Failed to download wallpaper, using alternative method..."
        curl -o /usr/share/backgrounds/darkarch/wallpaper.jpg "https://wallpapercave.com/wp/wp5998745.jpg" || {
            print_error "Failed to download wallpaper!"
            # Create a colored wallpaper as fallback
            convert -size 1920x1080 gradient:navy-black /usr/share/backgrounds/darkarch/wallpaper.jpg
        }
    }
    
    # Set up XFCE configuration
    mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/
    
    # Configure XFCE appearance settings
    cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" value="Nordic-darker"/>
    <property name="IconThemeName" value="Papirus-Dark"/>
    <property name="DoubleClickTime" value="400"/>
    <property name="DoubleClickDistance" value="5"/>
    <property name="DndDragThreshold" value="8"/>
    <property name="CursorBlink" value="true"/>
    <property name="CursorBlinkTime" value="1200"/>
    <property name="SoundThemeName" value="default"/>
    <property name="EnableEventSounds" value="false"/>
    <property name="EnableInputFeedbackSounds" value="false"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" value="-1"/>
    <property name="Antialias" value="1"/>
    <property name="Hinting" value="1"/>
    <property name="HintStyle" value="hintslight"/>
    <property name="RGBA" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CanChangeAccels" value="false"/>
    <property name="ColorPalette" value="black:white:gray50:red:purple:blue:light blue:green:yellow:orange:lavender:brown:goldenrod4:dodger blue:pink:light green:gray10:gray30:gray75:gray90"/>
    <property name="FontName" value="Sans 10"/>
    <property name="MonospaceFontName" value="Monospace 10"/>
    <property name="IconSizes" value=""/>
    <property name="KeyThemeName" value=""/>
    <property name="ToolbarStyle" value="icons"/>
    <property name="ToolbarIconSize" value="3"/>
    <property name="MenuImages" value="true"/>
    <property name="ButtonImages" value="true"/>
    <property name="MenuBarAccel" value="F10"/>
    <property name="CursorThemeName" value="Adwaita"/>
    <property name="CursorThemeSize" value="16"/>
    <property name="DecorationLayout" value="menu:minimize,maximize,close"/>
  </property>
</channel>
EOF

    # Configure XFCE desktop settings
    cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/darkarch/wallpaper.jpg"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="0"/>
  </property>
</channel>
EOF

    # Configure XFCE panel
    cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="icon-size" type="uint" value="0"/>
      <property name="size" type="uint" value="30"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
        <value type="int" value="8"/>
        <value type="int" value="9"/>
        <value type="int" value="10"/>
        <value type="int" value="11"/>
        <value type="int" value="12"/>
        <value type="int" value="13"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="button-icon" type="string" value="org.xfce.panel.applicationsmenu"/>
      <property name="button-title" type="string" value="Dark Arch"/>
    </property>
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-4" type="string" value="pager"/>
    <property name="plugin-5" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-6" type="string" value="systray">
      <property name="show-frame" type="bool" value="false"/>
      <property name="square-icons" type="bool" value="true"/>
      <property name="size-max" type="uint" value="22"/>
    </property>
    <property name="plugin-7" type="string" value="statusnotifier"/>
    <property name="plugin-8" type="string" value="pulseaudio"/>
    <property name="plugin-9" type="string" value="power-manager-plugin"/>
    <property name="plugin-10" type="string" value="notification-plugin"/>
    <property name="plugin-11" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-12" type="string" value="clock">
      <property name="digital-format" type="string" value="%a %d %b, %R"/>
    </property>
    <property name="plugin-13" type="string" value="actions">
      <property name="appearance" type="uint" value="0"/>
      <property name="items" type="array">
        <value type="string" value="-lock-screen"/>
        <value type="string" value="-switch-user"/>
        <value type="string" value="-separator"/>
        <value type="string" value="-suspend"/>
        <value type="string" value="-hibernate"/>
        <value type="string" value="-hybrid-sleep"/>
        <value type="string" value="-separator"/>
        <value type="string" value="-shutdown"/>
        <value type="string" value="-restart"/>
        <value type="string" value="-separator"/>
        <value type="string" value="+logout"/>
        <value type="string" value="-logout-dialog"/>
      </property>
    </property>
  </property>
</channel>
EOF

    # Configure LightDM
    print_info "Configuring LightDM..."
    
    # Create LightDM config directories
    mkdir -p /etc/lightdm
    
    # Configure LightDM GTK Greeter
    cat > /etc/lightdm/lightdm-gtk-greeter.conf << EOF
[greeter]
theme-name = Nordic-darker
icon-theme-name = Papirus-Dark
font-name = Sans 10
background = /usr/share/backgrounds/darkarch/wallpaper.jpg
user-background = false
default-user-image = #user-icon
position = 50%,center 50%,center
panel-position = top
indicators = ~host;~spacer;~clock;~spacer;~session;~power
clock-format = %a %d %b, %H:%M
screensaver-timeout = 60
EOF

    # Configure conky for system monitoring
    install_packages conky
    mkdir -p /etc/skel/.config/conky
    
    cat > /etc/skel/.config/conky/conky.conf << 'EOF'
conky.config = {
    alignment = 'top_right',
    background = true,
    border_width = 1,
    cpu_avg_samples = 2,
    default_color = 'white',
    default_outline_color = 'grey',
    default_shade_color = 'black',
    double_buffer = true,
    draw_borders = false,
    draw_graph_borders = true,
    draw_outline = false,
    draw_shades = false,
    extra_newline = false,
    font = 'DejaVu Sans Mono:size=10',
    gap_x = 30,
    gap_y = 60,
    minimum_height = 5,
    minimum_width = 5,
    net_avg_samples = 2,
    no_buffers = true,
    out_to_console = false,
    out_to_ncurses = false,
    out_to_stderr = false,
    out_to_x = true,
    own_window = true,
    own_window_class = 'Conky',
    own_window_type = 'normal',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 0,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
    show_graph_range = false,
    show_graph_scale = false,
    stippled_borders = 0,
    update_interval = 2.0,
    uppercase = false,
    use_spacer = 'none',
    use_xft = true,
}

conky.text = [[
${color cyan}DARK ARCH${color} ${hr}
${color white}System: ${color grey}$sysname $kernel
${color white}Uptime: ${color grey}$uptime
${color white}Frequency: ${color grey}$freq_g GHz
${color white}RAM: ${color grey}$mem/$memmax - $memperc%
${membar 4}
${color white}CPU: ${color grey}$cpu%
${cpubar 4}
${color white}Processes: ${color grey}$processes  ${color white}Running: ${color grey}$running_processes
${color white}Load: ${color grey}$loadavg

${color cyan}NETWORKING${color} ${hr}
${color white}Local IP: ${color grey}${addr wlan0}
${color white}External IP: ${color grey}${execi 1000 curl -s ifconfig.me}
${color white}Up: ${color grey}${upspeed wlan0} ${color white} - Down: ${color grey}${downspeed wlan0}

${color cyan}SECURITY TOOLS${color} ${hr}
${color white}nmap: ${color grey}Network scanning
${color white}metasploit: ${color grey}Penetration testing
${color white}wireshark: ${color grey}Packet analysis
${color white}aircrack-ng: ${color grey}WiFi security
${color white}hydra: ${color grey}Login cracker
${color white}john: ${color grey}Password cracker
${color white}sqlmap: ${color grey}SQL injection

${color cyan}SYSTEM ${color} ${hr}
${color white}Hostname: ${color grey}$nodename
${color white}File system: ${color grey}${fs_used /}/${fs_size /}
${fs_bar 4 /}
${color white}Battery: ${color grey}${battery_percent BAT0}% ${battery_bar 4 BAT0}
]]
EOF
    
    # Create autostart for conky
    mkdir -p /etc/skel/.config/autostart
    cat > /etc/skel/.config/autostart/conky.desktop << EOF
[Desktop Entry]
Type=Application
Name=Conky
Exec=conky --daemonize --pause=5
StartupNotify=false
Terminal=false
Hidden=false
EOF
    
    print_success "Theme and visual tweaks installed."
}

# Install Kali Linux tools
install_kali_tools() {
    print_info "Installing Kali Linux tools..."
    
    # Install BlackArch repository
    if [ ! -f /etc/pacman.d/blackarch-mirrorlist ]; then
        print_info "Adding BlackArch repository..."
        curl -O https://blackarch.org/strap.sh
        chmod +x strap.sh
        ./strap.sh
        rm strap.sh
    fi
    
    # Refresh package databases
    pacman -Sy
    
    # Essential security tool groups
    install_packages blackarch-scanner blackarch-webapp blackarch-fuzzer blackarch-exploitation \
                     blackarch-sniffer blackarch-spoof blackarch-password blackarch-recon \
                     blackarch-wireless blackarch-forensic blackarch-crypto
    
    # Specific popular tools
    install_packages nmap wireshark-qt metasploit aircrack-ng wifite hydra john sqlmap gobuster \
                     burpsuite zaproxy dirb nikto wpscan ffuf hashcat ophcrack social-engineer-toolkit \
                     netcat tcpdump whois whatweb maltego set binwalk steghide foremost autopsy \
                     volatility responder beef-xss mimikatz ipv6-toolkit dnschef powersploit commix \
                     crunch medusa masscan reaver fluxion lynis
    
    print_success "Security tools installed."
}

# Install development tools
install_dev_tools() {
    print_info "Installing development tools..."
    
    install_packages git vim neovim emacs nano python python-pip python2 ruby nodejs npm go \
                     jdk-openjdk jre-openjdk java-environment-common docker docker-compose
    
    # Python packages
    pip install --upgrade pip
    pip install requests scapy beautifulsoup4 pwntools
    
    # Ruby gems
    gem install wpscan bundler
    
    # Enable docker service
    systemctl enable docker.service
    
    print_success "Development tools installed."
}

# Install additional utilities
install_utilities() {
    print_info "Installing additional utilities..."
    
    # General utilities
    install_packages htop btop neofetch ranger fzf bat ripgrep fd xclip scrot \
                     keepassxc firefox chromium tor-browser torbrowser-launcher \
                     vlc mpv gimp inkscape libreoffice-fresh bleachbit timeshift \
                     gparted veracrypt cryptsetup rclone rsync
    
    # Network utilities
    install_packages wget curl traceroute dig whois dnscrypt-proxy openvpn \
                     networkmanager-openvpn networkmanager-vpnc networkmanager-openconnect \
                     networkmanager-l2tp networkmanager-strongswan network-manager-applet
    
    # Enable DNSCrypt proxy for encrypted DNS
    systemctl enable dnscrypt-proxy.service
    
    print_success "Additional utilities installed."
}

# Setup user environment
setup_user_environment() {
    print_info "Setting up user environment..."
    
    # Create scripts directory
    mkdir -p /usr/local/bin/darkarch
    
    # Create a script for quick update of all installed tools
    cat > /usr/local/bin/darkarch/update-tools << 'EOF'
#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*]${NC} Updating Dark Arch system..."

# Update system packages
echo -e "${BLUE}[*]${NC} Updating system packages..."
sudo pacman -Syu --noconfirm

# Update AUR packages
echo -e "${BLUE}[*]${NC} Updating AUR packages..."
yay -Syu --noconfirm

# Update Python packages
echo -e "${BLUE}[*]${NC} Updating Python packages..."
pip install --upgrade pip
pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install --upgrade

# Update Ruby gems
echo -e "${BLUE}[*]${NC} Updating Ruby gems..."
gem update

# Update Metasploit
if command -v msfupdate &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Updating Metasploit Framework..."
    msfupdate
fi

echo -e "${GREEN}[+]${NC} Dark Arch system update completed!"
EOF
    chmod +x /usr/local/bin/darkarch/update-tools
    
    # Create a script for system cleanup
    cat > /usr/local/bin/darkarch/system-cleanup << 'EOF'
#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*]${NC} Cleaning Dark Arch system..."

# Remove package cache
echo -e "${BLUE}[*]${NC} Removing package cache..."
sudo pacman -Scc --noconfirm

# Clean AUR build cache
echo -e "${BLUE}[*]${NC} Cleaning AUR build cache..."
yay -Scc --noconfirm

# Remove orphaned packages
echo -e "${BLUE}[*]${NC} Removing orphaned packages..."
orphaned=$(pacman -Qtdq)
if [ -n "$orphaned" ]; then
    echo "$orphaned" | sudo pacman -Rns - --noconfirm
else
    echo -e "${GREEN}[+]${NC} No orphaned packages found!"
fi

# Clear system logs
echo -e "${BLUE}[*]${NC} Clearing system logs..."
sudo journalctl --vacuum-time=3d

# Clear browser cache
echo -e "${BLUE}[*]${NC} Clearing browser caches..."
rm -rf ~/.cache/mozilla/firefox/*
rm -rf ~/.cache/chromium/*

echo -e "${GREEN}[+]${NC} Dark Arch system cleanup completed!"
EOF
    chmod +x /usr/local/bin/darkarch/system-cleanup
    
    # Create launcher scripts for common tasks
    mkdir -p /usr/local/share/applications
    
    # WiFi scanning script
    cat > /usr/local/bin/darkarch/wifi-scan << 'EOF'
#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[-]${NC} This script must be run as root!"
    exit 1
fi

# List available interfaces
echo -e "${BLUE}[*]${NC} Available wireless interfaces:"
iwconfig 2>/dev/null | grep -o "^[[:alnum:]]*" | grep -v "lo" | grep -v "eth"

# Ask user for interface
read -p "Enter interface name to use: " interface

# Check if interface exists
if ! iwconfig "$interface" &>/dev/null; then
    echo -e "${RED}[-]${NC} Interface $interface does not exist!"
    exit 1
fi

# Put interface in monitor mode
echo -e "${BLUE}[*]${NC} Putting $interface in monitor mode..."
airmon-ng check kill
airmon-ng start "$interface"

monitor_interface="${interface}mon"
if ! iwconfig "$monitor_interface" &>/dev/null; then
    monitor_interface="$interface"
fi

# Scan for networks
echo -e "${GREEN}[+]${NC} Starting scan with $monitor_interface. Press Ctrl+C to stop."
airodump-ng "$monitor_interface"

# Return to managed mode
echo -e "${BLUE}[*]${NC} Returning $interface to managed mode..."
airmon-ng stop "$monitor_interface"
systemctl restart NetworkManager

echo -e "${GREEN}[+]${NC} Scan completed!"
EOF
    chmod +x /usr/local/bin/darkarch/wifi-scan
    
    # Network scanning script
    cat > /usr/local/bin/darkarch/net-scan << 'EOF'
#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*]${NC} Dark Arch Network Scanner"
echo -e "${BLUE}[*]${NC} -----------------------"

# Get current network information
ip_info=$(ip route | grep default)
gateway=$(echo "$ip_info" | grep -oP 'via \K\S+')
interface=$(echo "$ip_info" | grep -oP 'dev \K\S+')
subnet=$(ip -o -f inet addr show | grep "$interface" | awk '{print $4}')

echo -e "${BLUE}[*]${NC} Network information:"
echo -e "  Gateway: $gateway"
echo -e "  Interface: $interface"
echo -e "  Subnet: $subnet"
echo

# Menu
echo "Select scanning option:"
echo "1) Quick scan (common ports)"
echo "2) Full scan (all ports)"
echo "3) Vulnerability scan"
echo "4) Return to terminal"
read -p "Enter option (1-4): " option

case $option in
    1)
        echo -e "${BLUE}[*]${NC} Running quick scan of $subnet..."
        sudo nmap -sV -T4 "$subnet" -oN "~/darkarch_quick_scan_$(date +%F_%H-%M-%S).txt"
        ;;
    2)
        echo -e "${BLUE}[*]${NC} Running full scan of $subnet (this may take a while)..."
        sudo nmap -sV -p- -T4 "$subnet" -oN "~/darkarch_full_scan_$(date +%F_%H-%M-%S).txt"
        ;;
    3)
        echo -e "${BLUE}[*]${NC} Running vulnerability scan of $subnet (this may take a while)..."
        sudo nmap -sV --script vuln "$subnet" -oN "~/darkarch_vuln_scan_$(date +%F_%H-%M-%S).txt"
        ;;
    4)
        echo -e "${BLUE}[*]${NC} Returning to terminal..."
        exit 0
        ;;
    *)
        echo -e "${RED}[-]${NC} Invalid option!"
        exit 1
        ;;
esac

echo -e "${GREEN}[+]${NC} Scan completed! Results saved to ~/"
EOF
    chmod +x /usr/local/bin/darkarch/net-scan
    
    # Create desktop shortcuts
    cat > /usr/local/share/applications/darkarch-wifi-scan.desktop << EOF
[Desktop Entry]
Type=Application
Name=Dark Arch WiFi Scanner
Comment=Scan for wireless networks
Exec=sudo /usr/local/bin/darkarch/wifi-scan
Icon=network-wireless
Terminal=true
Categories=System;Security;
EOF

    cat > /usr/local/share/applications/darkarch-net-scan.desktop << EOF
[Desktop Entry]
Type=Application
Name=Dark Arch Network Scanner
Comment=Scan the local network
Exec=sudo /usr/local/bin/darkarch/net-scan
Icon=network-wired
Terminal=true
Categories=System;Security;
EOF

    cat > /usr/local/share/applications/darkarch-tools-update.desktop << EOF
[Desktop Entry]
Type=Application
Name=Dark Arch Update Tools
Comment=Update all tools and packages
Exec=/usr/local/bin/darkarch/update-tools
Icon=system-software-update
Terminal=true
Categories=System;
EOF

    # Copy desktop files to skeleton directory
    mkdir -p /etc/skel/.local/share/applications
    cp /usr/local/share/applications/darkarch-*.desktop /etc/skel/.local/share/applications/
    
    # Create applications menu directory
    mkdir -p /etc/skel/.config/menus/applications-merged/
    
    # Create DarkArch menu category
    cat > /etc/skel/.config/menus/applications-merged/darkarch.menu << 'EOF'
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
  "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>Dark Arch</Name>
    <Directory>darkarch.directory</Directory>
    <Include>
      <Category>DarkArch</Category>
    </Include>
  </Menu>
</Menu>
EOF

    # Create menu directory file
    mkdir -p /etc/skel/.local/share/desktop-directories
    cat > /etc/skel/.local/share/desktop-directories/darkarch.directory << EOF
[Desktop Entry]
Name=Dark Arch
Comment=Dark Arch Security Tools
Icon=security-high
Type=Directory
EOF
    
    print_success "User environment set up successfully."
}

# Create a menu for various tools
create_tools_menu() {
    print_info "Creating tools menu..."
    
    # Create directory for menu files
    mkdir -p /usr/share/darkarch/icons
    
    # Download Dark Arch logo or create a simple one
    convert -size 128x128 xc:transparent -font DejaVu-Sans-Bold -pointsize 60 -fill black -annotate +10+70 "DA" -fill white -annotate +12+72 "DA" /usr/share/darkarch/icons/darkarch_logo.png || {
        print_warning "Failed to create logo, using default instead."
        cp /usr/share/icons/hicolor/128x128/apps/kali-menu.png /usr/share/darkarch/icons/darkarch_logo.png 2>/dev/null || true
    }
    
    # Create desktop file for menu
    cat > /usr/share/applications/darkarch-menu.desktop << EOF
[Desktop Entry]
Name=Dark Arch Tools
GenericName=Security Tools
Comment=Dark Arch Security Tools Menu
Exec=/usr/local/bin/darkarch-menu
Icon=/usr/share/darkarch/icons/darkarch_logo.png
Terminal=false
Type=Application
Categories=System;Security;
EOF
    
    # Create a simple menu script
    cat > /usr/local/bin/darkarch-menu << 'EOF'
#!/bin/bash

# Use zenity for a graphical menu
export WINDOWID=$(xdotool getactivewindow)

CHOICE=$(zenity --list --title="Dark Arch Tools" --text="Select a category:" --column="Category" \
    "Information Gathering" \
    "Vulnerability Assessment" \
    "Web Application Analysis" \
    "Database Assessment" \
    "Password Attacks" \
    "Wireless Attacks" \
    "Exploitation Tools" \
    "Sniffing & Spoofing" \
    "Post Exploitation" \
    "Forensics" \
    "Reverse Engineering" \
    "System Services" \
    "Utilities" \
    "Update Tools")

if [ -z "$CHOICE" ]; then
    exit 0
fi

case "$CHOICE" in
    "Information Gathering")
        TOOL=$(zenity --list --title="Information Gathering" --text="Select a tool:" --column="Tool" --column="Description" \
            "nmap" "Network scanner" \
            "maltego" "Open source intelligence" \
            "whatweb" "Web scanner" \
            "dig" "DNS lookup" \
            "whois" "Domain information" \
            "gobuster" "Directory scanning" \
            "recon-ng" "Web reconnaissance framework")
        ;;
    "Vulnerability Assessment")
        TOOL=$(zenity --list --title="Vulnerability Assessment" --text="Select a tool:" --column="Tool" --column="Description" \
            "nikto" "Web server scanner" \
            "lynis" "Security auditing" \
            "openvas" "Vulnerability scanner" \
            "nessus" "Vulnerability scanner" \
            "wpscan" "WordPress scanner")
        ;;
    "Web Application Analysis")
        TOOL=$(zenity --list --title="Web Application Analysis" --text="Select a tool:" --column="Tool" --column="Description" \
            "burpsuite" "Web proxy" \
            "zaproxy" "Web proxy" \
            "sqlmap" "SQL injection" \
            "dirb" "Web content scanner" \
            "ffuf" "Web fuzzer")
        ;;
    "Database Assessment")
        TOOL=$(zenity --list --title="Database Assessment" --text="Select a tool:" --column="Tool" --column="Description" \
            "sqlmap" "SQL injection" \
            "sqlninja" "SQL server injection" \
            "jsql" "Java SQL injection")
        ;;
    "Password Attacks")
        TOOL=$(zenity --list --title="Password Attacks" --text="Select a tool:" --column="Tool" --column="Description" \
            "hashcat" "Password cracker" \
            "john" "Password cracker" \
            "hydra" "Login cracker" \
            "crunch" "Wordlist generator" \
            "medusa" "Login brute forcer")
        ;;
    "Wireless Attacks")
        TOOL=$(zenity --list --title="Wireless Attacks" --text="Select a tool:" --column="Tool" --column="Description" \
            "aircrack-ng" "WEP/WPA cracking" \
            "wifite" "Automated wireless auditor" \
            "reaver" "WPS attack tool" \
            "kismet" "Wireless sniffer" \
            "fluxion" "WPA/WPA2 security auditor")
        ;;
    "Exploitation Tools")
        TOOL=$(zenity --list --title="Exploitation Tools" --text="Select a tool:" --column="Tool" --column="Description" \
            "metasploit" "Exploitation framework" \
            "set" "Social Engineering Toolkit" \
            "beef-xss" "Browser exploitation" \
            "commix" "Command injection" \
            "searchsploit" "Exploit database")
        ;;
    "Sniffing & Spoofing")
        TOOL=$(zenity --list --title="Sniffing & Spoofing" --text="Select a tool:" --column="Tool" --column="Description" \
            "wireshark" "Packet analyzer" \
            "tcpdump" "Packet analyzer" \
            "ettercap" "MITM attacks" \
            "responder" "LLMNR/NBT-NS/mDNS poisoner" \
            "dnschef" "DNS proxy")
        ;;
    "Post Exploitation")
        TOOL=$(zenity --list --title="Post Exploitation" --text="Select a tool:" --column="Tool" --column="Description" \
            "empire" "PowerShell post-exploitation" \
            "mimikatz" "Windows credential dumper" \
            "powersploit" "PowerShell exploitation" \
            "shellter" "Dynamic shellcode injector")
        ;;
    "Forensics")
        TOOL=$(zenity --list --title="Forensics" --text="Select a tool:" --column="Tool" --column="Description" \
            "autopsy" "Digital forensics platform" \
            "foremost" "File recovery" \
            "binwalk" "Firmware analysis" \
            "volatility" "Memory forensics" \
            "steghide" "Steganography")
        ;;
    "Reverse Engineering")
        TOOL=$(zenity --list --title="Reverse Engineering" --text="Select a tool:" --column="Tool" --column="Description" \
            "ghidra" "Software reverse engineering" \
            "radare2" "Disassembler" \
            "gdb" "Debugger" \
            "jadx" "Android decompiler")
        ;;
    "System Services")
        TOOL=$(zenity --list --title="System Services" --text="Select a tool:" --column="Tool" --column="Description" \
            "postgresql" "Database service" \
            "apache" "Web server" \
            "ssh" "SSH server" \
            "beef" "Browser Exploitation Framework" \
            "openvpn" "VPN service")
        ;;
    "Utilities")
        TOOL=$(zenity --list --title="Utilities" --text="Select a tool:" --column="Tool" --column="Description" \
            "keepassxc" "Password manager" \
            "veracrypt" "Disk encryption" \
            "bleachbit" "System cleaner" \
            "timeshift" "System backup" \
            "darkarch/update-tools" "Update all tools" \
            "darkarch/system-cleanup" "Clean system")
        ;;
    "Update Tools")
        xterm -e "/usr/local/bin/darkarch/update-tools"
        exit 0
        ;;
esac

if [ -z "$TOOL" ]; then
    exit 0
fi

# Special case for DarkArch scripts
if [[ "$TOOL" == darkarch/* ]]; then
    xterm -e "/usr/local/bin/$TOOL"
    exit 0
fi

# Launch the selected tool
if command -v "$TOOL" &> /dev/null; then
    if [ "$TOOL" = "metasploit" ]; then
        xterm -e "msfconsole"
    elif [ "$TOOL" = "autopsy" ] || [ "$TOOL" = "ghidra" ] || [ "$TOOL" = "maltego" ] || [ "$TOOL" = "burpsuite" ] || [ "$TOOL" = "zaproxy" ] || [ "$TOOL" = "wireshark" ]; then
        "$TOOL" &
    else
        xterm -e "$TOOL"
    fi
else
    zenity --error --text="Tool $TOOL not found or not installed."
fi
EOF
    chmod +x /usr/local/bin/darkarch-menu
    
    # Copy desktop file to skeleton directory
    cp /usr/share/applications/darkarch-menu.desktop /etc/skel/.local/share/applications/
    
    print_success "Tools menu created."
}

# Set up system branding
setup_branding() {
    print_info "Setting up Dark Arch branding..."
    
    # Create issue file
    cat > /etc/issue << 'EOF'
                                                  
   ▓█████▄  ▄▄▄       ██▀███   ██ ▄█▀    ▄▄▄       ██▀███   ▄████▄   ██░ ██ 
   ▒██▀ ██▌▒████▄    ▓██ ▒ ██▒ ██▄█▒    ▒████▄    ▓██ ▒ ██▒▒██▀ ▀█  ▓██░ ██▒
   ░██   █▌▒██  ▀█▄  ▓██ ░▄█ ▒▓███▄░    ▒██  ▀█▄  ▓██ ░▄█ ▒▒▓█    ▄ ▒██▀▀██░
   ░▓█▄   ▌░██▄▄▄▄██ ▒██▀▀█▄  ▓██ █▄    ░██▄▄▄▄██ ▒██▀▀█▄  ▒▓▓▄ ▄██▒░▓█ ░██ 
   ░▒████▓  ▓█   ▓██▒░██▓ ▒██▒▒██▒ █▄    ▓█   ▓██▒░██▓ ▒██▒▒ ▓███▀ ░░▓█▒░██▓
    ▒▒▓  ▒  ▒▒   ▓▒█░░ ▒▓ ░▒▓░▒ ▒▒ ▓▒    ▒▒   ▓▒█░░ ▒▓ ░▒▓░░ ░▒ ▒  ░ ▒ ░░▒░▒
    ░ ▒  ▒   ▒   ▒▒ ░  ░▒ ░ ▒░░ ░▒ ▒░     ▒   ▒▒ ░  ░▒ ░ ▒░  ░  ▒    ▒ ░▒░ ░
    ░ ░  ░   ░   ▒     ░░   ░ ░ ░░ ░      ░   ▒     ░░   ░ ░         ░  ░░ ░
      ░          ░  ░   ░     ░  ░            ░  ░   ░     ░ ░       ░  ░  ░
    ░                                                      ░                 
                                                                             
 \s \r

EOF

    # Set hostname
    echo "darkarch" > /etc/hostname
    
    # Set hosts file
    cat > /etc/hosts << EOF
127.0.0.1   localhost
127.0.1.1   darkarch
::1         localhost
EOF
    
    # Set os-release file
    cat > /etc/os-release << EOF
NAME="Dark Arch"
PRETTY_NAME="Dark Arch"
ID=arch
ID_LIKE=archlinux
BUILD_ID=$(date +%Y%m%d)
HOME_URL="https://archlinux.org/"
DOCUMENTATION_URL="https://wiki.archlinux.org/"
LOGO=/usr/share/darkarch/icons/darkarch_logo.png
EOF
    
    print_success "Branding configured."
}

# Main installation function
main() {
    clear
    
    echo -e "\n${MAGENTA}################################################${NC}"
    echo -e "${MAGENTA}##                                            ##${NC}"
    echo -e "${MAGENTA}##  Dark Arch Installer                       ##${NC}"
    echo -e "${MAGENTA}##  ==============================             ##${NC}"
    echo -e "${MAGENTA}##                                            ##${NC}"
    echo -e "${MAGENTA}##  Kali-like environment for Arch Linux      ##${NC}"
    echo -e "${MAGENTA}##                                            ##${NC}"
    echo -e "${MAGENTA}################################################${NC}\n"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root!"
        exit 1
    fi
    
    # Check for internet connection
    check_internet
    
    # Update system
    update_system
    
    # Install yay
    install_yay
    
    # Install packages
    install_desktop_environment
    install_terminal
    install_theme
    install_kali_tools
    install_dev_tools
    install_utilities
    setup_user_environment
    create_tools_menu
    setup_branding
    
    # Final message
    clear
    echo -e "\n${GREEN}################################################${NC}"
    echo -e "${GREEN}##                                            ##${NC}"
    echo -e "${GREEN}##  Dark Arch Installation Complete!          ##${NC}"
    echo -e "${GREEN}##  ==============================             ##${NC}"
    echo -e "${GREEN}##                                            ##${NC}"
    echo -e "${GREEN}##  Log out and log back in to see changes    ##${NC}"
    echo -e "${GREEN}##  or reboot your system with:               ##${NC}"
    echo -e "${GREEN}##                                            ##${NC}"
    echo -e "${GREEN}##  # systemctl reboot                        ##${NC}"
    echo -e "${GREEN}##                                            ##${NC}"
    echo -e "${GREEN}################################################${NC}\n"
}

# Run the main function
main "$@"


