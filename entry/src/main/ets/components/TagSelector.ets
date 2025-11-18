/**
 * Tag Selector Component
 * 用于选择和管理笔记标签的组件
 */

@ComponentV2
export struct TagSelector {
  @Watch('onSelectedTagsChange') selectedTags: string[] = [];
  @Prop availableTags: string[] = [];
  @Prop maxTags?: number = 10;
  @Prop editable: boolean = true;
  onTagsChange?: (tags: string[]) => void;

  @Local newTag: string = '';
  @Local showAddTag: boolean = false;

  onSelectedTagsChange() {
    this.onTagsChange?.(this.selectedTags);
  }

  build() {
    Column() {
      // 已选择的标签
      if (this.selectedTags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
          ForEach(this.selectedTags, (tag: string, index: number) => {
            Row() {
              Text(tag)
                .fontSize(14)
                .fontColor(Color.White)
                .margin({ left: 8, right: 4 })

              if (this.editable) {
                Image($r('app.media.ic_delete'))
                  .width(16)
                  .height(16)
                  .fillColor(Color.White)
                  .onClick(() => {
                    this.removeTag(index);
                  })
                  .margin({ right: 8 })
              }
            }
            .backgroundColor('#007DFF')
            .borderRadius(16)
            .height(32)
            .margin({ right: 8, bottom: 8 })
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          })
        }
        .width('100%')
        .margin({ bottom: 12 })
      }

      // 可用标签列表
      if (this.availableTags.length > 0) {
        Text('可用标签')
          .fontSize(12)
          .fontColor('#666666')
          .width('100%')
          .margin({ bottom: 8 })
          .textAlign(TextAlign.Start)

        Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
          ForEach(this.getAvailableTagsToAdd(), (tag: string) => {
            Text(tag)
              .fontSize(14)
              .fontColor('#007DFF')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .border({ width: 1, color: '#007DFF', radius: 16 })
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                if (this.editable) {
                  this.addTag(tag);
                }
              })
              .margin({ right: 8, bottom: 8 })
              .gesture(
                TapGesture()
                  .onAction(() => {
                    if (this.editable) {
                      this.addTag(tag);
                    }
                  })
              )
          })
        }
        .width('100%')
        .margin({ bottom: 12 })
      }

      // 添加新标签
      if (this.editable) {
        Row() {
          if (this.showAddTag) {
            TextInput({ placeholder: '输入新标签' })
              .fontSize(14)
              .width(120)
              .height(32)
              .backgroundColor('#F5F5F5')
              .borderRadius(16)
              .onChange((value: string) => {
                this.newTag = value;
              })
              .onSubmit(() => {
                this.createNewTag();
              })

            Button('添加')
              .fontSize(12)
              .height(32)
              .margin({ left: 8 })
              .onClick(() => {
                this.createNewTag();
              })

            Button('取消')
              .fontSize(12)
              .height(32)
              .margin({ left: 4 })
              .backgroundColor('#CCCCCC')
              .onClick(() => {
                this.showAddTag = false;
                this.newTag = '';
              })
          } else {
            Button('添加标签')
              .fontSize(14)
              .height(32)
              .backgroundColor('#F0F0F0')
              .fontColor('#007DFF')
              .onClick(() => {
                this.showAddTag = true;
              })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  /**
   * 获取可以添加的标签列表（排除已选择的）
   */
  private getAvailableTagsToAdd(): string[] {
    return this.availableTags.filter(tag => !this.selectedTags.includes(tag));
  }

  /**
   * 添加标签
   */
  private addTag(tag: string) {
    if (this.selectedTags.length >= (this.maxTags || 10)) {
      console.warn('已达到最大标签数量限制');
      return;
    }

    if (!this.selectedTags.includes(tag)) {
      this.selectedTags = [...this.selectedTags, tag];
    }
  }

  /**
   * 移除标签
   */
  private removeTag(index: number) {
    const newTags = [...this.selectedTags];
    newTags.splice(index, 1);
    this.selectedTags = newTags;
  }

  /**
   * 创建新标签
   */
  private createNewTag() {
    const trimmedTag = this.newTag.trim();

    if (!trimmedTag) {
      console.warn('标签不能为空');
      return;
    }

    if (this.selectedTags.length >= (this.maxTags || 10)) {
      console.warn('已达到最大标签数量限制');
      return;
    }

    if (this.selectedTags.includes(trimmedTag)) {
      console.warn('标签已存在');
      return;
    }

    // 检查标签长度
    if (trimmedTag.length > 20) {
      console.warn('标签长度不能超过20个字符');
      return;
    }

    this.selectedTags = [...this.selectedTags, trimmedTag];
    this.newTag = '';
    this.showAddTag = false;

    // 如果新标签不在可用标签列表中，可以通知父组件更新
    if (!this.availableTags.includes(trimmedTag)) {
      // 这里可以通过回调通知父组件
      console.log('新标签创建:', trimmedTag);
    }
  }
}

/**
 * 标签显示组件（只读）
 */
@ComponentV2
export struct TagDisplay {
  @Prop tags: string[] = [];
  @Prop maxDisplay?: number = 5;

  build() {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
      const displayTags = this.tags.slice(0, this.maxDisplay);
      const remainingCount = this.tags.length - displayTags.length;

      ForEach(displayTags, (tag: string) => {
        Text(tag)
          .fontSize(12)
          .fontColor('#007DFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .border({ width: 1, color: '#007DFF', radius: 12 })
          .backgroundColor('#F0F8FF')
          .margin({ right: 6, bottom: 6 })
      })

      if (remainingCount > 0) {
        Text(`+${remainingCount}`)
          .fontSize(12)
          .fontColor('#666666')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .border({ width: 1, color: '#CCCCCC', radius: 12 })
          .backgroundColor('#F5F5F5')
          .margin({ right: 6, bottom: 6 })
      }
    }
    .width('100%')
  }
}