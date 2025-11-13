@Component
export struct PlayerControl {
  @Link isPlaying: boolean;
  @Link currentTime: number;

  build() {
    Row() {
      Image($r(this.isPlaying ? 'app.media.ic_pause' : 'app.media.ic_play'))
        .onClick(() => this.isPlaying = !this.isPlaying)
      
      Slider({ value: this.currentTime, max: 100 })
        .width('60%')
    }
    .padding(10)
    .backgroundColor('#FFFFFF')
  }
}