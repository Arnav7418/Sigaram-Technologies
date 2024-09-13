import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<String> navItems = ['Settings', 'Categories', 'Home', 'Discover', 'Profile'];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Arnsv's Video Feed App"),
        centerTitle: true,
      ),
      body: _selectedIndex == 0
          ? SettingsScreen()
          : _selectedIndex == 2
              ? VideoFeed()
              : Center(child: Text(navItems[_selectedIndex])),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedLanguage = '';
  String selectedColor = '';
  List<String> languageOptions = [];
  List<String> colorOptions = [];

  @override
  void initState() {
    super.initState();
    fetchLanguageOptions();
    fetchColorOptions();
  }

  Future<void> fetchLanguageOptions() async {
    final snapshot = await FirebaseFirestore.instance.collection('language_options').get();
    setState(() {
      languageOptions = snapshot.docs
          .map((doc) => doc.data().values.first as String)
          .toList()
        ..sort((a, b) => a.compareTo(b));
      if (languageOptions.isNotEmpty) {
        selectedLanguage = languageOptions.first;
      }
    });
  }

  Future<void> fetchColorOptions() async {
    final snapshot = await FirebaseFirestore.instance.collection('color_options').get();
    setState(() {
      colorOptions = snapshot.docs
          .map((doc) => doc.data().values.first as String)
          .toList()
        ..sort((a, b) => a.compareTo(b));
      if (colorOptions.isNotEmpty) {
        selectedColor = colorOptions.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: languageOptions.map((language) => _buildLanguageButton(language)).toList(),
          ),
          SizedBox(height: 32),
          Text('Select Color', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colorOptions.map((color) => _buildColorButton(color)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String language) {
    bool isSelected = selectedLanguage == language;
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.black,
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          setState(() {
            selectedLanguage = language;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(language, style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            if (isSelected) Icon(Icons.check, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(String colorName) {
    bool isSelected = selectedColor == colorName;
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: _getColorFromName(colorName),
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
          ),
        ),
        onPressed: () {
          setState(() {
            selectedColor = colorName;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(colorName, style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            if (isSelected) Icon(Icons.check, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'beige(default)': return Color(0xFFF5F5DC);
      case 'green': return Colors.green;
      case 'hot pink': return const Color.fromARGB(255, 242, 4, 123);
      case 'blue': return Colors.blue;
      case 'lime yellow': return Colors.yellow;
      case 'royal blue': return const Color(0xff063970);
      default: return Colors.grey;
    }
  }
}

class VideoFeed extends StatefulWidget {
  @override
  _VideoFeedState createState() => _VideoFeedState();
}

class _VideoFeedState extends State<VideoFeed> {
  final PageController _pageController = PageController();
  List<DocumentSnapshot> _videos = [];
  List<YoutubePlayerController> _controllers = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('video_links').get();
      setState(() {
        _videos = snapshot.docs;
        _initializeControllers();
      });
    } catch (e) {
      print('Error fetching videos: $e');
    }
  }

  void _initializeControllers() {
    _controllers = _videos.map((video) {
      final videoData = video.data() as Map<String, dynamic>;
      final videoId = YoutubePlayer.convertUrlToId(videoData['link'] as String) ?? 'dQw4w9WgXcQ';
      return YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _videos.isEmpty
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _controllers[_currentIndex].play();
              },
              itemBuilder: (context, index) {
                final video = _videos[index].data() as Map<String, dynamic>;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    YoutubePlayer(
                      controller: _controllers[index],
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.red,
                      progressColors: ProgressBarColors(
                        playedColor: Colors.red,
                        handleColor: Colors.redAccent,
                      ),
                      onReady: () {
                        if (index == _currentIndex) _controllers[index].play();
                      },
                    ),
                    Positioned(
                      bottom: 20,
                      left: 10,
                      child: Text(
                        video['title'],
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}