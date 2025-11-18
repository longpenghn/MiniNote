import router from '@ohos.router';
import { Category, CategoryManager, CategoryWithStats } from '../service/CategoryManager';
import { NoteDataManager } from '../service/NoteDataManager';
import { ThemeManager, ThemeMode } from '../service/ThemeManager';
import promptAction from '@ohos.promptAction';

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

/**
 * Category Management Page
 * 分类管理页面 - 基础版本
 */

@Entry
@ComponentV2
struct CategoryPage {
  @Local categories: CategoryWithStats[] = [];
  @Local isLoading: boolean = true;
  @Local currentTheme: ThemeMode = ThemeMode.AUTO;
  @Local updateFlag: number = 0;
  @Local themeColors: ThemeColors = {
    background: '#F5F5F5',
    card: '#FFFFFF',
    text: '#333333',
    textSecondary: '#666666',
    border: '#E0E0E0'
  };
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.initTheme();
    this.loadCategories();
  }

  private async initTheme(): Promise<void> {
    try {
      await this.themeManager.init(getContext(this));
      this.currentTheme = this.themeManager.getCurrentThemeSync();
      this.updateFlag = this.themeManager.getUpdateFlag();
      this.themeColors = this.getThemeColors(); // 初始化主题颜色

      // 设置主题监听
      this.themeManager.onThemeChange((theme: ThemeMode) => {
        this.currentTheme = theme;
        this.updateFlag = this.themeManager.getUpdateFlag();
        this.themeColors = this.getThemeColors(); // 更新主题颜色
      });
    } catch (error) {
      console.error('Failed to initialize theme:', error);
    }
  }

  /**
   * 加载分类数据
   */
  private async loadCategories(): Promise<void> {
    try {
      this.isLoading = true;
      const categoryManager = CategoryManager.getInstance();
      const dataManager = NoteDataManager.getInstance();

      const allCategories = categoryManager.getCategories();
      const categoryStats: CategoryWithStats[] = [];

      for (const category of allCategories) {
        const notes = await dataManager.searchNotesByCategory(category.name);
        const categoryWithStats: CategoryWithStats = new CategoryWithStats(category, notes.length);
        categoryStats.push(categoryWithStats);
      }

      this.categories = categoryStats;
      this.isLoading = false;
    } catch (error) {
      console.error('加载分类失败:', error);
      this.isLoading = false;
    }
  }

  /**
   * 获取主题颜色
   */
  private getThemeColors(): ThemeColors {
    switch (this.currentTheme) {
      case ThemeMode.DARK:
        return {
          background: '#000000',      // 纯黑背景
          card: '#1F1F1F',            // 深灰卡片背景
          text: '#FFFFFF',            // 白色主文字
          textSecondary: '#999999',   // 灰色次要文字
          border: '#333333'           // 深灰边框
        };
      case ThemeMode.LIGHT:
        return {
          background: '#F1F3F5',    // 浅灰背景（与其他页面一致）
          card: '#FFFFFF',            // 白色卡片
          text: '#182431',            // 深色主文字（系统推荐）
          textSecondary: '#99A2AD',   // 灰色次要文字
          border: '#E1E4E8'           // 浅灰边框
        };
      default:
        // AUTO 模式下使用浅色主题的默认配置
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
   * 显示分类操作菜单
   */
  private showCategoryActionMenu(category: CategoryWithStats): void {
    const canEdit = category.noteCount === 0; // 只有未使用的分类才能编辑

    if (canEdit) {
      AlertDialog.show({
        title: `删除分类 "${category.name}"`,
        message: '此分类暂未使用，可以安全删除。',
        primaryButton: {
          value: '取消',
          action: () => {}
        },
        secondaryButton: {
          value: '删除',
          fontColor: '#FF4444',
          action: () => {
            this.deleteCategory(category.name);
          }
        }
      });
    } else {
      AlertDialog.show({
        title: `分类 "${category.name}"`,
        message: `此分类包含 ${category.noteCount} 条笔记，无法删除。\n\n点击查看该分类的笔记。`,
        primaryButton: {
          value: '查看笔记',
          action: () => {
            this.viewCategoryNotes(category.name);
          }
        },
        secondaryButton: {
          value: '关闭',
          action: () => {}
        }
      });
    }
  }

  
  /**
   * 删除分类
   */
  private async deleteCategory(categoryName: string): Promise<void> {
    try {
      const categoryManager = CategoryManager.getInstance();
      const dataManager = NoteDataManager.getInstance();

      // 更新使用该分类的笔记
      const notes = await dataManager.searchNotesByCategory(categoryName);
      for (const note of notes) {
        note.updateCategory('');
        await dataManager.saveNote(note);
      }

      // 删除分类
      await categoryManager.deleteCategoryByName(categoryName);

      // 重新加载分类列表
      await this.loadCategories();

      promptAction.showToast({ message: '分类删除成功' });
      console.log('分类删除成功:', categoryName);
    } catch (error) {
      console.error('删除分类失败:', error);
      promptAction.showToast({ message: '删除失败' });
    }
  }

  
  /**
   * 查看分类笔记
   */
  private viewCategoryNotes(categoryName: string): void {
    // 替换主页并传递分类参数
    router.replaceUrl({
      url: 'pages/Index',
      params: {
        selectedCategory: categoryName
      }
    });
  }

  /**
   * 创建默认分类
   */
  private async createDefaultCategories(): Promise<void> {
    try {
      const categoryManager = CategoryManager.getInstance();
      const defaultCategories = [
        new Category('工作', '#FF6B6B'),
        new Category('学习', '#4ECDC4'),
        new Category('生活', '#45B7D1'),
        new Category('灵感', '#96CEB4'),
        new Category('待办', '#FFEAA7')
      ];

      for (const category of defaultCategories) {
        await categoryManager.addCategory(category);
      }

      await this.loadCategories();
      promptAction.showToast({ message: '默认分类创建成功' });
    } catch (error) {
      console.error('创建默认分类失败:', error);
      promptAction.showToast({ message: '创建失败' });
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor(this.themeColors.text)
          .onClick(() => {
            router.back();
          })

        Text('分类管理')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.text)
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.themeColors.card)

      // 分类列表
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 100 })
      } else if (this.categories.length === 0) {
        Column() {
          Text('暂无分类')
            .fontSize(16)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 100 })

          Text('点击创建默认分类')
            .fontSize(14)
            .fontColor('#007DFF')
            .margin({ top: 20 })
            .onClick(() => {
              this.createDefaultCategories();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          List() {
            ForEach(this.categories, (category: CategoryWithStats, index: number) => {
              ListItem() {
                this.CategoryItemBuilder(category, index, this.themeColors)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)

          // 底部操作提示
          Row() {
            Text('💡 提示：分类功能正在完善中')
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.themeColors.card)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }

  /**
   * 分类项构建器
   */
  @Builder
  CategoryItemBuilder(category: CategoryWithStats, index: number, colors: ThemeColors) {
    Row() {
      // 分类颜色
      Circle({ width: 16, height: 16 })
        .fill(category.color)
        .margin({ right: 12 })

      // 分类信息
      Column() {
        Text(category.name)
          .fontSize(16)
          .fontColor(this.themeColors.text)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${category.noteCount} 条笔记`)
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 状态指示
      if (category.noteCount > 0) {
        Text('使用中')
          .fontSize(12)
          .fontColor('#52C234')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#1A3A1A' : '#F0F9FF')
          .borderRadius(10)
      } else {
        Text('未使用')
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#2A2A2A' : '#F5F5F5')
          .borderRadius(10)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.themeColors.card)
    .border({ width: { bottom: 0.5 }, color: this.themeColors.border })
    .onClick(() => {
      console.log('点击分类:', category.name);
      // 可以添加跳转到该分类的笔记列表功能
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          this.showCategoryActionMenu(category);
        })
    )
  }
}