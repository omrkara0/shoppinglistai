import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoppinglistai/constants.dart';
import 'package:shoppinglistai/models/urun.dart';
import 'package:shoppinglistai/services/gemini_service.dart';
import 'package:shoppinglistai/services/speech_service.dart';
import 'package:shoppinglistai/services/storage_service.dart';
import 'package:shoppinglistai/widgets/custom_app_bar.dart';
import 'package:shoppinglistai/widgets/empty_state.dart';
import 'package:shoppinglistai/widgets/no_results.dart';
import 'package:shoppinglistai/widgets/shopping_list_item.dart';
import 'package:shoppinglistai/widgets/speech_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final GeminiService _geminiService = GeminiService();
  final StorageService _storageService = StorageService();
  final SpeechService _speechService = SpeechService();

  // State
  List<Urun> _urunler = [];
  final Set<int> _selectedItems = {};
  String _searchQuery = '';

  // Animation controller for FAB
  late AnimationController _animationController;

  List<Urun> get _filteredUrunler => _urunler
      .where((urun) =>
          urun.isim.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize services
    await Future.wait([
      _speechService.initialize(),
      _storageService.initialize(),
    ]);

    // Load saved items
    final savedItems = await _storageService.loadItems();
    setState(() => _urunler = savedItems);

    // Initialize Gemini with existing items
    await _geminiService.initialize(_urunler);
  }

  void _startListening() {
    _animationController.forward();
    setState(() {});
    _speechService.startListening(
      onResult: (String text) {
        log(text);
        _processMessage(text);
      },
    );
  }

  Future<void> _stopListening() async {
    _animationController.reverse();
    setState(() {});
    await _speechService.stopListening();
  }

  Future<void> _processMessage(String message) async {
    final updatedItems = await _geminiService.processMessage(message);
    setState(() => _urunler = updatedItems);
    await _storageService.saveItems(updatedItems);
  }

  Future<void> _deleteSelectedItems() async {
    final itemsToDelete =
        _selectedItems.map((index) => _urunler[index].isim).toList();
    final updatedItems = await _geminiService.deleteItems(itemsToDelete);

    setState(() {
      _urunler = updatedItems;
      _selectedItems.clear();
    });

    await _storageService.saveItems(updatedItems);
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
      floatingActionButton: SpeechFAB(
        isAvailable: _speechService.isAvailable,
        isListening: _speechService.isListening,
        onStart: _startListening,
        onStop: _stopListening,
        animation: _animationController,
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
