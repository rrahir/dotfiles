#!/bin/sh
# -*- sh -*-

TMP_DISPLAY="$DISPLAY"
set -ou pipefail
echo "Installing local dots ..."

INSTALL_VERSION="0.1"
#defaults
skip=0
code=
tilix=
tilix_cmd=
uuid=
fzf=
# Packages Lists
APT_PACKS="git,tig,python3,python3-pip,vim" # unused

for opt in "$@"; do
    case $opt in
    --all)
        tilix=1
        tilix_cmd=1
        code=1
        fzf=1
        ;;
    --skip)
        skip=1
        ;;
    --gui)
        code=1
        tilix=1
        ;;
    --nogui)
        tilix=0
        tilix_cmd=0
        code=0
        ;;
    --no-fzf)
        fzf=0
        ;;
    *)
      echo "Exiting without any action"
    #   exit 1
      ;;
    esac
done

ask() { # taken from github.com/junegunn/fzf/install#L71-L81 -- on 13/11/2020
    while true; do
        read -p "$1 ([y]/n) " -r
    REPLY=${REPLY:-"y"}
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      return 1
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      return 0
    fi
  done
}
if [ -z "$code" ]; then
    ask "Do you want to install VS Code?"
    code=$?
fi
if [ -z "$tilix" ]; then
    ask "Do you want to install tilix?"
    tilix=$?
fi

if [[ ($tilix != "0" || $code != "0") &&  -z "$TMP_DISPLAY" ]]; then
    ask "You do not seem to be running DE-free session. Are you sure you want to install VS Code or Tilix?"
    keep_gui=$?
    if [ $keep_gui != "0" ]; then
        echo "Pursuing with installation of graphical programs."
    else
        tilix=0
        tilix_cmd=0
        code=0
        echo "Pursuing without graphical programs"
    fi
fi

if [ $skip = 0 ]; then
    echo "Udating packages"
    sudo apt -y update
    sudo apt -y upgrade
fi

# execute package installs
sudo apt install -y \
    git \
    tig \
    python3 \
    python3-pip \
    vim || (echo "An error occured while fetching the packages. Try runnnig ./install.sh --skip=0"  && exit 0)


# install FZF
if [[ ! -z "$fzf" && "$fzf" != "0" ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

if [ $code != "0" ]; then
    sudo apt install -y snap
    sudo snap install -y code
    code --install-extension ms-python.python
    code --install-extension ms-vsliveshare.vsliveshare
fi

if [ $tilix != "0" ]; then
    sudo apt install -y tilix
    if [ -z $tilix_cmd ]; then
        ask "Do you want a predefined configuration?"
        tilix_cmd=$?
        if [ $tilix_cmd != "0" ]; then
            uuid=$(uuidgen)
            cat .config/tilix_profile | dconf load /com/gexperts/Tilix/profiles/$uuid/
            [ ! -d "~/.config" ] && mkdir -p "~/.config"
            sed  "s/tilix_profile/$uuid/g" tilix-session.json > ~/.config/tilix-session.json
            printf "\n#### tilix ####\nalias tilix=\"tilix -s ~/.config/tilix-session.json\"" >> ./bashrc.ext
            echo "Tilix added with a predefined user profile"
        fi
    fi
    echo "You can now use the alias tilix to start it with a predefined user profile located at ~/.config/tilix-session.json"
fi


HEADER="# This section is inserted by rrahir install SH version $INSTALL_VERSION"
UPTODATE=$(grep -E "^$HEADER$" ~/.bashrc)
if [[ ! $UPTODATE ]]; then
    printf "\n\n$HEADER\n# github.com/rrahir/dotfiles/basic/install.sh\n" >> ~/.bashrc
    cat ./bashrc.ext >> ~/.bashrc
else
    echo "Skipping bashrc profile: Already at latest version"
fi
