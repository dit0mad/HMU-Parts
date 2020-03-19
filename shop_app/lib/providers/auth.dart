import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../models/http_except.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class Auth with ChangeNotifier {
  String _token;
  String _userId;
  DateTime _expiryDate;
  Timer _authTimer;

  bool get isAuth {
    return _token != null;
  }

  String get token {
    if (_token != null &&
        _expiryDate.isBefore(DateTime.now()) &&
        _expiryDate != null) {
      return _token;
    }
    return null;
  }

  String get userId {
    //for which user
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String segment) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$segment?key=AIzaSyBvEP3Gl6WOTYMdBenV-WqRveWjtYP6Ohs';

    try {
      final response = await http.post(
        url,
        body: jsonEncode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      print(response.statusCode);
      final decodedData = jsonDecode(response.body);

      if (decodedData['error'] != null) {
        throw HttpException(decodedData['error']['message']);
      }

      //saves token, uID
      _token = decodedData['idToken'];
      _userId = decodedData['localId'];
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(decodedData['expiresIn'])));
      autoLogout();
      notifyListeners();
      //store login data in device
      final prefs = await SharedPreferences.getInstance();

      final userData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate.toIso8601String()
        },
      );
      //storing serliazed data in local memory
      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

  Future<bool> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("userData")) {
      return false;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')) as Map<String, Object>;

    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = extractedUserData['token'];
    _userId = extractedUserData['userId'];
    _expiryDate = extractedUserData['expiryDate'];
    notifyListeners();
    autoLogout();
    return true;
  }

  Future<void> signUp(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> logIn(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  void logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();

    prefs.clear();
  }

  void autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    final expireTime = _expiryDate.difference(DateTime.now()).inSeconds;
    //timer is set to the expire time of token.
    //after the token expires, logout is called.
    _authTimer = Timer(Duration(seconds: expireTime), logout);
  }
}
