import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:texttospeech/Pages/savedlist.dart';
import 'dart:convert';
import 'package:texttospeech/service/tts.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _volumeSlider = 1.0;
  double _playbackSpeed = 1;
  String? selectedLanguage;
  String? selectedVoice;
  String? tempFilePath;
  String randomId = "";
  var uuid = Uuid();

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
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _generateAndPlayAudio() async {
    if (selectedVoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a voice to generate audio.')),
      );
      return;
    }

    final text = _controller.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter some text.')),
      );
      return;
    }
    randomId = 'temp';
    final directory = await getApplicationDocumentsDirectory();
    final audioFolder = Directory('${directory.path}/audio');
    tempFilePath = '${audioFolder.path}/voice_$randomId.mp3';

    await TTSApi.generateAudio(
      text: text,
      voiceId: randomId,
      selectedVoice: languageVoices[selectedLanguage]![selectedVoice]!,
    );

    await _audioPlayer.setVolume(_volumeSlider);
    await _audioPlayer.setPlaybackRate(_playbackSpeed);
    await _audioPlayer.play(DeviceFileSource(tempFilePath!));
  }

  Future<void> _saveAudio() async {
    final text = _controller.text;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter some text to save.')),
      );
      return;
    }

    if (selectedVoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a voice to generate audio.')),
      );
      return;
    }

    // Generate a new random ID
    randomId = uuid.v4();

    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final audioFolder = Directory('${directory.path}/audio');
    final savedAudiosFolder = Directory('${directory.path}/saved_audios');

    // Ensure the 'audio' and 'saved_audios' folders exist
    if (!await audioFolder.exists()) {
      await audioFolder.create(recursive: true);
    }
    if (!await savedAudiosFolder.exists()) {
      await savedAudiosFolder.create(recursive: true);
    }

    // Define the file path in the 'audio' folder
    final tempFilePath = '${audioFolder.path}/voice_$randomId.mp3';

    // Generate and save the audio file in the 'audio' folder
    await TTSApi.generateAudio(
      text: text,
      voiceId: randomId,
      selectedVoice: languageVoices[selectedLanguage]![selectedVoice]!,
    );

    // Define the new file path in the 'saved_audios' folder
    final fileName = 'audio_$randomId.mp3';
    final savedFilePath = '${savedAudiosFolder.path}/$fileName';

    // Move the audio file from the 'audio' folder to the 'saved_audios' folder
    final tempFile = File(tempFilePath);
    if (await tempFile.exists()) {
      await tempFile.rename(savedFilePath);
      debugPrint('Audio moved from $tempFilePath to $savedFilePath');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save audio. File not found.')),
      );
      return;
    }

    // Update the JSON file
    final jsonFile = File('${directory.path}/saved_audios.json');
    List<Map<String, dynamic>> audioList = [];

    if (await jsonFile.exists()) {
      final content = await jsonFile.readAsString();
      final decodedData = jsonDecode(content);

      // Ensure the decoded data is a List
      if (decodedData is List) {
        audioList = List<Map<String, dynamic>>.from(decodedData);
      } else {
        debugPrint(
            'Invalid JSON format: Expected a List but got ${decodedData.runtimeType}');
      }
    }

    // Add the new audio file to the list
    audioList.add({
      'path': savedFilePath,
      'text': text,
      'fileName': fileName,
    });

    // Write the updated list back to the JSON file
    await jsonFile.writeAsString(jsonEncode(audioList));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio saved successfully!')),
    );
  }

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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SavedLists()),
              );
            },
            icon: Icon(Icons.save_alt_rounded),
          ),
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
                  constraints: BoxConstraints(minHeight: 200),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: InputDecoration(
                      label: Text('Input Text', style: TextStyle(fontSize: 15)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _generateAndPlayAudio,
                      child: Column(
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              size: 30, color: Colors.green),
                          Text('Play', style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _audioPlayer.pause(),
                      child: Column(
                        children: [
                          Icon(Icons.pause_rounded,
                              size: 30, color: Colors.amber),
                          Text('Pause', style: TextStyle(color: Colors.amber)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _audioPlayer.stop(),
                      child: Column(
                        children: [
                          Icon(Icons.stop_rounded, size: 30, color: Colors.red),
                          Text('Stop', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // Language and Voice Selection
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLanguage,
                        hint: Text('Select Language'),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLanguage = newValue;
                            selectedVoice = null;
                          });
                        },
                        items: languageVoices.keys
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(value),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Voice Selection
                if (selectedLanguage != null)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedVoice,
                          hint: Text('Select Voice'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedVoice = newValue;
                            });
                          },
                          items: languageVoices[selectedLanguage]!
                              .keys
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(value),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 20),

                // Volume, Pitch, and Speech Rate Sliders
                Container(
                  constraints: BoxConstraints(minHeight: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Volume: ${_volumeSlider.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 15)),
                      Slider.adaptive(
                        value: _volumeSlider,
                        onChanged: (double newValue) {
                          setState(() {
                            _volumeSlider = newValue;
                            _audioPlayer.setVolume(_volumeSlider);
                          });
                        },
                      ),
                      Text('Speech Rate: ${_playbackSpeed.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 15)),
                      Slider.adaptive(
                        value: _playbackSpeed,
                        min: 0.5,
                        max: 2.0,
                        onChanged: (double newValue) {
                          setState(() {
                            _playbackSpeed = newValue;
                            _audioPlayer.setPlaybackRate(_playbackSpeed);
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
                    onPressed: _saveAudio,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
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
