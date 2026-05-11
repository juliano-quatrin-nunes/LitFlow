import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["playButton", "pauseButton", "progress", "currentTime", "duration", "title", "channel"]
  static values = { videoId: String }

  connect() {
    if (!this.videoIdValue) return
    
    // 1. Ensure global callback exists BEFORE loading script
    window.onYouTubeIframeAPIReady = window.onYouTubeIframeAPIReady || (() => {
      window.dispatchEvent(new CustomEvent("youtube-api-ready"))
    })

    if (window.YT && window.YT.Player) {
      this.initializePlayer()
    } else {
      this.loadYouTubeScript()
      window.addEventListener("youtube-api-ready", () => this.initializePlayer(), { once: true })
    }
  }

  disconnect() {
    this.stopTimer()
    if (this.player) {
      try {
        this.player.destroy()
      } catch (e) {
        // Ignore destroy errors if already cleaned up
      }
      this.player = null
    }
  }

  loadYouTubeScript() {
    if (document.querySelector('script[src*="youtube.com/iframe_api"]')) return

    const tag = document.createElement("script")
    tag.src = "https://www.youtube.com/iframe_api"
    const firstScriptTag = document.getElementsByTagName("script")[0]
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
  }

  initializePlayer() {
    if (this.player || !window.YT || !window.YT.Player) return

    const containerId = `yt-player-${this.videoIdValue}-${Math.random().toString(36).substr(2, 9)}`
    const placeholder = document.createElement("div")
    placeholder.id = containerId
    placeholder.style.display = "none"
    this.element.appendChild(placeholder)

    this.player = new YT.Player(containerId, {
      height: "0",
      width: "0",
      videoId: this.videoIdValue,
      playerVars: {
        autoplay: 0,
        controls: 0,
        disablekb: 1,
        enablejsapi: 1,
        origin: window.location.origin,
        playsinline: 1,
        rel: 0,
        widget_referrer: window.location.href
      },
      events: {
        onReady: (event) => this.onPlayerReady(event),
        onStateChange: (event) => this.onPlayerStateChange(event),
        onError: (event) => {
          // Handle common errors like "Video not available"
          if (event.data === 150 || event.data === 101) {
            console.warn("YouTube video doesn't allow embedding, showing full video link instead")
          }
        }
      }
    })
  }

  onPlayerReady(event) {
    this.duration = this.player.getDuration()
    if (this.hasDurationTarget) {
      this.durationTarget.textContent = this.formatTime(this.duration)
    }
    if (this.hasProgressTarget) {
      this.progressTarget.max = Math.floor(this.duration)
    }
    this.applyVideoMetadata()
    this.showPlayButton()
  }

  applyVideoMetadata() {
    const data = typeof this.player.getVideoData === "function" ? this.player.getVideoData() : null
    if (!data) return
    if (this.hasTitleTarget && data.title) this.titleTarget.textContent = data.title
    if (this.hasChannelTarget && data.author) this.channelTarget.textContent = data.author
  }

  onPlayerStateChange(event) {
    if (event.data === YT.PlayerState.PLAYING) {
      this.showPauseButton()
      this.startTimer()
    } else {
      this.showPlayButton()
      this.stopTimer()
    }
  }

  togglePlay(e) {
    if (e) e.preventDefault()
    if (!this.player || typeof this.player.getPlayerState !== 'function') return

    const state = this.player.getPlayerState()
    if (state === YT.PlayerState.PLAYING) {
      this.player.pauseVideo()
    } else {
      this.player.playVideo()
    }
  }

  seek(event) {
    if (!this.player || typeof this.player.seekTo !== 'function') return
    this.player.seekTo(event.target.value, true)
  }

  startTimer() {
    this.stopTimer()
    this.timer = setInterval(() => {
      if (!this.player || typeof this.player.getCurrentTime !== 'function') return
      const currentTime = this.player.getCurrentTime()
      if (this.hasCurrentTimeTarget) this.currentTimeTarget.textContent = this.formatTime(currentTime)
      if (this.hasProgressTarget) this.progressTarget.value = Math.floor(currentTime)
    }, 500)
  }

  stopTimer() {
    if (this.timer) clearInterval(this.timer)
  }

  showPlayButton() {
    if (this.hasPlayButtonTarget) this.playButtonTarget.classList.remove("hidden")
    if (this.hasPauseButtonTarget) this.pauseButtonTarget.classList.add("hidden")
  }

  showPauseButton() {
    if (this.hasPlayButtonTarget) this.playButtonTarget.classList.add("hidden")
    if (this.hasPauseButtonTarget) this.pauseButtonTarget.classList.remove("hidden")
  }

  formatTime(seconds) {
    if (!seconds || isNaN(seconds)) return "0:00"
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, "0")}`
  }
}
