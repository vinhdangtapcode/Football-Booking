import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rating_provider.dart';
import '../../../models/field.dart';
import '../../../models/rating.dart';
import '../../../services/theme_service.dart';

class RatingScreen extends StatefulWidget {
  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> with SingleTickerProviderStateMixin {
  List<Rating> ratings = [];
  List<Rating> myRatings = [];
  bool isLoading = false;
  String? errorMsg;
  Field? field;
  int tabIndex = 0;
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Field args = ModalRoute.of(context)!.settings.arguments as Field;
    field = args;
    _tabController ??= TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.index != tabIndex) {
        setState(() {
          tabIndex = _tabController!.index;
        });
        fetchRatings();
      }
    });
    fetchRatings();
  }

  Future<void> fetchRatings() async {
    if (field == null) return;
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final ratingProvider = context.read<RatingProvider>();
      if (tabIndex == 0) {
        await ratingProvider.loadRatings(field!.id!);
        if (mounted) {
          setState(() {
            ratings = ratingProvider.ratings;
            isLoading = false;
          });
        }
      } else {
        await ratingProvider.loadMyRatingsForField(field!.id!);
        if (mounted) {
          setState(() {
            myRatings = ratingProvider.myRatings;
            isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = "Không thể tải đánh giá.";
        });
      }
    }
  }

  void onEditRating(Rating rating) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isModern = themeProvider.isModernMode;
    int? newScore = rating.score;
    String? newComment = rating.comment;
    bool? newIsAnonymous = rating.isAnonymous;
    final scoreController = TextEditingController(text: rating.score.toString());
    final commentController = TextEditingController(text: rating.comment ?? '');
    bool isAnon = rating.isAnonymous ?? false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: isModern ? Color(0xFF121212) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Sửa đánh giá', style: TextStyle(color: isModern ? Colors.white : null)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: scoreController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isModern ? Colors.white : null),
                    decoration: InputDecoration(
                      labelText: 'Điểm (1-5)',
                      labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                      enabledBorder: isModern ? UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)) : null,
                      focusedBorder: isModern ? UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)) : null,
                    ),
                  ),
                  TextField(
                    controller: commentController,
                    style: TextStyle(color: isModern ? Colors.white : null),
                    decoration: InputDecoration(
                      labelText: 'Bình luận',
                      labelStyle: TextStyle(color: isModern ? Colors.white70 : null),
                      enabledBorder: isModern ? UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)) : null,
                      focusedBorder: isModern ? UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)) : null,
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isAnon,
                        activeColor: isModern ? Colors.white : Colors.amber,
                        checkColor: isModern ? Colors.black : Colors.white,
                        onChanged: (val) {
                          dialogSetState(() {
                            isAnon = val ?? false;
                          });
                        },
                      ),
                      Text('Ẩn danh', style: TextStyle(color: isModern ? Colors.white70 : null)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: isModern ? Colors.white70 : null)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    int? score = int.tryParse(scoreController.text);
                    if (score == null || score < 1 || score > 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Điểm phải từ 1 đến 5')),
                      );
                      return;
                    }
                    final ratingProvider = context.read<RatingProvider>();
                    bool success = await ratingProvider.updateRating(
                      rating.id!,
                      score,
                      commentController.text,
                      isAnon,
                      field!.id!,
                    );
                    if (success) {
                      Navigator.pop(context);
                      fetchRatings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cập nhật thành công')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cập nhật thất bại')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isModern ? Colors.white : Colors.amber,
                    foregroundColor: isModern ? Colors.black : Colors.white,
                  ),
                  child: Text('Lưu'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void onDeleteRating(Rating rating) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isModern = themeProvider.isModernMode;
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isModern ? Color(0xFF121212) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa đánh giá', style: TextStyle(color: isModern ? Colors.white : null)),
        content: Text('Bạn có chắc muốn xóa đánh giá này?', style: TextStyle(color: isModern ? Colors.white70 : null)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: isModern ? Colors.white70 : null)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isModern ? Colors.white : Colors.amber,
              foregroundColor: isModern ? Colors.black : Colors.white,
            ),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      bool success = await context.read<RatingProvider>().deleteRating(rating.id!, field!.id!);
      if (success) {
        fetchRatings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa đánh giá')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thất bại')),
        );
      }
    }
  }

  Widget buildRatingItem(Rating rating, {bool isMine = false}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;
    final displayName = (rating.isAnonymous == true)
        ? 'Ẩn danh'
        : (rating.userName ?? 'Người dùng');
    return Card(
      color: isModern ? Color(0xFF121212) : null,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: isModern ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isModern ? BorderSide(color: Colors.white10) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isModern ? Colors.white24 : Colors.amber[100],
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: TextStyle(fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.amber),
              ),
              radius: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isModern ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      Text(
                        rating.score.toString(),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          color: isModern ? Colors.amber[400] : Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rating.comment ?? '',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 15, color: isModern ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
            if (isMine)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: isModern ? Colors.blue[400] : Colors.blue),
                    tooltip: 'Sửa',
                    onPressed: () => onEditRating(rating),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: isModern ? Colors.red[400] : Colors.red),
                    tooltip: 'Xóa',
                    onPressed: () => onDeleteRating(rating),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đánh giá sân ", style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: isModern ? Colors.white : Colors.black,
          unselectedLabelColor: isModern ? Colors.white60 : Colors.black54,
          indicatorColor: isModern ? Colors.white : Colors.amber,
          tabs: [
            Tab(text: 'Tất cả đánh giá'),
            Tab(text: 'Đánh giá của tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: fetchRatings,
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
                : errorMsg != null
                    ? Center(child: Text(errorMsg!, style: TextStyle(color: isModern ? Colors.white70 : null)))
                    : ratings.isEmpty
                        ? Center(child: Text("Chưa có đánh giá nào.", style: TextStyle(color: isModern ? Colors.white70 : null)))
                        : ListView.builder(
                            itemCount: ratings.length,
                            itemBuilder: (context, index) {
                              return buildRatingItem(ratings[index]);
                            },
                          ),
          ),
          RefreshIndicator(
            onRefresh: fetchRatings,
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
                : errorMsg != null
                    ? Center(child: Text(errorMsg!, style: TextStyle(color: isModern ? Colors.white70 : null)))
                    : myRatings.isEmpty
                        ? Center(child: Text("Bạn chưa gửi đánh giá nào cho sân này.", style: TextStyle(color: isModern ? Colors.white70 : null)))
                        : ListView.builder(
                            itemCount: myRatings.length,
                            itemBuilder: (context, index) {
                              return buildRatingItem(myRatings[index], isMine: true);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/addRating', arguments: field)
                    .then((_) => fetchRatings());
              },
              icon: const Icon(Icons.add_comment),
              label: const Text('Thêm đánh giá', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
              backgroundColor: isModern ? Colors.white : Colors.amber,
              foregroundColor: isModern ? Colors.black : Colors.black,
            )
          : null,
      backgroundColor: isModern ? Colors.black : const Color(0xFFF8F8F8),
    );
  }
}
