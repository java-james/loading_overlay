# loading_overlay

A simple widget wrapper to enable modal progress HUD (a modal progress indicator, HUD = Heads Up Display)

A fork of [mobile_progress_hud](https://pub.dev/packages/modal_progress_hud)
Inspired by [this](https://codingwithjoe.com/flutter-how-to-build-a-modal-progress-indicator/) article.


## Demo

![Demo](https://raw.githubusercontent.com/java-james/loading_overlay/master/loading_overlay.gif)

*See example for details*


## Usage

Add the package to your `pubspec.yml` file.

```yml
dependencies:
  loading_overlay: ^0.2.0
```

Next, import the library into your widget.

```dart
import 'package:loading_overlay/loading_overlay.dart';
```

Now, all you have to do is simply wrap your widget as a child of `ModalProgressHUD`, typically a form, together with a boolean that is maintained in local state.

```dart
...
bool _saving = false
...

@override
Widget build(BuildContext context) {
  return Scaffold(
     body: LoadingOverlay(child: Container(
       Form(...)
     ), isLoading: _saving),
  );
}
```


## Options

The current parameters are customizable in the constructor
```dart
LoadingOverlay({
    @required this.opacity,
    @required this.isLoading,
    @required this.child,
    this.progressIndicator = const CircularProgressIndicator(),
    this.color,
});
```

Update: See this [article](https://medium.com/@nocnoc/the-secret-to-async-validation-on-flutter-forms-4b273c667c03) on Medium about async form validation

See the [example application](https://github.com/java-james/loading_overlay/tree/master/example) source
for a complete sample app using the modal progress HUD. Included in the
example is a method for using a form's validators while making async
calls (see [flutter/issues/9688](https://github.com/flutter/flutter/issues/9688) for details).


### Issues and feedback

Please file [issues](https://github.com/java-james/loading_overlay/issues/new)
to send feedback or report a bug. Thank you!

