import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import { find_icon } from "./iconUtils.js";
import { lookUpIcon, timeout } from 'resource:///com/github/Aylur/ags/utils.js';


export let clientMapWorkSpace = {};

export function substitute(str) {
  const subs = [
    { from: "code-url-handler", to: "visual-studio-code" },
    { from: "Code", to: "visual-studio-code" },
    { from: "GitHub Desktop", to: "github-desktop" },
    { from: "wpsoffice", to: "wps-office2019-kprometheus" },
    { from: "gnome-tweaks", to: "org.gnome.tweaks" },
    { from: "Minecraft* 1.20.1", to: "minecraft" },
    { from: "", to: "image-missing" },
  ];

  for (const { from, to } of subs) {
    if (from === str) {
      return to;
    }
  }

  return str;
}

function titleToClient(title, className) {
  const subs = [
    { from: "musicfox", to: "musicfox" },
  ];

  for (const { from, to } of subs) {
    if (title.indexOf(from) !== -1) {
      return to;
    }
  }

  return className
}

export const getClientByAdrees = function(address) {

  const clients = Hyprland.clients

  const client = clients.find(item => {
    return item.address === address
  })

  return client
}

//Fullscreen client
export const getFullScreenClientAddress = function(workspace_id) {

  const clients = Hyprland.clients
  const client = clients.find(item => {
    return item.fullscreen && item.workspace.id === workspace_id
  })
  return client
}

export const ignoreAppsClass = [
  'image-missing',
  'fcitx',
  'rofi'
]

export const getClientIcon = (clientClass, title = "") => {

  clientClass.toLowerCase()
  clientClass = clientClass.replace(" ", "_");


  if (title.length > 0) {
    clientClass = titleToClient(title, clientClass)
  }

  const awesome_icon = find_icon(clientClass)
  if (awesome_icon) {
    return awesome_icon
  }

  if (lookUpIcon(clientClass)) {
    return clientClass
  }

  if (find_icon('system')) {
    return find_icon('system')
  }

  return ""
}


export const focus = (client) => {
  //client
  const { address } = client;
  const liveClient = getClientByAdrees(address);

  //special window
  if (liveClient.workspace.id < 0) {
    const oldWorkSpace = clientMapWorkSpace[address];
    if (oldWorkSpace) {
      Utils.exec(
        `hyprctl dispatch movetoworkspace ${oldWorkSpace},address:${address}`,
      );
      Utils.exec(`hyprctl dispatch workspace ${oldWorkSpace}`);
    }
  }

  //fullscreen
  if (liveClient.fullscreen) {
    Utils.exec("hyprctl dispatch focuswindow address:" + address);
    return;
  }

  //workspace fullscreen client
  const currentFullScreenAddress = getFullScreenClientAddress(
    liveClient.workspace.id,
  );
  if (currentFullScreenAddress) {
    const fullScreenAdress = currentFullScreenAddress.address;
    Utils.exec("hyprctl dispatch focuswindow address:" + fullScreenAdress);
    Utils.exec("hyprctl dispatch fullscreen 1");
  }

  Utils.exec("hyprctl dispatch focuswindow address:" + address);
  // Utils.exec('hyprctl dispatch cyclenext')
  Utils.exec("hyprctl dispatch alterzorder top,address:" + address);
  if (currentFullScreenAddress) {
    Utils.exec("hyprctl dispatch fullscreen 1");
  }
};
