// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:texttospeech/Pages/home.dart';
import 'service/tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class AudioListScreen extends StatefulWidget {
  const AudioListScreen({super.key});

  @override
  State<AudioListScreen> createState() => _AudioListScreenState();
}

class _AudioListScreenState extends State<AudioListScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final TextEditingController _controller = TextEditingController();
  var uuid = Uuid();
  String randomId = '';
  List<Map<String, String>> audioFiles =
      []; // Store file path and original text

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  Future<void> _loadAudioFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final jsonFile = File('${directory.path}/audio_files.json');

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final List<dynamic> jsonData =
          jsonDecode(content); // Decode JSON as List<dynamic>

      // Convert List<dynamic> to List<Map<String, String>>
      setState(() {
        audioFiles = jsonData.map((item) {
          return {
            'path': item['path'] as String,
            'text': item['text'] as String,
          };
        }).toList();
      });
    }
  }

  // Function to play audio
  Future<void> playAudio(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        debugPrint('Playing audio from: $filePath');
        await audioPlayer.play(DeviceFileSource(filePath));
        await audioPlayer.setVolume(1);
      } else {
        debugPrint('File not found at: $filePath');
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  // Function to delete audio file and update JSON
  Future<void> _deleteAudioFile(int index) async {
    final filePath = audioFiles[index]['path']!;
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    setState(() {
      audioFiles.removeAt(index);
    });
    _updateJsonFile();
  }

  // Function to update the JSON file
  Future<void> _updateJsonFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final jsonFile = File('${directory.path}/audio_files.json');
    await jsonFile.writeAsString(jsonEncode(audioFiles));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter TTS API Demo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Text input field
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'Enter Text'),
                  ),
                ),
              ),
              // Generate Audio button
              ElevatedButton(
                onPressed: () async {
                  randomId = uuid.v4();
                  final promptText = _controller.text.isEmpty
                      ? 'Sample Text'
                      : _controller.text;

                  // Call the API to generate audio
                  await TTSApi.generateAudio(
                    text: promptText,
                    voiceId: randomId,
                    selectedVoice: 'en-US-JennyNeural',
                  );

                  // Add the new audio file to the list
                  final directory = await getApplicationDocumentsDirectory();
                  final filePath =
                      '${directory.path}/audio/voice_$randomId.mp3';

                  setState(() {
                    audioFiles.add({
                      'path': filePath,
                      'text': promptText, // Store the original prompt text
                    });
                  });

                  // Update the JSON file
                  await _updateJsonFile();
                },
                child: Text('Generate Audio'),
              ),

              SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => NewPage()));
                },
                child: Text('NextPage'),
              ),
              // List of audio files
              if (audioFiles.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: audioFiles.length,
                  itemBuilder: (context, index) {
                    final filePath = audioFiles[index]['path']!;
                    final text = audioFiles[index]['text']!;
                    return Dismissible(
                      key: Key(filePath),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        _deleteAudioFile(index);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50], // Light blue background
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(text), // Display the original prompt text
                          onTap: () {
                            playAudio(filePath);
                          },
                        ),
                      ),
                    );
                  },
                ),
              if (audioFiles.isEmpty) Text('No audio files found.'),
            ],
          ),
        ),
      ),
    );
  }
}

class NewPage extends StatefulWidget {
  const NewPage({super.key});

  @override
  State<NewPage> createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  final _controller = TextEditingController();
  double _VolumeSlider = 0.5;
  double _PitchSlider = 0.5;
  double _SpeechSlider = 0.5;
  String? selectedLanguage;
  String? selectedVoice;

  final Map<String, Map<String, String>> languageVoices = {
    "English": {
      "Steffan": "en-US-SteffanNeural",
      "Jenny": "en-US-JennyNeural",
      "Sonia": "en-GB-SoniaNeural",
      "Thomas": "en-GB-ThomasNeural"
    },
    "Amharic": {"Ameha": "am-ET-AmehaNeural", "Mekdes": "am-ET-MekdesNeural"},
    "Spanish": {
      "Federico": "es-NI-FedericoNeural",
      "Valentina": "es-UY-ValentinaNeural",
      "Alvaro": "es-ES-AlvaroNeural",
      "Elvira": "es-ES-ElviraNeural"
    },
    "Russian": {
      "Dmitry": "ru-RU-DmitryNeural",
      "Svetlana": "ru-RU-SvetlanaNeural"
    },
    "French": {"Denise": "fr-FR-DeniseNeural", "Henri": "fr-FR-HenriNeural"},
    "German": {
      "Ingrid": "de-AT-IngridNeural",
      "Jonas": "de-AT-JonasNeural",
      "Amala": "de-DE-AmalaNeural",
      "Conrad": "de-DE-ConradNeural"
    },
    "Arabic": {
      "Fatima": "ar-AE-FatimaNeural",
      "Hamdan": "ar-AE-HamdanNeural",
      "Hamed": "ar-SA-HamedNeural",
      "Zariyah": "ar-SA-ZariyahNeural"
    }
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fine Text to Speech'),
        shadowColor: Colors.black38,
        elevation: 3,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SavedLists()));
              },
              icon: Icon(Icons.save_alt_rounded))
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Text Field
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(5)),
                  constraints: BoxConstraints(
                      minHeight: 200), // Fixed height for the text field
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: InputDecoration(
                      label: Text(
                        'Input Text',
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                  ),
                ),

                SizedBox(
                  height: 30,
                ),
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 30,
                            color: Colors.green,
                          ),
                          Text(
                            'Play',
                            style: TextStyle(color: Colors.green),
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                        onTap: () {},
                        child: Column(
                          children: [
                            Icon(
                              Icons.pause_rounded,
                              size: 30,
                              color: Colors.amber,
                            ),
                            Text(
                              'Pause',
                              style: TextStyle(color: Colors.amber),
                            )
                          ],
                        )),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Icon(
                            Icons.stop_rounded,
                            size: 30,
                            color: Colors.red,
                          ),
                          Text(
                            'Stop',
                            style: TextStyle(color: Colors.red),
                          )
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 30,
                ),

                // Select Language
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12), // Padding inside dropdown
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey, width: 1), // Border
                      borderRadius:
                          BorderRadius.circular(8), // Optional rounded corners
                    ),
                    child: DropdownButtonHideUnderline(
                      // Removes default underline
                      child: DropdownButton<String>(
                        value: selectedLanguage,
                        hint: Text('Select Language'),
                        isExpanded:
                            true, // Ensures spacing between hint/value and icon
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLanguage = newValue;
                            selectedVoice =
                                null; // Reset voice when language changes
                          });
                        },
                        items: languageVoices.keys
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: 10), // Left padding for menu items
                              child: Text(value),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Select Voice
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12), // Padding inside dropdown
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey, width: 1), // Border
                      borderRadius:
                          BorderRadius.circular(8), // Optional rounded corners
                    ),
                    child: DropdownButtonHideUnderline(
                      // Removes default underline
                      child: DropdownButton<String>(
                        value: selectedVoice,
                        hint: Text('Select Voice'),
                        isExpanded:
                            true, // Ensures spacing between hint/value and icon
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedVoice = newValue;
                          });
                        },
                        items: selectedLanguage != null
                            ? languageVoices[selectedLanguage]!
                                .keys
                                .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: 10), // Left padding for items
                                    child: Text(value),
                                  ),
                                );
                              }).toList()
                            : [],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // if (selectedLanguage != null && selectedVoice != null)
                //   Text(
                //     'Selected Voice: ${languageVoices[selectedLanguage]![selectedVoice]}',
                //     style: TextStyle(fontSize: 18),
                //   ),

                // Voice Controllers
                Container(
                  constraints: BoxConstraints(minHeight: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volume : ${_VolumeSlider.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                      Slider.adaptive(
                        label: 'Slider',
                        thumbColor: Colors.green.shade900,
                        activeColor: Colors.green.shade700,
                        inactiveColor: Colors.green,
                        value: _VolumeSlider,
                        onChanged: (double newvalue) {
                          setState(() {
                            _VolumeSlider = newvalue;
                          });
                        },
                      ),
                      Text(
                        'Pitch ${_PitchSlider.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                      Slider.adaptive(
                        label: 'Slider',
                        thumbColor: Colors.red.shade900,
                        activeColor: Colors.red.shade700,
                        inactiveColor: Colors.red,
                        value: _PitchSlider,
                        onChanged: (double newvalue) {
                          setState(() {
                            _PitchSlider = newvalue;
                          });
                        },
                      ),
                      Text(
                        'Speech Rate ${_SpeechSlider.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                      Slider.adaptive(
                        label: 'Slider',
                        thumbColor: Colors.blue.shade900,
                        activeColor: Colors.blue.shade700,
                        inactiveColor: Colors.blue,
                        value: _SpeechSlider,
                        onChanged: (double newvalue) {
                          setState(() {
                            _SpeechSlider = newvalue;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Save Button
                Container(
                  margin: EdgeInsets.only(bottom: 15),
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      backgroundColor: Colors.amber,
                    ),
                    child: Text('Save Audio'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SavedLists extends StatefulWidget {
  const SavedLists({super.key});

  @override
  State<SavedLists> createState() => _SavedListsState();
}

class _SavedListsState extends State<SavedLists> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Load audio file
    // _audioPlayer.setSourceDeviceFile(widget.filePath);

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        _currentPosition = Duration.zero;
      });
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

  void _seekBy(Duration offset) {
    Duration newPosition = _currentPosition + offset;
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > _totalDuration) newPosition = _totalDuration;
    _audioPlayer.seek(newPosition);
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ListView() for displaying the loaded contents
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12), bottom: Radius.circular(5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // File Name
                  Text(
                    ' widget.fileName',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  // Seek Bar & Time Info
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
                            _audioPlayer.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Text(_formatDuration(_totalDuration),
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),

                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.replay_5, color: Colors.white),
                        onPressed: () => _seekBy(Duration(seconds: -5)),
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white),
                        onPressed: _playPause,
                      ),
                      IconButton(
                        icon: Icon(Icons.forward_5, color: Colors.white),
                        onPressed: () => _seekBy(Duration(seconds: 5)),
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
