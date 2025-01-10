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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Urun> _urunler = [];
  final Set<int> _selectedItems = {};

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;

  // Animation controller for FAB
  late AnimationController _animationController;

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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _generativeModel = GenerativeModel(
      apiKey: "AIzaSyBzDHhSknCFkedGpR8U7VaL4oKWlV2Q23Y",
      model: "gemini-1.5-flash-latest",
      generationConfig: _generationConfig,
    );
    _startGeminiSession();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() => _listening = true);
    _animationController.forward();
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
    _speech.stop().then((value) {
      setState(() => _listening = false);
      _animationController.reverse();
    });
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

  void _deleteSelectedItems() {
    String itemsToDelete =
        _selectedItems.map((index) => _urunler[index].isim).join(", ");

    final Content content =
        Content.text("Listeden şu ürünleri sil: $itemsToDelete");
    _chatSession.sendMessage(content).then(
      (GenerateContentResponse value) {
        if (value.text case final String text) {
          final List urunler = jsonDecode(text);
          setState(() {
            _urunler = urunler.map((e) => Urun.fromMap(e)).toList();
            _selectedItems.clear();
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Alışveriş Listesi",
          style: GoogleFonts.ubuntu(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          if (_selectedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _deleteSelectedItems,
                tooltip: 'Seçili öğeleri sil',
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _speechAvailable
            ? (_listening ? _stopListening : _startListening)
            : null,
        backgroundColor: _listening ? Colors.red : Colors.blue,
        label: Text(
          _listening ? 'Dinlemeyi Durdur' : 'Sesli Komut',
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.w500),
        ),
        icon: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _animationController,
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Alışveriş listeniz boş',
              style: GoogleFonts.ubuntu(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ürün eklemek için mikrofon butonuna tıklayın',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        itemCount: _urunler.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final Urun urun = _urunler[index];
          final bool isSelected = _selectedItems.contains(index);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedItems.add(index);
                        } else {
                          _selectedItems.remove(index);
                        }
                      });
                    },
                    shape: const CircleBorder(),
                    activeColor: Colors.blue,
                  ),
                ),
                title: Text(
                  urun.isim,
                  style: GoogleFonts.ubuntu(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    decoration: isSelected ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${urun.miktar} ",
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        TextSpan(
                          text: urun.miktarTuru,
                          style: GoogleFonts.ubuntu(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
