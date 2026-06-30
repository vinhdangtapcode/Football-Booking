import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rating_provider.dart';
import '../../../models/field.dart';
import '../../../services/theme_service.dart';

class AddRatingScreen extends StatefulWidget {
  @override
  _AddRatingScreenState createState() => _AddRatingScreenState();
}

class _AddRatingScreenState extends State<AddRatingScreen> {
  Field? field;
  final TextEditingController scoreController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  bool isLoading = false;
  bool isAnonymous = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    field = ModalRoute.of(context)!.settings.arguments as Field?;
  }

  void submitRating() async {
    if (field == null) return;
    int? score = int.tryParse(scoreController.text);
    if (score == null || score < 1 || score > 5) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Điểm đánh giá phải từ 1 đến 5")));
      return;
    }
    setState(() {
      isLoading = true;
    });
    
    final ratingProvider = context.read<RatingProvider>();
    bool success = await ratingProvider.addRating(
      field!.id!,
      score,
      commentController.text,
      isAnonymous,
    );
    
    setState(() {
      isLoading = false;
    });
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Gửi đánh giá thành công")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gửi đánh giá thất bại")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    return Scaffold(
      appBar: AppBar(
        title: Text("Thêm đánh giá", style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      backgroundColor: isModern ? Colors.black : const Color(0xFFF8F8F8),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: isModern ? Color(0xFF121212) : null,
          elevation: isModern ? 1 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isModern ? BorderSide(color: Colors.white10) : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.sports_soccer, color: isModern ? Colors.white70 : Colors.amber[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        field?.name ?? '',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isModern ? Colors.white : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: scoreController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Điểm (1-5)",
                          labelStyle: TextStyle(fontFamily: 'Roboto', color: isModern ? Colors.white70 : null),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: isModern ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)) : null,
                          focusedBorder: isModern ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white)) : null,
                        ),
                        style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 18, color: isModern ? Colors.white : null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Bình luận",
                    labelStyle: TextStyle(fontFamily: 'Roboto', color: isModern ? Colors.white70 : null),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: isModern ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)) : null,
                    focusedBorder: isModern ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white)) : null,
                  ),
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: isModern ? Colors.white : null),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: isAnonymous,
                      onChanged: (val) {
                        setState(() {
                          isAnonymous = val ?? false;
                        });
                      },
                      activeColor: isModern ? Colors.white : Colors.amber,
                      checkColor: isModern ? Colors.black : Colors.white,
                    ),
                    Text(
                      "Đánh giá Ẩn danh",
                      style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500, color: isModern ? Colors.white70 : null),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Center(
                  child: isLoading
                      ? CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: submitRating,
                            icon: Icon(Icons.send, color: isModern ? Colors.black : Colors.white),
                            label: Text(
                              "Gửi đánh giá",
                              style: TextStyle(fontSize: 16, fontFamily: 'Roboto', fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isModern ? Colors.white : Colors.amber[800],
                              foregroundColor: isModern ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
