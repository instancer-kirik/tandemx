// Radio FFI - JavaScript audio functionality for Pockets Radio
// Handles audio playback, channel management, and real-time updates

class PocketsRadioPlayer {
  constructor() {
    this.audio = new Audio();
    this.currentChannel = null;
    this.currentTrack = null;
    this.playlist = [];
    this.position = 0;
    this.volume = 0.8;
    this.isPlaying = false;
    this.dispatch = null;
    
    this.setupAudioEvents();
    this.setupPositionTracking();
  }
  
  setupAudioEvents() {
    this.audio.addEventListener('loadedmetadata', () => {
      console.log('Audio loaded:', this.audio.duration);
    });
    
    this.audio.addEventListener('play', () => {
      this.isPlaying = true;
      this.dispatchMsg('AudioReady');
    });
    
    this.audio.addEventListener('pause', () => {
      this.isPlaying = false;
    });
    
    this.audio.addEventListener('ended', () => {
      this.isPlaying = false;
      this.dispatchMsg('TrackEnded');
    });
    
    this.audio.addEventListener('error', (e) => {
      console.error('Audio error:', e);
      this.dispatchMsg('AudioError', e.message || 'Audio playback error');
    });
    
    this.audio.addEventListener('timeupdate', () => {
      this.position = Math.floor(this.audio.currentTime);
      this.dispatchMsg('PositionUpdate', this.position);
    });
  }
  
  setupPositionTracking() {
    // Update position every second when playing
    setInterval(() => {
      if (this.isPlaying && !this.audio.paused) {
        this.position = Math.floor(this.audio.currentTime);
      }
    }, 1000);
  }
  
  setDispatch(dispatch) {
    this.dispatch = dispatch;
  }
  
  dispatchMsg(msgType, data = null) {
    if (this.dispatch) {
      const msg = data !== null ? [msgType, data] : [msgType];
      this.dispatch(msg);
    }
  }
  
  async loadChannels() {
    try {
      // Mock data for now - replace with actual API call
      const mockChannels = [
        {
          id: 'main',
          name: 'Main',
          description: 'The main POCKETS station - Electronic & Chill',
          theme: ['Music', 'electronic', 'chill'],
          playlist: {
            tracks: [
              {
                id: 'track1',
                title: 'Digital Sunrise',
                artist: ['Some', 'Synth Explorer'],
                duration: 225,
                file_url: 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLinKnEOJipaMdM=',
                metadata: {
                  genre: ['Some', 'Electronic'],
                  year: ['Some', 2024],
                  album: ['Some', 'Test Album'],
                  tags: ['chill', 'ambient', 'electronic'],
                  uploaded_by: ['Some', 'admin'],
                  upload_date: ['Some', '2024-01-01']
                }
              },
              {
                id: 'track2',
                title: 'Neon Dreams',
                artist: ['Some', 'Digital Waves'],
                duration: 180,
                file_url: 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLinKnEOJipaMdM=',
                metadata: {
                  genre: ['Some', 'Synthwave'],
                  year: ['Some', 2024],
                  album: ['None'],
                  tags: ['synthwave', 'retro', 'chill'],
                  uploaded_by: ['Some', 'admin'],
                  upload_date: ['Some', '2024-01-01']
                }
              },
              {
                id: 'track3',
                title: 'Forest Whispers',
                artist: ['Some', 'Nature Sounds'],
                duration: 300,
                file_url: 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLinKnEOJipaMdM=',
                metadata: {
                  genre: ['Some', 'Ambient'],
                  year: ['Some', 2024],
                  album: ['Some', 'Natural Ambience'],
                  tags: ['ambient', 'nature', 'relaxing'],
                  uploaded_by: ['Some', 'admin'],
                  upload_date: ['Some', '2024-01-01']
                }
              }
            ],
            bumpers: [
              {
                id: 'bumper1',
                content: 'You\'re listening to POCKETS Radio - your soundtrack for creativity',
                voice: 'host',
                file_url: 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLinKnEOJipaMdM=',
                trigger: ['EveryNTracks', 3]
              }
            ],
            current_index: 0,
            shuffle: false,
            repeat: true
          },
          schedule: ['None'],
          is_active: true
        },
        {
          id: 'talk',
          name: 'Talk',
          description: 'Conversations, podcasts, and creative discussions',
          theme: ['Talk', 'The POCKETS Host', 'interview'],
          playlist: {
            tracks: [
              {
                id: 'talk1',
                title: 'Creative Process Deep Dive',
                artist: ['Some', 'POCKETS Host'],
                duration: 1800,
                file_url: 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLinKnEOJipaMdM=',
                metadata: {
                  genre: ['Some', 'Podcast'],
                  year: ['Some', 2024],
                  album: ['Some', 'POCKETS Talks'],
                  tags: ['interview', 'creative', 'discussion'],
                  uploaded_by: ['Some', 'admin'],
                  upload_date: ['Some', '2024-01-01']
                }
              }
            ],
            bumpers: [],
            current_index: 0,
            shuffle: false,
            repeat: false
          },
          schedule: ['None'],
          is_active: true
        },
        {
          id: 'night',
          name: 'Night Vibes',
          description: 'Late night ambient sounds for deep work and relaxation',
          theme: ['Ambient', 'forest'],
          playlist: {
            tracks: [
              {
                id: 'night1',
                title: 'Midnight Code Session',
                artist: ['Some', 'Ambient Coder'],
                duration: 3600,
                file_url: 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLinKnEOJipaMdM=',
                metadata: {
                  genre: ['Some', 'Ambient'],
                  year: ['Some', 2024],
                  album: ['Some', 'Night Sessions'],
                  tags: ['ambient', 'focus', 'minimal'],
                  uploaded_by: ['Some', 'admin'],
                  upload_date: ['Some', '2024-01-01']
                }
              }
            ],
            bumpers: [],
            current_index: 0,
            shuffle: false,
            repeat: true
          },
          schedule: ['None'],
          is_active: true
        }
      ];
      
      return mockChannels;
    } catch (error) {
      console.error('Failed to load channels:', error);
      throw error;
    }
  }
  
  selectChannel(channel) {
    this.currentChannel = channel;
    if (channel.playlist.tracks.length > 0) {
      this.playlist = channel.playlist.tracks;
      this.currentTrack = this.playlist[channel.playlist.current_index] || null;
      
      if (this.currentTrack) {
        this.loadTrack(this.currentTrack);
      }
    }
  }
  
  loadTrack(track) {
    if (!track) return;
    
    this.currentTrack = track;
    
    // Handle different audio sources
    try {
      this.audio.src = track.file_url;
      this.audio.load();
      console.log('Loading track:', track.title, 'from', track.file_url);
    } catch (error) {
      console.error('Failed to load track:', error);
      this.dispatchMsg('AudioError', 'Failed to load track: ' + track.title);
    }
  }
  
  play() {
    if (this.audio.src) {
      this.audio.play().catch(error => {
        console.error('Play failed:', error);
        this.dispatchMsg('AudioError', 'Failed to play audio');
      });
    }
  }
  
  pause() {
    this.audio.pause();
  }
  
  playTrack(track) {
    this.loadTrack(track);
    setTimeout(() => this.play(), 100); // Small delay to ensure loading
  }
  
  seek(position) {
    if (this.audio.duration) {
      this.audio.currentTime = position;
      this.position = position;
    }
  }
  
  setVolume(volume) {
    this.volume = Math.max(0, Math.min(1, volume));
    this.audio.volume = this.volume;
  }
  
  checkBumperTrigger(channel, position) {
    if (!channel || !channel[1] || !channel[1].playlist.bumpers.length) return;
    
    const bumpers = channel[1].playlist.bumpers;
    const timeSinceLastBumper = position - (this.lastBumperTime || 0);
    
    // Check for time-based triggers (every 5 minutes = 300 seconds)
    if (timeSinceLastBumper > 300) {
      const bumper = bumpers[Math.floor(Math.random() * bumpers.length)];
      this.playBumper(bumper);
      this.lastBumperTime = position;
    }
  }
  
  playBumper(bumper) {
    // Create a temporary audio element for bumper
    const bumperAudio = new Audio(bumper.file_url);
    bumperAudio.volume = this.volume * 0.8; // Slightly quieter than main audio
    
    // Pause main audio temporarily
    const wasPlaying = !this.audio.paused;
    const currentTime = this.audio.currentTime;
    
    if (wasPlaying) {
      this.audio.pause();
    }
    
    bumperAudio.play().then(() => {
      console.log('Playing bumper:', bumper.content);
    }).catch(error => {
      console.error('Bumper playback failed:', error);
    });
    
    // Resume main audio after bumper ends
    bumperAudio.addEventListener('ended', () => {
      if (wasPlaying) {
        this.audio.currentTime = currentTime;
        this.audio.play();
      }
    });
  }
}

// Global radio player instance
let radioPlayer = null;

// Initialize the radio player
function initRadioPlayer(dispatch) {
  if (!radioPlayer) {
    radioPlayer = new PocketsRadioPlayer();
  }
  radioPlayer.setDispatch(dispatch);
  return radioPlayer;
}

// FFI exports for Gleam
export function loadChannels() {
  return (dispatch) => {
    const player = initRadioPlayer(dispatch);
    
    player.loadChannels()
      .then(channels => {
        dispatch(['ChannelsLoaded', channels]);
      })
      .catch(error => {
        console.error('Load channels error:', error);
        dispatch(['Error', 'Failed to load channels: ' + error.message]);
      });
  };
}

export function selectChannel(channel) {
  return (dispatch) => {
    if (!radioPlayer) {
      dispatch(['Error', 'Radio player not initialized']);
      return;
    }
    
    try {
      radioPlayer.selectChannel(channel);
      dispatch(['ChannelSelected', channel]);
    } catch (error) {
      console.error('Select channel error:', error);
      dispatch(['Error', 'Failed to select channel: ' + error.message]);
    }
  };
}

export function playAudio() {
  return (dispatch) => {
    if (!radioPlayer) {
      dispatch(['Error', 'Radio player not initialized']);
      return;
    }
    
    try {
      radioPlayer.play();
      dispatch(['NoOp']);
    } catch (error) {
      console.error('Play audio error:', error);
      dispatch(['AudioError', 'Failed to play: ' + error.message]);
    }
  };
}

export function pauseAudio() {
  return (dispatch) => {
    if (!radioPlayer) {
      dispatch(['Error', 'Radio player not initialized']);
      return;
    }
    
    try {
      radioPlayer.pause();
      dispatch(['NoOp']);
    } catch (error) {
      console.error('Pause audio error:', error);
      dispatch(['AudioError', 'Failed to pause: ' + error.message]);
    }
  };
}

export function playTrack(track) {
  return (dispatch) => {
    if (!radioPlayer) {
      dispatch(['Error', 'Radio player not initialized']);
      return;
    }
    
    try {
      radioPlayer.playTrack(track);
      dispatch(['NoOp']);
    } catch (error) {
      console.error('Play track error:', error);
      dispatch(['AudioError', 'Failed to play track: ' + error.message]);
    }
  };
}

export function seekAudio(position) {
  return (dispatch) => {
    if (!radioPlayer) {
      dispatch(['Error', 'Radio player not initialized']);
      return;
    }
    
    try {
      radioPlayer.seek(position);
      dispatch(['NoOp']);
    } catch (error) {
      console.error('Seek audio error:', error);
      dispatch(['AudioError', 'Failed to seek: ' + error.message]);
    }
  };
}

export function setVolume(volume) {
  return (dispatch) => {
    if (!radioPlayer) {
      dispatch(['Error', 'Radio player not initialized']);
      return;
    }
    
    try {
      radioPlayer.setVolume(volume);
      dispatch(['NoOp']);
    } catch (error) {
      console.error('Set volume error:', error);
      dispatch(['AudioError', 'Failed to set volume: ' + error.message]);
    }
  };
}

export function checkBumperTrigger(channel, position) {
  return (dispatch) => {
    if (!radioPlayer) {
      dispatch(['NoOp']);
      return;
    }
    
    try {
      radioPlayer.checkBumperTrigger(channel, position);
      dispatch(['NoOp']);
    } catch (error) {
      console.error('Check bumper trigger error:', error);
      dispatch(['NoOp']); // Non-critical, don't error
    }
  };
}

// Utility function to handle audio format detection
function detectAudioFormat(url) {
  const ext = url.split('.').pop().toLowerCase();
  const formats = {
    'mp3': 'audio/mpeg',
    'ogg': 'audio/ogg',
    'wav': 'audio/wav',
    'm4a': 'audio/m4a',
    'flac': 'audio/flac'
  };
  return formats[ext] || 'audio/mpeg';
}

// Check if browser supports audio playback
function checkAudioSupport() {
  const audio = new Audio();
  return {
    mp3: audio.canPlayType('audio/mpeg'),
    ogg: audio.canPlayType('audio/ogg'),
    wav: audio.canPlayType('audio/wav'),
    m4a: audio.canPlayType('audio/m4a')
  };
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
  console.log('🎵 Pockets Radio FFI loaded');
  console.log('🔊 Audio support:', checkAudioSupport());
  
  // Test basic audio functionality
  try {
    const testAudio = new Audio();
    console.log('✅ Audio element created successfully');
  } catch (error) {
    console.error('❌ Audio element creation failed:', error);
  }
});