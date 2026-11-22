import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const String youtubeApiKey = String.fromEnvironment(
  'YOUTUBE_API_KEY',
);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(VideoHubProApp(prefs: prefs));
}

class DownloadItem {
  DownloadItem({
    required this.url,
    required this.name,
    required this.path,
    required this.kind,
    this.progress = 0,
    this.status = 'Queued',
    this.error,
  });

  final String url;
  final String name;
  final String path;
  final String kind;
  double progress;
  String status;
  String? error;

  String get partialPath => '$path.part';

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'path': path,
        'kind': kind,
        'progress': progress,
        'status': status,
        'error': error,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        url: json['url'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        kind: json['kind'] as String? ?? 'Video / Media',
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'Queued',
        error: json['error'] as String?,
      );
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
        _ => const Color(0xFF6558E8),
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
  Widget build(BuildContext context) => MaterialApp(
        title: 'VideoHub Pro',
        debugShowCheckedModeBanner: false,
        themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8274FF),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0B0D18),
        ),
        home: VideoHubHome(
          prefs: widget.prefs,
          darkMode: darkMode,
          lightStyle: lightStyle,
          onDarkModeChanged: setDarkMode,
          onLightStyleChanged: setLightStyle,
        ),
      );
}class VideoHubHome extends StatefulWidget {
  const VideoHubHome({
    super.key,
    required this.prefs,
    required this.darkMode,
    required this.lightStyle,
    required this.onDarkModeChanged,
    required this.onLightStyleChanged,
  });

  final SharedPreferences prefs;
  final bool darkMode;
  final String lightStyle;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onLightStyleChanged;

  @override
  State<VideoHubHome> createState() => _VideoHubHomeState();
}

class _VideoHubHomeState extends State<VideoHubHome> {
  int selectedTab = 0;
  final urlController = TextEditingController();
  final nameController = TextEditingController();
  final List<DownloadItem> items = [];
  final Dio dio = Dio();
  final Map<DownloadItem, CancelToken> cancelTokens = {};
  int activeDownloads = 0;
  bool loaded = false;
  bool processingQueue = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    for (final token in cancelTokens.values) {
      token.cancel('App screen disposed');
    }
    urlController.dispose();
    nameController.dispose();
    dio.close(force: true);
    super.dispose();
  }

  Future<void> _loadItems() async {
    final saved = widget.prefs.getStringList('downloadItems') ?? [];
    for (final entry in saved) {
      try {
        final item = DownloadItem.fromJson(
          jsonDecode(entry) as Map<String, dynamic>,
        );
        if (item.status == 'Downloading') item.status = 'Queued';
        if (item.status == 'Completed' &&
            !File(item.path).existsSync()) {
          continue;
        }
        items.add(item);
      } catch (_) {
        // Ignore damaged old preference entries.
      }
    }
    if (!mounted) return;
    setState(() => loaded = true);
    await _saveItems();
    _processQueue();
  }

  Future<void> _saveItems() async {
    await widget.prefs.setStringList(
      'downloadItems',
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  String _safeFileName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'videohub_media' : cleaned;
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    var name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    try {
      name = Uri.decodeComponent(name);
    } catch (_) {}
    if (name.isEmpty || !name.contains('.')) {
      name = 'media_${DateTime.now().millisecondsSinceEpoch}.mp4';
    }
    return _safeFileName(name);
  }

  String _kindFor(String name) {
    final ext = name.toLowerCase().split('.').last;
    const audio = {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac', 'opus'};
    return audio.contains(ext) ? 'Audio' : 'Video / Media';
  }

  Future<void> _addDownload() async {
    final rawUrl = urlController.text.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      _message('Enter a valid direct HTTP or HTTPS media URL.');
      return;
    }

    final pending = items
        .where((item) =>
            item.status == 'Queued' || item.status == 'Downloading')
        .length;
    if (pending >= 5) {
      _message('Maximum 5 active or queued tasks are allowed.');
      return;
    }

    var fileName = _fileNameFromUrl(rawUrl);
    final customName = nameController.text.trim();
    if (customName.isNotEmpty) {
      final extension =
          fileName.contains('.') ? '.${fileName.split('.').last}' : '';
      fileName = _safeFileName(customName);
      if (!fileName.contains('.') && extension.isNotEmpty) {
        fileName += extension;
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final uniqueName =
        '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final item = DownloadItem(
      url: rawUrl,
      name: fileName,
      path: '${dir.path}/$uniqueName',
      kind: _kindFor(fileName),
    );

    if (!mounted) return;
    setState(() {
      items.insert(0, item);
      selectedTab = 2;
      urlController.clear();
      nameController.clear();
    });
    await _saveItems();
    _processQueue();
  }

  void _processQueue() {
    if (processingQueue || !loaded) return;
    processingQueue = true;
    while (activeDownloads < 2) {
      final index = items.indexWhere((item) => item.status == 'Queued');
      if (index == -1) break;
      final item = items[index];
      activeDownloads++;
      item.status = 'Downloading';
      _saveItems();
      _download(item).whenComplete(() {
        activeDownloads--;
        cancelTokens.remove(item);
        processingQueue = false;
        if (mounted) {
          setState(() {});
          _processQueue();
        }
      });
    }
    processingQueue = false;
    if (mounted) setState(() {});
  }

  Future<void> _download(DownloadItem item) async {
    final token = CancelToken();
    cancelTokens[item] = token;
    try {
      final partial = File(item.partialPath);
      var offset = await partial.exists() ? await partial.length() : 0;

      final response = await dio.get<ResponseBody>(
        item.url,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 10),
          headers: {
            'Accept': '*/*',
            if (offset > 0) 'Range': 'bytes=$offset-',
          },
        ),
      );

      final supportsResume = response.statusCode == 206;
      if (offset > 0 && !supportsResume) {
        offset = 0;
        if (await partial.exists()) await partial.delete();
      }

      final contentLength = int.tryParse(
            response.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          -1;
      var total = contentLength > 0 ? contentLength + offset : -1;
      final contentRange =
          response.headers.value('content-range') ?? '';
      final rangeMatch = RegExp(r'/(\d+)$').firstMatch(contentRange);
      if (rangeMatch != null) {
        total = int.tryParse(rangeMatch.group(1)!) ?? total;
      }

      final sink = partial.openSync(
        mode: offset > 0 ? FileMode.append : FileMode.write,
      );
      var received = offset;
      try {
        final stream = response.data?.stream;
        if (stream == null) {
          throw Exception('The server returned no file data.');
        }
        await for (final chunk in stream) {
          if (token.isCancelled) break;
          sink.writeFromSync(chunk);
          received += chunk.length;
          if (total > 0 && mounted) {
            setState(() {
              item.progress = (received / total).clamp(0.0, 1.0);
            });
          }
        }
      } finally {
        sink.closeSync();
      }

      if (item.status == 'Paused' || token.isCancelled) {
        await _saveItems();
        return;
      }

      if (total > 0 && received < total) {
        throw Exception('Download ended before the full file was received.');
      }

      final destination = File(item.path);
      if (await destination.exists()) await destination.delete();
      await partial.rename(item.path);
      item.progress = 1;
      item.status = 'Completed';
      item.error = null;
    } on DioException catch (e) {
      if (item.status != 'Paused' && !CancelToken.isCancel(e)) {
        item.status = 'Failed';
        item.error = e.message ?? 'Download failed';
      }
    } catch (e) {
      if (item.status != 'Paused') {
        item.status = 'Failed';
        item.error = e.toString();
      }
    }
    await _saveItems();
    if (mounted) setState(() {});
  }

  Future<void> _pauseItem(DownloadItem item) async {
    if (item.status != 'Downloading') return;
    setState(() => item.status = 'Paused');
    cancelTokens[item]?.cancel('Paused by user');
    await _saveItems();
  }

  Future<void> _resumeItem(DownloadItem item) async {
    if (item.status != 'Paused' && item.status != 'Failed') return;
    final pending = items
        .where((entry) =>
            entry.status == 'Queued' || entry.status == 'Downloading')
        .length;
    if (pending >= 5) {
      _message('The queue already has 5 active or queued tasks.');
      return;
    }
    setState(() {
      item.status = 'Queued';
      item.error = null;
    });
    await _saveItems();
    _processQueue();
  }

  Future<void> _deleteItem(DownloadItem item) async {
    if (item.status == 'Downloading') {
      _message('Pause this download before deleting it.');
      return;
    }
    for (final path in [item.path, item.partialPath]) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    setState(() => items.remove(item));
    await _saveItems();
  }

  Future<void> _openDownload(DownloadItem item) async {
    if (item.status != 'Completed') return;
    await OpenFilex.open(item.path);
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> _showAddDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add authorized media download'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Direct media URL',
                  hintText: 'https://example.com/video.mp4',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'File name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use a direct media file link that you own or are allowed to save. '
                'Protected streaming pages and restricted platform links are not supported.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _addDownload();
            },
            child: const Text('Add to queue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed =
        items.where((item) => item.status == 'Completed').toList();
    final pages = [
      HomeTab(
  onExplore: () => setState(() => selectedTab = 1),
  onDownloads: () => setState(() => selectedTab = 2),
  onLibrary: () => setState(() => selectedTab = 3),
),
ExploreTab(onAdd: () => setState(() => selectedTab = 2)),
DownloadsTab(
        items: items,
        onOpen: _openDownload,
        onPause: _pauseItem,
        onResume: _resumeItem,
        onDelete: _deleteItem,
        onAdd: _showAddDialog,
      ),
      LibraryTab(downloads: completed),
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
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: selectedTab, children: pages),
      floatingActionButton: selectedTab == 2
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add download'),
            )
          : null,
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
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.onExplore,
    required this.onDownloads,
    required this.onLibrary,
  });

  final VoidCallback onExplore;
  final VoidCallback onDownloads;
  final VoidCallback onLibrary;

  @override
  State<HomeTab> createState() => _HomeTabState();
}


class _HomeTabState extends State<HomeTab> {
  final TextEditingController searchController =
      TextEditingController();

  final Dio youtubeDio = Dio();

  String searchText = '';
  bool isSearching = false;
  String? searchError;

  List<Map<String, String>> searchResults = [];

  final List<Map<String, dynamic>> shortcuts = [
    {
      'name': 'YouTube',
      'icon': Icons.play_circle_fill,
      'url': 'https://www.youtube.com',
    },
    {
      'name': 'Facebook',
      'icon': Icons.facebook,
      'url': 'https://www.facebook.com',
    },
    {
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'url': 'https://www.instagram.com',
    },
    {
      'name': 'TikTok',
      'icon': Icons.music_video,
      'url': 'https://www.tiktok.com',
    },
  ];

  final List<Map<String, dynamic>> sections = [
    {
      'title': 'Explore videos',
      'subtitle': 'Discover media platforms',
      'icon': Icons.explore,
      'action': 'explore',
    },
    {
      'title': 'My downloads',
      'subtitle': 'Open your downloaded media',
      'icon': Icons.download,
      'action': 'downloads',
    },
    {
      'title': 'My library',
      'subtitle': 'Browse media on your phone',
      'icon': Icons.video_library,
      'action': 'library',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    youtubeDio.close();
    super.dispose();
  }

  Future<void> searchYouTube(String value) async {
    final query = value.trim();

    if (query.isEmpty) return;

    if (youtubeApiKey.isEmpty) {
      setState(() {
        searchError = 'YouTube API key is missing.';
      });
      return;
    }

    setState(() {
      isSearching = true;
      searchError = null;
      searchResults = [];
    });

    try {
      final response = await youtubeDio.get(
        'https://www.googleapis.com/youtube/v3/search',
        queryParameters: {
         'part': 'snippet',
'type': 'video',
'videoEmbeddable': 'true',
'maxResults': 20,
'q': query,
'key': youtubeApiKey,,
        },
      );

      final data =
          Map<String, dynamic>.from(response.data as Map);

      final items = data['items'] as List<dynamic>? ?? [];

      final results = <Map<String, String>>[];

      for (final raw in items) {
        final item = Map<String, dynamic>.from(raw as Map);

        final id =
            Map<String, dynamic>.from(item['id'] as Map);

        final snippet =
            Map<String, dynamic>.from(item['snippet'] as Map);

        final videoId = id['videoId']?.toString() ?? '';

        if (videoId.isEmpty) continue;

        final thumbnails =
            Map<String, dynamic>.from(
          snippet['thumbnails'] as Map? ?? {},
        );

        final thumbnail =
            thumbnails['high'] ??
            thumbnails['medium'] ??
            thumbnails['default'];

        results.add({
          'id': videoId,
          'title': snippet['title']?.toString() ?? '',
          'channel': snippet['channelTitle']?.toString() ?? '',
          'thumbnail': thumbnail is Map
              ? thumbnail['url']?.toString() ?? ''
              : '',
        });
      }

      if (!mounted) return;

      setState(() {
        searchResults = results;
        isSearching = false;
        if (results.isEmpty) {
          searchError = 'No videos found.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSearching = false;
        searchError = 'Search failed. Check internet or API settings.';
      });
    }
  }

  Future<void> openPlatform(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppBrowserView,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open website.'),
        ),
      );
    }
  }

  Future<void> openVideo(String id) async {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => YouTubePlayerScreen(videoId: id),
    ),
  );
  }
  @override
  Widget build(BuildContext context) {
    final filteredSections = sections.where((section) {
      final query = searchText.toLowerCase();

      return section['title']
              .toString()
              .toLowerCase()
              .contains(query) ||
          section['subtitle']
              .toString()
              .toLowerCase()
              .contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() => searchText = value);
          },
          onSubmitted: searchYouTube,
          decoration: InputDecoration(
            hintText: 'Search YouTube videos...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () =>
                  searchYouTube(searchController.text),
            ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 18),

        if (isSearching)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),

        if (searchError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              searchError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        if (searchResults.isNotEmpty) ...[
          const Text(
            'YouTube Search Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...searchResults.map((video) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: video['thumbnail']!.isNotEmpty
                    ? Image.network(
                        video['thumbnail']!,
                        width: 112,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(
                          width: 112,
                          height: 72,
                          child: Icon(Icons.video_library),
                        ),
                      )
                    : const SizedBox(
                        width: 112,
                        height: 72,
                        child: Icon(Icons.video_library),
                      ),
                title: Text(
                  video['title']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(video['channel']!),
                trailing: const Icon(Icons.play_circle_fill),
                onTap: () => openVideo(video['id']!),
              ),
            );
          }),
        ],

        const SizedBox(height: 20),

        const Text(
          'Your favourite platforms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shortcuts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final site = shortcuts[index];

              return InkWell(
                onTap: () => openPlatform(
                  site['url'] as String,
                ),
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Icon(
                          site['icon'] as IconData,
                          size: 29,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(site['name'] as String),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          'Your media hub',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...filteredSections.map((section) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(section['icon'] as IconData),
              title: Text(section['title'] as String),
              subtitle: Text(section['subtitle'] as String),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                switch (section['action']) {
                  case 'explore':
                    widget.onExplore();
                    break;
                  case 'downloads':
                    widget.onDownloads();
                    break;
                  case 'library':
                    widget.onLibrary();
                    break;
                }
              },
            ),
          );
        }),
      ],
    );
  }
}
class YouTubePlayerScreen extends StatefulWidget {
  const YouTubePlayerScreen({
    super.key,
    required this.videoId,
  });

  final String videoId;

  @override
  State<YouTubePlayerScreen> createState() =>
      _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState
    extends State<YouTubePlayerScreen> {
  late final YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = YoutubePlayerController.fromVideoId(
  videoId: widget.videoId,
  autoPlay: true,
  params: const YoutubePlayerParams(
    showControls: true,
    showFullscreenButton: true,
  ),
);
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VideoHub Pro Player'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            YoutubePlayer(
              controller: controller,
              aspectRatio: 16 / 9,
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Now Playing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link, size: 60),
              const SizedBox(height: 12),
              const Text(
                'Add a direct media link',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use an authorized direct audio or video file URL. '
                'This app does not extract media from streaming websites.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.download),
                label: const Text('Open Downloads'),
              ),
            ],
          ),
        ),
      );
}

class DownloadsTab extends StatelessWidget {
  const DownloadsTab({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
    required this.onAdd,
  });

  final List<DownloadItem> items;
  final ValueChanged<DownloadItem> onOpen;
  final ValueChanged<DownloadItem> onPause;
  final ValueChanged<DownloadItem> onResume;
  final ValueChanged<DownloadItem> onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyTab(
        icon: Icons.download_outlined,
        title: 'No downloads yet',
        message: 'Add an authorized direct media URL to start a download.',
        action: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add download'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final completed = item.status == 'Completed';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                item.kind == 'Audio' ? Icons.music_note : Icons.movie,
              ),
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.kind} • ${item.status}'),
                if (item.status == 'Downloading' || completed) ...[
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: item.progress > 0 ? item.progress : null,
                  ),
                  Text('${(item.progress * 100).toStringAsFixed(0)}%'),
                ],
                if (item.status == 'Paused')
                  const Text('Partial file saved. Resume when ready.'),
                if (item.error != null)
                  Text(
                    item.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'open') onOpen(item);
                if (value == 'pause') onPause(item);
                if (value == 'resume') onResume(item);
                if (value == 'delete') onDelete(item);
              },
              itemBuilder: (_) => [
                if (completed)
                  const PopupMenuItem(
                    value: 'open',
                    child: Text('Open file'),
                  ),
                if (item.status == 'Downloading')
                  const PopupMenuItem(
                    value: 'pause',
                    child: Text('Pause'),
                  ),
                if (item.status == 'Paused' || item.status == 'Failed')
                  const PopupMenuItem(
                    value: 'resume',
                    child: Text('Resume / Retry'),
                  ),
                if (item.status != 'Downloading')
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key, required this.downloads});
  final List<DownloadItem> downloads;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  int mediaTab = 0;
  bool loading = false;
  bool permissionDenied = false;
  String? errorMessage;
  List<AssetEntity> videos = [];
  List<AssetEntity> audios = [];

  @override
  void initState() {
    super.initState();
    _scanDevice();
  }

  Future<void> _scanDevice() async {
    if (loading) return;
    setState(() {
      loading = true;
      permissionDenied = false;
      errorMessage = null;
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

      final videoPaths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );
      final audioPaths = await PhotoManager.getAssetPathList(
        type: RequestType.audio,
        onlyAll: true,
      );

      final videoList = videoPaths.isEmpty
          ? <AssetEntity>[]
          : await videoPaths.first.getAssetListPaged(page: 0, size: 200);
      final audioList = audioPaths.isEmpty
          ? <AssetEntity>[]
          : await audioPaths.first.getAssetListPaged(page: 0, size: 200);

      if (!mounted) return;
      setState(() {
        videos = videoList;
        audios = audioList;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Could not scan device media. Please try again.';
        loading = false;
      });
    }
  }

  Future<void> _openDeviceAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This media file is not available.')),
      );
      return;
    }
    await OpenFilex.open(file.path);
  }

  Future<void> _openDownloaded(DownloadItem item) async {
    await OpenFilex.open(item.path);
  }

  @override
  Widget build(BuildContext context) {
    final deviceItems = mediaTab == 0 ? videos : audios;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Library',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Phone media and completed downloads',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: loading ? null : _scanDevice,
                icon: const Icon(Icons.refresh),
                tooltip: 'Scan phone again',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.video_library_outlined),
                label: Text('Videos'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.audiotrack),
                label: Text('Audio'),
              ),
              ButtonSegment(
                value: 2,
                icon: Icon(Icons.download_done),
                label: Text('Downloads'),
              ),
            ],
            selected: {mediaTab},
            onSelectionChanged: (value) =>
                setState(() => mediaTab = value.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : permissionDenied
                  ? EmptyTab(
                      icon: Icons.lock_outline,
                      title: 'Media permission needed',
                      message:
                          'Allow VideoHub Pro to access the phone media you choose.',
                      action: FilledButton(
                        onPressed: _scanDevice,
                        child: const Text('Grant permission'),
                      ),
                    )
                  : errorMessage != null
                      ? EmptyTab(
                          icon: Icons.error_outline,
                          title: 'Library scan failed',
                          message: errorMessage!,
                          action: FilledButton(
                            onPressed: _scanDevice,
                            child: const Text('Try again'),
                          ),
                        )
                      : mediaTab == 2
                          ? _buildDownloads()
                          : deviceItems.isEmpty
                              ? EmptyTab(
                                  icon: mediaTab == 0
                                      ? Icons.video_library_outlined
                                      : Icons.music_note,
                                  title: 'No media found',
                                  message:
                                      'Media available to this app will appear here.',
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: deviceItems.length,
                                  itemBuilder: (context, index) {
                                    final asset = deviceItems[index];
                                    return _DeviceMediaTile(
                                      asset: asset,
                                      onTap: () => _openDeviceAsset(asset),
                                    );
                                  },
                                ),
        ),
      ],
    );
  }

  Widget _buildDownloads() {
    if (widget.downloads.isEmpty) {
      return const EmptyTab(
        icon: Icons.download_done,
        title: 'No completed downloads',
        message: 'Completed downloads will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.downloads.length,
      itemBuilder: (context, index) {
        final item = widget.downloads[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              item.kind == 'Audio' ? Icons.audiotrack : Icons.video_file,
            ),
            title: Text(item.name),
            subtitle: Text(item.kind),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _openDownloaded(item),
            ),
            onTap: () => _openDownloaded(item),
          ),
        );
      },
    );
  }
}class _DeviceMediaTile extends StatelessWidget {
  const _DeviceMediaTile({
    required this.asset,
    required this.onTap,
  });

  final AssetEntity asset;
  final VoidCallback onTap;

  String _duration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = asset.title ?? 'Untitled media';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 58,
          height: 58,
          child: asset.type == AssetType.video
              ? FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(
                    const ThumbnailSize(180, 180),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) {
                      return const ColoredBox(
                        color: Color(0xFF292B3A),
                        child: Icon(
                          Icons.video_file,
                          color: Colors.white,
                        ),
                      );
                    }
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  },
                )
              : const CircleAvatar(child: Icon(Icons.music_note)),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          asset.type == AssetType.video
              ? 'Video • ${_duration(asset.duration)}'
              : 'Audio • ${_duration(asset.duration)}',
        ),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
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
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Use the premium dark appearance'),
            value: darkMode,
            onChanged: onDarkModeChanged,
          ),
          const Divider(),
          const ListTile(
            title: Text('Light theme styles'),
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
            title: Text('On-device storage'),
            subtitle: Text('Download records and preferences stay on this device.'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About VideoHub Pro'),
            subtitle: Text('Flutter media manager'),
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
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
        ),
      );
}

class EmptyTab extends StatelessWidget {
  const EmptyTab({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 62, color: Colors.grey),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      );
}
