import { preferences } from '@kit.ArkData';
import { Context } from '@ohos.abilityAccessCtrl';
import { Note, NoteJson } from '../model/Note';
import { DataError, DataErrorType, BusinessError, BusinessErrorType, ErrorHandler } from '../common/ErrorTypes';

/**
 * Search filter interface
 */
export interface SearchFilters {
  keyword?: string;
  category?: string;
  tags?: string[];
}

/**
 * Note data manager for local storage operations
 */
export class NoteDataManager {
  private static instance: NoteDataManager;
  private preferencesStore: preferences.Preferences | null = null;
  private readonly STORE_NAME = 'note_store';
  private readonly NOTES_KEY = 'notes_data';

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): NoteDataManager {
    if (!NoteDataManager.instance) {
      NoteDataManager.instance = new NoteDataManager();
    }
    return NoteDataManager.instance;
  }

  /**
   * Initialize preferences store
   */
  async init(context: Context): Promise<void> {
    try {
      this.preferencesStore = await preferences.getPreferences(context, this.STORE_NAME);
    } catch (error) {
      console.error('Failed to initialize preferences store:', error);
      throw new Error('Failed to initialize preferences store');
    }
  }

  /**
   * Save all notes to local storage
   */
  async saveNotes(notes: Note[]): Promise<void> {
    if (!this.preferencesStore) {
      throw new Error('Preferences store not initialized');
    }
    
    try {
      const notesJson = notes.map(note => note.toJson());
      await this.preferencesStore.put(this.NOTES_KEY, JSON.stringify(notesJson));
      await this.preferencesStore.flush();
    } catch (error) {
      console.error('Failed to save notes:', error);
      throw new Error('Failed to save notes');
    }
  }

  /**
   * Load all notes from local storage
   */
  async loadNotes(): Promise<Note[]> {
    if (!this.preferencesStore) {
      throw new Error('Preferences store not initialized');
    }

    try {
      const notesData = await this.preferencesStore.get(this.NOTES_KEY, '[]') as string;
      const notesJson = JSON.parse(notesData) as NoteJson[];
      return notesJson.map(json => Note.fromJson(json));
    } catch (error) {
      console.error('Failed to load notes:', error);
      return [];
    }
  }

  /**
   * Save single note
   */
  async saveNote(note: Note): Promise<void> {
    const notes = await this.loadNotes();
    const existingIndex = notes.findIndex(n => n.id === note.id);
    
    if (existingIndex >= 0) {
      notes[existingIndex] = note;
    } else {
      notes.push(note);
    }
    
    await this.saveNotes(notes);
  }

  /**
   * Soft delete note by ID
   */
  async softDeleteNote(noteId: string): Promise<void> {
    const note = await this.getNoteById(noteId);
    if (!note) {
      throw new Error('笔记不存在或已被删除');
    }

    if (note.isDeleted) {
      throw new Error('笔记已在回收站中');
    }

    note.softDelete();
    await this.saveNote(note);
  }

  /**
   * Restore note from trash by ID
   */
  async restoreNote(noteId: string): Promise<void> {
    const note = await this.getNoteById(noteId);
    if (note) {
      note.restore();
      await this.saveNote(note);
    }
  }

  /**
   * Permanently delete note by ID
   */
  async deleteNote(noteId: string): Promise<void> {
    const notes = await this.loadNotes();
    const filteredNotes = notes.filter(note => note.id !== noteId);
    await this.saveNotes(filteredNotes);
  }

  /**
   * Get active notes (not deleted)
   */
  async getActiveNotes(): Promise<Note[]> {
    const notes = await this.loadNotes();
    return notes.filter(note => !note.isDeleted);
  }

  /**
   * Get deleted notes (in trash)
   */
  async getDeletedNotes(): Promise<Note[]> {
    const notes = await this.loadNotes();
    return notes.filter(note => note.isDeleted);
  }

  /**
   * Get note by ID
   */
  async getNoteById(noteId: string): Promise<Note | null> {
    const notes = await this.loadNotes();
    return notes.find(note => note.id === noteId) || null;
  }

  /**
   * Search active notes by keyword
   */
  async searchNotes(keyword: string): Promise<Note[]> {
    const notes = await this.getActiveNotes();
    if (!keyword.trim()) {
      return notes;
    }

    const lowerKeyword = keyword.toLowerCase();
    return notes.filter(note =>
      note.title.toLowerCase().includes(lowerKeyword) ||
      note.content.toLowerCase().includes(lowerKeyword)
    );
  }

  /**
   * Search notes by category
   */
  async searchNotesByCategory(category: string): Promise<Note[]> {
    const notes = await this.getActiveNotes();
    if (!category.trim()) {
      return notes;
    }

    return notes.filter(note => note.category === category);
  }

  /**
   * Search notes by tags
   */
  async searchNotesByTags(tags: string[]): Promise<Note[]> {
    const notes = await this.getActiveNotes();
    if (tags.length === 0) {
      return notes;
    }

    return notes.filter(note =>
      tags.some(tag => note.tags.includes(tag))
    );
  }

  /**
   * Search notes with filters
   */
  async searchNotesWithFilters(filters: SearchFilters): Promise<Note[]> {
    let notes = await this.getActiveNotes();

    // Filter by keyword
    if (filters.keyword?.trim()) {
      const lowerKeyword = filters.keyword.toLowerCase();
      notes = notes.filter(note =>
        note.title.toLowerCase().includes(lowerKeyword) ||
        note.content.toLowerCase().includes(lowerKeyword)
      );
    }

    // Filter by category
    if (filters.category?.trim()) {
      notes = notes.filter(note => note.category === filters.category);
    }

    // Filter by tags
    if (filters.tags && filters.tags.length > 0) {
      notes = notes.filter(note =>
        filters.tags!.some(tag => note.tags.includes(tag))
      );
    }

    return notes;
  }

  /**
   * Get active notes sorted by update time (newest first)
   */
  async getNotesOrderByUpdateTime(): Promise<Note[]> {
    const notes = await this.getActiveNotes();
    return notes.sort((a, b) => b.updateTime - a.updateTime);
  }

  /**
   * Get deleted notes sorted by delete time (newest first)
   */
  async getDeletedNotesOrderByDeleteTime(): Promise<Note[]> {
    const notes = await this.getDeletedNotes();
    return notes.sort((a, b) => b.deleteTime - a.deleteTime);
  }

  /**
   * Get all unique categories from notes
   */
  async getUsedCategories(): Promise<string[]> {
    const notes = await this.getActiveNotes();
    const categories = new Set<string>();
    notes.forEach(note => {
      if (note.category.trim()) {
        categories.add(note.category);
      }
    });
    return Array.from(categories);
  }

  /**
   * Get all unique tags from notes
   */
  async getUsedTags(): Promise<string[]> {
    const notes = await this.getActiveNotes();
    const tags = new Set<string>();
    notes.forEach(note => {
      note.tags.forEach(tag => {
        if (tag.trim()) {
          tags.add(tag);
        }
      });
    });
    return Array.from(tags).sort();
  }

  /**
   * Get notes count by category
   */
  async getNotesCountByCategory(): Promise<Record<string, number>> {
    const notes = await this.getActiveNotes();
    const countByCategory: Record<string, number> = {};

    notes.forEach(note => {
      const category = note.category || '未分类';
      countByCategory[category] = (countByCategory[category] || 0) + 1;
    });

    return countByCategory;
  }

  /**
   * Empty trash (permanently delete all deleted notes)
   */
  async emptyTrash(): Promise<void> {
    const notes = await this.loadNotes();
    const activeNotes = notes.filter(note => !note.isDeleted);
    await this.saveNotes(activeNotes);
  }

  /**
   * Clear all notes
   */
  async clearAllNotes(): Promise<void> {
    await this.saveNotes([]);
  }
}