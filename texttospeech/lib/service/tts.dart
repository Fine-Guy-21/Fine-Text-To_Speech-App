// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';

// class TTSApi {
//   static const String apiUrl = 'https://python2.sweaven.dev/generate-audio';

//   // Function to call the API and download the audio file
//   static Future<void> generateAudio({
//     required String text,
//     required String voiceId,
//     required String selectedVoice,
//   }) async {
//     try {
//       // Send a POST request to the API
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'text': text,
//           'voice_id': voiceId,
//           'selected_voice': selectedVoice,
//         }),
//       );

//       // Check if the request was successful
//       if (response.statusCode == 200) {
//         // Get the application documents directory
//         final directory = await getApplicationDocumentsDirectory();
//         final audioFolder = Directory('${directory.path}/audio');

//         // Create the audio folder if it doesn't exist
//         if (!await audioFolder.exists()) {
//           await audioFolder.create(recursive: true);
//         }

//         // Define the file path
//         final filePath = '${audioFolder.path}/voice_$voiceId.mp3';

//         // Save the file
//         final file = File(filePath);
//         await file.writeAsBytes(response.bodyBytes);

//         debugPrint('File saved at: $filePath');
//       } else {
//         debugPrint('Failed to generate audio: ${response.statusCode}');
//         debugPrint('Response: ${response.body}');
//       }
//     } catch (e) {
//       debugPrint('Error: $e');
//     }
//   }
// }

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TTSApi {
  static const String apiUrl = 'https://python2.sweaven.dev/generate-audio';

  // Function to call the API and download the audio file
  static Future<String?> generateAudio({
    required String text,
    required String voiceId,
    required String selectedVoice,
  }) async {
    try {
      // Validate input parameters
      if (text.isEmpty) {
        debugPrint('Error: Text cannot be empty.');
        return null;
      }
      if (selectedVoice.isEmpty) {
        debugPrint('Error: Selected voice cannot be empty.');
        return null;
      }

      // Send a POST request to the API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'voice_id': voiceId,
          'selected_voice': selectedVoice,
        }),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Validate the response body
        if (response.bodyBytes.isEmpty) {
          debugPrint('Error: Empty response body from the API.');
          return null;
        }

        // Get the application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final audioFolder = Directory('${directory.path}/audio');

        // Create the audio folder if it doesn't exist
        if (!await audioFolder.exists()) {
          await audioFolder.create(recursive: true);
        }

        // Define the file path
        final filePath = '${audioFolder.path}/voice_$voiceId.mp3';

        // Save the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        debugPrint('File saved successfully at: $filePath');
        return filePath; // Return the file path for further use
      } else {
        debugPrint(
            'Failed to generate audio. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      debugPrint('Network error: $e');
      return null;
    } on HttpException catch (e) {
      debugPrint('HTTP error: $e');
      return null;
    } on FileSystemException catch (e) {
      debugPrint('File system error: $e');
      return null;
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return null;
    }
  }

  // Helper method to delete a file
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('File deleted: $filePath');
      } else {
        debugPrint('File not found: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  // Helper method to check if a file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking file existence: $e');
      return false;
    }
  }
}
