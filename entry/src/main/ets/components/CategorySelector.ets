import { Category, CategoryManager } from '../service/CategoryManager';
import { Context } from '@ohos.abilityAccessCtrl';
import router from '@ohos.router';
import { ThemeManager, ThemeMode } from '../service/ThemeManager';

/**
 * 主题颜色接口
 */
interface ComponentThemeColors {
  background: string;
  card: string;
  text: string;
  textSecondary: string;
  border: string;
}

/**
 * Category Selector Component
 * 用于选择笔记分类的组件
 */

@Component
export struct CategorySelector {
  @Watch('onSelectedCategoryChange') @State selectedCategory: string = '';
  @Prop editable: boolean = true;
  onCategoryChange?: (category: string) => void;

  @State categories: Category[] = [];
  @State showAddCategory: boolean = false;
  @State newCategoryName: string = '';
  @State selectedColor: string = '#007DFF';
  @State showColorPicker: boolean = false;
  @State currentTheme: ThemeMode = ThemeMode.AUTO;
  @State themeColors: ComponentThemeColors = {
    background: '#F1F3F5',
    card: '#FFFFFF',
    text: '#182431',
    textSecondary: '#99A2AD',
    border: '#E1E4E8'
  };
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.initTheme();
    this.loadCategories();
  }

  onSelectedCategoryChange() {
    this.onCategoryChange?.(this.selectedCategory);
  }

  build() {
    Column() {
      // 当前选择的分类
      Row() {
        Text('分类')
          .fontSize(14)
          .fontColor(this.themeColors.text)
          .width(60)

        if (this.editable) {
          Select(this.getCategoryOptions())
            .selected(this.getCategoryIndex(this.selectedCategory))
            .value(this.getCategoryDisplay(this.selectedCategory))
            .font({ size: 14 })
            .fontColor('#007DFF')
            .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#2A2A2A' : '#F5F5F5')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .onSelect((index: number) => {
              if (index === 0) {
                this.selectedCategory = '';
              } else {
                this.selectedCategory = this.categories[index - 1]?.name || '';
              }
            })
        } else {
          Text(this.getCategoryDisplay(this.selectedCategory))
            .fontSize(14)
            .fontColor('#007DFF')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        }

        Blank()

        if (this.editable) {
          Button('管理')
            .fontSize(12)
            .height(32)
            .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#2A2A2A' : '#F0F0F0')
            .fontColor('#007DFF')
            .onClick(() => {
              this.navigateToCategoryManagement();
            })
        }
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16 })

      Divider()
        .color(this.themeColors.border)
        .strokeWidth(0.5)
        .margin({ top: 8, bottom: 8 })

      // 分类预览
      if (this.selectedCategory) {
        Row() {
          Text('当前分类')
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)

          Blank()

          Row() {
            Circle({ width: 8, height: 8 })
              .fill(this.getCategoryColor(this.selectedCategory))
              .margin({ right: 6 })

            Text(this.selectedCategory)
              .fontSize(12)
              .fontColor(this.themeColors.text)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#1A1A1A' : '#F8F8F8')
        .borderRadius(6)
        .margin({ bottom: 12 })
      }

      // 添加新分类
      if (this.editable && this.showAddCategory) {
        Column() {
          Text('创建新分类')
            .fontSize(14)
            .fontColor(this.themeColors.text)
            .width('100%')
            .margin({ bottom: 12 })
            .textAlign(TextAlign.Start)

          // 分类名称输入
          TextInput({ placeholder: '分类名称' })
            .fontSize(14)
            .width('100%')
            .height(44)
            .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#2A2A2A' : '#F5F5F5')
            .borderRadius(8)
            .margin({ bottom: 12 })
            .onChange((value: string) => {
              this.newCategoryName = value;
            })

          // 颜色选择
          Row() {
            Text('颜色')
              .fontSize(14)
              .fontColor(this.themeColors.text)
              .width(60)

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.getPredefinedColors(), (color: string) => {
                Circle({ width: 24, height: 24 })
                  .fill(color)
                  .margin({ right: 8, bottom: 8 })
                  .border({
                    width: this.selectedColor === color ? 2 : 0,
                    color: this.themeColors.text
                  })
                  .onClick(() => {
                    this.selectedColor = color;
                  })
              })
            }
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 操作按钮
          Row() {
            Button('取消')
              .fontSize(14)
              .height(36)
              .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#2A2A2A' : '#F0F0F0')
              .fontColor('#666666')
              .flexGrow(1)
              .margin({ right: 8 })
              .onClick(() => {
                this.showAddCategory = false;
                this.resetForm();
              })

            Button('创建')
              .fontSize(14)
              .height(36)
              .backgroundColor('#007DFF')
              .fontColor(Color.White)
              .flexGrow(1)
              .onClick(() => {
                this.createNewCategory();
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#1A1A1A' : '#FAFAFA')
        .borderRadius(8)
        .margin({ top: 12 })
      }

      // 添加分类按钮
      if (this.editable && !this.showAddCategory) {
        Button('+ 添加新分类')
          .fontSize(14)
          .height(40)
          .width('100%')
          .backgroundColor('#F0F8FF')
          .fontColor('#007DFF')
          .border({ width: 1, color: '#007DFF', radius: 8 })
          .onClick(() => {
            this.showAddCategory = true;
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.themeColors.card)
    .borderRadius(8)
  }

  /**
   * 加载分类列表 - CategorySelector主组件
   */
  private async loadCategories(): Promise<void> {
    try {
      const categoryManager = CategoryManager.getInstance();

      // 如果没有初始化，先进行初始化
      if (!categoryManager.getCategories().length) {
        try {
          await categoryManager.initialize(getContext(this) as Context);
        } catch (initError) {
          console.warn('CategoryManager already initialized or initialization failed:', initError);
        }
      }

      this.categories = categoryManager.getCategories();
    } catch (error) {
      console.error('加载分类失败:', error);
    }
  }

  /**
   * 获取分类选项列表
   */
  private getCategoryOptions(): Array<SelectOption> {
    const options: Array<SelectOption> = [
      { value: '', icon: '' }
    ];

    this.categories.forEach(category => {
      options.push({
        value: category.name,
        icon: ''
      });
    });

    return options;
  }

  /**
   * 获取分类索引
   */
  private getCategoryIndex(category: string): number {
    if (!category) return 0;
    const index = this.categories.findIndex(cat => cat.name === category);
    return index >= 0 ? index + 1 : 0; // +1 because index 0 is "未分类"
  }

  /**
   * 获取分类显示文本
   */
  private getCategoryDisplay(category: string): string {
    if (!category) {
      return '未分类';
    }
    return category;
  }

  /**
   * 获取分类颜色
   */
  private getCategoryColor(category: string): string {
    const foundCategory = this.categories.find(cat => cat.name === category);
    return foundCategory?.color || '#007DFF';
  }

  /**
   * 获取预定义颜色列表
   */
  private getPredefinedColors(): string[] {
    return [
      '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
      '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E2',
      '#F8B739', '#52C234', '#FF6F61', '#6B5B95', '#88D8B0'
    ];
  }

  /**
   * 初始化主题
   */
  private async initTheme(): Promise<void> {
    try {
      await this.themeManager.init(getContext(this) as Context);
      this.currentTheme = this.themeManager.getCurrentThemeSync();
      this.themeColors = this.getThemeColors();

      // 设置主题监听
      this.themeManager.onThemeChange((theme: ThemeMode) => {
        this.currentTheme = theme;
        this.themeColors = this.getThemeColors();
      });
    } catch (error) {
      console.error('Failed to initialize theme in CategorySelector:', error);
    }
  }

  /**
   * 获取主题颜色
   */
  private getThemeColors(): ComponentThemeColors {
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

  /**
   * 导航到分类管理页面
   */
  private navigateToCategoryManagement(): void {
    router.pushUrl({
      url: 'pages/CategoryPage'
    });
  }

  /**
   * 创建新分类
   */
  private async createNewCategory(): Promise<void> {
    const categoryName = this.newCategoryName.trim();

    if (!categoryName) {
      console.warn('分类名称不能为空');
      return;
    }

    // 检查分类名称是否已存在
    if (this.categories.some(cat => cat.name === categoryName)) {
      console.warn('分类名称已存在');
      return;
    }

    // 检查分类名称长度
    if (categoryName.length > 10) {
      console.warn('分类名称长度不能超过10个字符');
      return;
    }

    try {
      const categoryManager = CategoryManager.getInstance();
      const newCategory = new Category(categoryName, this.selectedColor);
      await categoryManager.addCategory(newCategory);

      // 重新加载分类列表
      await this.loadCategories();

      // 选择新创建的分类
      this.selectedCategory = categoryName;

      // 重置表单
      this.resetForm();
      this.showAddCategory = false;

      console.log('分类创建成功:', categoryName);
    } catch (error) {
      console.error('创建分类失败:', error);
    }
  }

  /**
   * 重置表单
   */
  private resetForm(): void {
    this.newCategoryName = '';
    this.selectedColor = '#007DFF';
  }
}

/**
 * 分类显示组件（只读）
 */
@Component
export struct CategoryDisplay {
  @Prop category: string = '';
  @Prop showColor: boolean = true;

  @State categories: Category[] = [];
  @State currentTheme: ThemeMode = ThemeMode.AUTO;
  @State themeColors: ComponentThemeColors = {
    background: '#F1F3F5',
    card: '#FFFFFF',
    text: '#182431',
    textSecondary: '#99A2AD',
    border: '#E1E4E8'
  };
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.initTheme();
    this.loadCategories();
  }

  build() {
    if (this.category) {
      Row() {
        if (this.showColor) {
          Circle({ width: 6, height: 6 })
            .fill(this.getCategoryColor(this.category))
            .margin({ right: 6 })
        }

        Text(this.category)
          .fontSize(12)
          .fontColor(this.themeColors.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(12)
      .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#2A2A2A' : '#F5F5F5')
    } else {
      Text('未分类')
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(12)
        .backgroundColor(this.currentTheme === ThemeMode.DARK ? '#1A1A1A' : '#FAFAFA')
    }
  }

  /**
   * 初始化主题
   */
  private async initTheme(): Promise<void> {
    try {
      await this.themeManager.init(getContext(this) as Context);
      this.currentTheme = this.themeManager.getCurrentThemeSync();
      this.themeColors = this.getThemeColors();

      // 设置主题监听
      this.themeManager.onThemeChange((theme: ThemeMode) => {
        this.currentTheme = theme;
        this.themeColors = this.getThemeColors();
      });
    } catch (error) {
      console.error('Failed to initialize theme in CategoryDisplay:', error);
    }
  }

  /**
   * 获取主题颜色
   */
  private getThemeColors(): ComponentThemeColors {
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

  /**
   * 加载分类列表
   */
  private async loadCategories(): Promise<void> {
    try {
      const categoryManager = CategoryManager.getInstance();
      this.categories = categoryManager.getCategories();
    } catch (error) {
      console.error('加载分类失败:', error);
    }
  }

  /**
   * 获取分类颜色
   */
  private getCategoryColor(category: string): string {
    const foundCategory = this.categories.find(cat => cat.name === category);
    return foundCategory?.color || '#007DFF';
  }
}