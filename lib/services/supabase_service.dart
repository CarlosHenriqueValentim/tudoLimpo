// Serviço de integração com Supabase para TudoLimpo
// Este arquivo contém a lógica para conectar e gerenciar dados no Supabase

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _projectUrl = 'https://seu-projeto.supabase.co';
  static const String _anonKey = 'sua-chave-anonima-aqui';

  static final SupabaseClient supabase = Supabase.instance.client;

  /// Inicializa a conexão com o Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _projectUrl,
      anonKey: _anonKey,
    );
  }

  /// Carrega todos os produtos do Supabase
  static Future<List<Map<String, dynamic>>> loadProductsFromSupabase() async {
    try {
      final List<dynamic> response = await supabase.from('products').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erro ao carregar produtos: $e');
    }
  }

  /// Insere um novo pedido no Supabase
  static Future<Map<String, dynamic>> createOrder({
    required String confirmationNumber,
    required double totalValue,
    required String shippingAddress,
    required String billingAddress,
  }) async {
    try {
      final response = await supabase.from('orders').insert({
        'confirmation_number': confirmationNumber,
        'total_value': totalValue,
        'shipping_address': shippingAddress,
        'billing_address': billingAddress,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }).select();
      return response.first;
    } catch (e) {
      throw Exception('Erro ao criar pedido: $e');
    }
  }

  /// Insere itens do pedido no Supabase
  static Future<void> createOrderItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await supabase.from('order_items').insert(
        items.map((item) {
          return {
            'order_id': orderId,
            'product_id': item['productId'],
            'quantity': item['quantity'],
            'price_per_unit': item['pricePerUnit'],
            'subtotal': item['subtotal'],
          };
        }).toList(),
      );
    } catch (e) {
      throw Exception('Erro ao criar itens do pedido: $e');
    }
  }

  /// Atualiza o estoque de um produto
  static Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await supabase.from('products').update({'stock': newStock}).eq('id', productId);
    } catch (e) {
      throw Exception('Erro ao atualizar estoque: $e');
    }
  }

  /// Busca um pedido pelo número de confirmação
  static Future<Map<String, dynamic>?> getOrderByConfirmationNumber(String confirmationNumber) async {
    try {
      final List<dynamic> response = await supabase
          .from('orders')
          .select()
          .eq('confirmation_number', confirmationNumber);
      return response.isNotEmpty ? response.first : null;
    } catch (e) {
      throw Exception('Erro ao buscar pedido: $e');
    }
  }

  /// Busca todos os pedidos de um usuário
  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final List<dynamic> response =
      await supabase.from('orders').select().eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erro ao buscar pedidos do usuário: $e');
    }
  }
}

/// INSTRUÇÕES DE CONFIGURAÇÃO NO SUPABASE:
///
/// 1. Acesse https://supabase.com e crie uma nova conta/projeto
///
/// 2. No dashboard do Supabase, acesse "SQL Editor" e execute os seguintes scripts:
///
/// -- Tabela de Produtos
/// CREATE TABLE products (
///   id TEXT PRIMARY KEY,
///   name TEXT NOT NULL,
///   price DECIMAL(10, 2) NOT NULL,
///   stock INTEGER NOT NULL,
///   icon TEXT NOT NULL,
///   short_description TEXT NOT NULL,
///   long_description TEXT NOT NULL,
///   created_at TIMESTAMP DEFAULT NOW()
/// );
///
/// -- Tabela de Pedidos
/// CREATE TABLE orders (
///   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
///   confirmation_number TEXT UNIQUE NOT NULL,
///   user_id UUID,
///   total_value DECIMAL(10, 2) NOT NULL,
///   shipping_address TEXT NOT NULL,
///   billing_address TEXT NOT NULL,
///   status TEXT DEFAULT 'pending',
///   created_at TIMESTAMP DEFAULT NOW()
/// );
///
/// -- Tabela de Itens do Pedido
/// CREATE TABLE order_items (
///   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
///   order_id UUID NOT NULL REFERENCES orders(id),
///   product_id TEXT NOT NULL REFERENCES products(id),
///   quantity INTEGER NOT NULL,
///   price_per_unit DECIMAL(10, 2) NOT NULL,
///   subtotal DECIMAL(10, 2) NOT NULL,
///   created_at TIMESTAMP DEFAULT NOW()
/// );
///
/// 3. Insira os produtos no Supabase (SQL):
/// INSERT INTO products (id, name, price, stock, icon, short_description, long_description)
/// VALUES
/// ('2001', 'Sabonete Líquido Neutro', 15.90, 150, 'soap', 'Higiene completa e delicada para toda a família.', 'Sabonete líquido neutro com pH balanceado...'),
/// ... (repetir para todos os 10 produtos)
///
/// 4. Em lib/config/supabase_config.dart, substitua:
///    - SUPABASE_URL: Copie de "Project URL" nas configurações
///    - SUPABASE_ANON_KEY: Copie de "Project API keys" (anon key)
///
/// 5. Para usar este serviço, chame:
///    await SupabaseService.initialize();
///    List<Map<String, dynamic>> products = await SupabaseService.loadProductsFromSupabase();
