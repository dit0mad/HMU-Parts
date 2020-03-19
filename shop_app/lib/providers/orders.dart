import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];

  Orders(this.authtoken, this.userId,this._orders, );

  final String authtoken;
  final String userId;

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchUpdateOrders() async {
    final url = 'https://buyandsell-21965.firebaseio.com/orders/$userId.json?auth=$authtoken';
    final response = await http.get(url);
    final extractedBody = json.decode(response.body) as Map<String, dynamic>;

    List<OrderItem> extractedOrders = [];

//dont execute if response is null.
if(extractedBody == null){
  return ;
}
    extractedBody.forEach((orderId, orderData) {
      extractedOrders.add(
        OrderItem(
          id: orderId,
          amount: orderData['amount'],
          dateTime: DateTime.parse(orderData['dateTime']),
          //products has a list of maps(cartItems). Take that info and map it for [product] key

          //so for product key has value ititle,and title as a key has a value of title from info.
          products: (orderData['products'] as List<dynamic>)
              .map(
                (item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ),
              )
              .toList(),
        ),
      );
    });
    _orders =extractedOrders.reversed.toList(); //shows newest order.
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = 'https://buyandsell-21965.firebaseio.com/orders/$userId.json?auth=$authtoken';
    final timeStamp = DateTime.now();

    final response = await http.post(
      url,
      body: json.encode({
        'amount': total,
        'dateTime': timeStamp.toIso8601String(),

        //for every item in cartProducts, take that item and create a map of its content
        // and send that map to server
        'products': cartProducts.map((cartprod) => {
              'id': cartprod.id,
              'title': cartprod.title,
              'quantity': cartprod.quantity,
              'price': cartprod.price,
            })
      }),
    );

    _orders.insert(
      0,
      //inserting locally/showing to widget,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        dateTime: DateTime.now(),
        products: cartProducts,
      ),
    );
    notifyListeners();
  }
}
