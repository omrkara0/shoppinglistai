import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoppinglistai/constants.dart';
import 'package:shoppinglistai/models/urun.dart';
import 'package:shoppinglistai/widgets/custom_app_bar.dart';
import 'package:shoppinglistai/widgets/empty_state.dart';
import 'package:shoppinglistai/widgets/no_results.dart';
import 'package:shoppinglistai/widgets/shopping_list_item.dart';
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
  String _searchQuery = '';

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

  List<Urun> get _filteredUrunler => _urunler
      .where((urun) =>
          urun.isim.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

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

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      itemCount: _urunler.length,
      selectedItems: _selectedItems,
      onDeleteSelected: _deleteSelectedItems,
      onSearch: (value) => setState(() => _searchQuery = value),
      showSearch: _urunler.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _speechAvailable
            ? (_listening ? _stopListening : _startListening)
            : null,
        backgroundColor: _listening ? AppColors.darkGrey : AppColors.accent,
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.2, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _listening ? 'Dinlemeyi Durdur' : 'Sesli Komut',
            key: ValueKey<bool>(_listening),
            style: GoogleFonts.ubuntu(
              fontWeight: FontWeight.w500,
              color: AppColors.lightText,
            ),
          ),
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            _listening ? Icons.stop_rounded : Icons.mic_rounded,
            key: ValueKey<bool>(_listening),
            color: AppColors.lightText,
          ),
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_urunler.isEmpty) {
      return const EmptyState();
    }

    final items = _filteredUrunler;
    if (items.isEmpty) {
      return const NoResults();
    }

    return Flexible(
      child: ListView.builder(
        itemCount: items.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final Urun urun = items[index];
          final bool isSelected = _selectedItems.contains(index);

          return ShoppingListItem(
            urun: urun,
            isSelected: isSelected,
            onSelected: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedItems.add(index);
                } else {
                  _selectedItems.remove(index);
                }
              });
            },
          );
        },
      ),
    );
  }
}
