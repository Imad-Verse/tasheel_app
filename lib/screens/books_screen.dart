// إعادة تصدير شاشة المتون والأقسام العلمية
export 'categories_screen.dart';

import 'package:flutter/material.dart';
import 'categories_screen.dart';

/// الاسم البديل لتوافق الكود
class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoriesScreen();
  }
}
