import 'package:flutter/material.dart';
import '../../services/points/points_service.dart';

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  final PointsService _pointsService = PointsService();
  Map<String, dynamic>? _summary;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;
  int _offset = 0;
  final int _limit = 50;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _pointsService.getPointsSummary();
      final history = await _pointsService.getPointsHistory(limit: _limit, offset: 0);
      
      setState(() {
        _summary = summary;
        _transactions = history['transactions'] ?? [];
        _offset = _transactions.length;
        _hasMore = _transactions.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading points data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;

    try {
      final history = await _pointsService.getPointsHistory(limit: _limit, offset: _offset);
      final newTransactions = history['transactions'] ?? [];
      
      setState(() {
        _transactions.addAll(newTransactions);
        _offset = _transactions.length;
        _hasMore = newTransactions.length >= _limit;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'meeting_confirmed':
        return 'Meeting Confirmed';
      case 'meeting_attended':
        return 'Meeting Attended';
      case 'shake_meetup':
        return 'Shake MeetUp';
      case 'store_purchase':
        return 'Store Purchase';
      case 'mission_completed':
        return 'Mission Completed';
      default:
        return type.replaceAll('_', ' ').split(' ').map((word) => 
          word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points History'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Points Summary Card
                      if (_summary != null)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Total Points',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_summary!['total_points']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Transactions List
                      if (_transactions.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Text('No transactions yet'),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == _transactions.length) {
                                if (_hasMore) {
                                  _loadMore();
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }

                              final transaction = _transactions[index];
                              final isPositive = transaction['points'] > 0;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isPositive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isPositive ? Icons.add : Icons.remove,
                                      color: isPositive ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    _getTransactionTypeLabel(
                                      transaction['transaction_type'],
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: transaction['description'] != null
                                      ? Text(transaction['description'])
                                      : null,
                                  trailing: Text(
                                    '${isPositive ? '+' : ''}${transaction['points']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isPositive ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _transactions.length + (_hasMore ? 1 : 0),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

