import 'package:flutter/material.dart';
import '../models/field.dart';
import '../services/api_service.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Field> favoriteFields = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  void fetchFavorites() async {
    setState(() {
      isLoading = true;
    });
    List<Field> favorites = await ApiService.getFavorites();
    setState(() {
      favoriteFields = favorites;
      isLoading = false;
    });
  }

  void removeFavorite(int fieldId) async {
    await ApiService.removeFavorite(fieldId);
    fetchFavorites();
  }

  Widget buildFavoriteItem(Field field) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/fieldDetail', arguments: field);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: field.imageUrl?.isEmpty ?? true
                    ? Image.asset(
                        'lib/assets/images/san_bong.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        field.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'lib/assets/images/san_bong.png',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.amber[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.amber[600], size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            field.address,
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Sử dụng Wrap và thay đổi cách hiển thị thông tin để tránh tràn
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Phần rating
                        Container(
                          constraints: BoxConstraints(maxWidth: 80),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${field.rating?.toStringAsFixed(1) ?? 'N/A'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[800],
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Phần giá
                        Container(
                          constraints: BoxConstraints(maxWidth: 100),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on, color: Colors.green[600], size: 14),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  field.pricePerHour.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite, color: Colors.red[400]),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Xác nhận'),
                      content: Text('Bạn có muốn xóa sân này khỏi danh sách yêu thích không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            removeFavorite(field.id!);
                          },
                          child: Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Xóa khỏi yêu thích',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sân yêu thích",
        ),
        backgroundColor: Colors.amberAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.amber[900]),
            onPressed: fetchFavorites,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber))
          : favoriteFields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.amber[300]),
                      SizedBox(height: 16),
                      Text(
                        "Bạn chưa có sân yêu thích nào!",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Hãy thêm sân yêu thích từ màn hình chi tiết sân",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: favoriteFields.length,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    return buildFavoriteItem(favoriteFields[index]);
                  },
                ),
    );
  }
}
