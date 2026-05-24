import 'package:flutter/material.dart';
import '../models/field.dart';
import '../services/api_service.dart';
import '../services/map_service.dart';

class FieldDetailScreen extends StatefulWidget {
  @override
  _FieldDetailScreenState createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  Field? field;
  bool isFavorite = false;
  bool favLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Field args = ModalRoute.of(context)!.settings.arguments as Field;
    field = args;
    checkFavorite();
  }

  Future<void> checkFavorite() async {
    if (field?.id == null) return;
    final favs = await ApiService.getFavorites();
    setState(() {
      isFavorite = favs.any((f) => f.id == field!.id);
    });
  }

  Future<void> toggleFavorite() async {
    if (field?.id == null) return;
    setState(() { favLoading = true; });
    if (isFavorite) {
      await ApiService.removeFavorite(field!.id!);
    } else {
      await ApiService.addFavorite(field!.id!);
    }
    await checkFavorite();
    setState(() { favLoading = false; });
  }

  void bookField() {
    // Kiểm tra tình trạng sân trước khi cho phép đặt
    if (field?.available != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sân không sẵn sàng để đặt'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.pushNamed(context, '/booking', arguments: field);
  }

  void viewRatings() {
    Navigator.pushNamed(context, '/ratings', arguments: field);
  }

  // Thêm các method mới cho Maps
  void viewOnMap() {
    Navigator.pushNamed(context, '/map', arguments: field);
  }

  Future<void> openDirections() async {
    try {
      await MapService.openDirectionsWithAddress(field!.address);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở chỉ đường: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openChat() async {
    if (field?.owner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy thông tin chủ sân'), backgroundColor: Colors.red),
      );
      return;
    }

    // Lấy thông tin user hiện tại
    final currentUser = await ApiService.getProfile();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đăng nhập để nhắn tin'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    try {
      // Tạo hoặc lấy conversation
      final conversation = await ApiService.getOrCreateConversation(
        currentUser.id!,
        field!.owner!.id,
        field!.id,
      );

      Navigator.pop(context); // Đóng loading

      if (conversation != null && conversation['id'] != null) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'conversationId': conversation['id'],
            'currentUserId': currentUser.id,
            'currentUserType': 'USER',
            'otherPartyName': field!.owner!.ownerName,
            'fieldName': field!.name,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo cuộc hội thoại'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Đóng loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (field == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Field Details")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          field!.name,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.amber,
        elevation: 0,
        actions: [
          IconButton(
            icon: favLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                : Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.redAccent,
                  ),
            onPressed: favLoading ? null : toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner image
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                image: DecorationImage(
                  image: (field!.imageUrl?.isNotEmpty ?? false)
                      ? NetworkImage(field!.imageUrl!)
                      : const AssetImage('lib/assets/images/san_bong.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: viewRatings,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.yellow, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              field!.rating != null
                                  ? (field!.rating % 1 == 0
                                      ? field!.rating.toInt().toString()
                                      : field!.rating.toStringAsFixed(1))
                                  : '0',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Card with info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên chủ sân
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text('Chủ sân: ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                          Expanded(
                            child: Text(
                              field!.owner?.ownerName ?? '-',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          if (field!.owner != null)
                            IconButton(
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.chat_bubble_outline, color: Colors.amber.shade800, size: 20),
                              ),
                              onPressed: () => _openChat(),
                              tooltip: 'Nhắn tin cho chủ sân',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              field!.address,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.category, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text('Loại sân: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(field!.type ?? '-', style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Text('Giá: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('${field!.pricePerHour.toInt()} VNĐ/giờ', style: TextStyle(color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text('Giờ mở cửa: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            (field!.openingTime != null && field!.openingTime!.isNotEmpty && field!.openingTime != 'null')
                                ? field!.openingTime!.substring(0, 5)
                                : '-',
                            style: TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(width: 16),
                          Text('Giờ đóng cửa: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            (field!.closingTime != null && field!.closingTime!.isNotEmpty && field!.closingTime != 'null')
                                ? field!.closingTime!.substring(0, 5)
                                : '-',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.grass, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text('Loại cỏ: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            field!.grassType == 'artificial'
                                ? 'Nhân tạo'
                                : field!.grassType == 'natural'
                                    ? 'Tự nhiên'
                                    : (field!.grassType ?? '-'),
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.wifi, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text('Tiện ích: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          Expanded(child: Text('${field!.facilities ?? '-'}', style: TextStyle(color: Colors.black87))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Hàng đầu tiên: Đặt sân và Xem đánh giá
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: bookField,
                          icon: const Icon(Icons.calendar_month),
                          label: const Text("Đặt sân"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: viewRatings,
                          icon: const Icon(Icons.star, color: Colors.amber),
                          label: const Text("Xem đánh giá"),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber, width: 2),
                            foregroundColor: Colors.amber,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Hàng thứ hai: Xem bản đồ và Chỉ đường
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: viewOnMap,
                          icon: const Icon(Icons.map, color: Colors.white),
                          label: const Text("Xem bản đồ"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: openDirections,
                          icon: const Icon(Icons.directions, color: Colors.white),
                          label: const Text("Chỉ đường"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF8F8F8),
    );
  }
}
