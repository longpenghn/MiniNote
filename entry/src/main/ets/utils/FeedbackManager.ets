import promptAction from '@ohos.promptAction';

/**
 * 消息类型
 */
export enum MessageType {
  SUCCESS = 'success',
  ERROR = 'error',
  WARNING = 'warning',
  INFO = 'info'
}

/**
 * 反馈配置
 */
export interface FeedbackConfig {
  message: string;
  type?: MessageType;
  duration?: number;
  showIcon?: boolean;
}

/**
 * 用户反馈管理器
 * 统一管理Toast提示和用户反馈
 */
export class FeedbackManager {
  private static instance: FeedbackManager;

  static getInstance(): FeedbackManager {
    if (!FeedbackManager.instance) {
      FeedbackManager.instance = new FeedbackManager();
    }
    return FeedbackManager.instance;
  }

  /**
   * 显示成功消息
   */
  static showSuccess(message: string, duration: number = 2000): void {
    FeedbackManager.getInstance().show({
      message: `✅ ${message}`,
      type: MessageType.SUCCESS,
      duration
    });
  }

  /**
   * 显示错误消息
   */
  static showError(message: string, duration: number = 3000): void {
    FeedbackManager.getInstance().show({
      message: `❌ ${message}`,
      type: MessageType.ERROR,
      duration
    });
  }

  /**
   * 显示警告消息
   */
  static showWarning(message: string, duration: number = 2500): void {
    FeedbackManager.getInstance().show({
      message: `⚠️ ${message}`,
      type: MessageType.WARNING,
      duration
    });
  }

  /**
   * 显示信息消息
   */
  static showInfo(message: string, duration: number = 2000): void {
    FeedbackManager.getInstance().show({
      message: `ℹ️ ${message}`,
      type: MessageType.INFO,
      duration
    });
  }

  /**
   * 显示通用消息
   */
  static show(message: string, duration: number = 2000): void {
    FeedbackManager.getInstance().show({
      message,
      duration
    });
  }

  /**
   * 显示加载状态
   */
  static showLoading(message: string = '加载中...'): void {
    FeedbackManager.getInstance().show({
      message: `⏳ ${message}`,
      type: MessageType.INFO,
      duration: 3000
    });
  }

  /**
   * 显示确认对话框
   */
  static async showConfirm(options: {
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
  }): Promise<boolean> {
    return new Promise((resolve) => {
      AlertDialog.show({
        title: options.title,
        message: options.message,
        primaryButton: {
          value: options.cancelText || '取消',
          action: () => {
            resolve(false);
          }
        },
        secondaryButton: {
          value: options.confirmText || '确定',
          fontColor: '#007DFF',
          action: () => {
            resolve(true);
          }
        }
      });
    });
  }

  /**
   * 显示删除确认对话框
   */
  static async showDeleteConfirm(itemName: string, itemType: string = '项目'): Promise<boolean> {
    return FeedbackManager.showConfirm({
      title: `删除${itemType}`,
      message: `确定要删除${itemName}吗？\n\n删除后无法恢复。`,
      confirmText: '删除',
      cancelText: '取消'
    });
  }

  /**
   * 内部显示方法
   */
  private show(config: FeedbackConfig): void {
    try {
      promptAction.showToast({
        message: config.message,
        duration: config.duration || 2000
      });
    } catch (error) {
      console.error('Failed to show toast:', error);
      // 降级处理：使用console.log
      console.log(`[Feedback] ${config.message}`);
    }
  }
}

/**
 * 常用消息集合
 */
export const CommonMessages = {
  // 操作成功
  SAVE_SUCCESS: '保存成功',
  DELETE_SUCCESS: '删除成功',
  CREATE_SUCCESS: '创建成功',
  UPDATE_SUCCESS: '更新成功',
  COPY_SUCCESS: '复制成功',

  // 操作失败
  SAVE_FAILED: '保存失败，请重试',
  DELETE_FAILED: '删除失败，请重试',
  LOAD_FAILED: '加载失败，请检查网络',
  CREATE_FAILED: '创建失败，请重试',

  // 分类相关
  CATEGORY_CREATE_SUCCESS: '分类创建成功',
  CATEGORY_DELETE_SUCCESS: '分类删除成功',
  CATEGORY_ALREADY_EXISTS: '分类已存在',
  CATEGORY_IN_USE: '该分类下还有笔记，无法删除',

  // 笔记相关
  NOTE_EMPTY: '笔记内容不能为空',
  NOTE_NOT_FOUND: '笔记不存在',
  NOTE_RESTORED: '笔记已恢复',
  NOTE_MOVED_TO_TRASH: '笔记已移至回收站',

  // 网络和存储
  NETWORK_ERROR: '网络连接失败',
  STORAGE_FULL: '存储空间不足',
  PERMISSION_DENIED: '权限不足',

  // 通用
  LOADING: '加载中...',
  PROCESSING: '处理中...',
  NO_DATA: '暂无数据',
  OPERATION_SUCCESS: '操作成功',
  OPERATION_FAILED: '操作失败'
};

/**
 * 快捷方法
 */
export const showSuccess = FeedbackManager.showSuccess;
export const showError = FeedbackManager.showError;
export const showWarning = FeedbackManager.showWarning;
export const showInfo = FeedbackManager.showInfo;
export const showToast = FeedbackManager.show;
export const showConfirm = FeedbackManager.showConfirm;
export const showDeleteConfirm = FeedbackManager.showDeleteConfirm;