import promptAction from '@ohos.promptAction';

/**
 * 应用错误类型定义
 */

/**
 * 数据操作错误类型
 */
export enum DataErrorType {
  INITIALIZATION_FAILED = 'INITIALIZATION_FAILED',
  SAVE_FAILED = 'SAVE_FAILED',
  LOAD_FAILED = 'LOAD_FAILED',
  NOTE_NOT_FOUND = 'NOTE_NOT_FOUND',
  CATEGORY_NOT_FOUND = 'CATEGORY_NOT_FOUND',
  CATEGORY_ALREADY_EXISTS = 'CATEGORY_ALREADY_EXISTS',
  STORAGE_QUOTA_EXCEEDED = 'STORAGE_QUOTA_EXCEEDED',
  INVALID_DATA = 'INVALID_DATA'
}

/**
 * 业务逻辑错误类型
 */
export enum BusinessErrorType {
  CATEGORY_IN_USE = 'CATEGORY_IN_USE',
  EMPTY_NOTE_CONTENT = 'EMPTY_NOTE_CONTENT',
  INVALID_CATEGORY_NAME = 'INVALID_CATEGORY_NAME',
  NOTE_ALREADY_DELETED = 'NOTE_ALREADY_DELETED'
}

/**
 * 自定义错误基类
 */
export class AppError extends Error {
  public code: string;
  public details?: Object;

  constructor(code: string, message: string, details?: Object) {
    super(message);
    this.code = code;
    this.details = details;
    this.name = 'AppError';
  }

  /**
   * 获取用户友好的错误消息
   */
  getUserMessage(): string {
    return this.message;
  }

  /**
   * 获取开发者调试信息
   */
  getDebugInfo(): string {
    return `${this.code}: ${this.message}\nDetails: ${JSON.stringify(this.details)}`;
  }
}

/**
 * 数据操作错误
 */
export class DataError extends AppError {
  public type: DataErrorType;

  constructor(type: DataErrorType, message: string, details?: Object) {
    super(type, message, details);
    this.type = type;
    this.name = 'DataError';
  }

  getUserMessage(): string {
    switch (this.type) {
      case DataErrorType.INITIALIZATION_FAILED:
        return '应用初始化失败，请重启应用';
      case DataErrorType.SAVE_FAILED:
        return '保存失败，请重试';
      case DataErrorType.LOAD_FAILED:
        return '加载数据失败，请检查应用权限';
      case DataErrorType.NOTE_NOT_FOUND:
        return '笔记不存在或已被删除';
      case DataErrorType.CATEGORY_NOT_FOUND:
        return '分类不存在';
      case DataErrorType.CATEGORY_ALREADY_EXISTS:
        return '分类已存在';
      case DataErrorType.STORAGE_QUOTA_EXCEEDED:
        return '存储空间不足，请清理应用数据';
      case DataErrorType.INVALID_DATA:
        return '数据格式错误';
      default:
        return this.message;
    }
  }
}

/**
 * 业务逻辑错误
 */
export class BusinessError extends AppError {
  public type: BusinessErrorType;

  constructor(type: BusinessErrorType, message: string, details?: Object) {
    super(type, message, details);
    this.type = type;
    this.name = 'BusinessError';
  }

  getUserMessage(): string {
    switch (this.type) {
      case BusinessErrorType.CATEGORY_IN_USE:
        return '该分类下还有笔记，无法删除';
      case BusinessErrorType.EMPTY_NOTE_CONTENT:
        return '笔记内容不能为空';
      case BusinessErrorType.INVALID_CATEGORY_NAME:
        return '分类名称无效，请输入1-20个字符';
      case BusinessErrorType.NOTE_ALREADY_DELETED:
        return '笔记已在回收站中';
      default:
        return this.message;
    }
  }
}

/**
 * 错误处理工具类
 */
export class ErrorHandler {
  }

/**
 * 处理错误并显示用户友好的提示
 */
export function handleError(error: Error, context?: string): void {
  let userMessage = '操作失败，请重试';

  if (error instanceof DataError || error instanceof BusinessError) {
    userMessage = error.getUserMessage();
  }

  // 记录错误日志
  console.error(`[${context || 'Unknown'}] ${error.name}:`, error.message);

  // 显示用户提示
  promptAction.showToast({
    message: userMessage,
    duration: 2000
  });
}

/**
 * 包装异步函数，自动处理错误
 */
export async function safeExecute<T>(
  fn: () => Promise<T>,
  context?: string,
  fallback?: T
): Promise<T | undefined> {
  try {
    return await fn();
  } catch (error) {
    handleError(error as Error, context);
    return fallback;
  }
}

/**
 * 创建数据错误
 */
export function createDataError(type: DataErrorType, details?: Object): DataError {
  return new DataError(type, `数据操作失败: ${type}`, details);
}

/**
 * 创建业务错误
 */
export function createBusinessError(type: BusinessErrorType, details?: Object): BusinessError {
  return new BusinessError(type, `业务逻辑错误: ${type}`, details);
}