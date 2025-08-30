import options from 'options';
import { dependencies, sh } from 'lib/utils';

export type Resolution = 1920 | 1366 | 3840;
export type Market = 'random' | 'en-US' | 'ja-JP' | 'en-AU' | 'en-GB' | 'de-DE' | 'en-NZ' | 'en-CA';

const WP = `${Utils.HOME}/pictures/wallpapers`;
const Cache = `${Utils.HOME}/Pictures/Wallpapers/Bing`;

class Wallpaper extends Service {
  static {
    Service.register(
      this,
      {},
      {
        wallpaper: ['string'],
      },
    );
  }

  #blockMonitor = false;

  #wallpaper() {
    if (!dependencies('swww')) return;

    sh('hyprctl cursorpos').then(pos => {
      sh(['swww', 'img', '--transition-type', 'grow', '--transition-pos', pos.replace(' ', ''), WP]).then(() => {
        this.changed('wallpaper');
      });
    });
  }

  async #setWallpaper(path: string) {
    this.#blockMonitor = true;

    await sh(`cp "${path}" "${WP}"`);
    this.#wallpaper();

    this.#blockMonitor = false;
  }

  async #fetchBing() {
    // Check if wallpaper functionality is enabled
    if (!options.wallpaper.enable.value) {
      console.log('Wallpaper functionality is disabled.');
      return;
    }

    try {
      const res = await Utils.fetch('https://bing.biturl.top/', {
        params: {
          resolution: options.wallpaper.resolution.value,
          format: 'json',
          image_format: 'jpg',
          index: 'random',
          mkt: options.wallpaper.market.value,
        },
      });

      if (!res.ok) {
        console.warn('Failed to fetch from Bing:', res.statusText);
        return;
      }

      const data = await res.json();
      const { url } = data;

      if (!url) {
        console.warn('No URL found in Bing response:', data);
        return;
      }

      const file = `${Cache}/${url.replace('https://www.bing.com/th?id=', '')}`;

      Utils.ensureDirectory(Cache);

      if (!(await Utils.fileExists(file))) {
        await sh(`curl "${url}" --output "${file}"`);
        await this.#setWallpaper(file);
      } else {
        console.log(`Wallpaper already exists: ${file}`);
      }
    } catch (error) {
      console.error('Error fetching wallpaper:', error);
    }
  }

  readonly random = () => {
    // Check if wallpaper functionality is enabled
    if (!options.wallpaper.enable.value) {
      console.log('Wallpaper functionality is disabled.');
      return;
    }
    this.#fetchBing();
  };

  readonly set = (path: string) => {
    this.#setWallpaper(path);
  };

  get wallpaper() {
    return WP;
  }
  constructor() {
    super();

    // Respect wallpaper.enable option
    if (!options.wallpaper.enable.value) {
      console.log('Wallpaper functionality is disabled, not starting swww-daemon.');
      return;
    }

    if (!dependencies('swww')) return;

    // Monitor and set wallpaper if enabled
    Utils.monitorFile(WP, () => {
      if (!this.#blockMonitor) this.#wallpaper();
    });

    // Start swww-daemon only when wallpaper is enabled
    Utils.execAsync('swww-daemon')
      .then(this.#wallpaper)
      .catch(() => null);
  }
}

export default new Wallpaper();
