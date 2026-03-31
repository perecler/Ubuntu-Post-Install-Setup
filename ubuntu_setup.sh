#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
#  🚀  Ubuntu Post-Install Setup
#  Uso:  sudo bash ubuntu-setup.sh          → GUI automático
#        sudo bash ubuntu-setup.sh --cli    → modo terminal
# ╚══════════════════════════════════════════════════════════╝

# ── Verificar permisos root ────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "❌  Este script necesita permisos de superusuario."
    echo "    Ejecuta: sudo bash $0 $*"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER")
SELECTIONS_FILE="/tmp/ubuntu_setup_selections"
LOG_FILE="/tmp/ubuntu-setup.log"

# ── Colores ────────────────────────────────────────────────
G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'
R='\033[0;31m'; W='\033[1m';    N='\033[0m'

# ══════════════════════════════════════════════════════════
#  FUNCIONES DE INSTALACIÓN
# ══════════════════════════════════════════════════════════

log() { echo -e "${C}▶${N}  $1" | tee -a "$LOG_FILE"; }
ok()  { echo -e "${G}✔${N}  $1" | tee -a "$LOG_FILE"; }
err() { echo -e "${R}✘${N}  $1" | tee -a "$LOG_FILE"; }
sep() { echo -e "${W}──────────────────────────────────────${N}" | tee -a "$LOG_FILE"; }

apt_q() { DEBIAN_FRONTEND=noninteractive apt install -y "$@" >> "$LOG_FILE" 2>&1; }

gsettings_user() {
    sudo -u "$REAL_USER" \
        XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" \
        gsettings "$@" >> "$LOG_FILE" 2>&1
}

ensure_zshrc() {
    [[ ! -f "$REAL_HOME/.zshrc" ]] && sudo -u "$REAL_USER" touch "$REAL_HOME/.zshrc"
}

install_restricted_extras() {
    sep; log "ubuntu-restricted-extras..."
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
        | debconf-set-selections
    apt_q ubuntu-restricted-extras && ok "ubuntu-restricted-extras instalado"
}

install_flatpak() {
    sep; log "Flatpak + Flathub..."
    apt_q flatpak gnome-software-plugin-flatpak
    sudo -u "$REAL_USER" flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo >> "$LOG_FILE" 2>&1
    ok "Flatpak + Flathub configurado"
}

install_gpaste() {
    sep; log "GPaste (historial de portapapeles)..."
    apt_q gpaste gnome-shell-extension-gpaste && ok "GPaste instalado"
}

install_dig() {
    sep; log "dnsutils (dig)..."
    apt_q dnsutils && ok "dig instalado"
}

install_whois() {
    sep; log "whois..."
    apt_q whois && ok "whois instalado"
}

install_nmap() {
    sep; log "nmap..."
    apt_q nmap && ok "nmap instalado"
}

install_python() {
    sep; log "Python3 + pip + venv..."
    apt_q python3 python3-pip python3-venv && ok "Python3 instalado"
}

install_gnome_ext() {
    sep; log "GNOME Extensions + Browser Connector..."
    apt_q gnome-shell-extensions gnome-browser-connector && ok "GNOME Extensions instalado"
}

install_nemo() {
    sep; log "Nemo (explorador de archivos)..."
    add-apt-repository -y ppa:linuxmint-daily/main >> "$LOG_FILE" 2>&1
    apt update -qq >> "$LOG_FILE" 2>&1
    apt_q nemo nemo-fileroller
    sudo -u "$REAL_USER" xdg-mime default nemo.desktop \
        inode/directory application/x-gnome-saved-search >> "$LOG_FILE" 2>&1
    gsettings_user set org.gnome.desktop.background show-desktop-icons false
    gsettings_user set org.nemo.desktop show-desktop-icons true
    ok "Nemo instalado y configurado como explorador por defecto"
}

install_tlp() {
    sep; log "TLP (optimización de batería)..."
    apt_q tlp tlp-rdw
    systemctl enable tlp >> "$LOG_FILE" 2>&1
    ok "TLP instalado y habilitado"
}

install_gnome_tweaks() {
    sep; log "GNOME Tweaks..."
    apt_q gnome-tweaks && ok "GNOME Tweaks instalado"
}

install_minimize() {
    sep; log "Configurando minimizar al clic en dock..."
    gsettings_user set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
    ok "Minimizar al clic configurado"
}

install_vlc() {
    sep; log "VLC..."
    apt_q vlc && ok "VLC instalado"
}

install_vscode() {
    sep; log "Visual Studio Code..."
    wget -qO /tmp/microsoft.asc https://packages.microsoft.com/keys/microsoft.asc
    gpg --dearmor < /tmp/microsoft.asc > /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
        > /etc/apt/sources.list.d/vscode.list
    apt update -qq >> "$LOG_FILE" 2>&1
    apt_q code && ok "Visual Studio Code instalado"
}

install_bleachbit() {
    sep; log "BleachBit..."
    apt_q bleachbit && ok "BleachBit instalado"
}

install_zsh() {
    sep; log "Zsh..."
    apt_q zsh
    chsh -s "$(which zsh)" "$REAL_USER" >> "$LOG_FILE" 2>&1
    ensure_zshrc
    ok "Zsh instalado y establecido como shell por defecto"
}

install_starship() {
    sep; log "Starship + tema Catppuccin Mocha Powerline..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y >> "$LOG_FILE" 2>&1
    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config"
    sudo -u "$REAL_USER" starship preset catppuccin-powerline \
        -o "$REAL_HOME/.config/starship.toml" >> "$LOG_FILE" 2>&1
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/starship.toml"
    ensure_zshrc
    grep -qF 'starship init zsh' "$REAL_HOME/.zshrc" || \
        echo 'eval "$(starship init zsh)"' >> "$REAL_HOME/.zshrc"
    ok "Starship + Catppuccin Mocha Powerline instalado"
}

install_fastfetch() {
    sep; log "fastfetch + lolcat..."
    add-apt-repository -y ppa:zhangsongcui3371/fastfetch >> "$LOG_FILE" 2>&1
    apt update -qq >> "$LOG_FILE" 2>&1
    apt_q fastfetch lolcat
    ensure_zshrc
    grep -qF 'fastfetch' "$REAL_HOME/.zshrc" || \
        echo 'fastfetch | lolcat' >> "$REAL_HOME/.zshrc"
    ok "fastfetch + lolcat instalado y añadido a ~/.zshrc"
}

# ══════════════════════════════════════════════════════════
#  DEFINICIÓN DE APPS
#  Formato: "id|función|Nombre|Descripción"
# ══════════════════════════════════════════════════════════

ALL_APPS=(
    "restricted_extras|install_restricted_extras|ubuntu-restricted-extras|Codecs multimedia y fuentes Microsoft"
    "flatpak|install_flatpak|Flatpak + Flathub|Gestor de paquetes universal"
    "gpaste|install_gpaste|GPaste|Historial de portapapeles para GNOME"
    "dig|install_dig|dig / dnsutils|Herramientas de consulta DNS"
    "whois|install_whois|whois|Información de dominios y direcciones IP"
    "nmap|install_nmap|nmap|Escáner de redes y puertos"
    "python|install_python|Python3 + pip + venv|Entorno Python completo"
    "gnome_ext|install_gnome_ext|GNOME Extensions|Extensiones de shell + conector navegador"
    "nemo|install_nemo|Nemo|Explorador de archivos, reemplaza Nautilus"
    "tlp|install_tlp|TLP|Optimización de batería para laptops"
    "gnome_tweaks|install_gnome_tweaks|GNOME Tweaks|Personalización avanzada del escritorio"
    "minimize|install_minimize|Minimizar al clic en dock|Configura dash-to-dock click-action"
    "vlc|install_vlc|VLC Media Player|Reproductor multimedia universal"
    "vscode|install_vscode|Visual Studio Code|Editor de código – repositorio Microsoft"
    "bleachbit|install_bleachbit|BleachBit|Limpieza y optimización del sistema"
    "zsh|install_zsh|Zsh|Shell alternativa, se establece por defecto"
    "starship|install_starship|Starship Catppuccin Mocha|Prompt moderno con tema Powerline"
    "fastfetch|install_fastfetch|fastfetch + lolcat|Info del sistema al abrir terminal"
)

# ══════════════════════════════════════════════════════════
#  EJECUTAR INSTALACIONES
# ══════════════════════════════════════════════════════════

run_installations() {
    local selected="$1"
    : > "$LOG_FILE"

    echo -e "\n${W}╔══════════════════════════════════════╗${N}"
    echo -e "${W}║   🚀 Ubuntu Post-Install Setup       ║${N}"
    echo -e "${W}╚══════════════════════════════════════╝${N}\n"

    log "Actualizando repositorios..."
    apt update -qq >> "$LOG_FILE" 2>&1
    echo ""

    local installed=0 errors=0
    for entry in "${ALL_APPS[@]}"; do
        IFS='|' read -r id func name desc <<< "$entry"
        if echo " $selected " | grep -qw "$id"; then
            if $func; then
                (( installed++ ))
            else
                err "Error al instalar: $name"
                (( errors++ ))
            fi
            echo ""
        fi
    done

    echo -e "\n${W}╔══════════════════════════════════════╗${N}"
    if [[ $errors -eq 0 ]]; then
        echo -e "${W}║  ${G}✅  Instalación completada sin errores${W}  ║${N}"
    else
        echo -e "${W}║  ${Y}⚠   Completado con $errors error(es)${W}          ║${N}"
    fi
    echo -e "${W}╚══════════════════════════════════════╝${N}\n"
    echo -e "  ${C}$installed${N} apps instaladas · Log: ${C}$LOG_FILE${N}\n"
}

# ══════════════════════════════════════════════════════════
#  MODO CLI  (whiptail)
# ══════════════════════════════════════════════════════════

run_cli() {
    command -v whiptail &>/dev/null || apt_q whiptail

    local items=()
    for entry in "${ALL_APPS[@]}"; do
        IFS='|' read -r id func name desc <<< "$entry"
        items+=("$id" "$name  –  $desc" "ON")
    done

    local selected
    selected=$(whiptail \
        --title "🚀 Ubuntu Post-Install Setup" \
        --checklist "\nSelecciona las aplicaciones a instalar:\n[Espacio] marcar/desmarcar   [Tab] OK/Cancelar\n" \
        30 82 18 "${items[@]}" 3>&1 1>&2 2>&3) || { echo -e "\n${Y}Cancelado.${N}"; exit 0; }

    selected=$(echo "$selected" | tr -d '"')
    [[ -z "$selected" ]] && echo -e "\n${Y}No se seleccionó ninguna app.${N}" && exit 0

    echo -e "\n${W}Se instalarán las siguientes apps:${N}"
    for id in $selected; do
        for entry in "${ALL_APPS[@]}"; do
            IFS='|' read -r aid _ aname _ <<< "$entry"
            [[ "$aid" == "$id" ]] && echo -e "  ${G}•${N} $aname"
        done
    done
    echo ""
    read -rp "¿Continuar? [s/N] " confirm
    [[ "${confirm,,}" != "s" ]] && echo -e "${Y}Cancelado.${N}" && exit 0

    run_installations "$selected"
}

# ══════════════════════════════════════════════════════════
#  MODO GUI  (Python GTK3)
# ══════════════════════════════════════════════════════════

run_gui() {
    # Asegurar dependencias GTK
    python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk" \
        2>/dev/null || apt_q python3-gi python3-gi-cairo gir1.2-gtk-3.0 >> "$LOG_FILE" 2>&1

    local py_script="/tmp/ubuntu_setup_gui.py"
    rm -f "$SELECTIONS_FILE"

    # ── Escribir script Python ──────────────────────────
    cat > "$py_script" << 'PYEOF'
#!/usr/bin/env python3
import gi, sys, os
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

SELECTIONS_FILE = sys.argv[1]

APPS = [
    ("restricted_extras", "ubuntu-restricted-extras",  "Codecs multimedia y fuentes Microsoft"),
    ("flatpak",           "Flatpak + Flathub",          "Gestor de paquetes universal"),
    ("gpaste",            "GPaste",                     "Historial de portapapeles GNOME"),
    ("dig",               "dig / dnsutils",             "Herramientas de consulta DNS"),
    ("whois",             "whois",                      "Información de dominios y IPs"),
    ("nmap",              "nmap",                       "Escáner de redes y puertos"),
    ("python",            "Python3 + pip + venv",       "Entorno Python completo"),
    ("gnome_ext",         "GNOME Extensions",           "Extensiones de shell + conector navegador"),
    ("nemo",              "Nemo",                       "Explorador de archivos, reemplaza Nautilus"),
    ("tlp",               "TLP",                        "Optimización de batería para laptops"),
    ("gnome_tweaks",      "GNOME Tweaks",               "Personalización avanzada del escritorio"),
    ("minimize",          "Minimizar al clic en dock",  "Configura comportamiento del dock"),
    ("vlc",               "VLC Media Player",           "Reproductor multimedia universal"),
    ("vscode",            "Visual Studio Code",         "Editor de código – repositorio Microsoft"),
    ("bleachbit",         "BleachBit",                  "Limpieza y optimización del sistema"),
    ("zsh",               "Zsh",                        "Shell alternativa, se establece por defecto"),
    ("starship",          "Starship Catppuccin Mocha",  "Prompt moderno con tema Powerline"),
    ("fastfetch",         "fastfetch + lolcat",         "Info del sistema al abrir terminal"),
]

CSS = b"""
* { font-family: "Ubuntu", "Cantarell", sans-serif; }
window { background-color: #1e1e2e; }
.titlebar { background-color: #181825; padding: 22px 24px 14px; }
.app-title { color: #cba6f7; font-size: 20px; font-weight: bold; }
.app-subtitle { color: #585b70; font-size: 12px; margin-top: 6px; }
.toolbar { background-color: #1e1e2e; padding: 8px 18px;
           border-bottom: 1px solid #2a2a3c; }
.sel-label { color: #6c7086; font-size: 12px; }
.sel-btn { background: #313244; color: #cdd6f4; border: none;
           border-radius: 5px; padding: 4px 12px; font-size: 11px; }
.sel-btn:hover { background: #45475a; }
listbox { background-color: #1e1e2e; }
row { background-color: #1e1e2e; border-bottom: 1px solid #262637; }
row:hover { background-color: #25253a; }
.app-name { color: #cdd6f4; font-size: 13px; font-weight: bold; }
.app-desc { color: #585b70; font-size: 11px; margin-top: 2px; }
.bottombar { background-color: #181825; padding: 14px 20px;
             border-top: 1px solid #2a2a3c; }
.count-label { color: #6c7086; font-size: 12px; }
.btn-install { background: #cba6f7; color: #1e1e2e; font-weight: bold;
               font-size: 13px; border: none; border-radius: 8px;
               padding: 10px 28px; }
.btn-install:hover { background: #b4befe; }
.btn-install:disabled { background: #45475a; color: #6c7086; }
.btn-cancel { background: transparent; color: #6c7086; font-size: 12px;
              border: 1px solid #45475a; border-radius: 8px; padding: 10px 20px; }
.btn-cancel:hover { background: #313244; color: #cdd6f4; }
"""

class SetupApp(Gtk.Window):
    def __init__(self):
        super().__init__(title="Ubuntu Post-Install Setup")
        self.set_default_size(620, 660)
        self.set_border_width(0)
        self.set_resizable(True)

        p = Gtk.CssProvider()
        p.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), p,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.checks = {}
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(root)

        # ── Barra de título
        tb = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        tb.get_style_context().add_class("titlebar")
        t1 = Gtk.Label(label="🚀  Ubuntu Post-Install Setup")
        t1.get_style_context().add_class("app-title")
        t1.set_halign(Gtk.Align.START)
        t2 = Gtk.Label(label="Selecciona las aplicaciones a instalar. Todas marcadas por defecto.")
        t2.get_style_context().add_class("app-subtitle")
        t2.set_halign(Gtk.Align.START)
        tb.pack_start(t1, False, False, 0)
        tb.pack_start(t2, False, False, 0)
        root.pack_start(tb, False, False, 0)

        # ── Barra de selección rápida
        bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        bar.get_style_context().add_class("toolbar")
        lbl = Gtk.Label(label="Selección rápida:")
        lbl.get_style_context().add_class("sel-label")
        ba = Gtk.Button(label="✓  Todas")
        ba.get_style_context().add_class("sel-btn")
        ba.connect("clicked", lambda _: self.sel_all(True))
        bn = Gtk.Button(label="✕  Ninguna")
        bn.get_style_context().add_class("sel-btn")
        bn.connect("clicked", lambda _: self.sel_all(False))
        bar.pack_start(lbl, False, False, 0)
        bar.pack_start(ba, False, False, 0)
        bar.pack_start(bn, False, False, 0)
        root.pack_start(bar, False, False, 0)

        # ── Lista de apps
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_vexpand(True)
        listbox = Gtk.ListBox()
        listbox.set_selection_mode(Gtk.SelectionMode.NONE)

        for aid, aname, adesc in APPS:
            row = Gtk.ListBoxRow()
            hb = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
            hb.set_margin_start(18); hb.set_margin_end(18)
            hb.set_margin_top(9);    hb.set_margin_bottom(9)

            chk = Gtk.CheckButton()
            chk.set_active(True)
            chk.connect("toggled", self.update_count)
            self.checks[aid] = chk

            vb = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            ln = Gtk.Label(label=aname)
            ln.get_style_context().add_class("app-name")
            ln.set_halign(Gtk.Align.START)
            ld = Gtk.Label(label=adesc)
            ld.get_style_context().add_class("app-desc")
            ld.set_halign(Gtk.Align.START)
            vb.pack_start(ln, False, False, 0)
            vb.pack_start(ld, False, False, 0)

            hb.pack_start(chk, False, False, 0)
            hb.pack_start(vb, True, True, 0)
            row.add(hb)

            # Clic en la fila → toggle checkbox
            row.connect("activate", lambda r, c=chk: c.set_active(not c.get_active()))
            listbox.add(row)

        scroll.add(listbox)
        root.pack_start(scroll, True, True, 0)

        # ── Barra inferior
        bb = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        bb.get_style_context().add_class("bottombar")

        self.lbl_count = Gtk.Label()
        self.lbl_count.get_style_context().add_class("count-label")

        self.btn_cancel = Gtk.Button(label="Cancelar")
        self.btn_cancel.get_style_context().add_class("btn-cancel")
        self.btn_cancel.connect("clicked", lambda _: Gtk.main_quit())

        self.btn_ok = Gtk.Button(label="⬇   Instalar seleccionados")
        self.btn_ok.get_style_context().add_class("btn-install")
        self.btn_ok.connect("clicked", self.on_install)

        bb.pack_start(self.lbl_count, False, False, 0)
        bb.pack_end(self.btn_ok, False, False, 0)
        bb.pack_end(self.btn_cancel, False, False, 0)
        root.pack_end(bb, False, False, 0)

        self.update_count()

    def sel_all(self, v):
        for c in self.checks.values():
            c.set_active(v)

    def update_count(self, *_):
        n = sum(1 for c in self.checks.values() if c.get_active())
        s = "s" if n != 1 else ""
        self.lbl_count.set_text(f"{n} app{s} seleccionada{s}")
        self.btn_ok.set_sensitive(n > 0)

    def on_install(self, _):
        sel = [aid for aid, c in self.checks.items() if c.get_active()]
        if not sel:
            return

        # Diálogo de confirmación
        dlg = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.OK_CANCEL,
            text=f"Se instalarán {len(sel)} aplicaciones"
        )
        dlg.format_secondary_text(
            "La instalación se realizará en la terminal donde ejecutaste el script.\n"
            "Esta ventana se cerrará al confirmar."
        )
        resp = dlg.run()
        dlg.destroy()

        if resp == Gtk.ResponseType.OK:
            with open(SELECTIONS_FILE, "w") as f:
                f.write(" ".join(sel))
            Gtk.main_quit()

win = SetupApp()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
PYEOF

    # ── Lanzar GUI como usuario real ────────────────────
    sudo -u "$REAL_USER" \
        DISPLAY="${DISPLAY:-:0}" \
        WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
        XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" \
        XAUTHORITY="${XAUTHORITY:-$REAL_HOME/.Xauthority}" \
        python3 "$py_script" "$SELECTIONS_FILE"

    # ── Leer selección y proceder ────────────────────────
    if [[ -f "$SELECTIONS_FILE" ]]; then
        local selected
        selected=$(cat "$SELECTIONS_FILE")
        rm -f "$SELECTIONS_FILE"
        [[ -n "$selected" ]] && run_installations "$selected"
    else
        echo -e "\n${Y}Instalación cancelada.${N}\n"
    fi
}

# ══════════════════════════════════════════════════════════
#  PUNTO DE ENTRADA
# ══════════════════════════════════════════════════════════

case "${1:-}" in
    --cli)
        run_cli
        ;;
    *)
        if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
            run_gui
        else
            echo -e "${Y}Sin entorno gráfico → modo CLI.${N}"
            run_cli
        fi
        ;;
esac
