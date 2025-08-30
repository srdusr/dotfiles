import { opt, mkOptions } from 'lib/option';
import { distro } from 'lib/variables';
import { icon } from 'lib/utils';
import { icons } from 'assets';
import icons from 'lib/icons';
//import Dock from "./widgets/dock/index.js";

const options = mkOptions(OPTIONS, {
  autotheme: opt(false),

  wallpaper: {
    enable: opt(false),
    resolution: opt<import('service/wallpaper').Resolution>(1920),
    market: opt<import('service/wallpaper').Market>('random'),
  },

  theme: {
    dark: {
      primary: {
        bg: opt('#51a4e7'),
        fg: opt('#141414'),
      },
      error: {
        bg: opt('#e55f86'),
        fg: opt('#141414'),
      },
      bg: opt('#171717'),
      fg: opt('#eeeeee'),
      widget: opt('#eeeeee'),
      border: opt('#eeeeee'),
    },
    light: {
      primary: {
        bg: opt('#426ede'),
        fg: opt('#eeeeee'),
      },
      error: {
        bg: opt('#b13558'),
        fg: opt('#eeeeee'),
      },
      bg: opt('#fffffa'),
      fg: opt('#080808'),
      widget: opt('#080808'),
      border: opt('#080808'),
    },

    blur: opt(0),
    scheme: opt<'dark' | 'light'>('dark'),
    widget: { opacity: opt(94) },
    border: {
      width: opt(1),
      opacity: opt(100),
    },

    shadows: opt(true),
    padding: opt(7),
    spacing: opt(12),
    radius: opt(11),
  },

  transition: opt(200),

  font: {
    size: opt(13),
    name: opt('Ubuntu Nerd Font'),
  },
  bar: {
    flatButtons: opt(true),
    position: opt<'top' | 'bottom'>('top'),
    corners: opt(false),
    layout: {
      start: opt<Array<import('widget/bar/Bar').BarWidget>>([
        'launcher',
        'workspaces',
        //"taskbar",
        'expander',
        'messages',
      ]),
      center: opt<Array<import('widget/bar/Bar').BarWidget>>(['date']),
      end: opt<Array<import('widget/bar/Bar').BarWidget>>([
        'media',
        'expander',
        //"colorpicker",
        'screenrecord',
        'battery',
        'systray',
        'system',
        'powermenu',
      ]),
    },
    launcher: {
      icon: {
        colored: opt(true),
        icon: opt(icon(distro.logo, icons.ui.search)),
      },
      label: {
        colored: opt(false),
        label: opt(''),
        //label: opt(" Applications"),
      },
      action: opt(() => App.toggleWindow('launcher')),
    },
    date: {
      format: opt('%a  %d %b %Y  %H:%M:%S'),
      action: opt(() => App.toggleWindow('datemenu')),
    },
    battery: {
      bar: opt<'hidden' | 'regular' | 'whole'>('regular'),
      charging: opt('#00D787'),
      percentage: opt(true),
      blocks: opt(7),
      width: opt(50),
      low: opt(30),
    },
    workspaces: {
      workspaces: opt(6),
    },
    taskbar: {
      iconSize: opt(0),
      monochrome: opt(false),
      exclusive: opt(false),
    },
    messages: {
      action: opt(() => App.toggleWindow('datemenu')),
    },
    systray: {
      ignore: opt([
        'KDE Connect Indicator',
        //"spotify-client",
      ]),
    },
    media: {
      monochrome: opt(false),
      preferred: opt('spotify'),
      direction: opt<'left' | 'right'>('right'),
      format: opt('{artists} - {title}'),
      length: opt(40),
    },
    powermenu: {
      monochrome: opt(false),
      action: opt(() => App.toggleWindow('powermenu')),
    },
  },

  dock: {
    iconSize: opt(44),
    pinnedApps: opt([
      'nemo',
      'firefox',
      'mullvad',
      'qbittorrent',
      'com.obsproject.Studio',
      'vlc',
      'spotify',
      //"viewnior",
      //"phototonic",
      'gthumb',
      'nomachine',
      'lutris',
      'steam',
      'discord',
      'vscode',
      'wezterm',
      'obsidian',
    ]),
    toolbox: {
      icons: [opt(icon(icons.ui.tbox_close)), opt(icon(icons.ui.tbox_appkill)), opt(icon(icons.ui.tbox_rotate)), opt(icon(icons.ui.tbox_workspaceprev)), opt(icon(icons.ui.tbox_workspacenext)), opt(icon(icons.ui.tbox_moveleft)), opt(icon(icons.ui.tbox_moveright)), opt(icon(icons.ui.tbox_moveup)), opt(icon(icons.ui.tbox_movedown)), opt(icon(icons.ui.tbox_swapnext)), opt(icon(icons.ui.tbox_split)), opt(icon(icons.ui.tbox_float)), opt(icon(icons.ui.tbox_pinned)), opt(icon(icons.ui.tbox_fullscreen)), opt(icon(icons.ui.tbox_osk))],
    },
  },
  launcher: {
    width: opt(0),
    margin: opt(80),
    nix: {
      pkgs: opt('nixpkgs/nixos-unstable'),
      max: opt(8),
    },
    sh: {
      max: opt(16),
    },
    apps: {
      iconSize: opt(62),
      max: opt(6),
      favorites: opt([['firefox', 'nemo', 'obsidian', 'discord', 'spotify']]),
    },
  },

  overview: {
    scale: opt(9),
    workspaces: opt(6),
    monochromeIcon: opt(false),
  },

  powermenu: {
    //sleep: opt('systemctl suspend'),
    sleep: opt('loginctl suspend'),
    //reboot: opt('reboot'),
    reboot: opt('loginctl reboot'),
    logout: opt('pkill Hyprland'),
    //shutdown: opt('shutdown now'),
    shutdown: opt('loginctl poweroff'),
    layout: opt<'line' | 'box'>('line'),
    labels: opt(true),
  },

  quicksettings: {
    avatar: {
      image: opt(`/var/lib/AccountsService/icons/${Utils.USER}`),
      size: opt(40),
    },
    width: opt(380),
    position: opt<'left' | 'center' | 'right'>('right'),
    networkSettings: opt('gtk-launch nm-connection-editor'),
    //networkSettings: opt('gtk-launch gnome-control-center'),
    media: {
      monochromeIcon: opt(true),
      coverSize: opt(100),
    },
  },

  datemenu: {
    position: opt<'left' | 'center' | 'right'>('center'),
    weather: {
      interval: opt(60_000),
      unit: opt<'metric' | 'imperial' | 'standard'>('metric'),
      key: opt<string>(JSON.parse(Utils.readFile(`${App.configDir}/.weather`) || '{}')?.key || ''),
      cities: opt<Array<number>>(JSON.parse(Utils.readFile(`${App.configDir}/.weather`) || '{}')?.cities || []),
    },
  },

  osd: {
    progress: {
      vertical: opt(true),
      pack: {
        h: opt<'start' | 'center' | 'end'>('end'),
        v: opt<'start' | 'center' | 'end'>('center'),
      },
    },
    microphone: {
      pack: {
        h: opt<'start' | 'center' | 'end'>('center'),
        v: opt<'start' | 'center' | 'end'>('end'),
      },
    },
  },

  notifications: {
    position: opt<Array<'top' | 'bottom' | 'left' | 'right'>>(['top', 'right']),
    blacklist: opt(['']),
    //blacklist: opt(["Spotify"]),
    width: opt(440),
  },

  hyprland: {
    gaps: opt(2.4),
    inactiveBorder: opt('333333ff'),
    gapsWhenOnly: opt(false),
  },
});

globalThis['options'] = options;
export default options;
