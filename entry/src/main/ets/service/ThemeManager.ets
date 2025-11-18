import { preferences } from '@kit.ArkData';
import { Context, ConfigurationConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

/**
 * Theme modes enumeration
 */
export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  AUTO = 'auto'
}

/**
 * Theme manager for handling light/dark mode with reactive state management
 */
export class ThemeManager {
  private static instance: ThemeManager;
  private preferencesStore: preferences.Preferences | null = null;
  private readonly STORE_NAME = 'theme_store';
  private readonly THEME_KEY = 'current_theme';

  private _currentTheme: ThemeMode = ThemeMode.AUTO;
  private themeChangeCallbacks: Array<(theme: ThemeMode) => void> = [];
  private _updateFlag: number = 0; // 用于触发UI更新
  private appContext: Context | null = null;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  /**
   * Initialize theme manager
   */
  async init(context: Context): Promise<void> {
    try {
      this.appContext = context;
      this.preferencesStore = await preferences.getPreferences(context, this.STORE_NAME);
      // Load saved theme
      this._currentTheme = await this.getCurrentTheme() as ThemeMode;
      // Apply theme immediately
      await this.applyTheme(this._currentTheme);
    } catch (error) {
      console.error('Failed to initialize theme manager:', error);
      throw new Error('Failed to initialize theme manager');
    }
  }

  /**
   * Get current theme mode
   */
  async getCurrentTheme(): Promise<ThemeMode> {
    if (!this.preferencesStore) {
      return ThemeMode.AUTO;
    }

    try {
      const theme = await this.preferencesStore.get(this.THEME_KEY, ThemeMode.AUTO) as string;
      return Object.values(ThemeMode).includes(theme as ThemeMode) ? theme as ThemeMode : ThemeMode.AUTO;
    } catch (error) {
      console.error('Failed to get current theme:', error);
      return ThemeMode.AUTO;
    }
  }

  /**
   * Get current theme mode synchronously
   */
  getCurrentThemeSync(): ThemeMode {
    return this._currentTheme;
  }

  /**
   * Subscribe to theme changes
   */
  onThemeChange(callback: (theme: ThemeMode) => void): void {
    this.themeChangeCallbacks.push(callback);
  }

  /**
   * Unsubscribe from theme changes
   */
  offThemeChange(callback: (theme: ThemeMode) => void): void {
    const index = this.themeChangeCallbacks.indexOf(callback);
    if (index > -1) {
      this.themeChangeCallbacks.splice(index, 1);
    }
  }

  /**
   * Notify theme change listeners
   */
  private notifyThemeChange(theme: ThemeMode): void {
    this._updateFlag++; // 触发UI更新
    this.themeChangeCallbacks.forEach(callback => {
      try {
        callback(theme);
      } catch (error) {
        console.error('Theme change callback error:', error);
      }
    });
  }

  /**
   * Get update flag for reactive UI updates
   */
  getUpdateFlag(): number {
    return this._updateFlag;
  }

  /**
   * Set theme mode
   */
  async setTheme(theme: ThemeMode): Promise<void> {
    if (!this.preferencesStore) {
      throw new Error('Theme manager not initialized');
    }

    try {
      await this.preferencesStore.put(this.THEME_KEY, theme);
      await this.preferencesStore.flush();
      this._currentTheme = theme;

      // Apply theme to the application
      await this.applyTheme(theme);

      // Notify listeners
      this.notifyThemeChange(theme);
    } catch (error) {
      console.error('Failed to set theme:', error);
      throw new Error('Failed to set theme');
    }
  }

  /**
   * Toggle between theme modes
   */
  async toggleTheme(): Promise<ThemeMode> {
    const currentTheme = this._currentTheme;
    let newTheme: ThemeMode;

    switch (currentTheme) {
      case ThemeMode.LIGHT:
        newTheme = ThemeMode.DARK;
        break;
      case ThemeMode.DARK:
        newTheme = ThemeMode.AUTO;
        break;
      default:
        newTheme = ThemeMode.LIGHT;
        break;
    }

    await this.setTheme(newTheme);
    return newTheme;
  }

  /**
   * Get theme display text
   */
  getThemeDisplayText(theme?: ThemeMode): string {
    const mode = theme || this._currentTheme;
    switch (mode) {
      case ThemeMode.LIGHT:
        return '浅色';
      case ThemeMode.DARK:
        return '深色';
      case ThemeMode.AUTO:
        return '自动';
      default:
        return '自动';
    }
  }

  /**
   * Get theme icon
   */
  getThemeIcon(theme?: ThemeMode): string {
    const mode = theme || this._currentTheme;
    switch (mode) {
      case ThemeMode.LIGHT:
        return '☀️';
      case ThemeMode.DARK:
        return '🌙';
      case ThemeMode.AUTO:
        return '🌓';
      default:
        return '🌓';
    }
  }

  /**
   * Apply theme to the application
   */
  private async applyTheme(theme: ThemeMode): Promise<void> {
    if (!this.appContext) {
      console.error('App context not initialized, cannot apply theme');
      return;
    }

    try {
      let colorMode: ConfigurationConstant.ColorMode;

      switch (theme) {
        case ThemeMode.LIGHT:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
          break;
        case ThemeMode.DARK:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
          break;
        case ThemeMode.AUTO:
        default:
          colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET; // Follow system
          break;
      }

      // Apply color mode to application context
      this.appContext.getApplicationContext().setColorMode(colorMode);

      // Also try to set window theme if possible
      try {
        const windowStage = await window.getLastWindow(this.appContext);
        if (windowStage) {
          await windowStage.setWindowSystemBarProperties({
            statusBarContentColor: '#000000',
            navigationBarContentColor: '#000000',
            isStatusBarLightIcon: theme === ThemeMode.LIGHT,
            isNavigationBarLightIcon: theme === ThemeMode.LIGHT
          });
        }
      } catch (windowError) {
        console.warn('Failed to set window properties:', windowError);
      }

      console.log('Theme applied successfully:', theme, 'ColorMode:', colorMode);
    } catch (error) {
      console.error('Failed to apply theme:', error);
    }
  }

  /**
   * Get application color mode based on current theme
   */
  getAppColorMode(): 'light' | 'dark' {
    switch (this._currentTheme) {
      case ThemeMode.LIGHT:
        return 'light';
      case ThemeMode.DARK:
        return 'dark';
      case ThemeMode.AUTO:
        // Follow system setting
        return 'light'; // Default to light for AUTO mode
      default:
        return 'light';
    }
  }
}