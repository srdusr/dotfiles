import { clock, uptime } from 'lib/variables';
import GLib from 'gi://GLib';
import Gtk from 'gi://Gtk';

function up(up: number) {
  const h = Math.floor(up / 60);
  const m = Math.floor(up % 60);
  return `uptime: ${h}:${m < 10 ? '0' + m : m}`;
}

export default () =>
  Widget.Box({
    vertical: true,
    class_name: 'date-column vertical',
    children: [
      Widget.Box({
        class_name: 'clock-box',
        vertical: true,
        children: [
          Widget.Label({
            class_name: 'clock',
            label: clock.bind().as(t => t.format('%H:%M')!),
          }),
          Widget.Label({
            class_name: 'uptime',
            label: uptime.bind().as(up),
          }),
        ],
      }),
      Widget.Box({
        class_name: 'calendar',
        children: [
          (() => {
            const calendar = Widget.Calendar({
              hexpand: true,
              hpack: 'center',
            });

            // Get today's date and mark it
            const today = new Date();
            calendar.select_day(today.getDate());
            calendar.select_month(today.getMonth(), today.getFullYear());
            calendar.mark_day(today.getDate()); // This should trigger styling

            // Prevent scrolling from triggering GNOME Calendar
            const eventBox = Widget.EventBox({
              child: calendar,
              onPrimaryClick: () => {
                GLib.spawn_command_line_async('gnome-calendar');
              },
            });

            return eventBox;
          })(),
        ],
      }),
    ],
  });
