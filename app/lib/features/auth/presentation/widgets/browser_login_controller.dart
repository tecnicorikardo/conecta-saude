/// Synchronizes browser-managed values before Flutter validates/submits.
class BrowserLoginController {
  void Function()? synchronize;
  void sync() => synchronize?.call();
}
