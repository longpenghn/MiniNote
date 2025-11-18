import router from '@ohos.router';
import { Note } from '../model/Note';
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
 * Trash Page - 回收站页面
 * 显示已删除的笔记，支持恢复和永久删除
 */

@Entry
@ComponentV2
struct TrashPage {
  @Local deletedNotes: Note[] = [];
  @Local isLoading: boolean = true;
  @Local currentTheme: ThemeMode = ThemeMode.AUTO;
  @Local themeColors: ThemeColors = {
    background: '#F1F3F5',
    card: '#FFFFFF',
    text: '#182431',
    textSecondary: '#99A2AD',
    border: '#E1E4E8'
  };
  private themeManager: ThemeManager = ThemeManager.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.initTheme();
    this.loadDeletedNotes();
  }

  onPageShow(): void {
    this.loadDeletedNotes();
  }

  /**
   * 初始化主题
   */
  private async initTheme(): Promise<void> {
    try {
      await this.themeManager.init(getContext(this));
      this.currentTheme = this.themeManager.getCurrentThemeSync();
      this.themeColors = this.getThemeColors();

      // 设置主题监听
      this.themeManager.onThemeChange((theme: ThemeMode) => {
        this.currentTheme = theme;
        this.themeColors = this.getThemeColors();
      });
    } catch (error) {
      console.error('Failed to initialize theme in TrashPage:', error);
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

  /**
   * 加载已删除的笔记
   */
  private async loadDeletedNotes(): Promise<void> {
    try {
      this.isLoading = true;
      const dataManager = NoteDataManager.getInstance();
      this.deletedNotes = await dataManager.getDeletedNotesOrderByDeleteTime();
      this.isLoading = false;
    } catch (error) {
      console.error('加载回收站失败:', error);
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(this.themeColors.text)
          .onClick(() => {
            router.back();
          })

        Text('回收站')
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

      // 笔记列表
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 100 })
      } else if (this.deletedNotes.length === 0) {
        Column() {
          Image($r('app.media.ic_trash_empty'))
            .width(64)
            .height(64)
            .fillColor('#CCCCCC')
            .margin({ bottom: 16 })

          Text('回收站为空')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.deletedNotes, (note: Note, index: number) => {
            ListItem() {
              this.TrashNoteItemBuilder(note, index)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)

        // 底部操作栏
        Row() {
          Button('清空回收站')
            .fontSize(16)
            .height(48)
            .backgroundColor('#FF4444')
            .fontColor(Color.White)
            .width('100%')
            .margin({ left: 16, right: 16, bottom: 16 })
            .onClick(() => {
              this.clearTrash();
            })
        }
        .width('100%')
        .backgroundColor(Color.Transparent)
        .border({ width: { top: 0.5 }, color: '#E0E0E0' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }

  /**
   * 回收站笔记项构建器
   */
  @Builder
  TrashNoteItemBuilder(note: Note, index: number) {
    Row() {
      // 笔记信息
      Column() {
        Text(note.title)
          .fontSize(16)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(note.getPreview())
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4 })
          .textAlign(TextAlign.Start)

        Text(`${this.formatDateTime(note.deleteTime)} 删除`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 操作按钮
      Row() {
        Button('恢复')
          .fontSize(14)
          .height(36)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .margin({ right: 8 })
          .onClick(() => {
            this.restoreNote(note.id);
          })

        Button('删除')
          .fontSize(14)
          .height(36)
          .backgroundColor('#FF4444')
          .fontColor(Color.White)
          .onClick(() => {
            this.deleteNote(note.id);
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .onClick(() => {
      // 可以添加预览功能
      console.log('预览笔记:', note.title);
    })
  }

  /**
   * 格式化日期时间
   */
  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diffDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return `今天 ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`;
    } else if (diffDays === 1) {
      return `昨天 ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`;
    } else if (diffDays < 7) {
      return `${diffDays} 天前`;
    } else {
      return `${date.getMonth() + 1}/${date.getDate()}`;
    }
  }

  /**
   * 恢复单个笔记
   */
  private async restoreNote(noteId: string): Promise<void> {
    try {
      const dataManager = NoteDataManager.getInstance();
      await dataManager.restoreNote(noteId);
      await this.loadDeletedNotes(); // 重新加载列表
      promptAction.showToast({ message: '恢复成功' });
      console.log('笔记恢复成功:', noteId);
    } catch (error) {
      console.error('恢复笔记失败:', error);
      promptAction.showToast({ message: '恢复失败' });
    }
  }

  /**
   * 永久删除单个笔记
   */
  private async deleteNote(noteId: string): Promise<void> {
    try {
      const dataManager = NoteDataManager.getInstance();
      await dataManager.deleteNote(noteId);
      await this.loadDeletedNotes(); // 重新加载列表
      promptAction.showToast({ message: '删除成功' });
      console.log('笔记删除成功:', noteId);
    } catch (error) {
      console.error('删除笔记失败:', error);
      promptAction.showToast({ message: '删除失败' });
    }
  }

  /**
   * 清空回收站
   */
  private async clearTrash(): Promise<void> {
    try {
      const dataManager = NoteDataManager.getInstance();
      await dataManager.emptyTrash();
      await this.loadDeletedNotes(); // 重新加载列表
      promptAction.showToast({ message: '回收站已清空' });
      console.log('回收站清空成功');
    } catch (error) {
      console.error('清空回收站失败:', error);
      promptAction.showToast({ message: '清空失败' });
    }
  }
}