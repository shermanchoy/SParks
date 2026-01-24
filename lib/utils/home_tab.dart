typedef HomeTabSetter = void Function(int index);

class HomeTab {
  static HomeTabSetter? _setIndex;

  static void bind(HomeTabSetter setter) {
    _setIndex = setter;
  }

  static void unbind() {
    _setIndex = null;
  }

  static void goDiscover() => _setIndex?.call(0);
  static void goMatches() => _setIndex?.call(1);
  static void goProfile() => _setIndex?.call(2);
}
