/**
 * 搜索栏组件
 */
@Component
export struct SearchBar {
  @State inputValue: string = ''
  onSearch?: (keyword: string) => void

  build() {
    Row() {
      TextInput({ placeholder: '搜索歌曲', text: this.inputValue })
        .width('70%')
        .onChange((value: string) => {
          this.inputValue = value
        })
        .onSubmit(() => {
          if (this.onSearch) {
            this.onSearch(this.inputValue)
          }
        })

      Button('搜索')
        .width('25%')
        .margin({ left: 10 })
        .onClick(() => {
          if (this.onSearch) {
            this.onSearch(this.inputValue)
          }
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }
}
