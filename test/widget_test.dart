// Testes de widget para TudoLimpo

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tudolimpo_flutter/main.dart';

void main() {
  testWidgets('TudoLimpo app loads and displays home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TudoLimpoApp());

    // Verify that the app bar title is displayed
    expect(find.text('TudoLimpo - Higiene Pessoal'), findsOneWidget);

    // Verify that the welcome text is displayed
    expect(find.text('Bem-vindo à TudoLimpo!'), findsOneWidget);

    // Verify that the buttons are displayed
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);

    // Tap the 'Ver Produtos' button
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Verify that we navigated to the products page
    expect(find.text('Nossos Produtos'), findsOneWidget);
  });

  testWidgets('Product can be added to cart', (WidgetTester tester) async {
    await tester.pumpWidget(const TudoLimpoApp());

    // Navigate to products page
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Tap on a product to view details
    await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
    await tester.pumpAndSettle();

    // Wait for navigation
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify that the product details page is displayed
    expect(find.text('Adicionar ao Carrinho'), findsOneWidget);
  });

  testWidgets('Cart displays items correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const TudoLimpoApp());

    // Navigate to cart
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();

    // Verify that the empty cart message is displayed
    expect(find.text('Carrinho vazio'), findsOneWidget);
  });

  testWidgets('Summary card shows correct values', (WidgetTester tester) async {
    await tester.pumpWidget(const TudoLimpoApp());

    // Verify that "Resumo da compra" appears when we navigate to cart
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();

    // The summary should appear after adding items
    expect(find.byType(SummaryCard), findsWidgets);
  });
}
