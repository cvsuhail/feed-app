// Centralized asset paths for clean usage across the UI layer
// Follow user's rule: always use const

class AppAssets {
  const AppAssets._();

  // Base folders
  static const String images = 'assets/images';
  static const String icons = 'assets/icons';
  static const String animations = 'assets/animations';
  static const String lottie = 'assets/lottie';
  static const String illustrations = 'assets/illustrations';

  // Example: place your files accordingly and add typed getters if needed
  // Images
  static const String placeholderImage = '$images/placeholder.png';

  // Icons
  static const String placeholderIcon = '$icons/placeholder.png';

  // Animations (Rive/GIF/etc.)
  static const String loadingAnimation = '$animations/loading.riv';

  // Lottie
  static const String loadingLottie = '$lottie/loading.json';

  // Illustrations
  static const String emptyState = '$illustrations/empty_state.png';
}


