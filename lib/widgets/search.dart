import 'package:flutter/material.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SearchScreen extends StatefulWidget {
  final Function(String) onSearch;
  final String initialQuery;
  final bool autoStartListening;

  const SearchScreen({
    super.key,
    required this.onSearch,
    this.initialQuery = '',
    this.autoStartListening = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseService firebaseService = GetIt.instance<FirebaseService>();
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  bool _dialogOpen = false; // Tracks the STT dialog to avoid duplicate pops

  // Speech to text
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _loadRecentSearches();
    _initSpeech().then((_) {
      if (!mounted) return;
      if (widget.autoStartListening) {
        _startListeningWithDialog();
      }
    });
  }

  /// This has to happen only once per app
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      // Request microphone permission
      PermissionStatus status = await Permission.microphone.request();
      
      if (!status.isGranted) {
        print('Microphone permission not granted');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required for speech-to-text')),
          );
        }
        setState(() {
          _speechEnabled = false;
        });
        return;
      }

      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          print('onStatus: $status');
          if (status == 'done' || status == 'notListening') {
            _closeDialogIfOpen();
          }
          if (mounted) {
            setState(() {});
          }
        },
        onError: (errorNotification) {
          print('onError: $errorNotification');
          // Stop immediately on any STT error (e.g., error_no_match)
          _stopListening();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech error: ${errorNotification.errorMsg}')),
            );
            setState(() {});
          }
        },
      );
      if (!_speechEnabled) {
        print('Speech recognition not available');
        // Show snackbar to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
      } else {
        print('Speech recognition initialized successfully');
      }
    } catch (e) {
      print('Error initializing speech: $e');
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startListeningWithDialog() async {
    final started = await _startListening();
    if (started && mounted) {
      _showSttPopup();
    }
  }

  /// Each time to start a speech recognition session
  Future<bool> _startListening() async {
    if (!_speechEnabled) {
      print('Speech recognition not enabled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not enabled')),
        );
      }
      return false;
    }
    
    // Request permission again before listening
    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
      return false;
    }
    
    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 40),
        pauseFor: const Duration(seconds: 5),
        localeId: "en_US",
      );
      if (mounted) {
        setState(() {});
      }
      // If listen didn't actually start, don't show the dialog
      if (!_speech.isListening) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mic is not ready yet. Please try again.')),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      print('Error starting listening: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return false;
    }
  }

  /// Manually stop the active speech recognition session
  void _stopListening() async {
    await _speech.stop();
    _closeDialogIfOpen();
    if (mounted) {
      setState(() {});
    }
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(result) {
    if (!mounted) return;
    setState(() {
      _lastWords = result.recognizedWords;
      _searchController.text = _lastWords;
    });
    if (result.finalResult) {
      _stopListening();
      _onSearch();
    }
  }

  void _showSttPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Listening...",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_lastWords),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _stopListening,
                    child: const Text("Stop"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _dialogOpen = true;
  }

  void _closeDialogIfOpen() {
    if (_dialogOpen && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _dialogOpen = false;
  }

  void _loadRecentSearches() async {
    _recentSearches = await firebaseService.fetchRecentSearches();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _closeDialogIfOpen();
    if (_speech.isListening) {
      _speech.stop();
    }
    _speech.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      await firebaseService.saveRecentSearch(query);
      widget.onSearch(query);
      setState(() {
        _recentSearches.insert(0, query);
      });
    }
  }

  void _clearSearchResults() {
    _searchController.clear();
    setState(() {});
    widget.onSearch('');
  }

  Future<void> _removeRecentSearch(String query) async {
    _recentSearches.removeWhere((item) => item == query);
    setState(() {});
    await firebaseService.removeRecentSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _onSearch,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: _clearSearchResults,
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      onPressed: _onSearch,
                      icon: const Icon(Icons.search),
                    ),
                    IconButton(
                      onPressed: _speechEnabled 
                          ? _startListeningWithDialog 
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Speech recognition not available on this device.\nPlease use text search.'),
                                ),
                              );
                            },
                      icon: Icon(
                        Icons.mic,
                        color: _speechEnabled ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent Searches',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView(
                children: _recentSearches
                    .map((search) => ListTile(
                          title: Text(search),
                          onTap: () {
                            _searchController.text = search;
                            _onSearch();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove',
                            onPressed: () => _removeRecentSearch(search),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}