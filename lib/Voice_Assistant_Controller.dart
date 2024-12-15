import 'dart:developer';

import 'package:allen/secrets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';



class HomeController extends GetxController{

  static HomeController get instance => Get.find();

  final SpeechToText speechToText = SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  bool isListening = false;
  RxString lastWords = ''.obs;
  String? generatedContent;

  Future<void> initSpeechToText() async {
    await speechToText.initialize();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
  }

  Future<void> startListening(Function(SpeechRecognitionResult) onSpeechResult) async {
    if (await speechToText.hasPermission) {
      isListening = true;
      await speechToText.listen(onResult: onSpeechResult);
    }
  }

  Future<void> stopListening() async {
    if (isListening) {
      isListening = false;
      await speechToText.stop();
    }
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  Future<String> getAnswerFromGemini(String question) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: geminiKey,
      );

      final content = [Content.text(question)];
      final res = await model.generateContent(content, safetySettings: [
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      ]);

      log('Response: ${res.text}');
      return res.text ?? 'No response from Gemini API';
    } catch (e) {
      log('Error fetching response: $e');
      return 'Something went wrong. Please try again later.';
    }
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    lastWords.value = result.recognizedWords;
  }
}
