/**
 * 防抖Hook
 * 用于优化搜索等频繁触发的操作
 */

/**
 * 防抖函数返回值
 */
export interface DebounceReturn {
  debouncedValue: string;
  flush: () => void;
  cancel: () => void;
  isPending: boolean;
}

/**
 * 创建防抖函数
 * @param delay 延迟时间（毫秒）
 * @param callback 回调函数
 * @returns 防抖函数
 */
export function createDebounce<T extends (...args: any[]) => void>(
  delay: number,
  callback: T
): {
  (...args: Parameters<T>): void;
  flush: () => void;
  cancel: () => void;
  isPending: boolean;
} {
  let timeoutId: number = -1;
  let isDebouncing = false;
  let lastArgs: Parameters<T> | null = null;

  const debouncedFunction = (...args: Parameters<T>) => {
    lastArgs = args;
    isDebouncing = true;

    if (timeoutId !== -1) {
      clearTimeout(timeoutId);
    }

    timeoutId = setTimeout(() => {
      isDebouncing = false;
      if (lastArgs) {
        callback(...lastArgs);
        lastArgs = null;
      }
    }, delay);
  };

  debouncedFunction.flush = () => {
    if (timeoutId !== -1) {
      clearTimeout(timeoutId);
      timeoutId = -1;
    }
    isDebouncing = false;
    if (lastArgs) {
      callback(...lastArgs);
      lastArgs = null;
    }
  };

  debouncedFunction.cancel = () => {
    if (timeoutId !== -1) {
      clearTimeout(timeoutId);
      timeoutId = -1;
    }
    isDebouncing = false;
    lastArgs = null;
  };

  Object.defineProperty(debouncedFunction, 'isPending', {
    get: () => isDebouncing
  });

  return debouncedFunction;
}

/**
 * 使用防抖Hook
 * @param value 需要防抖的值
 * @param delay 延迟时间（毫秒）
 * @returns 防抖后的值和控制函数
 */
export function useDebounce<T>(value: T, delay: number): DebounceReturn {
  // 在ArkTS中，我们需要手动管理状态
  // 这里提供一个简化的实现

  let debouncedValue: T = value;
  let timeoutId: number = -1;
  let isPending = false;

  const setValue = (newValue: T) => {
    if (timeoutId !== -1) {
      clearTimeout(timeoutId);
    }

    isPending = true;
    timeoutId = setTimeout(() => {
      debouncedValue = newValue;
      isPending = false;
    }, delay);
  };

  const flush = () => {
    if (timeoutId !== -1) {
      clearTimeout(timeoutId);
      timeoutId = -1;
    }
    debouncedValue = value;
    isPending = false;
  };

  const cancel = () => {
    if (timeoutId !== -1) {
      clearTimeout(timeoutId);
      timeoutId = -1;
    }
    isPending = false;
  };

  // 当value变化时，启动防抖
  setValue(value);

  return {
    debouncedValue,
    flush,
    cancel,
    isPending
  };
}

/**
 * 节流函数
 * @param delay 时间间隔（毫秒）
 * @param callback 回调函数
 * @returns 节流函数
 */
export function createThrottle<T extends (...args: any[]) => void>(
  delay: number,
  callback: T
): (...args: Parameters<T>) => void {
  let lastExecutionTime = 0;
  let timeoutId: number = -1;

  return (...args: Parameters<T>) => {
    const currentTime = Date.now();

    if (currentTime - lastExecutionTime >= delay) {
      lastExecutionTime = currentTime;
      callback(...args);
    } else {
      if (timeoutId !== -1) {
        clearTimeout(timeoutId);
      }

      timeoutId = setTimeout(() => {
        lastExecutionTime = Date.now();
        callback(...args);
      }, delay - (currentTime - lastExecutionTime));
    }
  };
}