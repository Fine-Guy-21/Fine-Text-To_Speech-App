import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

// class SavedLists extends StatefulWidget {
//   const SavedLists({super.key});

//   @override
//   State<SavedLists> createState() => _SavedListsState();
// }

// class _SavedListsState extends State<SavedLists> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   List<Map<String, dynamic>> savedAudios = [];
//   Duration _currentPosition = Duration.zero;
//   final Duration _totalDuration = Duration.zero;
//   bool isPlaying = false;
//   String? currentFilePath;

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedAudios();
//   }

//   Future<void> _loadSavedAudios() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final jsonFile = File('${directory.path}/saved_audios.json');

//     if (await jsonFile.exists()) {
//       final content = await jsonFile.readAsString();
//       final decodedData = jsonDecode(content);

//       // Ensure the decoded data is a List
//       if (decodedData is List) {
//         setState(() {
//           savedAudios = List<Map<String, dynamic>>.from(decodedData);
//         });
//       } else {
//         debugPrint(
//             'Invalid JSON format: Expected a List but got ${decodedData.runtimeType}');
//       }
//     }
//   }

//   Future<void> _playAudio(String filePath) async {
//     await _audioPlayer.setSourceDeviceFile(filePath);
//     await _audioPlayer.play(DeviceFileSource(filePath));
//     setState(() {
//       currentFilePath = filePath;
//       isPlaying = true;
//     });
//   }

//   void _playPause() {
//     if (isPlaying) {
//       _audioPlayer.pause();
//     } else {
//       _audioPlayer.resume();
//     }
//     setState(() {
//       isPlaying = !isPlaying;
//     });
//   }

//   void _stop() {
//     _audioPlayer.stop();
//     setState(() {
//       isPlaying = false;
//       _currentPosition = Duration.zero;
//     });
//   }

//   void _seekBy(Duration offset) {
//     Duration newPosition = _currentPosition + offset;
//     if (newPosition < Duration.zero) newPosition = Duration.zero;
//     if (newPosition > _totalDuration) newPosition = _totalDuration;
//     _audioPlayer.seek(newPosition);
//   }

//   String _formatDuration(Duration duration) {
//     return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Saved Audios'),
//         shadowColor: Colors.black38,
//         elevation: 3,
//       ),
//       body: Padding(
//         padding: EdgeInsets.fromLTRB(5, 15, 5, 5),
//         child: Column(
//           children: [
//             if (savedAudios.isEmpty)
//               Center(child: Text('No audio files found.')),
//             if (savedAudios.isNotEmpty)
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: savedAudios.length,
//                   itemBuilder: (context, index) {
//                     final audio = savedAudios[index];
//                     return Dismissible(
//                       key: Key(audio['path']!), // Unique key for each item
//                       direction: DismissDirection
//                           .endToStart, // Swipe from right to left
//                       background: Container(
//                         color: Colors.red, // Background color when swiping
//                         alignment: Alignment.centerRight,
//                         padding: EdgeInsets.only(right: 20),
//                         child: Icon(
//                           Icons.delete,
//                           color: Colors.white,
//                         ),
//                       ),
//                       onDismissed: (direction) async {
//                         // Delete the file from storage
//                         final file = File(audio['path']!);
//                         if (await file.exists()) {
//                           await file.delete();
//                         }

//                         // Remove the item from the list
//                         setState(() {
//                           savedAudios.removeAt(index);
//                         });

//                         // Update the JSON file
//                         final directory =
//                             await getApplicationDocumentsDirectory();
//                         final jsonFile =
//                             File('${directory.path}/saved_audios.json');
//                         await jsonFile.writeAsString(jsonEncode(savedAudios));

//                         // Show a snackbar to confirm deletion
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                               content: Text('Audio deleted successfully!')),
//                         );
//                       },
//                       child: Card(
//                         color: Colors.blue,
//                         margin: EdgeInsets.symmetric(vertical: 5),
//                         child: ListTile(
//                           title: Text(audio['text'] ?? 'No text'),
//                           subtitle: Text(audio['fileName'] ?? 'No file name'),
//                           onTap: () => _playAudio(audio['path']!),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             if (currentFilePath != null)
//               Container(
//                 padding: EdgeInsets.all(5),
//                 decoration: BoxDecoration(
//                   color: Colors.black54,
//                   borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(12), bottom: Radius.circular(5)),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       currentFilePath!.split('/').last,
//                       style: TextStyle(
//                           color: Colors.white, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Text(_formatDuration(_currentPosition),
//                             style: TextStyle(color: Colors.white70)),
//                         Expanded(
//                           child: Slider(
//                             value: _currentPosition.inSeconds.toDouble(),
//                             min: 0,
//                             max: _totalDuration.inSeconds.toDouble(),
//                             onChanged: (double value) {
//                               _audioPlayer
//                                   .seek(Duration(seconds: value.toInt()));
//                             },
//                           ),
//                         ),
//                         Text(_formatDuration(_totalDuration),
//                             style: TextStyle(color: Colors.white70)),
//                       ],
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.replay_5, color: Colors.white),
//                           onPressed: () => _seekBy(Duration(seconds: -1)),
//                         ),
//                         IconButton(
//                           icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
//                               color: Colors.white),
//                           onPressed: _playPause,
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.forward_5, color: Colors.white),
//                           onPressed: () => _seekBy(Duration(seconds: 1)),
//                         ),
//                         IconButton(
//                           icon: Icon(Icons.stop, color: Colors.white),
//                           onPressed: _stop,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class SavedLists extends StatefulWidget {
  const SavedLists({super.key});

  @override
  State<SavedLists> createState() => _SavedListsState();
}

class _SavedListsState extends State<SavedLists> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> savedAudios = [];
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool isPlaying = false;
  String? currentFilePath;

  @override
  void initState() {
    super.initState();
    _loadSavedAudios();
    _setupAudioPlayerListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAudios() async {
    final directory = await getApplicationDocumentsDirectory();
    final jsonFile = File('${directory.path}/saved_audios.json');

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final decodedData = jsonDecode(content);

      // Ensure the decoded data is a List
      if (decodedData is List) {
        setState(() {
          savedAudios = List<Map<String, dynamic>>.from(decodedData);
        });
      } else {
        debugPrint(
            'Invalid JSON format: Expected a List but got ${decodedData.runtimeType}');
      }
    }
  }

  void _setupAudioPlayerListeners() {
    // Listen for duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    // Listen for position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Listen for playback completion
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        _currentPosition = Duration.zero;
      });
    });
  }

  Future<void> _playAudio(String filePath) async {
    await _audioPlayer.setSourceDeviceFile(filePath);
    await _audioPlayer.play(DeviceFileSource(filePath));
    setState(() {
      currentFilePath = filePath;
      isPlaying = true;
    });
  }

  void _playPause() {
    if (isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _stop() {
    _audioPlayer.stop();
    setState(() {
      isPlaying = false;
      _currentPosition = Duration.zero;
    });
  }

  void _seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Audios'),
        shadowColor: Colors.black38,
        elevation: 3,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(5, 15, 5, 5),
        child: Column(
          children: [
            if (savedAudios.isEmpty)
              Center(child: Text('No audio files found.')),
            if (savedAudios.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: savedAudios.length,
                  itemBuilder: (context, index) {
                    final audio = savedAudios[index];
                    return Dismissible(
                      key: Key(audio['path']!), // Unique key for each item
                      direction: DismissDirection
                          .endToStart, // Swipe from right to left
                      background: Container(
                        color: Colors.red, // Background color when swiping
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) async {
                        // Delete the file from storage
                        final file = File(audio['path']!);
                        if (await file.exists()) {
                          await file.delete();
                        }

                        // Remove the item from the list
                        setState(() {
                          savedAudios.removeAt(index);
                        });

                        // Update the JSON file
                        final directory =
                            await getApplicationDocumentsDirectory();
                        final jsonFile =
                            File('${directory.path}/saved_audios.json');
                        await jsonFile.writeAsString(jsonEncode(savedAudios));

                        // Show a snackbar to confirm deletion
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Audio deleted successfully!')),
                        );
                      },
                      child: Card(
                        color: Colors.blue[50],
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(audio['text'] ?? 'No text'),
                          subtitle: Text(audio['fileName'] ?? 'No file name'),
                          onTap: () {
                            setState(() {
                              _currentPosition = Duration.zero;
                            });
                            _playAudio(audio['path']!);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (currentFilePath != null)
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12), bottom: Radius.circular(5)),
                ),
                child: Column(
                  children: [
                    Text(
                      currentFilePath!.split('/').last,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(_formatDuration(_currentPosition),
                            style: TextStyle(color: Colors.white70)),
                        Expanded(
                          child: Slider(
                            value: _currentPosition.inSeconds.toDouble(),
                            min: 0,
                            max: _totalDuration.inSeconds.toDouble(),
                            onChanged: (double value) {
                              _seekTo(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                        Text(_formatDuration(_totalDuration),
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.fast_rewind_outlined,
                              color: Colors.white),
                          onPressed: () =>
                              _seekTo(_currentPosition - Duration(seconds: 1)),
                        ),
                        IconButton(
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white),
                          onPressed: _playPause,
                        ),
                        IconButton(
                          icon: Icon(Icons.fast_forward_outlined,
                              color: Colors.white),
                          onPressed: () =>
                              _seekTo(_currentPosition + Duration(seconds: 1)),
                        ),
                        IconButton(
                          icon: Icon(Icons.stop, color: Colors.white),
                          onPressed: _stop,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
