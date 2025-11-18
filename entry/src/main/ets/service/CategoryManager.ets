import preferences from '@ohos.data.preferences';
import { Context } from '@ohos.abilityAccessCtrl';

/**
 * Category entity class
 */
export class Category {
  id: string;
  name: string;
  color: string;
  icon: string;
  createTime: number;

  constructor(name?: string, color?: string, icon?: string) {
    this.id = this.generateId();
    this.name = name || '';
    this.color = color || '#007DFF';
    this.icon = icon || 'folder';
    this.createTime = Date.now();
  }

  private generateId(): string {
    return Date.now().toString() + Math.random().toString(36).substr(2, 9);
  }

  toJson(): CategoryJson {
    return {
      id: this.id,
      name: this.name,
      color: this.color,
      icon: this.icon,
      createTime: this.createTime
    };
  }

  static fromJson(json: CategoryJson): Category {
    const category = new Category(json.name, json.color, json.icon);
    category.id = json.id;
    category.createTime = json.createTime;
    return category;
  }
}

/**
 * Category JSON interface
 */
export interface CategoryJson {
  id: string;
  name: string;
  color: string;
  icon: string;
  createTime: number;
}

/**
 * Category Manager - Singleton class for managing note categories
 */
export class CategoryManager {
  private static instance: CategoryManager;
  private preferencesStore: preferences.Preferences | null = null;
  private categories: Category[] = [];
  private readonly STORAGE_KEY = 'categories_data';

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): CategoryManager {
    if (!CategoryManager.instance) {
      CategoryManager.instance = new CategoryManager();
    }
    return CategoryManager.instance;
  }

  /**
   * Initialize with context
   */
  async initialize(context: Context): Promise<void> {
    try {
      this.preferencesStore = await preferences.getPreferences(context, 'mininote_categories');
      await this.loadCategories();

      // Create default categories if none exist
      if (this.categories.length === 0) {
        await this.createDefaultCategories();
      }
    } catch (error) {
      console.error('CategoryManager initialization failed:', error);
      throw new Error('Operation failed');
    }
  }

  /**
   * Load categories from local storage
   */
  private async loadCategories(): Promise<void> {
    if (!this.preferencesStore) return;

    try {
      const categoriesJson = await this.preferencesStore.get(this.STORAGE_KEY, '[]') as string;
      const categoriesData: CategoryJson[] = JSON.parse(categoriesJson);
      this.categories = categoriesData.map(json => Category.fromJson(json));
    } catch (error) {
      console.error('Failed to load categories:', error);
      this.categories = [];
    }
  }

  /**
   * Save categories to local storage
   */
  private async saveCategories(): Promise<void> {
    if (!this.preferencesStore) return;

    try {
      const categoriesJson = JSON.stringify(this.categories.map(cat => cat.toJson()));
      await this.preferencesStore.put(this.STORAGE_KEY, categoriesJson);
      await this.preferencesStore.flush();
    } catch (error) {
      console.error('Failed to save categories:', error);
      throw new Error('Operation failed');
    }
  }

  /**
   * Create default categories
   */
  private async createDefaultCategories(): Promise<void> {
    const defaultCategories = [
      new Category('工作', '#FF6B6B', 'work'),
      new Category('学习', '#4ECDC4', 'study'),
      new Category('生活', '#45B7D1', 'life'),
      new Category('灵感', '#96CEB4', 'idea'),
      new Category('待办', '#FFEAA7', 'todo')
    ];

    this.categories = defaultCategories;
    await this.saveCategories();
  }

  /**
   * Get all categories
   */
  getCategories(): Category[] {
    return [...this.categories];
  }

  /**
   * Get category by ID
   */
  getCategory(id: string): Category | undefined {
    return this.categories.find(cat => cat.id === id);
  }

  /**
   * Get category by name
   */
  getCategoryByName(name: string): Category | undefined {
    return this.categories.find(cat => cat.name === name);
  }

  /**
   * Add new category
   */
  async addCategory(category: Category): Promise<void> {
    // Check for duplicate names
    if (this.categories.some(cat => cat.name === category.name)) {
      throw Error(`Category "${category.name}" already exists`);
    }

    this.categories.push(category);
    await this.saveCategories();
  }

  /**
   * Update category
   */
  async updateCategory(category: Category): Promise<void> {
    const index = this.categories.findIndex(cat => cat.id === category.id);
    if (index === -1) {
      throw Error('Category not found');
    }

    // Check for duplicate names (excluding current category)
    if (this.categories.some(cat => cat.name === category.name && cat.id !== category.id)) {
      throw Error(`Category "${category.name}" already exists`);
    }

    this.categories[index] = category;
    await this.saveCategories();
  }

  /**
   * Delete category
   */
  async deleteCategory(categoryId: string): Promise<void> {
    const index = this.categories.findIndex(cat => cat.id === categoryId);
    if (index === -1) {
      throw Error('Category not found');
    }

    this.categories.splice(index, 1);
    await this.saveCategories();
  }

  /**
   * Delete category by name
   */
  async deleteCategoryByName(categoryName: string): Promise<void> {
    const category = this.getCategoryByName(categoryName);
    if (!category) {
      throw Error('Category not found');
    }

    await this.deleteCategory(category.id);
  }

  /**
   * Update category color
   */
  async updateCategoryColor(categoryName: string, newColor: string): Promise<void> {
    const category = this.getCategoryByName(categoryName);
    if (!category) {
      throw Error('Category not found');
    }

    category.color = newColor;
    await this.updateCategory(category);
  }

  /**
   * Get category statistics
   */
  getCategoryStats(noteCountByCategory: Record<string, number>): CategoryWithStats[] {
    const result: CategoryWithStats[] = [];
    for (const category of this.categories) {
      const stats = new CategoryWithStats(category, noteCountByCategory[category.id] || 0);
      result.push(stats);
    }
    return result.sort((a, b) => b.noteCount - a.noteCount);
  }

  /**
   * Get all unique category names
   */
  getCategoryNames(): string[] {
    return this.categories.map(cat => cat.name);
  }

  /**
   * Validate category name
   */
  isValidCategoryName(name: string): boolean {
    return name.trim().length > 0 && name.trim().length <= 20;
  }
}

/**
 * Category with statistics
 */
export class CategoryWithStats extends Category {
  noteCount: number = 0;

  constructor(category: Category, noteCount: number) {
    super();
    this.id = category.id;
    this.name = category.name;
    this.color = category.color;
    this.icon = category.icon;
    this.createTime = category.createTime;
    this.noteCount = noteCount;
  }
}