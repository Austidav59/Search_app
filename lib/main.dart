import 'package:flutter/material.dart';
import 'backend.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Animated icons list
  final List<String> animatedIcons = [
    'assets/analysis.png',
    'assets/check.png',
    'assets/search.png',
    'assets/search2.png',
    'assets/search3.png',
    'assets/searchi.png',
    'assets/analysis.png',
    'assets/check.png',
    'assets/search.png',
    'assets/search2.png',
    'assets/search3.png',
    'assets/searchi.png',
  ];

  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isLoading = false; // To show loading spinner
  List<String> _gridImages = []; // List to store images from the API
  int _page = 1; // To handle pagination
  Timer? _debounce;
  bool _hasMoreImages = true; // Flag to check if more images are available

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _animation = Tween<double>(begin: -500, end: 800).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _controller.repeat();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreImages();
    }
  }

  void _loadMoreImages() {
    if (!_isLoading && _hasMoreImages) {
      setState(() {
        _page++;
        fetchImages(_searchController.text);
      });
    }
  }

  // Fetch images from the API
  Future<void> fetchImages(String query) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    List<String> newImages = await pexelsApi(query, _page);
    setState(() {
      _isLoading = false;
      if (newImages.isEmpty) {
        _hasMoreImages = false;
      } else {
        _gridImages.addAll(newImages);
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        setState(() {
          _gridImages = [];
          _page = 1;
          _hasMoreImages = true;
        });
        fetchImages(query);
      } else {
        setState(() {
          _gridImages = [];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 33, 44, 77),
      body: Column(
        children: [
          // Top Text
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                'Search Anything',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Animated Icons Row
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: animatedIcons.map((image) {
                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_animation.value, 0),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Image.asset(
                      image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white,
                ),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _isTyping = value.isNotEmpty;
                });
                _onSearchChanged(value);
              },
            ),
          ),
          // Image Grid
          Expanded(
            child: _isTyping
                ? GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: _gridImages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _gridImages.length) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: HoverToZoomImage(
                            imageUrl: _gridImages[index],
                            zoomFactor: 1.1,
                          ),
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class HoverToZoomImage extends StatefulWidget {
  final String imageUrl;
  final double zoomFactor;

  HoverToZoomImage({required this.imageUrl, this.zoomFactor = 1.1});

  @override
  _HoverToZoomImageState createState() => _HoverToZoomImageState();
}

class _HoverToZoomImageState extends State<HoverToZoomImage> {
  bool _isHovering = false;

  void _showEnlargedImage() {
    showDialog(
      context: context,
      builder: (context) => ImageEnlargeModal(imageUrl: widget.imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _showEnlargedImage,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: _isHovering
              ? (Matrix4.identity()..scale(widget.zoomFactor))
              : Matrix4.identity(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.error, color: Colors.red),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ImageEnlargeModal extends StatelessWidget {
  final String imageUrl;

  const ImageEnlargeModal({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          maxScale: 5.0,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
