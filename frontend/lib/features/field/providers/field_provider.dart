import 'package:flutter/material.dart';
import '../../../models/field.dart';
import '../repositories/field_repository.dart';

class FieldProvider extends ChangeNotifier {
  List<Field> _fields = [];
  List<Field> _favoriteFields = [];
  bool _isLoading = false;

  List<Field> get fields => _fields;
  List<Field> get favoriteFields => _favoriteFields;
  bool get isLoading => _isLoading;

  bool isFavorite(int? fieldId) {
    if (fieldId == null) return false;
    return _favoriteFields.any((f) => f.id == fieldId);
  }

  Future<void> loadPublicFields() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await FieldRepository.getPublicFields();
      _fields = list;
    } catch (e) {
      print("Error in loadPublicFields provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavoriteFields() async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await FieldRepository.getFavorites();
      _favoriteFields = list;
    } catch (e) {
      print("Error in loadFavoriteFields provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(Field field) async {
    if (field.id == null) return false;
    final fav = isFavorite(field.id);
    bool success = false;
    try {
      if (fav) {
        success = await FieldRepository.removeFavorite(field.id!);
        if (success) {
          _favoriteFields.removeWhere((f) => f.id == field.id);
          notifyListeners();
        }
      } else {
        success = await FieldRepository.addFavorite(field.id!);
        if (success) {
          _favoriteFields.add(field);
          notifyListeners();
        }
      }
    } catch (e) {
      print("Error toggling favorite in provider: $e");
    }
    return success;
  }
}
