import { ThemeManager, ThemeMode } from '../service/ThemeManager';
import { Context } from '@ohos.abilityAccessCtrl';

/**
 * 主题颜色接口
 */
export interface ThemeColors {
  background: string;
  card: string;
  text: string;
  textSecondary: string;
  border: string;
}

/**
 * 主题Hook返回值
 */
export interface UseThemeReturn {
  currentTheme: ThemeMode;
  themeColors: ThemeColors;
  toggleTheme: () => Promise<void>;
  getThemeIcon: (theme: ThemeMode) => string;
  getThemeDisplayText: (theme: ThemeMode) => string;
}

/**
 * 主题Hook
 * 提供主题状态管理和颜色获取功能
 */
export function useTheme(context?: Context): UseThemeReturn {
  const themeManager = ThemeManager.getInstance();
  const currentTheme = themeManager.getCurrentThemeSync();
  const themeColors = getThemeColors(currentTheme);

  /**
   * 获取主题颜色配置
   */
  function getThemeColors(theme: ThemeMode): ThemeColors {
    switch (theme) {
      case ThemeMode.DARK:
        return {
          background: '#000000',
          card: '#1F1F1F',
          text: '#FFFFFF',
          textSecondary: '#999999',
          border: '#333333'
        };
      case ThemeMode.LIGHT:
        return {
          background: '#F1F3F5',
          card: '#FFFFFF',
          text: '#182431',
          textSecondary: '#99A2AD',
          border: '#E1E4E8'
        };
      default:
        return {
          background: '#F1F3F5',
          card: '#FFFFFF',
          text: '#182431',
          textSecondary: '#99A2AD',
          border: '#E1E4E8'
        };
    }
  }

  /**
   * 切换主题
   */
  async function toggleTheme(): Promise<void> {
    try {
      await themeManager.toggleTheme();
    } catch (error) {
      console.error('Failed to toggle theme:', error);
    }
  }

  /**
   * 获取主题图标
   */
  function getThemeIcon(theme: ThemeMode): string {
    switch (theme) {
      case ThemeMode.DARK:
        return '🌙';
      case ThemeMode.LIGHT:
        return '☀️';
      default:
        return '🌗';
    }
  }

  /**
   * 获取主题显示文字
   */
  function getThemeDisplayText(theme: ThemeMode): string {
    switch (theme) {
      case ThemeMode.DARK:
        return '深色';
      case ThemeMode.LIGHT:
        return '浅色';
      default:
        return '自动';
    }
  }

  return {
    currentTheme,
    themeColors,
    toggleTheme,
    getThemeIcon,
    getThemeDisplayText
  };
}

/**
 * 主题颜色工具类
 * 提供静态方法获取主题相关颜色
 */
export class ThemeUtils {
  /**
   * 根据主题获取文字颜色
   */
  static getTextColor(theme: ThemeMode, isSecondary: boolean = false): string {
    if (isSecondary) {
      return theme === ThemeMode.DARK ? '#999999' : '#99A2AD';
    }
    return theme === ThemeMode.DARK ? '#FFFFFF' : '#182431';
  }

  /**
   * 根据主题获取背景颜色
   */
  static getBackgroundColor(theme: ThemeMode, isCard: boolean = false): string {
    if (isCard) {
      return theme === ThemeMode.DARK ? '#1F1F1F' : '#FFFFFF';
    }
    return theme === ThemeMode.DARK ? '#000000' : '#F1F3F5';
  }

  /**
   * 根据主题获取边框颜色
   */
  static getBorderColor(theme: ThemeMode): string {
    return theme === ThemeMode.DARK ? '#333333' : '#E1E4E8';
  }

  /**
   * 根据主题获取按钮背景颜色
   */
  static getButtonBackgroundColor(theme: ThemeMode, isSecondary: boolean = false): string {
    if (isSecondary) {
      return theme === ThemeMode.DARK ? '#2A2A2A' : '#F5F5F5';
    }
    return theme === ThemeMode.DARK ? '#1A1A1A' : '#F8F8F8';
  }
}