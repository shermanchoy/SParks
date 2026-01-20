class HomeTab {
  static void Function(int index)? _setIndex;

  static void bind(void Function(int) fn) {
    _setIndex = fn;
  }

  static void goMatches() {
    _setIndex?.call(1); // 0 discover, 1 matches, 2 profile
  }
}
