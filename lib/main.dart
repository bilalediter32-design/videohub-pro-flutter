
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VideoHubApp());
}

class VideoHubApp extends StatefulWidget {
  const VideoHubApp({super.key});

  @override
  State<VideoHubApp> createState() => _VideoHubAppState();
}

class _VideoHubAppState extends State<VideoHubApp> {
  bool darkMode = true;
  String lightStyle = 'Classic';
  bool ready = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? true;
      lightStyle = prefs.getString('lightStyle') ?? 'Classic';
      ready = true;
    });
  }

  Future<void> updateTheme(bool value) async {
    setState(() => darkMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> updateStyle(String value) async {
    setState(() => lightStyle = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lightStyle', value);
  }

  Color get seedColor {
    switch (lightStyle) {
      case 'Ocean':
        return const Color(0xFF008C95);
      case 'Minimal':
        return const Color(0xFF596579);
      default:
        return const Color(0xFF6558E8);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VideoHub Pro',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F6FA),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8274FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0D18),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0D18),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Color(0xFF171A2A),
        ),
      ),
      home: MainScreen(
        darkMode: darkMode,
        lightStyle: lightStyle,
        onThemeChanged: updateTheme,
        onStyleChanged: updateStyle,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool darkMode;
  final String lightStyle;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onStyleChanged;

  const MainScreen({
    super.key,
    required this.darkMode,
    required this.lightStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const ExplorePage(),
      const DownloadsPage(),
      const LibraryPage(),
      SettingsPage(
        darkMode: widget.darkMode,
        lightStyle: widget.lightStyle,
        onThemeChanged: widget.onThemeChanged,
        onStyleChanged: widget.onStyleChanged,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7667FF), Color(0xFF28B6D5)],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VideoHub Pro',
                      style: TextStyle(
                          fontSize: 21, fontWeight: FontWeight.bold)),
                  Text('Your personal media space',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.notifications_none_rounded, size: 27),
          ],
        ),
        const SizedBox(height: 28),
        const Text('Welcome back',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        const Text('Everything you love, in one place.',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6558E8), Color(0xFF258FC9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              const SizedBox(height: 17),
              const Text('Your media. Your space.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Organize and enjoy your personal video collection.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5145C7),
                ),
                icon: const Icon(Icons.video_library_outlined),
                label: const Text('Explore library'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 27),
        const SectionTitle(title: 'Your workspace'),
        const SizedBox(height: 13),
        const Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.video_collection_outlined,
                title: 'Library',
                value: 'Ready',
                color: Color(0xFF8274FF),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.download_done_rounded,
                title: 'Downloads',
                value: 'No tasks',
                color: Color(0xFF24B69B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 27),
        const SectionTitle(title: 'Quick access'),
        const SizedBox(height: 13),
        const FeatureTile(
          icon: Icons.explore_outlined,
          title: 'Explore videos',
          subtitle: 'Discover your media collection',
        ),
        const SizedBox(height: 10),
        const FeatureTile(
          icon: Icons.folder_open_outlined,
          title: 'My library',
          subtitle: 'Keep your videos organized',
        ),
      ],
    );
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          title: 'Explore',
          subtitle: 'Find and organize your media',
        ),
        const SizedBox(height: 22),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search your videos...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 25),
        const SectionTitle(title: 'Browse categories'),
        const SizedBox(height: 14),
        const FeatureTile(
          icon: Icons.movie_outlined,
          title: 'Movies',
          subtitle: 'Your saved movie collection',
        ),
        const SizedBox(height: 10),
        const FeatureTile(
          icon: Icons.music_video_outlined,
          title: 'Music videos',
          subtitle: 'Your video playlists',
        ),
        const SizedBox(height: 10),
        const FeatureTile(
          icon: Icons.video_camera_back_outlined,
          title: 'Personal videos',
          subtitle: 'Videos stored on your device',
        ),
      ],
    );
  }
}

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        PageHeading(
          title: 'Downloads',
          subtitle: 'Manage your download activity',
        ),
        SizedBox(height: 25),
        EmptyState(
          icon: Icons.cloud_download_outlined,
          title: 'No downloads yet',
          subtitle:
              'Your permitted downloads will appear here when download support is added.',
        ),
      ],
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        PageHeading(
          title: 'My Library',
          subtitle: 'Your personal media collection',
        ),
        SizedBox(height: 25),
        EmptyState(
          icon: Icons.video_library_outlined,
          title: 'Your library is empty',
          subtitle:
              'Your personal videos will appear here when library scanning is added.',
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  final bool darkMode;
  final String lightStyle;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onStyleChanged;

  const SettingsPage({
    super.key,
    required this.darkMode,
    required this.lightStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          title: 'Settings',
          subtitle: 'Make VideoHub Pro yours',
        ),
        const SizedBox(height: 25),
        const SectionTitle(title: 'Appearance'),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark theme'),
            subtitle: const Text('Use the premium dark appearance'),
            value: darkMode,
            onChanged: onThemeChanged,
          ),
        ),
        const SizedBox(height: 14),
        const Text('Light theme styles',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          children: ['Classic', 'Minimal', 'Ocean'].map((style) {
            return ChoiceChip(
              label: Text(style),
              selected: lightStyle == style,
              onSelected: (_) => onStyleChanged(style),
            );
          }).toList(),
        ),
        const SizedBox(height: 25),
        const SectionTitle(title: 'General'),
        const SizedBox(height: 12),
        const FeatureTile(
          icon: Icons.storage_outlined,
          title: 'Local storage',
          subtitle: 'Your preferences are saved on this device',
        ),
        const SizedBox(height: 10),
        const FeatureTile(
          icon: Icons.info_outline,
          title: 'About VideoHub Pro',
          subtitle: 'Version 1.0.0',
        ),
        const SizedBox(height: 25),
        const Center(
          child: Text(
            'VIDEOHUB PRO',
            style: TextStyle(
              color: Colors.grey,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class PageHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 15),
            Text(value,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
        child: Column(
          children: [
            Icon(icon, size: 55, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 17),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
