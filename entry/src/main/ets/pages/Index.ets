import { router } from '@kit.ArkUI';
import { Note } from '../model/Note';
import { NoteDataManager, SearchFilters } from '../service/NoteDataManager';
import { ThemeManager, ThemeMode } from '../service/ThemeManager';
import { CategoryManager } from '../service/CategoryManager';
import { CategoryDisplay } from '../components/CategorySelector';
import { TagDisplay as SimpleTagDisplay } from '../components/TagSelector';

/**
 * 主题颜色接口
 */
interface ThemeColors {
  background: string;
  card: string;
  text: string;
  textSecondary: string;
  border: string;
}

@Entry
@ComponentV2
struct Index {
  @Local notes: Note[] = [];
  @Local searchKeyword: string = '';
  @Local isLoading: boolean = true;
  @Local currentTheme: ThemeMode = ThemeMode.AUTO;
  @Local updateFlag: number = 0;
  @Local selectedCategory: string = '';
  @Local availableCategories: string[] = [];
  @Local availableTags: string[] = [];
  @Local showFilterOptions: boolean = false;
  @Local themeColors: ThemeColors = {
    background: '#F1F3F5',
    card: '#FFFFFF',
    text: '#182431',
    textSecondary: '#99A2AD',
    border: '#E1E4E8'
  };
  private dataManager: NoteDataManager = NoteDataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private categoryManager: CategoryManager = CategoryManager.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.initData();
    await this.loadNotes();
    this.setupThemeListener();
  }

  async onPageShow(): Promise<void> {
    // Refresh notes when page becomes visible (e.g., returning from edit page)
    await this.loadNotes();
    // Update current theme state
    this.currentTheme = this.themeManager.getCurrentThemeSync();
    this.updateFlag = this.themeManager.getUpdateFlag();
    this.themeColors = this.getThemeColors();

    // Check if returning from category page with a selected category
    const params = router.getParams() as Record<string, Object>;
    if (params?.selectedCategory && typeof params.selectedCategory === 'string') {
      this.selectedCategory = params.selectedCategory;
      this.showFilterOptions = true; // Show filter options if category is selected
      await this.loadNotes(); // Reload notes with category filter
    }
  }

  aboutToDisappear(): void {
    this.cleanupThemeListener();
  }

  private setupThemeListener(): void {
    this.themeManager.onThemeChange((theme: ThemeMode) => {
      this.currentTheme = theme;
      this.updateFlag = this.themeManager.getUpdateFlag(); // 触发UI更新
      this.themeColors = this.getThemeColors();
    });
  }

  private cleanupThemeListener(): void {
    // Cleanup theme listeners
  }

  async initData(): Promise<void> {
    try {
      await this.dataManager.init(getContext(this));
      await this.themeManager.init(getContext(this));
      await this.categoryManager.initialize(getContext(this));
      this.currentTheme = this.themeManager.getCurrentThemeSync();
      this.updateFlag = this.themeManager.getUpdateFlag();
      this.themeColors = this.getThemeColors();
    } catch (error) {
      console.error('Failed to initialize managers:', error);
    }
  }

  /**
   * 获取主题颜色
   */
  private getThemeColors(): ThemeColors {
    switch (this.currentTheme) {
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

  async loadNotes(): Promise<void> {
    try {
      this.isLoading = true;

      // 加载筛选选项
      await this.loadFilterOptions();

      // 根据筛选条件加载笔记
      if (this.searchKeyword.trim() || this.selectedCategory) {
        const filters: SearchFilters = {
          keyword: this.searchKeyword.trim(),
          category: this.selectedCategory
        };
        this.notes = await this.dataManager.searchNotesWithFilters(filters);
      } else {
        this.notes = await this.dataManager.getNotesOrderByUpdateTime();
      }
    } catch (error) {
      console.error('Failed to load notes:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 加载筛选选项
   */
  private async loadFilterOptions(): Promise<void> {
    try {
      this.availableCategories = await this.dataManager.getUsedCategories();
      this.availableTags = await this.dataManager.getUsedTags();
    } catch (error) {
      console.error('Failed to load filter options:', error);
    }
  }

  async onSearch(): Promise<void> {
    await this.loadNotes();
  }

  onCreateNote(): void {
    router.pushUrl({
      url: 'pages/NoteEdit',
      params: { isNew: true }
    });
  }

  onEditNote(note: Note): void {
    router.pushUrl({
      url: 'pages/NoteEdit',
      params: { 
        isNew: false,
        noteId: note.id 
      }
    });
  }

  async onDeleteNote(noteId: string): Promise<void> {
    try {
      await this.dataManager.softDeleteNote(noteId);
      await this.loadNotes();
    } catch (error) {
      console.error('Failed to delete note:', error);
    }
  }

  /**
   * 跳转到分类管理页面
   */
  onManageCategories(): void {
    router.pushUrl({
      url: 'pages/CategoryPage'
    });
  }

  /**
   * 跳转到回收站页面
   */
  onOpenTrash(): void {
    router.pushUrl({
      url: 'pages/TrashPage'
    });
  }

  /**
   * 切换筛选选项显示
   */
  onToggleFilterOptions(): void {
    this.showFilterOptions = !this.showFilterOptions;
  }

  /**
   * 选择分类筛选
   */
  onSelectCategory(category: string): void {
    this.selectedCategory = category;
    this.loadNotes();
  }

  /**
   * 清除所有筛选条件
   */
  onClearFilters(): void {
    this.searchKeyword = '';
    this.selectedCategory = '';
    this.loadNotes();
  }

  async onToggleTheme(): Promise<void> {
    try {
      console.log('Toggling theme...');
      await this.themeManager.toggleTheme();
      // 立即更新UI状态
      this.currentTheme = this.themeManager.getCurrentThemeSync();
      this.updateFlag = this.themeManager.getUpdateFlag();
      console.log('Theme toggled to:', this.currentTheme);
    } catch (error) {
      console.error('Failed to toggle theme:', error);
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diffTime = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
    } else if (diffDays === 1) {
      return '昨天';
    } else if (diffDays < 7) {
      return `${diffDays}天前`;
    } else {
      return date.toLocaleDateString('zh-CN', { month: '2-digit', day: '2-digit' });
    }
  }

  @Builder
  NoteItem(note: Note) {
    Row() {
      Column({ space: 8 }) {
        // 标题和分类
        Row() {
          Text(note.title || 'Untitled')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .textAlign(TextAlign.Start)

          if (note.category) {
            CategoryDisplay({ category: note.category, showColor: true })
          }
        }
        .width('100%')

        if (note.getPreview()) {
          Text(note.getPreview())
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Start)
        }

        // 标签显示（简化版）
        if (note.tags.length > 0) {
          Text(note.tags.slice(0, 3).join(', '))
            .fontSize(12)
            .fontColor('#007DFF')
            .margin({ top: 4 })
        }

        // 时间信息
        Text(this.formatTime(note.updateTime))
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(18)
        .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .borderRadius(12)
    .border({
      width: 1,
      color: $r('sys.color.ohos_id_color_list_separator')
    })
    .onClick(() => this.onEditNote(note))
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          AlertDialog.show({
            title: '删除笔记',
            message: '确定要将这条笔记移到回收站吗？',
            primaryButton: {
              value: '取消',
              action: () => {}
            },
            secondaryButton: {
              value: '删除',
              fontColor: $r('sys.color.ohos_id_color_warning'),
              action: () => {
                this.onDeleteNote(note.id);
              }
            }
          });
        })
    )
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('极简笔记')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)

        Row() {
          // 分类管理按钮
          Button() {
            Text('📁')
              .fontSize(20)
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onManageCategories())
          .margin({ right: 8 })
          .stateStyles({
            pressed: {
              .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
              .scale({ x: 0.95, y: 0.95 })
            }
          })

          // 回收站按钮
          Button() {
            Text('🗑️')
              .fontSize(20)
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onOpenTrash())
          .margin({ right: 8 })
          .stateStyles({
            pressed: {
              .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
              .scale({ x: 0.95, y: 0.95 })
            }
          })

          // Theme toggle button
          Button() {
            Column({ space: 4 }) {
              Text(this.themeManager.getThemeIcon(this.currentTheme))
                .fontSize(20)
              Text(this.themeManager.getThemeDisplayText(this.currentTheme))
                .fontSize(10)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .alignItems(HorizontalAlign.Center)
          }
          .width(56)
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

      // Search and Filter Bar
      Column() {
        // Search Row
        Row() {
          TextInput({ placeholder: '搜索笔记...', text: $$this.searchKeyword })
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .padding({ left: 16, right: 16 })
            .fontSize(14)
            .onSubmit(() => this.onSearch())
            .onChange(() => this.onSearch())

          if (this.searchKeyword) {
            Button('清除')
              .fontSize(14)
              .height(40)
              .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
              .margin({ left: 8 })
              .onClick(() => {
                this.searchKeyword = '';
                this.onSearch();
              })
          }

          // 筛选按钮
          Button() {
            Text('🔍')
              .fontSize(20)
              .fontColor(this.selectedCategory ? '#007DFF' : '#333333')
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(Color.Transparent)
          .margin({ left: 8 })
          .onClick(() => this.onToggleFilterOptions())
          .stateStyles({
            pressed: {
              .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
              .scale({ x: 0.95, y: 0.95 })
            }
          })
        }
        .width('100%')

        // 筛选选项
        if (this.showFilterOptions) {
          Column() {
            // 当前筛选条件
            if (this.searchKeyword.trim() || this.selectedCategory) {
              Row() {
                Text('当前筛选:')
                  .fontSize(12)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .margin({ right: 8 })

                if (this.searchKeyword.trim()) {
                  Text(`关键词: ${this.searchKeyword}`)
                    .fontSize(12)
                    .fontColor($r('sys.color.ohos_id_color_emphasize'))
                    .margin({ right: 8 })
                }

                if (this.selectedCategory) {
                  Text(`分类: ${this.selectedCategory}`)
                    .fontSize(12)
                    .fontColor($r('sys.color.ohos_id_color_emphasize'))
                    .margin({ right: 8 })
                }

                Blank()

                Button('清除')
                  .fontSize(12)
                  .height(24)
                  .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#2A2A2A' : '#F5F5F5')
                  .fontColor(this.themeColors.textSecondary)
                  .onClick(() => this.onClearFilters())
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#1A1A1A' : '#F8F8F8')
              .borderRadius(8)
              .margin({ top: 8 })
            }

            // 分类筛选
            if (this.availableCategories.length > 0) {
              Column() {
                Text('分类筛选')
                  .fontSize(14)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .width('100%')
                  .margin({ bottom: 8 })
                  .textAlign(TextAlign.Start)

                Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
                  // 全部选项
                  Text('全部')
                    .fontSize(14)
                    .fontColor(!this.selectedCategory ? Color.White : $r('sys.color.ohos_id_color_emphasize'))
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .backgroundColor(!this.selectedCategory ? $r('sys.color.ohos_id_color_emphasize') : '#F0F0F0')
                    .margin({ right: 8, bottom: 8 })
                    .onClick(() => this.onSelectCategory(''))

                  ForEach(this.availableCategories, (category: string) => {
                    Text(category)
                      .fontSize(14)
                      .fontColor(this.selectedCategory === category ? Color.White : $r('sys.color.ohos_id_color_emphasize'))
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .borderRadius(16)
                      .backgroundColor(this.selectedCategory === category ? $r('sys.color.ohos_id_color_emphasize') : '#F0F0F0')
                      .margin({ right: 8, bottom: 8 })
                      .onClick(() => this.onSelectCategory(category))
                  })
                }
                .width('100%')
              }
              .width('100%')
              .margin({ top: 12 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.themeColors.card)
          .borderRadius(12)
          .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })

      // Notes List
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(32)
            .height(32)
            .color($r('sys.color.ohos_id_color_text_secondary'))
          
          Text('加载中...')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .height('60%')
        .justifyContent(FlexAlign.Center)
      } else if (this.notes.length === 0) {
        Column() {
          Text('📝')
            .fontSize(64)
            .opacity(0.6)

          Text(this.searchKeyword ? '没有找到相关笔记' : '还没有笔记\n点击右下角按钮开始记录')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .textAlign(TextAlign.Center)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('60%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.notes, (note: Note) => {
            ListItem() {
              this.NoteItem(note)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Auto)
      }

      // Floating Action Button
      Stack({ alignContent: Alignment.BottomEnd }) {
        Button() {
          Text('+')
            .fontSize(28)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
        .margin({ right: 16, bottom: 16 })
        .onClick(() => this.onCreateNote())
        .shadow({
          radius: 12,
          color: $r('sys.color.ohos_id_color_emphasize'),
          offsetX: 0,
          offsetY: 4
        })
        .stateStyles({
          pressed: {
            .scale({ x: 0.95, y: 0.95 })
            .shadow({
              radius: 8,
              color: $r('sys.color.ohos_id_color_emphasize'),
              offsetX: 0,
              offsetY: 2
            })
          },
          normal: {
            .scale({ x: 1.0, y: 1.0 })
            .shadow({
              radius: 12,
              color: $r('sys.color.ohos_id_color_emphasize'),
              offsetX: 0,
              offsetY: 4
            })
          }
        })
        .animation({
          duration: 150,
          curve: Curve.EaseInOut
        })
      }
      .width('100%')
      .height(80)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}