
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_manager/photo_manager.dart';

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
    if (!mounted) return;
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
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VideoHub Pro',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your personal media space',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.notifications_none_rounded, size: 27),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Welcome back',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          'Everything you love, in one place.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6558E8), Color(0xFF258FC9)],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              SizedBox(height: 17),
              Text(
                'Your media. Your space.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Organize and enjoy your personal video collection.',
                style: TextStyle(color: Colors.white70),
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
                value: 'My videos',
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
          subtitle: 'Your videos stored on this device',
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
      children: const [
        PageHeading(
          title: 'Explore',
          subtitle: 'Find and organize your media',
        ),
        SizedBox(height: 22),
        FeatureTile(
          icon: Icons.movie_outlined,
          title: 'Movies',
          subtitle: 'Your saved movie collection',
        ),
        SizedBox(height: 10),
        FeatureTile(
          icon: Icons.music_video_outlined,
          title: 'Music videos',
          subtitle: 'Your video collection',
        ),
        SizedBox(height: 10),
        FeatureTile(
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
          subtitle: 'Download manager support will be added in a later update.',
        ),
      ],
    );
  }
}

// REAL DEVICE VIDEO LIBRARY

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<AssetEntity> videos = [];
  bool loading = false;
  bool permissionDenied = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  Future<void> loadVideos() async {
    if (loading) return;

    setState(() {
      loading = true;
      errorMessage = null;
      permissionDenied = false;
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      if (!permission.isAuth && !permission.hasAccess) {
        if (!mounted) return;
        setState(() {
          permissionDenied = true;
          loading = false;
        });
        return;
      }

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );

      if (paths.isEmpty) {
        if (!mounted) return;
        setState(() {
          videos = [];
          loading = false;
        });
        return;
      }

      final result = await paths.first.getAssetListPaged(
        page: 0,
        size: 100,
      );

      if (!mounted) return;
      setState(() {
        videos = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Could not load videos. Please try again.';
        loading = false;
      });
    }
  }

  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: PageHeading(
                  title: 'My Library',
                  subtitle: 'Videos on your device',
                ),
              ),
              IconButton(
                onPressed: loading ? null : loadVideos,
                tooltip: 'Refresh videos',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildLibraryContent(),
        ),
      ],
    );
  }

  Widget _buildLibraryContent() {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text('Scanning your video library...'),
          ],
        ),
      );
    }

    if (permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_library_outlined,
                size: 65,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Video permission needed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Allow access to selected videos or your video library '
                'to display them here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: loadVideos,
                icon: const Icon(Icons.lock_open),
                label: const Text('Grant permission'),
              ),
              TextButton(
                onPressed: () => PhotoManager.openSetting(),
                child: const Text('Open app settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50),
            const SizedBox(height: 12),
            Text(errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: loadVideos,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_library_outlined,
                size: 65,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No videos found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Videos available to this app will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: loadVideos,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 15,
        childAspectRatio: 0.86,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];

        return VideoCard(
          video: video,
          durationText: formatDuration(video.duration),
        );
      },
    );
  }
}

class VideoCard extends StatelessWidget {
  final AssetEntity video;
  final String durationText;

  const VideoCard({
    super.key,
    required this.video,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Video details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title),
                  const SizedBox(height: 10),
                  Text('Duration: $durationText'),
                  const SizedBox(height: 5),
                  Text('Created: ${video.createDateTime}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumbnail(video: video),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        durationText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white70,
                      size: 43,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoThumbnail extends StatelessWidget {
  final AssetEntity video;

  const VideoThumbnail({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: video.thumbnailDataWithSize(
        const ThumbnailSize(400, 300),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: Color(0xFF25283A),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
          );
        }

        return const ColoredBox(
          color: Color(0xFF25283A),
          child: Center(
            child: Icon(
              Icons.video_file_outlined,
              color: Colors.white70,
              size: 45,
            ),
          ),
        );
      },
    );
  }
}

// SETTINGS

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
        const Text(
          'Light theme styles',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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

// REUSABLE DESIGN COMPONENTS

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
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 15,
        ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 38,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 55,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
