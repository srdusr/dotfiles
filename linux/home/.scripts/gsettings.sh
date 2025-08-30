#!/bin/bash

# Disable screen lock
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.session idle-delay 0

# Mutter Overlay Key
gsettings set org.gnome.mutter overlay-key ''

# Disable update notification
#gsettings set org.gnome.software download-updates false
#gsettings set com.ubuntu.update-notifier no-show-notifications true
#sudo rm /etc/xdg/autostart/upg-notifier-autostart.desktop

#sudo mv /etc/xdg/autostart/update-notifier.desktop /etc/xdg/autostart/update-notifier.desktop.old
#sudo mv /etc/xdg/autostart/gnome-software-service.desktop /etc/xdg/autostart/gnome-software-service.desktop.old

# Custom Keybinding Names
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

# Custom Keybinding 0
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Alt>T"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "scratchpad"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "scratchpad"

# Disable keyboard plugin
gsettings set org.gnome.settings-daemon.plugins.keyboard active false
