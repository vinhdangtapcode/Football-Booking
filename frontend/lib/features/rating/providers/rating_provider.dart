import 'package:flutter/material.dart';
import '../../../models/rating.dart';
import '../repositories/rating_repository.dart';

class RatingProvider extends ChangeNotifier {
  List<Rating> _ratings = [];
  List<Rating> _myRatings = [];
  bool _isLoading = false;

  List<Rating> get ratings => _ratings;
  List<Rating> get myRatings => _myRatings;
  bool get isLoading => _isLoading;

  Future<void> loadRatings(int fieldId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await RatingRepository.getRatings(fieldId);
      _ratings = list;
    } catch (e) {
      print("Error in loadRatings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyRatingsForField(int fieldId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await RatingRepository.getMyRatings();
      _myRatings = list.where((r) => r.field.id == fieldId).toList();
    } catch (e) {
      print("Error in loadMyRatingsForField: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRating(int fieldId, int score, String comment, bool isAnonymous) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await RatingRepository.addRating(fieldId, score, comment, isAnonymous);
      if (success) {
        await loadRatings(fieldId);
        await loadMyRatingsForField(fieldId);
        return true;
      }
    } catch (e) {
      print("Error in addRating provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateRating(int ratingId, int score, String comment, bool isAnonymous, int fieldId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await RatingRepository.updateRating(ratingId, score, comment, isAnonymous);
      if (success) {
        await loadRatings(fieldId);
        await loadMyRatingsForField(fieldId);
        return true;
      }
    } catch (e) {
      print("Error in updateRating provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteRating(int ratingId, int fieldId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await RatingRepository.deleteRating(ratingId);
      if (success) {
        _ratings.removeWhere((r) => r.id == ratingId);
        _myRatings.removeWhere((r) => r.id == ratingId);
        return true;
      }
    } catch (e) {
      print("Error in deleteRating provider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
