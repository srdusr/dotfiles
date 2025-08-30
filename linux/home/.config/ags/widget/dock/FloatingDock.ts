import options from 'options';
import Dock from './Dock.ts';
const hyprland = await Service.import('hyprland');
const apps = await Service.import('applications');

const { Gdk, Gtk } = imports.gi;
import type Gtk from 'gi://Gtk?version=3.0';
import { type WindowProps } from 'types/widgets/window';
import { type RevealerProps } from 'types/widgets/revealer';
import { type EventBoxProps } from 'types/widgets/eventbox';

/** @param {number} monitor */
const FloatingDock = (monitor: number): Gtk.Window & WindowProps => {
  const update = () => {
    const ws = Hyprland.getWorkspace(Hyprland.active.workspace.id);
    if (Hyprland.getMonitor(monitor)?.name === ws?.monitor) self.reveal_child = ws?.windows === 0;
  };
  const revealer: Gtk.Revealer & RevealerProps = Widget.Revealer({
    transition: 'slide_up',
    transitionDuration: 90,
    child: Dock(),
    setup: self => self.hook(hyprland, update, 'client-added').hook(hyprland, update, 'client-removed').hook(hyprland.active.workspace, update),
  });

  const window = Widget.Window({
    monitor,
    //halign: 'fill',
    halign: 'end',
    //layer: "overlay",
    layer: 'dock',
    name: `dock${monitor}`,
    click_through: false,
    class_name: 'floating-dock',
    // class_name: 'floating-dock-no-gap',
    // class_name: "f-dock-wrap",

    typeHint: Gdk.WindowTypeHint.DOCK,
    exclusivity: 'false',

    anchor: ['bottom'],
    child: Widget.Box({
      vertical: false,
      halign: 'bottom',
      hpack: 'start',
      children: [
        revealer,
        Widget.Box({
          class_name: 'padding',
          css: 'padding: 9px; margin: 0;',
          vertical: false,
          halign: 'bottom',
          hpack: 'start',
        }),
      ],
    }),
  });

  window
    .on('enter-notify-event', () => {
      revealer.reveal_child = true;
    })
    .on('leave-notify-event', () => {
      revealer.reveal_child = false;
    })
    .bind('visible', options.bar.position, 'value', v => v !== 'left');

  return window;
};

export default FloatingDock;
