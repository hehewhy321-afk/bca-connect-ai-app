// Easter Egg Configuration
class EasterEggConfig {
  final String soundFile;
  final String emoji;
  final String message;

  const EasterEggConfig({
    required this.soundFile,
    required this.emoji,
    required this.message,
  });
}

class EasterEggs {
  // Fixed locations (as specified)
  static const aiAssistant = EasterEggConfig(
    soundFile: 'sounds/for-ai.mp3',
    emoji: '🤖',
    message: 'AI magic activated!',
  );

  static const finance = EasterEggConfig(
    soundFile: 'sounds/for-finance.mp3',
    emoji: '💰',
    message: 'Money talks!',
  );

  static const study = EasterEggConfig(
    soundFile: 'sounds/for-study.mp3',
    emoji: '📚',
    message: 'Study mode unlocked!',
  );

  // Random locations with random sounds
  static const profile = EasterEggConfig(
    soundFile: 'sounds/koun-hai-re_8ep4nAR.mp3',
    emoji: '⚙️',
    message: 'Tweaking time!',
  );

  static const events = EasterEggConfig(
    soundFile: 'sounds/puneet-superstar-made-with-Voicemod.mp3',
    emoji: '🎉',
    message: 'Party time!',
  );

  static const forum = EasterEggConfig(
    soundFile: 'sounds/indian-gamer-laugh-made-with-Voicemod.mp3',
    emoji: '💬',
    message: 'Let\'s chat!',
  );

  static const resources = EasterEggConfig(
    soundFile: 'sounds/faaah.mp3',
    emoji: '📖',
    message: 'Knowledge is power!',
  );

  static const certificates = EasterEggConfig(
    soundFile: 'sounds/puneet-superstar-rap-god-made-with-Voicemod.mp3',
    emoji: '🏆',
    message: 'Champion!',
  );

  static const achievements = EasterEggConfig(
    soundFile: 'sounds/krish-ka-gana-made-with-Voicemod.mp3',
    emoji: '🎖️',
    message: 'Achievement unlocked!',
  );

  static const algorithmGame = EasterEggConfig(
    soundFile: 'sounds/indian-memes-sound-effect-#3-made-with-Voicemod.mp3',
    emoji: '🧠',
    message: 'Big brain time!',
  );

  static const pomodoro = EasterEggConfig(
    soundFile: 'sounds/ngakak-laugh-annoying.mp3',
    emoji: '⏰',
    message: 'Time flies!',
  );

  static const calendar = EasterEggConfig(
    soundFile: 'sounds/meow-ghop-ghop-ghop.mp3',
    emoji: '📅',
    message: 'Mark your calendar!',
  );

  static const settings = EasterEggConfig(
    soundFile: 'sounds/omgwow.mp3',
    emoji: '⭐',
    message: 'You\'re a star!',
  );

  static const home = EasterEggConfig(
    soundFile: 'sounds/twinkle-twinkle-little-star_-indian-version-made-with-Voicemod.mp3',
    emoji: '🏠',
    message: 'Welcome home!',
  );

  static const funZone = EasterEggConfig(
    soundFile: 'data/amit-sound.mp3', // In data folder, not sounds
    emoji: '🔥',
    message: 'You found the secret! 🎮',
  );

  // NEW: Using leftover sounds for additional locations
  static const foundingMembers = EasterEggConfig(
    soundFile: 'sounds/puneet-laughing-made-with-Voicemod.mp3',
    emoji: '👥',
    message: 'Founding legends discovered!',
  );

  static const feedbackRequest = EasterEggConfig(
    soundFile: 'sounds/puneet-crying-made-with-Voicemod.mp3',
    emoji: '💡',
    message: 'Your ideas matter!',
  );

  static const developerCredits = EasterEggConfig(
    soundFile: 'sounds/hello-your-computer-has-virus-made-with-Voicemod.mp3',
    emoji: '👨‍💻',
    message: 'Meet the creator!',
  );
}
