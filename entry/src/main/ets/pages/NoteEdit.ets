import { router } from '@kit.ArkUI';
import { Note } from '../model/Note';
import { NoteDataManager } from '../service/NoteDataManager';
import { ThemeManager, ThemeMode } from '../service/ThemeManager';
import { CategorySelector } from '../components/CategorySelector';
import { TagSelector } from '../components/TagSelector';
import { CategoryManager } from '../service/CategoryManager';

@Entry
@ComponentV2
struct NoteEdit {
  @Local content: string = '';
  @Local isNew: boolean = true;
  @Local noteId: string = '';
  @Local isSaving: boolean = false;
  @Local lastSaveTime: number = 0;
  @Local currentTheme: ThemeMode = ThemeMode.AUTO;
  @Local updateFlag: number = 0;
  @Local selectedCategory: string = '';
  @Local selectedTags: string[] = [];
  @Local availableTags: string[] = [];
  @Local showMetadata: boolean = false;
  private dataManager: NoteDataManager = NoteDataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private saveTimer: number = -1;
  private currentNote: Note | null = null;

  async aboutToAppear(): Promise<void> {
    await this.initData();
    await this.loadNote();
    this.setupThemeListener();
  }

  aboutToDisappear(): void {
    this.saveNote();
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
    }
    this.cleanupThemeListener();
  }

  private setupThemeListener(): void {
    this.themeManager.onThemeChange((theme: ThemeMode) => {
      this.currentTheme = theme;
      this.updateFlag = this.themeManager.getUpdateFlag(); // 触发UI更新
    });
  }

  private cleanupThemeListener(): void {
    // Cleanup theme listeners
  }

  async initData(): Promise<void> {
    try {
      await this.dataManager.init(getContext(this));
      await this.themeManager.init(getContext(this));
      this.currentTheme = this.themeManager.getCurrentThemeSync();
      this.updateFlag = this.themeManager.getUpdateFlag();

      // 初始化分类管理器
      const categoryManager = CategoryManager.getInstance();
      await categoryManager.initialize(getContext(this));

      // 加载可用标签
      await this.loadAvailableTags();

      // Get parameters from router
      const params = router.getParams() as Record<string, Object>;
      this.isNew = params?.isNew as boolean ?? true;
      this.noteId = params?.noteId as string ?? '';
    } catch (error) {
      console.error('Failed to initialize managers:', error);
    }
  }

  async loadNote(): Promise<void> {
    if (!this.isNew && this.noteId) {
      try {
        this.currentNote = await this.dataManager.getNoteById(this.noteId);
        if (this.currentNote) {
          this.content = this.currentNote.content;
          this.selectedCategory = this.currentNote.category;
          this.selectedTags = [...this.currentNote.tags];
        }
      } catch (error) {
        console.error('Failed to load note:', error);
      }
    } else {
      // Create new note
      this.currentNote = new Note();
    }
  }

  /**
   * 加载可用标签
   */
  private async loadAvailableTags(): Promise<void> {
    try {
      this.availableTags = await this.dataManager.getUsedTags();
    } catch (error) {
      console.error('Failed to load available tags:', error);
    }
  }

  onContentChange(value: string): void {
    this.content = value;
    this.scheduleAutoSave();
  }

  scheduleAutoSave(): void {
    if (this.saveTimer !== -1) {
      clearTimeout(this.saveTimer);
    }
    
    // Auto save after 1 second of no typing
    this.saveTimer = setTimeout(() => {
      this.saveNote();
    }, 1000);
  }

  async saveNote(): Promise<void> {
    if (!this.currentNote) {
      return;
    }

    // Don't save empty notes for new notes
    if (this.isNew && !this.content.trim()) {
      return;
    }

    try {
      this.isSaving = true;
      this.currentNote.updateContent(this.content);
      this.currentNote.updateCategory(this.selectedCategory);

      // 更新标签
      this.currentNote.tags = [...this.selectedTags];

      await this.dataManager.saveNote(this.currentNote);
      this.lastSaveTime = Date.now();

      // Update noteId if it's a new note
      if (this.isNew) {
        this.noteId = this.currentNote.id;
        this.isNew = false;
      }

      // 重新加载可用标签
      await this.loadAvailableTags();
    } catch (error) {
      console.error('Failed to save note:', error);
    } finally {
      this.isSaving = false;
    }
  }

  async onDeleteNote(): Promise<void> {
    if (!this.currentNote || this.isNew) {
      return;
    }

    try {
      await this.dataManager.softDeleteNote(this.currentNote.id);
      router.back();
    } catch (error) {
      console.error('Failed to delete note:', error);
    }
  }

  /**
   * 切换元数据面板显示
   */
  onToggleMetadata(): void {
    this.showMetadata = !this.showMetadata;
  }

  /**
   * 处理分类变更
   */
  onCategoryChange(category: string): void {
    this.selectedCategory = category;
    this.scheduleAutoSave();
  }

  /**
   * 处理标签变更
   */
  onTagsChange(tags: string[]): void {
    this.selectedTags = tags;
    this.scheduleAutoSave();
  }

  async onBack(): Promise<void> {
    await this.saveNote();
    router.back();
  }

  async onToggleTheme(): Promise<void> {
    try {
      console.log('Toggling theme in NoteEdit...');
      await this.themeManager.toggleTheme();
      // 立即更新UI状态
      this.currentTheme = this.themeManager.getCurrentThemeSync();
      this.updateFlag = this.themeManager.getUpdateFlag();
      console.log('Theme toggled to:', this.currentTheme);
    } catch (error) {
      console.error('Failed to toggle theme:', error);
    }
  }

  showDeleteDialog(): void {
    AlertDialog.show({
      title: '删除笔记',
      message: '确定要删除这条笔记吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: $r('sys.color.ohos_id_color_warning'),
        action: () => {
          this.onDeleteNote();
        }
      }
    });
  }

  getTitle(): string {
    if (!this.content) {
      return this.isNew ? '新建笔记' : 'Untitled';
    }
    const firstLine = this.content.split('\n')[0].trim();
    return firstLine || (this.isNew ? '新建笔记' : 'Untitled');
  }

  getSaveStatusText(): string {
    if (this.isSaving) {
      return '保存中...';
    }
    if (this.lastSaveTime > 0) {
      const now = Date.now();
      const diffSeconds = Math.floor((now - this.lastSaveTime) / 1000);
      if (diffSeconds < 60) {
        return '已保存';
      } else {
        return `${Math.floor(diffSeconds / 60)}分钟前保存`;
      }
    }
    return '';
  }

  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Text('‹')
            .fontSize(24)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontWeight(FontWeight.Bold)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.onBack())
        .stateStyles({
          pressed: {
            .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
          }
        })
        .animation({
          duration: 150,
          curve: Curve.EaseInOut
        })

        Column() {
          Text(this.getTitle())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.getSaveStatusText()) {
            Text(this.getSaveStatusText())
              .fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Row() {
          // 元数据按钮
          Button() {
            Text('🏷️')
              .fontSize(20)
              .fontColor(this.showMetadata ? '#007DFF' : '#333333')
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(Color.Transparent)
          .margin({ right: 8 })
          .onClick(() => this.onToggleMetadata())
          .stateStyles({
            pressed: {
              .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
              .scale({ x: 0.95, y: 0.95 })
            }
          })

          // Theme toggle button
          Button() {
            Column({ space: 2 }) {
              Text(this.themeManager.getThemeIcon(this.currentTheme))
                .fontSize(16)
              Text(this.themeManager.getThemeDisplayText(this.currentTheme))
                .fontSize(8)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .alignItems(HorizontalAlign.Center)
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onToggleTheme())
          .stateStyles({
            pressed: {
              .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
              .scale({ x: 0.95, y: 0.95 })
            }
          })
          .animation({
            duration: 150,
            curve: Curve.EaseInOut
          })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      // 元数据面板
      if (this.showMetadata) {
        Column() {
          Text('笔记分类')
            .fontSize(16)
            .fontColor(this.currentTheme === ThemeMode.DARK ? '#FFFFFF' : '#333333')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 12 })
            .width('100%')
            .textAlign(TextAlign.Start)

          CategorySelector({
            selectedCategory: this.selectedCategory,
            editable: true,
            onCategoryChange: (category: string) => {
              this.onCategoryChange(category);
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#1F1F1F' : '#FAFAFA')
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 16 })
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      }

      // Content Editor
      TextArea({
        placeholder: '开始记录你的想法...',
        text: $$this.content
      })
        .width('100%')
        .layoutWeight(1)
        .padding(16)
        .fontSize(16)
        .lineHeight(26)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .placeholderColor($r('sys.color.ohos_id_color_text_tertiary'))
        .placeholderFont({
          size: 16,
          style: FontStyle.Normal
        })
        .onChange((value: string) => this.onContentChange(value))
        .onFocus(() => {
          // Auto focus and show keyboard
        })

      // Bottom padding for better UX
      Row()
        .width('100%')
        .height(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}