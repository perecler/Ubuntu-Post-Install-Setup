# Ubuntu-Post-Install-Setup
Script de post-instalación para Ubuntu que permite seleccionar e instalar un conjunto de aplicaciones y configuraciones de forma automatizada, con interfaz gráfica GTK3 y modo terminal (CLI).

✨ Características

Interfaz gráfica (GTK3 / GNOME) con lista de apps seleccionables
Modo terminal (CLI) vía whiptail para entornos sin escritorio o SSH
Detección automática del entorno: lanza GUI si hay $DISPLAY o $WAYLAND_DISPLAY, CLI en caso contrario
Todas las apps vienen marcadas por defecto; el usuario decide qué excluir
Compatible con X11 y Wayland
Output coloreado en terminal con log completo en /tmp/ubuntu-setup.log
Idempotente: no duplica entradas en .zshrc


📦 Apps incluidas
AppFuenteDescripciónubuntu-restricted-extrasaptCodecs multimedia y fuentes MicrosoftFlatpak + FlathubaptGestor de paquetes universalGPasteaptHistorial de portapapeles para GNOMEdig / dnsutilsaptHerramientas de consulta DNSwhoisaptConsulta de información de dominiosnmapaptEscáner de redes y puertosPython3 + pip + venvaptEntorno Python completoGNOME Extensions + Browser ConnectoraptSoporte de extensiones de shellNemoPPA linuxmint-dailyExplorador de archivos, reemplaza NautilusTLPaptOptimización de batería para laptopsGNOME TweaksaptPersonalización avanzada del escritorioMinimizar al clic en dockgsettingsdash-to-dock click-action 'minimize'VLCaptReproductor multimediaVisual Studio CodeRepositorio MicrosoftEditor de códigoBleachBitaptLimpieza y optimización del sistemaZshapt + chshShell alternativa (se establece por defecto)Starship + Catppuccin Mochacurl (starship.rs)Prompt moderno con tema Powerlinefastfetch + lolcatPPA zhangsongcui3371Info del sistema al abrir terminal

⚙️ Requisitos

Ubuntu 22.04 LTS o superior (probado también en 24.04)
sudo / permisos de administrador
Python 3 con python3-gi (se instala automáticamente si falta)
Conexión a internet


🛠️ Uso
bash# Clonar o descargar el script
git clone https://github.com/usuario/ubuntu-post-install.git
cd ubuntu-post-install

# Dar permisos de ejecución
chmod +x ubuntu-setup.sh

# Ejecutar (modo automático)
sudo bash ubuntu-setup.sh

# Forzar modo terminal (CLI)
sudo bash ubuntu-setup.sh --cli

🖥️ Capturas de pantalla

GUI GTK3 — lista de selección con tema Catppuccin Mocha
(añadir capturas aquí)


🏗️ Arquitectura
ubuntu-setup.sh
├── Funciones de instalación   (una por app)
├── ALL_APPS[]                 (array con id | función | nombre | descripción)
├── run_installations()        (itera sobre selección y llama funciones)
├── run_cli()                  (menú whiptail → run_installations)
└── run_gui()
    ├── ubuntu_setup_gui.py    (escrito en /tmp en tiempo de ejecución)
    │   └── Ventana GTK3       (checklist → escribe selección en fichero temporal)
    └── Lee fichero temporal → run_installations()
Flujo de ejecución (modo GUI):

El script bash verifica permisos root y variables de entorno.
Genera el script Python GTK3 en /tmp/ubuntu_setup_gui.py.
Lanza la GUI como el usuario real (sudo -u $REAL_USER) con las variables de entorno de sesión necesarias para X11/Wayland.
El usuario selecciona apps y confirma; la GUI escribe los IDs en /tmp/ubuntu_setup_selections y termina.
El script bash lee el fichero, lo elimina y ejecuta run_installations() con output en la terminal original.


🔒 Consideraciones de seguridad

La GUI corre como el usuario real (no root) para compatibilidad con Wayland y buenas prácticas.
Los PPAs y repositorios externos usados son:

ppa:linuxmint-daily/main (Nemo)
ppa:zhangsongcui3371/fastfetch (fastfetch)
packages.microsoft.com (VS Code)
starship.rs (Starship, instalado vía script oficial)


Se recomienda revisar el contenido del script antes de ejecutarlo con sudo.


🤝 Contribuir
Las contribuciones son bienvenidas. Para añadir una nueva app:

Crea una función install_miapp() siguiendo el patrón existente.
Añade una entrada al array ALL_APPS con el formato "id|función|Nombre|Descripción".
Abre un PR con una breve descripción del caso de uso.
