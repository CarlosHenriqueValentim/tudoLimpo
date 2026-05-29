// ============================================================
//  TudoLimpo – TL Loja de Higiene Pessoal
//  Versão: 2.0.0
//
//  Desafios implementados:
//   1. Produtos novos  – products.json com 36 produtos reais
//   2. Frete grátis    – acima de R$ 150,00
//   3. Campo CEP       – CEP de cobrança e entrega separados
//   4. Tela confirmação – OrderConfirmationPage dedicada
//   5. Supabase        – SupabaseService com stub pronto para conexão
// ============================================================

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// ─────────────────────────────────────────────
//  DESAFIO 5 – SUPABASE SERVICE (stub / plano)
//
//  Para conectar ao banco real:
//   1. Adicione supabase_flutter ao pubspec.yaml
//   2. Substitua os valores abaixo pelos seus
//   3. Descomente os blocos marcados com [SUPABASE]
//
//  Tabela sugerida no Supabase:
//  CREATE TABLE products (
//    id              TEXT PRIMARY KEY,
//    name            TEXT NOT NULL,
//    price           NUMERIC(10,2) NOT NULL,
//    stock           INT DEFAULT 0,
//    icon            TEXT,
//    category        TEXT,
//    brand           TEXT,
//    short_description TEXT,
//    long_description  TEXT,
//    rating          NUMERIC(3,1),
//    reviews         INT DEFAULT 0
//  );
// ─────────────────────────────────────────────
class SupabaseConfig {
  // ↓ Substitua pelas suas credenciais do Supabase
  static const String supabaseUrl = 'https://SEU_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'SUA_ANON_KEY_AQUI';

  // Quando o banco estiver pronto, mude para true
  static const bool useSupabase = false;
}

class SupabaseService {
  // [SUPABASE] Descomente quando instalar supabase_flutter:
  // static late final SupabaseClient _client;
  // static Future<void> initialize() async {
  //   await Supabase.initialize(
  //     url: SupabaseConfig.supabaseUrl,
  //     anonKey: SupabaseConfig.supabaseAnonKey,
  //   );
  //   _client = Supabase.instance.client;
  // }
  //
  // static Future<List<Map<String,dynamic>>> fetchProducts() async {
  //   final response = await _client.from('products').select().order('name');
  //   return List<Map<String,dynamic>>.from(response as List);
  // }

  /// Por enquanto carrega do assets/products.json
  static Future<List<Product>> loadProducts() async {
    if (SupabaseConfig.useSupabase) {
      // [SUPABASE] Troque pelo fetch real quando pronto:
      // final rows = await fetchProducts();
      // return rows.map(Product.fromSupabaseRow).toList();
      throw UnimplementedError('Supabase não configurado ainda.');
    }
    final String jsonText = await rootBundle.loadString('assets/products.json');
    final List<dynamic> decoded = json.decode(jsonText) as List<dynamic>;
    return decoded
        .map((dynamic item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

// ─────────────────────────────────────────────
//  MODELOS
// ─────────────────────────────────────────────
class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String icon;
  final String category;
  final String brand;
  final String shortDescription;
  final String longDescription;
  final double rating;
  final int reviews;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.icon,
    required this.category,
    required this.brand,
    required this.shortDescription,
    required this.longDescription,
    required this.rating,
    required this.reviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      icon: json['icon'] as String,
      category: json['category'] as String? ?? 'geral',
      brand: json['brand'] as String? ?? 'TudoLimpo',
      shortDescription: json['shortDescription'] as String,
      longDescription: json['longDescription'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviews: json['reviews'] as int? ?? 0,
    );
  }

  // [SUPABASE] Factory para linhas vindas do banco:
  factory Product.fromSupabaseRow(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      price: (row['price'] as num).toDouble(),
      stock: row['stock'] as int,
      icon: row['icon'] as String? ?? 'soap',
      category: row['category'] as String? ?? 'geral',
      brand: row['brand'] as String? ?? 'TudoLimpo',
      shortDescription: row['short_description'] as String? ?? '',
      longDescription: row['long_description'] as String? ?? '',
      rating: (row['rating'] as num?)?.toDouble() ?? 4.5,
      reviews: row['reviews'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────
//  CONTROLADOR CENTRAL
// ─────────────────────────────────────────────
class StoreController extends ChangeNotifier {
  final Map<String, int> _cart = <String, int>{};

  List<Product> products = <Product>[];
  List<Product> _filtered = <Product>[];
  bool loading = true;
  String? loadError;
  String? confirmationNumber;
  String searchQuery = '';
  String selectedCategory = 'todos';

  Future<void> loadProducts() async {
    try {
      products = await SupabaseService.loadProducts();
      _applyFilter();
      loading = false;
      notifyListeners();
    } catch (error) {
      loading = false;
      loadError = 'Não foi possível carregar os produtos: $error';
      notifyListeners();
    }
  }

  List<Product> get filteredProducts => _filtered;

  void search(String query) {
    searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void filterByCategory(String category) {
    selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = products.where((Product p) {
      final bool matchSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.brand.toLowerCase().contains(searchQuery.toLowerCase());
      final bool matchCategory =
          selectedCategory == 'todos' || p.category == selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  List<String> get categories {
    final Set<String> cats = <String>{'todos'};
    for (final Product p in products) {
      cats.add(p.category);
    }
    return cats.toList();
  }

  // ── Carrinho ─────────────────────────────
  Map<String, int> get cart => Map<String, int>.unmodifiable(_cart);
  int get cartItemCount => _cart.values.fold(0, (int t, int q) => t + q);
  Product productById(String id) =>
      products.firstWhere((Product p) => p.id == id);
  int quantityOf(String id) => _cart[id] ?? 0;
  List<Product> get cartProducts => _cart.keys.map(productById).toList();

  bool addToCart(Product product) {
    final int next = quantityOf(product.id) + 1;
    if (next > product.stock) return false;
    _cart[product.id] = next;
    confirmationNumber = null;
    notifyListeners();
    return true;
  }

  bool updateQuantity(Product product, int quantity) {
    if (quantity < 0) return true;
    if (quantity > product.stock) return false;
    if (quantity == 0) {
      _cart.remove(product.id);
    } else {
      _cart[product.id] = quantity;
    }
    confirmationNumber = null;
    notifyListeners();
    return true;
  }

  void cancelOrder() {
    _cart.clear();
    confirmationNumber = null;
    notifyListeners();
  }

  String finishOrder() {
    final String number = 'TL${100000 + Random().nextInt(900000)}';
    confirmationNumber = number;
    _cart.clear();
    notifyListeners();
    return number;
  }

  // ── Totais ───────────────────────────────
  double get subtotal {
    double total = 0;
    _cart.forEach((String id, int qty) {
      total += productById(id).price * qty;
    });
    return total;
  }

  /// DESAFIO 2 – Frete grátis acima de R$ 150,00
  double get shipping => subtotal == 0
      ? 0
      : (subtotal >= 150 ? 0 : 14.90);

  double get taxes => subtotal * 0.10;
  double get total => subtotal + shipping + taxes;
}

// ─────────────────────────────────────────────
//  PALETA & TEMA
// ─────────────────────────────────────────────
class TLColors {
  static const Color primary = Color(0xFF5C6BC0);      // índigo suave
  static const Color primaryDark = Color(0xFF3949AB);
  static const Color accent = Color(0xFFEC407A);       // rosa vibrante
  static const Color success = Color(0xFF26A69A);      // verde-teal
  static const Color warning = Color(0xFFEF5350);
  static const Color bg = Color(0xFFF8F7FF);
  static const Color card = Colors.white;
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color gold = Color(0xFFFFC107);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TLColors.primary,
      primary: TLColors.primary,
      secondary: TLColors.accent,
    ),
    scaffoldBackgroundColor: TLColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: TLColors.primary,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: TLColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TLColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TLColors.primary,
        side: const BorderSide(color: TLColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCFCFCF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TLColors.primary, width: 2),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────
void main() {
  // [SUPABASE] Descomente quando configurar:
  // WidgetsFlutterBinding.ensureInitialized();
  // await SupabaseService.initialize();
  runApp(const TudoLimpoApp());
}

class TudoLimpoApp extends StatefulWidget {
  const TudoLimpoApp({super.key});

  @override
  State<TudoLimpoApp> createState() => _TudoLimpoAppState();
}

class _TudoLimpoAppState extends State<TudoLimpoApp> {
  final StoreController controller = StoreController();

  @override
  void initState() {
    super.initState();
    controller.loadProducts();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TudoLimpo – TL',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext ctx, _) {
          if (controller.loading) return const _LoadingPage();
          if (controller.loadError != null) {
            return _ErrorPage(message: controller.loadError!);
          }
          return HomePage(controller: controller);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PÁGINAS AUXILIARES
// ─────────────────────────────────────────────
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TLColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const TLLogo(size: 80),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: TLColors.primary),
            const SizedBox(height: 16),
            Text(
              'Carregando produtos...',
              style: TextStyle(color: TLColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final String message;
  const _ErrorPage({required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TudoLimpo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 64, color: TLColors.warning),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP BAR COMPARTILHADA
// ─────────────────────────────────────────────
class TLAppBar extends StatelessWidget implements PreferredSizeWidget {
  final StoreController controller;
  final String title;
  final bool showBack;

  const TLAppBar({
    required this.controller,
    required this.title,
    this.showBack = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const TLLogo(size: 26, white: true),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      actions: <Widget>[
        AnimatedBuilder(
          animation: controller,
          builder: (BuildContext ctx, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Badge(
                label: Text('${controller.cartItemCount}'),
                isLabelVisible: controller.cartItemCount > 0,
                backgroundColor: TLColors.accent,
                child: IconButton(
                  tooltip: 'Carrinho',
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () => _openCart(context, controller),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ─────────────────────────────────────────────
//  NAVEGAÇÃO HELPERS
// ─────────────────────────────────────────────
void _openCart(BuildContext context, StoreController controller) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => CartPage(controller: controller)),
  );
}

void _openProducts(BuildContext context, StoreController controller,
    {bool replace = false}) {
  final MaterialPageRoute<void> route = MaterialPageRoute<void>(
    builder: (_) => ProductsPage(controller: controller),
  );
  if (replace) {
    Navigator.pushReplacement(context, route);
  } else {
    Navigator.push(context, route);
  }
}

void _showMessage(BuildContext context, String msg, {bool success = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? TLColors.success : TLColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: <Widget>[
            Icon(
              success ? Icons.check_circle_outline : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
}

// ─────────────────────────────────────────────
//  HOME PAGE
// ─────────────────────────────────────────────
class HomePage extends StatelessWidget {
  final StoreController controller;
  const HomePage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TLAppBar(controller: controller, title: 'TudoLimpo'),
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _HeroBanner(controller: controller),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bem-vindo à TudoLimpo!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: TLColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Produtos de higiene e autocuidado selecionados para você se sentir bem todos os dias.',
                  style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 20),
                _BenefitBanners(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.spa_outlined),
                  label: const Text('Explorar Produtos', style: TextStyle(fontSize: 17)),
                  onPressed: () => _openProducts(context, controller),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Ver Carrinho', style: TextStyle(fontSize: 17)),
                  onPressed: () => _openCart(context, controller),
                ),
                const SizedBox(height: 24),
                _CategoryHighlights(controller: controller),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final StoreController controller;
  const _HeroBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF5C6BC0),
            Color(0xFF9575CD),
            Color(0xFFEC407A),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Círculos decorativos
          Positioned(
            top: -30,
            right: -30,
            child: _Circle(size: 130, color: Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -20,
            left: 40,
            child: _Circle(size: 90, color: Colors.white.withOpacity(0.06)),
          ),
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TLColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FRETE GRÁTIS acima de R\$ 150',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Autocuidado\nem todo lugar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mais de 36 produtos premium',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: controller,
                  builder: (_, __) => Text(
                    '${controller.products.length} produtos disponíveis',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ícones decorativos direita
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                _HeroIcon(icon: Icons.spa, size: 36),
                SizedBox(height: 10),
                _HeroIcon(icon: Icons.face_retouching_natural, size: 30),
                SizedBox(height: 10),
                _HeroIcon(icon: Icons.water_drop_outlined, size: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const _HeroIcon({required this.icon, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

class _BenefitBanners extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        Expanded(
          child: _BenefitChip(
            icon: Icons.verified_outlined,
            label: 'Testado dermatologicamente',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _BenefitChip(
            icon: Icons.eco_outlined,
            label: 'Fórmulas sustentáveis',
          ),
        ),
      ],
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BenefitChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: TLColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TLColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: TLColors.primary, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHighlights extends StatelessWidget {
  final StoreController controller;
  const _CategoryHighlights({required this.controller});

  static const List<Map<String, dynamic>> _cats = <Map<String, dynamic>>[
    <String, dynamic>{'label': 'Cabelo', 'icon': Icons.waves, 'cat': 'cabelo'},
    <String, dynamic>{'label': 'Rosto', 'icon': Icons.face_retouching_natural, 'cat': 'rosto'},
    <String, dynamic>{'label': 'Corpo', 'icon': Icons.spa_outlined, 'cat': 'corpo'},
    <String, dynamic>{'label': 'Bucal', 'icon': Icons.sentiment_satisfied_alt, 'cat': 'bucal'},
    <String, dynamic>{'label': 'Masculino', 'icon': Icons.man_outlined, 'cat': 'masculino'},
    <String, dynamic>{'label': 'Pés', 'icon': Icons.directions_walk, 'cat': 'pés'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Categorias',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: TLColors.primaryDark),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _cats.map((Map<String, dynamic> cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    controller.filterByCategory(cat['cat'] as String);
                    _openProducts(context, controller);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF5C6BC0), Color(0xFF9575CD)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x335C6BC0),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Icon(cat['icon'] as IconData, color: Colors.white, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          cat['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PRODUCTS PAGE
// ─────────────────────────────────────────────
class ProductsPage extends StatelessWidget {
  final StoreController controller;
  const ProductsPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TLAppBar(controller: controller, title: 'TudoLimpo', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext ctx, _) {
          return Column(
            children: <Widget>[
              _SearchBar(controller: controller),
              _CategoryFilter(controller: controller),
              Expanded(
                child: controller.filteredProducts.isEmpty
                    ? const _EmptySearch()
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.filteredProducts.length + 1,
                  itemBuilder: (BuildContext ctx, int i) {
                    if (i == 0) {
                      return _ProductsHeader(
                        count: controller.filteredProducts.length,
                        category: controller.selectedCategory,
                      );
                    }
                    final Product product =
                    controller.filteredProducts[i - 1];
                    return ProductCard(
                      product: product,
                      onSelect: () {
                        Navigator.push(
                          ctx,
                          MaterialPageRoute<void>(
                            builder: (_) => ProductDetailsPage(
                              controller: controller,
                              product: product,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final StoreController controller;
  const _SearchBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: TLColors.primary,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: TextField(
        onChanged: controller.search,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar produtos, marcas ou categorias...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final StoreController controller;
  const _CategoryFilter({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        children: controller.categories.map((String cat) {
          final bool selected = controller.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_formatCategory(cat)),
              selected: selected,
              onSelected: (_) => controller.filterByCategory(cat),
              selectedColor: TLColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : TLColors.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              showCheckmark: false,
              backgroundColor: const Color(0xFFF0F0FF),
            ),
          );
        }).toList(),
      ),
    );
  }
}

String _formatCategory(String cat) {
  if (cat == 'todos') return 'Todos';
  return cat[0].toUpperCase() + cat.substring(1);
}

class _ProductsHeader extends StatelessWidget {
  final int count;
  final String category;
  const _ProductsHeader({required this.count, required this.category});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Text(
            _formatCategory(category),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: TLColors.primaryDark,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TLColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count produto${count == 1 ? '' : 's'}',
              style: const TextStyle(
                color: TLColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Icon(Icons.search_off, size: 60, color: TLColors.textMuted),
          SizedBox(height: 12),
          Text(
            'Nenhum produto encontrado',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: TLColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRODUCT CARD
// ─────────────────────────────────────────────
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onSelect;
  const ProductCard({required this.product, required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ProductIcon(product: product, size: 80),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _CategoryBadge(category: product.category),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.brand,
                      style: const TextStyle(
                          fontSize: 11, color: TLColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    _StarRating(rating: product.rating, reviews: product.reviews, small: true),
                    const SizedBox(height: 4),
                    Text(
                      product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatMoney(product.price),
                    style: const TextStyle(
                      color: TLColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estoque: ${product.stock}',
                    style: const TextStyle(fontSize: 10, color: TLColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(80, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: onSelect,
                    child: const Text('Ver', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRODUCT DETAILS PAGE
// ─────────────────────────────────────────────
class ProductDetailsPage extends StatelessWidget {
  final StoreController controller;
  final Product product;
  const ProductDetailsPage(
      {required this.controller, required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TLAppBar(
          controller: controller, title: 'TudoLimpo', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Header produto
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ProductIcon(product: product, size: 120),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _CategoryBadge(category: product.category),
                            const SizedBox(height: 6),
                            Text(
                              product.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: TLColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.brand,
                              style: const TextStyle(
                                  color: TLColors.textMuted,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            _StarRating(
                                rating: product.rating,
                                reviews: product.reviews),
                            const SizedBox(height: 12),
                            Text(
                              formatMoney(product.price),
                              style: const TextStyle(
                                color: TLColors.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                const Icon(Icons.check_circle,
                                    color: TLColors.success, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.stock} unidades em estoque',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Frete info
          _ShippingInfo(price: product.price),
          const SizedBox(height: 12),
          // Descrição
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Descrição do Produto',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: TLColors.primaryDark),
                  ),
                  const SizedBox(height: 10),
                  Text(product.longDescription,
                      style: const TextStyle(height: 1.6, fontSize: 14)),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.tag, size: 14, color: TLColors.textMuted),
                      const SizedBox(width: 4),
                      Text('ID: ${product.id}',
                          style: const TextStyle(
                              fontSize: 12, color: TLColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Adicionar ao Carrinho',
                style: TextStyle(fontSize: 16)),
            onPressed: () {
              final bool added = controller.addToCart(product);
              if (added) {
                _showMessage(context, '${product.name} adicionado!',
                    success: true);
              } else {
                _showMessage(context,
                    'Estoque insuficiente. Disponível: ${product.stock} unidade(s).');
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Ver Mais Produtos'),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ShippingInfo extends StatelessWidget {
  final double price;
  const _ShippingInfo({required this.price});

  @override
  Widget build(BuildContext context) {
    final bool freeShipping = price >= 150;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: freeShipping
            ? TLColors.success.withOpacity(0.1)
            : TLColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: freeShipping
              ? TLColors.success.withOpacity(0.4)
              : TLColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            freeShipping ? Icons.local_shipping : Icons.info_outline,
            color: freeShipping ? TLColors.success : TLColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              freeShipping
                  ? 'Frete GRÁTIS para este produto!'
                  : 'Frete: R\$ 14,90  •  Grátis acima de R\$ 150,00',
              style: TextStyle(
                color: freeShipping ? TLColors.success : TLColors.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CART PAGE
// ─────────────────────────────────────────────
class CartPage extends StatelessWidget {
  final StoreController controller;
  const CartPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TLAppBar(
          controller: controller, title: 'TudoLimpo', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext ctx, _) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: <Widget>[
              _PageHeader(
                title: 'Seu Carrinho',
                subtitle:
                '${controller.cartItemCount} item${controller.cartItemCount == 1 ? '' : 's'} selecionado${controller.cartItemCount == 1 ? '' : 's'}',
              ),
              if (controller.subtotal > 0 && controller.subtotal < 150)
                _FreeShippingProgress(subtotal: controller.subtotal),
              if (controller.cartProducts.isEmpty)
                const _EmptyCartCard()
              else ...<Widget>[
                for (final Product p in controller.cartProducts)
                  CartItemCard(controller: controller, product: p),
                const SizedBox(height: 8),
                SummaryCard(controller: controller),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Finalizar Pedido'),
                onPressed: controller.cartProducts.isEmpty
                    ? null
                    : () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CheckoutPage(controller: controller),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: TLColors.warning,
                  side: const BorderSide(color: TLColors.warning),
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cancelar Pedido'),
                onPressed: () {
                  controller.cancelOrder();
                  _showMessage(ctx, 'Pedido cancelado.');
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.spa_outlined),
                label: const Text('Ver Mais Produtos'),
                onPressed: () => _openProducts(ctx, controller, replace: true),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _FreeShippingProgress extends StatelessWidget {
  final double subtotal;
  const _FreeShippingProgress({required this.subtotal});
  @override
  Widget build(BuildContext context) {
    final double progress = (subtotal / 150).clamp(0.0, 1.0);
    final double remaining = 150 - subtotal;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TLColors.success.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.local_shipping_outlined,
                  color: TLColors.success, size: 18),
              const SizedBox(width: 6),
              Text(
                'Falta ${formatMoney(remaining)} para frete grátis!',
                style: const TextStyle(
                    color: TLColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: TLColors.success.withOpacity(0.15),
              valueColor:
              const AlwaysStoppedAnimation<Color>(TLColors.success),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartCard extends StatelessWidget {
  const _EmptyCartCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: <Widget>[
            Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text('Seu carrinho está vazio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Adicione produtos para começar',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final StoreController controller;
  final Product product;
  const CartItemCard(
      {required this.controller, required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final int quantity = controller.quantityOf(product.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            ProductIcon(product: product, size: 64),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2),
                  Text(product.brand,
                      style: const TextStyle(
                          fontSize: 11, color: TLColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(formatMoney(product.price),
                      style: const TextStyle(
                          color: TLColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  QuantityControl(
                    quantity: quantity,
                    onDecrease: () =>
                        controller.updateQuantity(product, quantity - 1),
                    onIncrease: () {
                      final bool ok =
                      controller.updateQuantity(product, quantity + 1);
                      if (!ok) {
                        _showMessage(context,
                            'Estoque máximo: ${product.stock} unidade(s).');
                      }
                    },
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const Text('Subtotal',
                    style: TextStyle(fontSize: 11, color: TLColors.textMuted)),
                Text(
                  formatMoney(product.price * quantity),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  const QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: TLColors.primary.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: onDecrease,
            borderRadius:
            const BorderRadius.horizontal(left: Radius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Icon(Icons.remove, size: 16, color: TLColors.primary),
            ),
          ),
          Container(
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                  vertical: BorderSide(
                      color: TLColors.primary.withOpacity(0.4))),
            ),
            child: Text('$quantity',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          InkWell(
            onTap: onIncrease,
            borderRadius:
            const BorderRadius.horizontal(right: Radius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Icon(Icons.add, size: 16, color: TLColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final StoreController controller;
  const SummaryCard({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Resumo da Compra',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: TLColors.primaryDark)),
            const SizedBox(height: 10),
            _SummaryRow(
                label: 'Subtotal',
                value: formatMoney(controller.subtotal)),
            _SummaryRow(
              label: controller.shipping == 0
                  ? 'Frete ✓ Grátis'
                  : 'Frete',
              value: controller.shipping == 0
                  ? 'GRÁTIS'
                  : formatMoney(controller.shipping),
              greenValue: controller.shipping == 0,
            ),
            _SummaryRow(
                label: 'Impostos (10%)',
                value: formatMoney(controller.taxes)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(),
            ),
            _SummaryRow(
                label: 'Total',
                value: formatMoney(controller.total),
                highlight: true),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool greenValue;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.greenValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: TextStyle(
                  fontSize: highlight ? 16 : 14,
                  fontWeight:
                  highlight ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight
                  ? TLColors.primary
                  : greenValue
                  ? TLColors.success
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHECKOUT PAGE
// ─────────────────────────────────────────────
class CheckoutPage extends StatefulWidget {
  final StoreController controller;
  const CheckoutPage({required this.controller, super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Cobrança
  final TextEditingController _billingName =
  TextEditingController(text: 'Maria Silva');
  final TextEditingController _billingStreet =
  TextEditingController(text: 'Rua das Flores, 123');
  final TextEditingController _billingCity =
  TextEditingController(text: 'São Paulo');
  final TextEditingController _billingState =
  TextEditingController(text: 'SP');
  // DESAFIO 3 – CEP cobrança separado
  final TextEditingController _billingZip =
  TextEditingController(text: '01234-567');
  final TextEditingController _billingPhone =
  TextEditingController(text: '(11) 91234-5678');

  // Entrega
  final TextEditingController _shippingName =
  TextEditingController(text: 'Maria Silva');
  final TextEditingController _shippingStreet =
  TextEditingController(text: 'Rua das Flores, 123');
  final TextEditingController _shippingCity =
  TextEditingController(text: 'São Paulo');
  final TextEditingController _shippingState =
  TextEditingController(text: 'SP');
  // DESAFIO 3 – CEP entrega separado
  final TextEditingController _shippingZip =
  TextEditingController(text: '01234-567');

  bool _useSameAddress = true;

  @override
  void dispose() {
    _billingName.dispose();
    _billingStreet.dispose();
    _billingCity.dispose();
    _billingState.dispose();
    _billingZip.dispose();
    _billingPhone.dispose();
    _shippingName.dispose();
    _shippingStreet.dispose();
    _shippingCity.dispose();
    _shippingState.dispose();
    _shippingZip.dispose();
    super.dispose();
  }

  void _copyBillingToShipping() {
    _shippingName.text = _billingName.text;
    _shippingStreet.text = _billingStreet.text;
    _shippingCity.text = _billingCity.text;
    _shippingState.text = _billingState.text;
    _shippingZip.text = _billingZip.text;
  }

  void _confirm() {
    if (widget.controller.cartProducts.isEmpty) {
      _showMessage(context, 'Carrinho vazio.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showMessage(context, 'Preencha todos os campos obrigatórios.');
      return;
    }
    if (_useSameAddress) _copyBillingToShipping();

    final String number = widget.controller.finishOrder();

    // DESAFIO 4 – navega para a tela de confirmação
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationPage(
          controller: widget.controller,
          orderNumber: number,
          billingName: _billingName.text,
          shippingAddress:
          '${_shippingStreet.text}, ${_shippingCity.text} - ${_shippingState.text}, CEP ${_shippingZip.text}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TLAppBar(
          controller: widget.controller,
          title: 'TudoLimpo',
          showBack: true),
      body: Form(
        key: _formKey,
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (BuildContext ctx, _) {
            return ListView(
              padding: const EdgeInsets.all(14),
              children: <Widget>[
                _PageHeader(
                  title: 'Finalização do Pedido',
                  subtitle: 'Informe os endereços e confirme a compra.',
                ),
                // ENDEREÇO DE COBRANÇA
                _AddressSection(
                  title: 'Endereço de Cobrança',
                  icon: Icons.credit_card_outlined,
                  nameCtrl: _billingName,
                  streetCtrl: _billingStreet,
                  cityCtrl: _billingCity,
                  stateCtrl: _billingState,
                  zipCtrl: _billingZip,
                  phoneCtrl: _billingPhone,
                  showPhone: true,
                ),
                const SizedBox(height: 12),
                // CHECKBOX MESMO ENDEREÇO
                Card(
                  child: CheckboxListTile(
                    value: _useSameAddress,
                    activeColor: TLColors.primary,
                    onChanged: (bool? v) {
                      setState(() {
                        _useSameAddress = v ?? false;
                        if (_useSameAddress) _copyBillingToShipping();
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Entrega no mesmo endereço de cobrança'),
                  ),
                ),
                if (!_useSameAddress) ...<Widget>[
                  const SizedBox(height: 12),
                  // DESAFIO 3 – ENDEREÇO DE ENTREGA COM CEP SEPARADO
                  _AddressSection(
                    title: 'Endereço de Entrega',
                    icon: Icons.local_shipping_outlined,
                    nameCtrl: _shippingName,
                    streetCtrl: _shippingStreet,
                    cityCtrl: _shippingCity,
                    stateCtrl: _shippingState,
                    zipCtrl: _shippingZip,
                    showPhone: false,
                  ),
                ],
                const SizedBox(height: 12),
                // RESUMO
                _CheckoutSummary(controller: widget.controller),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Confirmar Pedido',
                      style: TextStyle(fontSize: 16)),
                  onPressed: _confirm,
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final TextEditingController nameCtrl;
  final TextEditingController streetCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController stateCtrl;
  // DESAFIO 3 – campo CEP dedicado
  final TextEditingController zipCtrl;
  final TextEditingController? phoneCtrl;
  final bool showPhone;

  const _AddressSection({
    required this.title,
    required this.icon,
    required this.nameCtrl,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.zipCtrl,
    this.phoneCtrl,
    this.showPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: TLColors.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: TLColors.primaryDark)),
              ],
            ),
            const SizedBox(height: 14),
            _Field(ctrl: nameCtrl, label: 'Nome completo', icon: Icons.person_outline),
            const SizedBox(height: 10),
            _Field(ctrl: streetCtrl, label: 'Rua e número', icon: Icons.home_outlined),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                    flex: 2,
                    child: _Field(
                        ctrl: cityCtrl,
                        label: 'Cidade',
                        icon: Icons.location_city_outlined)),
                const SizedBox(width: 8),
                SizedBox(
                    width: 70,
                    child: _Field(ctrl: stateCtrl, label: 'UF', icon: null)),
              ],
            ),
            const SizedBox(height: 10),
            // DESAFIO 3 – campo CEP dedicado e destacado
            _Field(
                ctrl: zipCtrl,
                label: 'CEP',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number),
            if (showPhone && phoneCtrl != null) ...<Widget>[
              const SizedBox(height: 10),
              _Field(
                  ctrl: phoneCtrl!,
                  label: 'Telefone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
            ],
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;
  const _Field(
      {required this.ctrl,
        required this.label,
        this.icon,
        this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      ),
      validator: (String? v) {
        if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
        return null;
      },
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  final StoreController controller;
  const _CheckoutSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Resumo do Pedido',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: TLColors.primaryDark)),
            const SizedBox(height: 12),
            for (final Product p in controller.cartProducts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    ProductIcon(product: p, size: 40),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${p.name}\nQtd: ${controller.quantityOf(p.id)}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Text(formatMoney(p.price * controller.quantityOf(p.id))),
                  ],
                ),
              ),
            const Divider(),
            _SummaryRow(label: 'Subtotal', value: formatMoney(controller.subtotal)),
            _SummaryRow(
              label: controller.shipping == 0 ? 'Frete ✓ Grátis' : 'Frete',
              value: controller.shipping == 0 ? 'GRÁTIS' : formatMoney(controller.shipping),
              greenValue: controller.shipping == 0,
            ),
            _SummaryRow(label: 'Impostos (10%)', value: formatMoney(controller.taxes)),
            _SummaryRow(
                label: 'Total',
                value: formatMoney(controller.total),
                highlight: true),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DESAFIO 4 – ORDEM DE CONFIRMAÇÃO (página dedicada)
// ─────────────────────────────────────────────
class OrderConfirmationPage extends StatelessWidget {
  final StoreController controller;
  final String orderNumber;
  final String billingName;
  final String shippingAddress;

  const OrderConfirmationPage({
    required this.controller,
    required this.orderNumber,
    required this.billingName,
    required this.shippingAddress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TLAppBar(controller: controller, title: 'TudoLimpo'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 16),
          // Ícone de sucesso animado
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: TLColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 60, color: TLColors.success),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pedido Confirmado!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: TLColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seu pedido foi recebido e está sendo processado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TLColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Número do pedido
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF5C6BC0), Color(0xFF9575CD)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: <Widget>[
                const Text('Número do Pedido',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  orderNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guarde este número para rastrear seu pedido.',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Detalhes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Detalhes do Pedido',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: TLColors.primaryDark)),
                  const Divider(height: 20),
                  _ConfirmRow(
                      icon: Icons.person_outline,
                      label: 'Cliente',
                      value: billingName),
                  const SizedBox(height: 10),
                  _ConfirmRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Entrega',
                      value: shippingAddress),
                  const SizedBox(height: 10),
                  _ConfirmRow(
                      icon: Icons.email_outlined,
                      label: 'E-mail',
                      value: 'Confirmação enviada para o e-mail cadastrado'),
                  const SizedBox(height: 10),
                  _ConfirmRow(
                      icon: Icons.schedule_outlined,
                      label: 'Prazo estimado',
                      value: '3 a 7 dias úteis'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Timeline do pedido
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text('Status do Pedido',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: TLColors.primaryDark)),
                  SizedBox(height: 14),
                  _StatusStep(
                      label: 'Pedido Confirmado',
                      done: true,
                      isFirst: true),
                  _StatusStep(label: 'Em Separação', done: false),
                  _StatusStep(label: 'Enviado', done: false),
                  _StatusStep(label: 'Entregue', done: false, isLast: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            icon: const Icon(Icons.spa_outlined),
            label: const Text('Continuar Comprando',
                style: TextStyle(fontSize: 16)),
            onPressed: () {
              Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ConfirmRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: TLColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: TLColors.textMuted)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool isFirst;
  final bool isLast;
  const _StatusStep({
    required this.label,
    required this.done,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Column(
          children: <Widget>[
            if (!isFirst)
              Container(
                  width: 2, height: 14, color: done ? TLColors.success : const Color(0xFFDDDDDD)),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? TLColors.success : const Color(0xFFDDDDDD),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : Icons.circle,
                size: done ? 14 : 6,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                  width: 2, height: 14, color: const Color(0xFFDDDDDD)),
          ],
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: done ? FontWeight.bold : FontWeight.normal,
            color: done ? TLColors.success : TLColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS COMPARTILHADOS
// ─────────────────────────────────────────────
class TLLogo extends StatelessWidget {
  final double size;
  final bool white;
  const TLLogo({this.size = 40, this.white = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: white ? Colors.white.withOpacity(0.2) : TLColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'TL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: size * 0.36,
            color: white ? Colors.white : TLColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class ProductIcon extends StatelessWidget {
  final Product product;
  final double size;
  const ProductIcon({required this.product, required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    final Color bg = _categoryColor(product.category).withOpacity(0.12);
    final Color iconColor = _categoryColor(product.category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        _productIconData(product.icon),
        size: size * 0.5,
        color: iconColor,
      ),
    );
  }
}

Color _categoryColor(String category) {
  switch (category) {
    case 'cabelo':
      return const Color(0xFF7C4DFF);
    case 'rosto':
      return const Color(0xFFEC407A);
    case 'corpo':
      return const Color(0xFF26A69A);
    case 'bucal':
      return const Color(0xFF42A5F5);
    case 'masculino':
      return const Color(0xFF78909C);
    case 'mãos':
      return const Color(0xFFFF7043);
    case 'pés':
      return const Color(0xFF66BB6A);
    case 'fragrâncias':
      return const Color(0xFFAB47BC);
    case 'banho':
      return const Color(0xFF26C6DA);
    case 'infantil':
      return const Color(0xFFFFCA28);
    default:
      return TLColors.primary;
  }
}

IconData _productIconData(String icon) {
  switch (icon) {
    case 'shampoo':
      return Icons.water_drop_outlined;
    case 'conditioner':
      return Icons.waves;
    case 'soap':
      return Icons.soap_outlined;
    case 'cream':
      return Icons.spa_outlined;
    case 'deodorant':
      return Icons.air;
    case 'toothpaste':
      return Icons.sentiment_satisfied_alt_outlined;
    case 'toothbrush':
      return Icons.cleaning_services_outlined;
    case 'mouthwash':
      return Icons.local_drink_outlined;
    case 'sunscreen':
      return Icons.wb_sunny_outlined;
    case 'serum':
      return Icons.science_outlined;
    case 'facewash':
      return Icons.face_retouching_natural;
    case 'toner':
      return Icons.opacity;
    case 'moisturizer':
      return Icons.water_outlined;
    case 'oil':
      return Icons.oil_barrel_outlined;
    case 'handcream':
      return Icons.back_hand_outlined;
    case 'mask':
      return Icons.face_outlined;
    case 'spray':
      return Icons.grain;
    case 'shaving':
      return Icons.cut_outlined;
    case 'aftershave':
      return Icons.man_outlined;
    case 'perfume':
      return Icons.local_florist_outlined;
    case 'scrub':
      return Icons.texture;
    case 'micellar':
      return Icons.remove_red_eye_outlined;
    case 'nail':
      return Icons.content_cut_outlined;
    case 'lotion':
      return Icons.shower_outlined;
    case 'dental':
      return Icons.health_and_safety_outlined;
    case 'pumice':
      return Icons.grass_outlined;
    case 'footcream':
      return Icons.directions_walk;
    default:
      return Icons.spa_outlined;
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _categoryColor(category).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatCategory(category),
        style: TextStyle(
          color: _categoryColor(category),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final int reviews;
  final bool small;
  const _StarRating(
      {required this.rating, required this.reviews, this.small = false});

  @override
  Widget build(BuildContext context) {
    final double sz = small ? 12.0 : 14.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...List<Widget>.generate(5, (int i) {
          final double fill = (rating - i).clamp(0.0, 1.0);
          return Icon(
            fill >= 1
                ? Icons.star
                : fill >= 0.5
                ? Icons.star_half
                : Icons.star_outline,
            color: TLColors.gold,
            size: sz,
          );
        }),
        const SizedBox(width: 4),
        Text(
          '$rating ($reviews)',
          style: TextStyle(
            fontSize: small ? 10 : 11,
            color: TLColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: TLColors.primaryDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(color: TLColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  UTILS
// ─────────────────────────────────────────────
String formatMoney(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}