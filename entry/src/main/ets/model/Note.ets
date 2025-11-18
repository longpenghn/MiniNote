/**
 * Note JSON interface for type safety
 */
export interface NoteJson {
  id: string;
  title: string;
  content: string;
  createTime: number;
  updateTime: number;
  category: string;
  tags: string[];
  isDeleted: boolean;
  deleteTime?: number;
}

/**
 * Note entity class for storing note data
 */
export class Note {
  id: string = '';
  title: string = '';
  content: string = '';
  createTime: number = 0;
  updateTime: number = 0;
  category: string = '';
  tags: string[] = [];
  isDeleted: boolean = false;
  deleteTime: number = 0;

  constructor(id?: string, title?: string, content?: string, createTime?: number, updateTime?: number,
              category?: string, tags?: string[], isDeleted?: boolean, deleteTime?: number) {
    this.id = id || this.generateId();
    this.title = title || '';
    this.content = content || '';
    this.createTime = createTime || Date.now();
    this.updateTime = updateTime || Date.now();
    this.category = category || '';
    this.tags = tags || [];
    this.isDeleted = isDeleted || false;
    this.deleteTime = deleteTime || 0;
  }

  /**
   * Generate unique ID for note
   */
  private generateId(): string {
    return Date.now().toString() + Math.random().toString(36).substr(2, 9);
  }

  /**
   * Extract title from content (first line)
   */
  extractTitle(): string {
    if (!this.content) {
      return 'Untitled';
    }
    const firstLine = this.content.split('\n')[0].trim();
    return firstLine || 'Untitled';
  }

  /**
   * Get content preview (first 50 characters)
   */
  getPreview(): string {
    if (!this.content) {
      return '';
    }
    const lines = this.content.split('\n');
    const contentWithoutTitle = lines.length > 1 ? lines.slice(1).join('\n') : '';
    return contentWithoutTitle.length > 50 ? contentWithoutTitle.substring(0, 50) + '...' : contentWithoutTitle;
  }

  /**
   * Update note content and refresh title and update time
   */
  updateContent(content: string): void {
    this.content = content;
    this.title = this.extractTitle();
    this.updateTime = Date.now();
  }

  /**
   * Update note category
   */
  updateCategory(category: string): void {
    this.category = category;
    this.updateTime = Date.now();
  }

  /**
   * Add a tag to the note
   */
  addTag(tag: string): void {
    if (!this.tags.includes(tag) && tag.trim()) {
      this.tags.push(tag.trim());
      this.updateTime = Date.now();
    }
  }

  /**
   * Remove a tag from the note
   */
  removeTag(tag: string): void {
    const index = this.tags.indexOf(tag);
    if (index > -1) {
      this.tags.splice(index, 1);
      this.updateTime = Date.now();
    }
  }

  /**
   * Check if note has a specific tag
   */
  hasTag(tag: string): boolean {
    return this.tags.includes(tag);
  }

  /**
   * Soft delete the note
   */
  softDelete(): void {
    this.isDeleted = true;
    this.deleteTime = Date.now();
    this.updateTime = Date.now();
  }

  /**
   * Restore the note from trash
   */
  restore(): void {
    this.isDeleted = false;
    this.deleteTime = 0;
    this.updateTime = Date.now();
  }

  /**
   * Get all unique tags from the note
   */
  getTags(): string[] {
    return [...this.tags];
  }

  /**
   * Convert to JSON object for storage
   */
  toJson(): NoteJson {
    return {
      id: this.id,
      title: this.title,
      content: this.content,
      createTime: this.createTime,
      updateTime: this.updateTime,
      category: this.category,
      tags: this.tags,
      isDeleted: this.isDeleted,
      deleteTime: this.deleteTime > 0 ? this.deleteTime : undefined
    };
  }

  /**
   * Create Note instance from JSON object
   */
  static fromJson(json: NoteJson): Note {
    return new Note(
      json.id,
      json.title,
      json.content,
      json.createTime,
      json.updateTime,
      json.category,
      json.tags,
      json.isDeleted,
      json.deleteTime
    );
  }
}