import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoppinglistai/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int itemCount;
  final Set<int> selectedItems;
  final Function() onDeleteSelected;
  final Function(String) onSearch;
  final bool showSearch;

  const CustomAppBar({
    super.key,
    required this.itemCount,
    required this.selectedItems,
    required this.onDeleteSelected,
    required this.onSearch,
    required this.showSearch,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.darkBackground,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Alışveriş Listesi",
            style: GoogleFonts.ubuntu(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.lightText,
            ),
          ),
          if (showSearch)
            Text(
              "$itemCount ürün",
              style: GoogleFonts.ubuntu(
                fontSize: 14,
                color: AppColors.lightGrey.withOpacity(0.7),
              ),
            ),
        ],
      ),
      bottom: showSearch
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  onChanged: onSearch,
                  style: TextStyle(color: AppColors.lightText),
                  decoration: InputDecoration(
                    hintText: 'Ürün ara...',
                    hintStyle:
                        TextStyle(color: AppColors.lightText.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.lightText.withOpacity(0.7)),
                    filled: true,
                    fillColor: AppColors.darkGrey.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            )
          : null,
      actions: [
        if (selectedItems.isNotEmpty) ...[
          Text(
            "${selectedItems.length} seçildi",
            style: GoogleFonts.ubuntu(
              color: AppColors.lightText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: AppColors.accent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  title: Text(
                    'Seçili Ürünleri Sil',
                    style: GoogleFonts.ubuntu(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  content: Text(
                    'Seçili ${selectedItems.length} ürünü silmek istediğinizden emin misiniz?',
                    style: GoogleFonts.ubuntu(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'İptal',
                        style: GoogleFonts.ubuntu(color: AppColors.darkGrey),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDeleteSelected();
                      },
                      child: Text(
                        'Sil',
                        style: GoogleFonts.ubuntu(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Seçili öğeleri sil',
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);
}
