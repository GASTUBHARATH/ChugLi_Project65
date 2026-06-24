import 'dart:math';

/// Generates random anonymous handles like "NeonPanther", "FrostWolf", etc.
/// Each handle has an optional animal emoji appended.
class HandleGenerator {
  HandleGenerator._();

  static final _rng = Random();

  static const _adjectives = [
    'Neon', 'Frost', 'Cosmic', 'Turbo', 'Lunar', 'Mystic', 'Shadow', 'Silent',
    'Urban', 'Hidden', 'Electric', 'Rustic', 'Astral', 'Crystal', 'Blazing',
    'Stealth', 'Velvet', 'Phantom', 'Rogue', 'Quantum', 'Hyper', 'Iron',
    'Solar', 'Vapor', 'Crimson', 'Golden', 'Arctic', 'Venom', 'Thunder',
    'Chaos', 'Glitch', 'Sonic', 'Pixel', 'Digital', 'Retro', 'Apex',
    'Swift', 'Dark', 'Bright', 'Wild', 'Echo', 'Ghost', 'Storm', 'Blaze',
    'Nova', 'Void', 'Flux', 'Prism', 'Surge', 'Zen',
  ];

  static const _nouns = [
    'Panther', 'Wolf', 'Falcon', 'Tiger', 'Fox', 'Koala', 'Ninja',
    'Raven', 'Viper', 'Phoenix', 'Dragon', 'Hawk', 'Bear', 'Lynx',
    'Panda', 'Cobra', 'Eagle', 'Jaguar', 'Otter', 'Gecko',
    'Hyena', 'Wombat', 'Badger', 'Manta', 'Raptor', 'Mantis',
    'Coyote', 'Dingo', 'Ferret', 'Mongoose', 'Sparrow', 'Bison',
    'Walrus', 'Ibex', 'Kestrel', 'Lemur', 'Narwhal', 'Osprey',
    'Quokka', 'Serval', 'Tanuki', 'Urial', 'Xerus', 'Zorilla',
    'Marmot', 'Jackal', 'Condor', 'Basilisk', 'Axolotl', 'Capybara',
  ];

  static const _emojis = [
    '🐯', '🦊', '🐺', '🦅', '🐼', '🐉', '🦁', '🦝', '🦎', '🦋',
    '🐦', '🦬', '🐻', '🦩', '🐸', '🦇', '🐬', '🦑', '🦋', '🐲',
  ];

  /// Generates [count] unique random handles.
  static List<String> generateHandles(int count) {
    final Set<String> seen = {};
    final List<String> results = [];
    int attempts = 0;
    while (results.length < count && attempts < count * 10) {
      attempts++;
      final adj = _adjectives[_rng.nextInt(_adjectives.length)];
      final noun = _nouns[_rng.nextInt(_nouns.length)];
      final number = _rng.nextInt(90) + 10; // 10-99
      final emoji = _emojis[_rng.nextInt(_emojis.length)];
      final handle = '$adj$noun$number $emoji';
      if (!seen.contains(handle)) {
        seen.add(handle);
        results.add(handle);
      }
    }
    return results;
  }

  /// Returns just the text part of a handle (strips emoji + trailing space).
  static String textOnly(String handle) {
    return handle.split(' ').first;
  }
}
