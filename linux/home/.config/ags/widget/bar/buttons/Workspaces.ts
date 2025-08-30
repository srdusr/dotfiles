import PanelButton from '../PanelButton';
import options from 'options';
import { sh, range } from 'lib/utils';

const hyprland = await Service.import('hyprland');
const { workspaces } = options.bar.workspaces;

const dispatch = arg => {
  sh(`hyprctl dispatch workspace ${arg}`);
};

const Workspaces = ws =>
  Widget.Box({
    children: range(ws || 20).map(i =>
      Widget.Label({
        attribute: i,
        vpack: 'center',
        label: `${i}`,
        setup: self => {
          const updateState = () => {
            const monitorData = JSON.parse(hyprland.message('j/monitors'));
            const activeWorkspaceId = monitorData[0]?.activeWorkspace?.id;
            const workspaceData = hyprland.getWorkspace(i);

            if (activeWorkspaceId !== undefined) {
              self.toggleClassName('active', activeWorkspaceId === i);
            }
            self.toggleClassName('occupied', (workspaceData?.windows || 0) > 0);
          };

          // Hook to Hyprland for updates
          self.hook(hyprland, updateState);

          // Initial update
          updateState();
        },
      }),
    ),
    setup: box => {
      box.hook(hyprland, () => {
        const monitorData = JSON.parse(hyprland.message('j/monitors'));
        const activeWorkspaceId = monitorData[0]?.activeWorkspace?.id;

        if (activeWorkspaceId !== undefined) {
          for (const btn of box.children) {
            const workspaceId = btn.attribute;
            btn.toggleClassName('active', workspaceId === activeWorkspaceId);

            if (ws === 0) {
              btn.visible = hyprland.workspaces.some(workspace => workspace.id === workspaceId);
            }
          }
        }
      });
    },
  });

export default () =>
  PanelButton({
    window: 'overview',
    class_name: 'workspaces',
    on_scroll_up: () => dispatch('m+1'),
    on_scroll_down: () => dispatch('m-1'),
    on_clicked: () => App.toggleWindow('overview'),
    child: workspaces.bind().as(Workspaces),
  });
