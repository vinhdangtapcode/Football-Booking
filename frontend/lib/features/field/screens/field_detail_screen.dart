import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/field.dart';
import '../../../services/api_service.dart';
import '../../../services/map_service.dart';
import '../../../services/theme_service.dart';

class FieldDetailScreen extends StatefulWidget {
  @override
  _FieldDetailScreenState createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  Field? field;
  bool isFavorite = false;
  bool favLoading = false;
  int _currentImageIndex = 0;
  List<String> _galleryImages = [];
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      final Field args = ModalRoute.of(context)!.settings.arguments as Field;
      field = args;
      if (field!.imageUrls != null && field!.imageUrls!.isNotEmpty) {
        _galleryImages = List<String>.from(field!.imageUrls!);
      } else if (field!.imageUrl != null && field!.imageUrl!.isNotEmpty) {
        _galleryImages = [field!.imageUrl!];
      }
      checkFavorite();
      _loadFieldImages();
      _hasInitialized = true;
    }
  }

  Future<void> _loadFieldImages() async {
    if (field?.id == null) return;
    try {
      final images = await ApiService.getFieldImages(field!.id!);
      if (images.isNotEmpty) {
        final resolvedUrls = images.map((img) => img['url'] as String).toList();
        // Check if lists are equal before calling setState to avoid image flashing/recreation
        bool isIdentical = _galleryImages.length == resolvedUrls.length;
        if (isIdentical) {
          for (int i = 0; i < _galleryImages.length; i++) {
            if (_galleryImages[i] != resolvedUrls[i]) {
              isIdentical = false;
              break;
            }
          }
        }
        if (!isIdentical) {
          setState(() {
            _galleryImages = resolvedUrls;
          });
        }
      }
    } catch (e) {
      print('Error loading field images in detail screen: $e');
    }
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

  Widget _buildBentoBox({
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool isModern = false,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isModern ? const Color(0xFF16181D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isModern ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: isModern
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    if (field == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Field Details"),
          backgroundColor: isModern ? Colors.black : Colors.amber,
        ),
        body: Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber)),
      );
    }
    return Scaffold(
      backgroundColor: isModern ? const Color(0xFF0A0B0E) : const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: isModern ? const Color(0xFF0A0B0E) : Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: favLoading
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: isModern ? Colors.white : Colors.red))
                    : Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : (isModern ? Colors.white : Colors.redAccent),
                      ),
                onPressed: favLoading ? null : toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                field!.name,
                style: TextStyle(
                  fontFamily: 'sans-serif-condensed',
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1.5),
                      blurRadius: 4.0,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _galleryImages.isNotEmpty
                      ? PageView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _galleryImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: _galleryImages[index],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(child: CircularProgressIndicator(color: Colors.white)),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            );
                          },
                        )
                      : ((field!.imageUrl?.isNotEmpty ?? false)
                          ? CachedNetworkImage(
                              imageUrl: field!.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(child: CircularProgressIndicator(color: Colors.white)),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            )
                          : const Image(image: AssetImage('lib/assets/images/san_bong.png'), fit: BoxFit.cover)),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_galleryImages.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _galleryImages.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 10 : 6,
                            height: _currentImageIndex == index ? 10 : 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: viewRatings,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: isModern ? 0.8 : 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: isModern ? Border.all(color: Colors.white24) : null,
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
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Row 1: Chủ sân & Loại cỏ
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildBentoBox(
                        isModern: isModern,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isModern ? Colors.white10 : Colors.amber.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: isModern ? Colors.white : Colors.amber.shade800, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Chủ sân', style: TextStyle(fontSize: 10, color: isModern ? Colors.white54 : Colors.grey.shade600, fontFamily: 'Roboto')),
                                  const SizedBox(height: 2),
                                  Text(
                                    field!.owner?.ownerName ?? '-',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.black87, fontFamily: 'Roboto'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (field!.owner != null)
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isModern ? Colors.white.withValues(alpha: 0.05) : Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isModern ? Border.all(color: Colors.white12) : null,
                                  ),
                                  child: Icon(Icons.chat_bubble_outline, color: isModern ? const Color(0xFF00E676) : Colors.amber.shade800, size: 16),
                                ),
                                onPressed: () => _openChat(),
                                tooltip: 'Nhắn tin cho chủ sân',
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildBentoBox(
                        isModern: isModern,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isModern ? Colors.white10 : Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.grass, color: isModern ? const Color(0xFF00E676) : Colors.teal, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mặt sân', style: TextStyle(fontSize: 10, color: isModern ? Colors.white54 : Colors.grey.shade600, fontFamily: 'Roboto')),
                                  const SizedBox(height: 2),
                                  Text(
                                    field!.grassType == 'artificial'
                                        ? 'Nhân tạo'
                                        : field!.grassType == 'natural'
                                            ? 'Tự nhiên'
                                            : (field!.grassType ?? '-'),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.black87, fontFamily: 'Roboto'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Row 2: Loại sân & Giờ hoạt động
                Row(
                  children: [
                    Expanded(
                      child: _buildBentoBox(
                        isModern: isModern,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isModern ? Colors.white10 : Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.category, color: isModern ? Colors.white : Colors.blueAccent, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Loại sân', style: TextStyle(fontSize: 10, color: isModern ? Colors.white54 : Colors.grey.shade600, fontFamily: 'Roboto')),
                                  const SizedBox(height: 2),
                                  Text(
                                    field!.type ?? '-',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.black87, fontFamily: 'Roboto'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBentoBox(
                        isModern: isModern,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isModern ? Colors.white10 : Colors.purple.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.access_time, color: isModern ? Colors.white : Colors.purple, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Giờ mở', style: TextStyle(fontSize: 10, color: isModern ? Colors.white54 : Colors.grey.shade600, fontFamily: 'Roboto')),
                                  const SizedBox(height: 2),
                                  Text(
                                    (field!.openingTime != null && field!.openingTime!.isNotEmpty && field!.openingTime != 'null')
                                        ? '${field!.openingTime!.substring(0, 5)} - ${field!.closingTime!.substring(0, 5)}'
                                        : '06:00 - 22:00',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.black87, fontFamily: 'Roboto'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 3: Tiện ích (Bento Full Width)
                _buildBentoBox(
                  isModern: isModern,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stars, size: 20, color: isModern ? const Color(0xFF00E676) : Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text('Dịch vụ & Tiện ích', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.black87, fontFamily: 'Roboto')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (field!.facilities ?? '-')
                            .split(',')
                            .map((facility) {
                              final name = facility.trim();
                              if (name.isEmpty) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isModern ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isModern ? Border.all(color: Colors.white12, width: 0.5) : null,
                                ),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isModern ? Colors.white70 : Colors.black87,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Row 4: Địa điểm & Bản đồ
                _buildBentoBox(
                  isModern: isModern,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: isModern ? const Color(0xFF00E676) : Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Text('Vị trí & Đường đi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.black87, fontFamily: 'Roboto')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        field!.address,
                        style: TextStyle(fontSize: 14, color: isModern ? Colors.white70 : Colors.black87, height: 1.4, fontFamily: 'Roboto'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: viewOnMap,
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('Bản đồ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isModern ? Colors.white.withValues(alpha: 0.1) : Colors.blue.shade600,
                                foregroundColor: isModern ? Colors.white : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: openDirections,
                              icon: const Icon(Icons.directions, size: 18),
                              label: const Text('Chỉ dẫn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isModern ? const Color(0xFF00E676).withValues(alpha: 0.15) : Colors.green.shade600,
                                foregroundColor: isModern ? const Color(0xFF00E676) : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isModern ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: isModern ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giá thuê sân',
                        style: TextStyle(
                          fontSize: 11,
                          color: isModern ? Colors.white54 : Colors.grey.shade600,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${field!.pricePerHour.toInt()}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isModern ? const Color(0xFF00E676) : Colors.green.shade700,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'đ/giờ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isModern ? Colors.white70 : Colors.black87,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: bookField,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isModern ? Colors.white : Colors.amber,
                        foregroundColor: isModern ? Colors.black : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, size: 20, color: isModern ? Colors.black : Colors.black),
                          const SizedBox(width: 8),
                          const Text(
                            'Đặt sân ngay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
