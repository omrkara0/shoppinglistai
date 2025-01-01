import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoppinglistai/constants.dart';
import 'package:shoppinglistai/models/urun.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Urun> _urunler = [];

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;

  // Google Generative AI
  late final GenerativeModel _generativeModel;

  final GenerationConfig _generationConfig = GenerationConfig(
      responseMimeType: "application/json",
      responseSchema: Schema.array(
          items: Schema.object(properties: {
        "isim": Schema.string(),
        "miktar": Schema.number(),
        "miktarTuru": Schema.enumString(enumValues: miktarTurleri)
      })));

  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _speech
        .initialize()
        .then((value) => setState(() => _speechAvailable = true));

    _generativeModel = GenerativeModel(
      apiKey: "AIzaSyBzDHhSknCFkedGpR8U7VaL4oKWlV2Q23Y",
      model: "gemini-1.5-flash-latest",
      generationConfig: _generationConfig,
    );
    _startGeminiSession();
  }

  void _startListening() {
    setState(() => _listening = true);
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          log(result.recognizedWords);
          _sendMessage(result.recognizedWords);
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop().then((value) => setState(() => _listening = false));
  }

  void _startGeminiSession() {
    _chatSession = _generativeModel.startChat(history: [
      Content("user", [
        TextPart(
            "Vereceğim cümlede geçen alışveriş listesini JSON formatında döndür: {isim, miktar, miktarTuru(kilo, adet veya litre)}")
      ]),
    ]);
  }

  void _sendMessage(String message) {
    final Content content = Content.text(message);
    _generativeModel.countTokens([content]).then(
      (CountTokensResponse value) {
        log("${value.totalTokens} token harcandı");
      },
    );

    _chatSession.sendMessage(content).then(
      (GenerateContentResponse value) {
        if (value.text case final String text) {
          final List urunler = jsonDecode(text);
          _urunler = urunler.map((e) => Urun.fromMap(e)).toList();
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Alışveriş Listesi",
          style: GoogleFonts.ubuntu(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: !_listening
            ? IconButton(
                onPressed: _speechAvailable ? _startListening : null,
                icon: const Icon(
                  Icons.keyboard_voice,
                ),
              )
            : IconButton(
                onPressed: _stopListening,
                icon: const Icon(
                  Icons.stop,
                ),
              ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _urunlerListe(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _urunlerListe() {
    if (_urunler.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return Flexible(
        child: ListView.builder(
          itemCount: _urunler.length,
          itemBuilder: (context, index) {
            final Urun urun = _urunler[index];
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: ListTile(
                title: Text(
                  urun.isim,
                  style: GoogleFonts.ubuntu(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                trailing: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${urun.miktar} ",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: "${urun.miktarTuru} ",
                        style: GoogleFonts.ubuntu(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
      );
    }
  }
}
