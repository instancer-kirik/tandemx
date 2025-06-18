# 📻 Pockets Radio

A modern web-based radio station system built with Gleam and Lustre, designed for the TandemX creative platform.

## Overview

Pockets Radio is a multi-channel streaming system that provides curated audio experiences for different moods and activities. Think Jet Set Radio meets modern podcast networks - each channel has its own personality, playlist, and bumpers.

## Architecture

### Frontend (Gleam + Lustre)
- **`radio/types.gleam`** - Core data types for channels, tracks, playlists, and player state
- **`radio.gleam`** - Main radio module with Model-View-Update pattern
- **`radio_ffi.js`** - JavaScript FFI for audio playback and browser integration
- **`radio.css`** - Glassmorphism-inspired styling for the radio interface

### Channel System
Each channel represents a different "station" with:
- **Theme**: Music, Talk, Character, or Ambient
- **Playlist**: Ordered list of tracks with shuffle/repeat options
- **Bumpers**: Voice-over segments that play between tracks
- **Schedule**: Optional time-based programming (future feature)

## Features

### Current
- ✅ Multi-channel selection
- ✅ Audio playback with Web Audio API
- ✅ Real-time position tracking
- ✅ Volume control
- ✅ Next/previous track navigation
- ✅ Bumper system for station identification
- ✅ Responsive design with glassmorphism UI

### Planned
- 🔄 File upload system for content creators
- 🔄 Admin panel for playlist management
- 🔄 Scheduled programming
- 🔄 Live streaming integration
- 🔄 FM broadcast output
- 🔄 User song requests
- 🔄 Real-time chat/community features

## Channel Concepts

### Main Channel
- **Theme**: Electronic & Chill
- **Vibe**: Productivity music, coding sessions, creative work
- **Content**: Curated electronic, ambient, and lo-fi tracks

### Talk Channel
- **Theme**: Conversations & Podcasts
- **Vibe**: Creative discussions, interviews, behind-the-scenes
- **Content**: Recorded conversations, technical talks, creative process deep-dives

### Night Vibes
- **Theme**: Ambient & Focus
- **Vibe**: Late-night deep work, relaxation, minimal distractions
- **Content**: Long-form ambient tracks, nature sounds, minimal beats

### Character Channels (Future)
- **Theme**: Voiced personalities
- **Vibe**: Like having different DJs with unique personalities
- **Content**: Character-driven commentary, themed music selections

## Technical Implementation

### Audio Pipeline
1. **Source**: Audio files stored on CDN (Bunny.net or Fly.io volumes)
2. **Metadata**: Track info, bumpers, and scheduling stored in Supabase
3. **Streaming**: Client-side audio assembly using Web Audio API
4. **Output**: Browser playback with optional FM transmission

### Data Flow
```
User selects channel → Load playlist from API → Stream audio files → 
Play bumpers at intervals → Track position/events → Update UI in real-time
```

### Browser Compatibility
- **Audio Formats**: MP3, OGG, WAV, M4A
- **APIs**: Web Audio API, HTML5 Audio Element
- **Fallbacks**: Progressive enhancement for older browsers

## Development

### Running the Radio
1. Start the Gleam development server
2. Navigate to `/radio` in your browser
3. Select a channel to begin streaming
4. Use the test page at `/radio_test.html` for debugging

### Adding New Channels
1. Update the mock data in `radio_ffi.js` (development)
2. Add channel data to Supabase (production)
3. Upload audio content to CDN
4. Configure bumpers and scheduling

### Testing Audio
- Use the test page to verify browser audio support
- Test with different audio formats and bitrates
- Verify bumper timing and transitions
- Check responsive design on mobile devices

## File Structure

```
radio/
├── types.gleam          # Core data types
├── README.md           # This documentation
├── ../radio.gleam      # Main radio module
├── ../radio_ffi.js     # JavaScript audio integration
├── ../radio.css        # Radio-specific styles
└── ../radio_test.html  # Development test page
```

## Audio Content Guidelines

### Track Requirements
- **Format**: MP3 or OGG preferred
- **Bitrate**: 128-320 kbps
- **Length**: 2-10 minutes for music, 5-60 minutes for talk content
- **Metadata**: Title, artist, duration, genre tags

### Bumper Requirements
- **Format**: MP3 or OGG
- **Length**: 5-30 seconds
- **Content**: Station identification, community quotes, lore snippets
- **Voice**: Consistent character/host voice per channel

### File Organization
```
audio/
├── main/
│   ├── tracks/
│   └── bumpers/
├── talk/
│   ├── episodes/
│   └── bumpers/
└── night/
    ├── ambient/
    └── bumpers/
```

## Integration with TandemX

### Navigation
- Radio link added to main navigation
- Accessible from any page in the application
- State persists across navigation (continues playing)

### User System
- Leverages existing Supabase authentication
- Admin controls for content management
- User preferences and favorites (planned)

### Design System
- Consistent with TandemX visual language
- Glassmorphism effects matching the platform aesthetic
- Responsive design for mobile and desktop

## Future Enhancements

### FM Broadcasting
- Integration with GNU Radio or similar software
- Low-power FM transmission for local events
- Streaming bridge for internet → radio conversion

### Community Features
- Song request system
- Real-time listener chat
- Community-submitted bumpers and quotes
- Collaborative playlists

### Advanced Audio
- Crossfading between tracks
- Real-time audio effects
- Dynamic playlist generation based on time/mood
- Integration with music streaming APIs

## Contributing

When adding new features:
1. Update type definitions in `types.gleam`
2. Add corresponding JavaScript in `radio_ffi.js`
3. Update the UI in `radio.gleam`
4. Add appropriate CSS styling
5. Test across different browsers and devices
6. Update this documentation

## License

Part of the TandemX platform. See main project license.

---

🎵 *"You're listening to POCKETS Radio - your soundtrack for creativity"*