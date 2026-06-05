import 'package:flutter/material.dart';

mixin PaginationMixin<T> on State<StatefulWidget> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  List<T> _items = [];

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  List<T> get items => List.unmodifiable(_items);

  int get pageSize => 20;

  Future<({List<T> items, int total})> fetchPage(int page);

  Future<void> loadFirstPage() async {
    _currentPage = 0;
    _hasMore = true;
    _items = [];
    await _fetchPageInternal(0);
  }

  Future<void> nextPage() async {
    if (!_hasMore || _isLoading) return;
    await _fetchPageInternal(_currentPage + 1);
  }

  Future<void> previousPage() async {
    if (_currentPage == 0 || _isLoading) return;
    await _fetchPageInternal(_currentPage - 1);
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    await _fetchPageInternal(0);
  }

  Future<void> _fetchPageInternal(int page) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await fetchPage(page);
      if (!mounted) return;
      setState(() {
        _currentPage = page;
        _totalPages = result.total == 0 ? 0 : (result.total / pageSize).ceil();
        _hasMore =
            result.items.length == pageSize && (_currentPage + 1) < _totalPages;
        if (page == 0) {
          _items = result.items;
        } else {
          _items = [..._items, ...result.items];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      rethrow;
    }
  }
}
