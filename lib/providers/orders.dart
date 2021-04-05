import 'dart:convert';
import 'package:shop/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shop/providers/cart.dart';

class Order {
  final String id;
  final double total;
  final List<CartItem> products;
  final DateTime date;

  Order({
    @required this.id,
    @required this.total,
    @required this.products,
    @required this.date,
  });
}

class Orders with ChangeNotifier {
  final String _baseUrl = '${Constants.BASE_API_URL}/orders';
  String _token;
  String _userId;
  List<Order> _orders = [];

  Orders([this._token, this._userId, this._orders = const []]);

  List<Order> get orders {
    return [..._orders];
  }

  int get ordersCount {
    return _orders.length;
  }

  Future<void> loadOrders() async {
    List<Order> loadedOrders = [];
    final response = await http.get('$_baseUrl/$_userId.json?auth=$_token');

    Map<String, dynamic> data = json.decode(response.body);

    if (data != null) {
      data.forEach((orderId, orderData) {
        loadedOrders.add(
          Order(
            id: orderId,
            total: orderData['total'],
            date: DateTime.parse(orderData['date']),
            products: (orderData['products'] as List<dynamic>).map((item) {
              return CartItem(
                id: item['id'],
                productId: item['productId'],
                title: item['title'],
                quantity: item['quantity'],
                price: item['price'],
              );
            }).toList(),
          ),
        );
      });
    }
    _orders = loadedOrders.reversed.toList();
    return Future.value();
  }

  Future<void> addOrder(Cart cart) async {
    final date = DateTime.now();
    final response = await http.post(
      "$_baseUrl/$_userId.json?auth=$_token",
      body: json.encode({
        'total': cart.totalAmount,
        'date': date.toIso8601String(),
        'products': cart.item.values
            .map((cartItem) => {
                  'id': cartItem.id,
                  'productId': cartItem.productId,
                  'title': cartItem.title,
                  'quantity': cartItem.quantity,
                  'price': cartItem.price,
                })
            .toList(),
      }),
    );

    _orders.insert(
      0,
      Order(
        id: json.decode(response.body)['name'],
        total: cart.totalAmount,
        products: cart.item.values.toList(),
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
