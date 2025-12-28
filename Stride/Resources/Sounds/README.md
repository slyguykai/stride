# Stride Audio Assets

This folder contains audio files used throughout the Stride app for haptic-accompanied feedback.

## Current Files

### `complete_soft.wav`
- **Usage:** Subtask completion
- **Duration:** 150ms
- **Description:** Gentle high-pitched tone (800Hz) with fade-out
- **Style:** Minimal, non-intrusive click/tick sound

### `complete_major.wav`
- **Usage:** Full task completion
- **Duration:** 400ms
- **Description:** Two-tone sequence (C5 → E5) with fade-out
- **Style:** Celebratory but subtle, upward progression

### `focus_start.wav`
- **Usage:** Focus Time session begins
- **Duration:** 800ms
- **Description:** Calming tone at 432Hz (healing frequency) with long fade
- **Style:** Meditation-like, centered, grounding

## Implementation

These sounds are loaded in `AudioManager.swift` and played via AVAudioPlayer:
- Preloaded on app launch for instant playback
- Respect system silent mode
- No loops or repeats

## Replacement

These are **programmatically generated placeholder sounds** using sine waves. For production, consider replacing with professionally designed sounds from:

### Recommended Sources
- **Freesound.org**: Creative Commons licensed sounds
- **Pixabay**: Royalty-free sound effects (no attribution needed)
- **Mixkit.co**: Modern UI sounds, free license
- **Zapsplat**: Professional quality (free tier with attribution)

### Guidelines for Replacement
- Keep files in WAV format for iOS compatibility
- Duration: 150-800ms (avoid longer sounds for UI feedback)
- Volume: Subtle, not jarring
- Style: Match Stride's encouraging but non-nagging personality
- Test on device with haptics for combined effect

### Search Keywords
- Soft: "subtle notification", "gentle success", "light chime"
- Major: "achievement", "success notification", "level complete"
- Focus: "meditation bell", "calm tone", "focus begin"

## License

Current placeholder sounds are generated code and can be used/modified freely. When replacing, ensure new assets have appropriate licensing for commercial iOS app use.

