# 🚀 Ubuntu Post-Install Setup

Cada vez que instalo Ubuntu de cero me encuentro con la misma rutina: repositorios, PPAs, ajustes de gsettings, añadir líneas al .zshrc… Así que decidí automatizarlo de una vez.
Esta aplicación presenta una lista de aplicaciones y configuraciones, todas seleccionadas por defecto. El usuario decide qué quitar antes de confirmar.
Aunque me baso en guías de implementación y recomendaciones, se trata de una selección de aplicaciones para mi uso particular, tal vez no sean las adecuadas para tu sistema.

---

## ✨ Características

- **Interfaz gráfica** (GTK3 / GNOME) con lista de apps seleccionables
- **Modo terminal** (CLI) vía `whiptail` para entornos sin escritorio o SSH
- **Detección automática** del entorno: lanza GUI si hay `$DISPLAY` o `$WAYLAND_DISPLAY`, CLI en caso contrario
- Todas las apps vienen **marcadas por defecto**; el usuario decide qué excluir
- Compatible con **X11 y Wayland**
- Output coloreado en terminal con log completo en `/tmp/ubuntu-setup.log`
- Idempotente: no duplica entradas en `.zshrc`

---

## 📦 Apps incluidas

| App | Fuente | Descripción |
|-----|--------|-------------|
| ubuntu-restricted-extras | apt | Codecs multimedia y fuentes Microsoft |
| Flatpak + Flathub | apt | Gestor de paquetes universal |
| GPaste | apt | Historial de portapapeles para GNOME |
| dig / dnsutils | apt | Herramientas de consulta DNS |
| whois | apt | Consulta de información de dominios |
| nmap | apt | Escáner de redes y puertos |
| Python3 + pip + venv | apt | Entorno Python completo |
| GNOME Extensions + Browser Connector | apt | Soporte de extensiones de shell |
| Nemo | PPA linuxmint-daily | Explorador de archivos, reemplaza Nautilus |
| TLP | apt | Optimización de batería para laptops |
| GNOME Tweaks | apt | Personalización avanzada del escritorio |
| Minimizar al clic en dock | gsettings | `dash-to-dock click-action 'minimize'` |
| VLC | apt | Reproductor multimedia |
| Visual Studio Code | Repositorio Microsoft | Editor de código |
| BleachBit | apt | Limpieza y optimización del sistema |
| Zsh | apt + chsh | Shell alternativa (se establece por defecto) |
| Starship + Catppuccin Mocha | curl (starship.rs) | Prompt moderno con tema Powerline |
| fastfetch + lolcat | PPA zhangsongcui3371 | Info del sistema al abrir terminal |

---

## ⚙️ Requisitos

- Ubuntu 22.04 LTS o superior (probado también en 24.04)
- `sudo` / permisos de administrador
- Python 3 con `python3-gi` (se instala automáticamente si falta)
- Conexión a internet

---

## 🛠️ Uso

```bash
# Clonar o descargar el script
git clone https://github.com/usuario/ubuntu-post-install.git
cd ubuntu-post-install

# Dar permisos de ejecución
chmod +x ubuntu-setup.sh

# Ejecutar (modo automático)
sudo bash ubuntu-setup.sh

# Forzar modo terminal (CLI)
sudo bash ubuntu-setup.sh --cli
```

---

## 🖥️ Capturas de pantalla

> *GUI GTK3 — lista de selección con tema Catppuccin Mocha*
> *(añadir capturas aquí)*

---

## 🏗️ Arquitectura

```
ubuntu-setup.sh
├── Funciones de instalación   (una por app)
├── ALL_APPS[]                 (array con id | función | nombre | descripción)
├── run_installations()        (itera sobre selección y llama funciones)
├── run_cli()                  (menú whiptail → run_installations)
└── run_gui()
    ├── ubuntu_setup_gui.py    (escrito en /tmp en tiempo de ejecución)
    │   └── Ventana GTK3       (checklist → escribe selección en fichero temporal)
    └── Lee fichero temporal → run_installations()
```

**Flujo de ejecución (modo GUI):**

1. El script bash verifica permisos root y variables de entorno.
2. Genera el script Python GTK3 en `/tmp/ubuntu_setup_gui.py`.
3. Lanza la GUI **como el usuario real** (`sudo -u $REAL_USER`) con las variables de entorno de sesión necesarias para X11/Wayland.
4. El usuario selecciona apps y confirma; la GUI escribe los IDs en `/tmp/ubuntu_setup_selections` y termina.
5. El script bash lee el fichero, lo elimina y ejecuta `run_installations()` con output en la terminal original.

---

## 🔒 Consideraciones de seguridad

- La GUI corre como el usuario real (no root) para compatibilidad con Wayland y buenas prácticas.
- Los PPAs y repositorios externos usados son:
  - `ppa:linuxmint-daily/main` (Nemo)
  - `ppa:zhangsongcui3371/fastfetch` (fastfetch)
  - `packages.microsoft.com` (VS Code)
  - `starship.rs` (Starship, instalado vía script oficial)
- Se recomienda revisar el contenido del script antes de ejecutarlo con `sudo`.

---

## 🤝 Contribuir

Las contribuciones son bienvenidas. Para añadir una nueva app:

1. Crea una función `install_miapp()` siguiendo el patrón existente.
2. Añade una entrada al array `ALL_APPS` con el formato `"id|función|Nombre|Descripción"`.
3. Abre un PR con una breve descripción del caso de uso.

---

