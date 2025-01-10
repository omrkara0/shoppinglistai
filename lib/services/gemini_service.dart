import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shoppinglistai/constants.dart';
import 'package:shoppinglistai/models/urun.dart';

class GeminiService {
  late final GenerativeModel _generativeModel;
  late final ChatSession _chatSession;

  final GenerationConfig _generationConfig = GenerationConfig(
    responseMimeType: "application/json",
    responseSchema: Schema.array(
      items: Schema.object(
        properties: {
          "isim": Schema.string(),
          "miktar": Schema.number(),
          "miktarTuru": Schema.enumString(enumValues: miktarTurleri)
        },
      ),
    ),
  );

  Future<void> initialize(List<Urun> existingItems) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }

    _generativeModel = GenerativeModel(
      apiKey: apiKey,
      model: "gemini-1.5-flash-latest",
      generationConfig: _generationConfig,
    );

    await _startSession(existingItems);
  }

  Future<void> _startSession(List<Urun> existingItems) async {
    final List<Content> history = [
      Content("user", [
        TextPart(
          "Vereceğim cümlede geçen alışveriş listesini JSON formatında döndür: {isim, miktar, miktarTuru(kilo, adet veya litre)}",
        ),
      ]),
    ];

    if (existingItems.isNotEmpty) {
      final String itemsList = existingItems
          .map((e) => "${e.miktar} ${e.miktarTuru} ${e.isim}")
          .join(", ");
      history.add(Content("user", [TextPart(itemsList)]));
      history.add(
        Content(
          "model",
          [TextPart(jsonEncode(existingItems.map((e) => e.toMap()).toList()))],
        ),
      );
    }

    _chatSession = _generativeModel.startChat(history: history);
  }

  Future<List<Urun>> processMessage(String message) async {
    final Content content = Content.text(message);
    await _generativeModel.countTokens([content]);

    final response = await _chatSession.sendMessage(content);
    if (response.text case final String text) {
      final List items = jsonDecode(text);
      return items.map((e) => Urun.fromMap(e)).toList();
    }
    return [];
  }

  Future<List<Urun>> deleteItems(List<String> itemsToDelete) async {
    final Content content =
        Content.text("Listeden şu ürünleri sil: ${itemsToDelete.join(", ")}");

    final response = await _chatSession.sendMessage(content);
    if (response.text case final String text) {
      final List items = jsonDecode(text);
      return items.map((e) => Urun.fromMap(e)).toList();
    }
    return [];
  }
}
