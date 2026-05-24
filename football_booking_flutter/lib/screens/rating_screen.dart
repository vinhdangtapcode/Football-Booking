import 'package:flutter/material.dart';
import '../models/field.dart';
import '../models/rating.dart';
import '../services/api_service.dart';

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
      if (tabIndex == 0) {
        List<Rating> fetchedRatings = await ApiService.getRatings(field!.id!);
        setState(() {
          ratings = fetchedRatings;
          isLoading = false;
        });
      } else {
        List<Rating> fetchedMyRatings = await ApiService.getMyRatings();
        // Lọc các đánh giá của tôi cho sân này
        fetchedMyRatings = fetchedMyRatings.where((r) => r.field.id == field!.id).toList();
        setState(() {
          myRatings = fetchedMyRatings;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMsg = "Không thể tải đánh giá.";
      });
    }
  }

  void onEditRating(Rating rating) async {
    int? newScore = rating.score;
    String? newComment = rating.comment;
    bool? newIsAnonymous = rating.isAnonymous;
    final scoreController = TextEditingController(text: rating.score.toString());
    final commentController = TextEditingController(text: rating.comment ?? '');
    bool isAnon = rating.isAnonymous ?? false;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sửa đánh giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Điểm (1-5)'),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(labelText: 'Bình luận'),
              ),
              Row(
                children: [
                  Checkbox(
                    value: isAnon,
                    onChanged: (val) {
                      isAnon = val ?? false;
                      setState(() {});
                    },
                  ),
                  Text('Ẩn danh'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
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
                bool success = await ApiService.updateRating(
                  rating.id!,
                  score,
                  commentController.text,
                  isAnon,
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
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void onDeleteRating(Rating rating) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa đánh giá'),
        content: Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      bool success = await ApiService.deleteRating(rating.id!);
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
    final displayName = (rating.isAnonymous == true)
        ? 'Ẩn danh'
        : (rating.userName ?? 'Người dùng');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber[100],
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
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
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      Text(
                        rating.score.toString(),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rating.comment ?? '',
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),
            if (isMine)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Sửa',
                    onPressed: () => onEditRating(rating),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đánh giá sân ", style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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
                ? const Center(child: CircularProgressIndicator())
                : errorMsg != null
                    ? Center(child: Text(errorMsg!))
                    : ratings.isEmpty
                        ? Center(child: Text("Chưa có đánh giá nào."))
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
                ? const Center(child: CircularProgressIndicator())
                : errorMsg != null
                    ? Center(child: Text(errorMsg!))
                    : myRatings.isEmpty
                        ? Center(child: Text("Bạn chưa gửi đánh giá nào cho sân này."))
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
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            )
          : null,
      backgroundColor: const Color(0xFFF8F8F8),
    );
  }
}
