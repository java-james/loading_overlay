// Compiled integration recipes. Supply your application's actual operations.
import 'package:loading_overlay/loading_overlay.dart';
import 'package:material_ui/material_ui.dart';

/// Use a context below the scope, and preserve the operation's error for the UI.
class SavePage extends StatelessWidget {
  const SavePage({super.key, required this.save});
  final Future<void> Function() save;

  @override
  Widget build(BuildContext context) => LoadingOverlayScope(
    child: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () async {
              final loading = context.loadingOverlay;
              if (loading.isLoading) return; // Guard same-frame activation too.
              try {
                await loading.run(save, message: 'Saving…');
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not save: $error')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ),
      ),
    ),
  );
}

/// Manage a typed upload operation without storing a BuildContext in a service.
Future<T> showUploadProgress<T>(
  LoadingOverlayController loading,
  Future<T> Function(void Function(int sent, int total) onProgress) upload,
) async {
  final task = loading.start(message: 'Uploading…', progress: 0);
  try {
    return await upload((sent, total) {
      task.update(
        message: 'Uploading…',
        progress: total > 0 ? (sent / total).clamp(0.0, 1.0) : null,
      );
    });
  } finally {
    task.finish();
  }
}

/// Pass an already-created future; never restart requests in build.
class FuturePage extends StatelessWidget {
  const FuturePage({super.key, required this.request});
  final Future<List<String>> request;

  @override
  Widget build(BuildContext context) => LoadingOverlay.withFuture(
    future: request,
    child: FutureBuilder<List<String>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Request failed. Try again.');
        return Text(snapshot.data?.join(', ') ?? '');
      },
    ),
  );
}

/// Demonstrates app hosting without a global singleton. Dispose in the owner.
class ScopedApp extends StatefulWidget {
  const ScopedApp({super.key});
  @override
  State<ScopedApp> createState() => _ScopedAppState();
}

class _ScopedAppState extends State<ScopedApp> {
  final loading = LoadingOverlayController();

  @override
  void dispose() {
    loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: (_, child) => LoadingOverlayScope(
      controller: loading,
      style: const LoadingOverlayStyle(
        showDelay: Duration(milliseconds: 150),
        minimumVisibleDuration: Duration(milliseconds: 300),
      ),
      child: child!,
    ),
    home: const LoadingOverlayBackGuard(
      child: Scaffold(body: Center(child: Text('App-wide scope'))),
    ),
  );
}
