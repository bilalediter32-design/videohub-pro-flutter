import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(VideoHubProApp(prefs: prefs));
}

class VideoHubProApp extends StatefulWidget {
  const VideoHubProApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<VideoHubProApp> createState() => _VideoHubProAppState();
}

class _VideoHubProAppState extends State<VideoHubProApp> {
  late bool darkMode;
  late String lightStyle;

  @override
  void initState() {
    super.initState();
    darkMode = widget.prefs.getBool('darkMode') ?? false;
    lightStyle = widget.prefs.getString('lightStyle') ?? 'Classic';
  }

  Color get seedColor => switch (lightStyle) {
        'Ocean' => const Color(0xFF087E8B),
        'Minimal' => const Color(0xFF596275),
        _ => const Color(0xFFB8860B),
      };

  Future<void> setDarkMode(bool value) async {
    setState(() => darkMode = value);
    await widget.prefs.setBool('darkMode', value);
  }

  Future<void> setLightStyle(String value) async {
    setState(() => lightStyle = value);
    await widget.prefs.setString('lightStyle', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VideoHub Pro',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB8860B),
          brightness: Brightness.dark,
        ),
      ),
      home: VideoHubHome(
        darkMode: darkMode,
        lightStyle: lightStyle,
        onDarkModeChanged: setDarkMode,
        onLightStyleChanged: setLightStyle,
      ),
    );
  }
}

class VideoHubHome extends StatefulWidget {
  const VideoHubHome({
    super.key,
    required this.darkMode,
    required this.lightStyle,
    required this.onDarkModeChanged,
    required this.onLightStyleChanged,
  });

  final bool darkMode;
  final String lightStyle;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onLightStyleChanged;

  @override
  State<VideoHubHome> createState() => _VideoHubHomeState();
}

class _VideoHubHomeState extends State<VideoHubHome> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeTab(),
      const ExploreTab(),
      const DownloadsTab(),
      const LibraryTab(),
      SettingsTab(
        darkMode: widget.darkMode,
        lightStyle: widget.lightStyle,
        onDarkModeChanged: widget.onDarkModeChanged,
        onLightStyleChanged: widget.onLightStyleChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VideoHub Pro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => selectedTab = 1),
            icon: const Icon(Icons.search),
            tooltip: 'Explore',
          ),
        ],
      ),
      body: pages[selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (value) =>
            setState(() => selectedTab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your media, in one place',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore supported media and manage files you are authorized to save.',
          ),
          const SizedBox(height: 20),
          const FeatureTile(
            icon: Icons.search,
            title: 'Explore media',
            subtitle: 'Find supported sources and content.',
          ),
          const FeatureTile(
            icon: Icons.download,
            title: 'Download manager',
            subtitle: 'Manage permitted downloads in one place.',
          ),
          const FeatureTile(
            icon: Icons.video_library,
            title: 'Local library',
            subtitle: 'Keep track of media stored on your device.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Starter build: download and media scanning features are not connected yet.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      );
}

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search supported media',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          FeatureTile(
            icon: Icons.public,
            title: 'Supported sources',
            subtitle: 'Use official playback and download options.',
          ),
          FeatureTile(
            icon: Icons.folder_open,
            title: 'On-device files',
            subtitle: 'Device media browsing will be added in a later stage.',
          ),
        ],
      );
}

class DownloadsTab extends StatelessWidget {
  const DownloadsTab({super.key});

  @override
  Widget build(BuildContext context) => const EmptyTab(
        icon: Icons.download_for_offline_outlined,
        title: 'No downloads yet',
        message:
            'The download queue will be implemented in a later stage. Only content you own or are authorized to download will be supported.',
      );
}

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) => const EmptyTab(
        icon: Icons.video_library_outlined,
        title: 'Your library is empty',
        message: 'Local media library support will be added in a later stage.',
      );
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    super.key,
    required this.darkMode,
    required this.lightStyle,
    required this.onDarkModeChanged,
    required this.onLightStyleChanged,
  });

  final bool darkMode;
  final String lightStyle;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onLightStyleChanged;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Turn dark appearance on or off'),
            value: darkMode,
            onChanged: onDarkModeChanged,
          ),
          const Divider(),
          const ListTile(
            title: Text('Light theme style'),
            subtitle: Text('Choose a style for light mode'),
          ),
          for (final style in ['Classic', 'Minimal', 'Ocean'])
            RadioListTile<String>(
              title: Text(style),
              value: style,
              groupValue: lightStyle,
              onChanged: (value) {
                if (value != null) onLightStyleChanged(value);
              },
            ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy-first design'),
            subtitle: Text(
              'Preferences are saved locally on this device.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About VideoHub Pro'),
            subtitle: Text('Flutter starter project'),
          ),
        ],
      );
}

class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}

class EmptyTab extends StatelessWidget {
  const EmptyTab({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
