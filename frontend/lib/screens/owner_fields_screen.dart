import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/field.dart';
import '../services/api_service.dart';

class OwnerFieldsScreen extends StatefulWidget {
  @override
  _OwnerFieldsScreenState createState() => _OwnerFieldsScreenState();
}

class _OwnerFieldsScreenState extends State<OwnerFieldsScreen> {
  List<Field> ownerFields = [];
  List<Field> filteredFields = [];
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchOwnerFields();
  }

  void fetchOwnerFields() async {
    setState(() {
      isLoading = true;
    });
    List<Field> fields = await ApiService.getOwnerFields();
    setState(() {
      ownerFields = fields;
      filteredFields = fields;
      isLoading = false;
    });
  }

  void _filterFields(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFields = ownerFields;
      } else {
        filteredFields = ownerFields.where((field) {
          return field.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void deleteField(Field field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        String inputVal = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isMatch = inputVal.trim() == field.name.trim();
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xác nhận xóa sân'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hành động này KHÔNG THỂ hoàn tác!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toàn bộ lịch đặt sân, đánh giá, hình ảnh và lượt yêu thích của sân "${field.name}" sẽ bị xóa vĩnh viễn khỏi hệ thống.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nhập tên sân bên dưới để xác nhận:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: field.name,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        inputVal = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isMatch
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Xóa vĩnh viễn'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirm != true) return;

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    bool success = await ApiService.deleteField(field.id!);
    Navigator.of(context).pop(); // Close loading spinner

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa sân "${field.name}" thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      fetchOwnerFields();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Xóa sân thất bại!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToEditField(Field field) {
    Navigator.pushNamed(context, '/addEditField', arguments: field)
        .then((_) => fetchOwnerFields());
  }

  void navigateToFieldBookingHistory(Field field) {
    Navigator.pushNamed(context, '/fieldBookingHistory', arguments: field);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.amberAccent,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: searchController,
            onChanged: _filterFields,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sân của bạn',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/addEditField')
                  .then((_) => fetchOwnerFields());
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : filteredFields.isEmpty
              ? Center(child: Text('Bạn chưa có sân nào!', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: filteredFields.length,
                  itemBuilder: (context, index) {
                    Field field = filteredFields[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      child: InkWell(
                        onTap: () => navigateToFieldBookingHistory(field),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double imageWidth = constraints.maxWidth / 5;
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: imageWidth,
                                    height: imageWidth * 0.75,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: (field.imageUrl?.isEmpty ?? true)
                                          ? Image.asset(
                                              'lib/assets/images/san_bong.png',
                                              fit: BoxFit.cover,
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: field.imageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              errorWidget: (_, __, ___) => Image.asset(
                                                'lib/assets/images/san_bong.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          field.name,
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          field.address ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.yellow,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              field.rating != null
                                                  ? (field.rating % 1 == 0
                                                      ? field.rating.toInt().toString()
                                                      : field.rating.toStringAsFixed(1))
                                                  : '0',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${field.pricePerHour.toInt()} VNĐ/giờ',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Đặt các nút sửa và xóa theo chiều ngang
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => navigateToEditField(field),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deleteField(field),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
          Navigator.pushNamed(context, '/addEditField')
              .then((_) => fetchOwnerFields());
        },
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Thêm sân mới',
      ),
    );
  }
}
