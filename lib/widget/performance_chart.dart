import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/app_schema.dart';
import '../services/locale_service.dart';

class PerformanceChart extends StatefulWidget {
  final String uid;
  const PerformanceChart({super.key, required this.uid});

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart> {
  int _selectedTabIndex = 0; // 0: 1W, 1: 1M, 2: 1Y
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Strength', 'Intelligence', 'Defense', 'Vitality', 'Agility'];
  bool _isLoading = true;
  List<FlSpot> _chartData = [];
  double _maxY = 100;
  double _maxX = 6;
  
  // Cache the fetched documents so we don't query Firestore multiple times when switching tabs
  List<QueryDocumentSnapshot> _taskDocs = [];
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      if (!_hasFetched) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('tasks')
            .where(TaskSchema.done, isEqualTo: true)
            .get();
        _taskDocs = snap.docs;
        _hasFetched = true;
      }

      _processData();
    } catch (e) {
      debugPrint('PerformanceChart Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData() {
    final now = DateTime.now();
    DateTime startDate;
    
    if (_selectedTabIndex == 0) {
      startDate = now.subtract(const Duration(days: 6));
    } else if (_selectedTabIndex == 1) {
      startDate = now.subtract(const Duration(days: 29));
    } else {
      startDate = now.subtract(const Duration(days: 364));
    }
    startDate = DateTime(startDate.year, startDate.month, startDate.day);

    List<FlSpot> spots = [];
    double maxY = 0;

    if (_selectedTabIndex == 2) {
      // 1 Year - Group by month
      Map<String, int> xpPerMonth = {};
      for (var doc in _taskDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final docCat = data[TaskSchema.category] as String? ?? '';
        if (_selectedCategory != 'All' && docCat != _selectedCategory) continue;

        final ts = data[TaskSchema.completedAt] as Timestamp?;
        if (ts != null) {
           final dt = ts.toDate();
           if (dt.isAfter(startDate) || dt.isAtSameMomentAs(startDate)) {
              final mKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
              final xp = data[TaskSchema.xp] as int? ?? 0;
              xpPerMonth[mKey] = (xpPerMonth[mKey] ?? 0) + xp;
           }
        }
      }
      
      for (int i = 0; i < 12; i++) {
         int month = now.month - 11 + i;
         int year = now.year;
         if (month <= 0) {
           month += 12;
           year -= 1;
         }
         final mKey = '$year-${month.toString().padLeft(2, '0')}';
         final val = (xpPerMonth[mKey] ?? 0).toDouble();
         if (val > maxY) maxY = val;
         spots.add(FlSpot(i.toDouble(), val));
      }
      _maxX = 11;
    } else {
      // 1W or 1M - Group by day
      Map<String, int> xpPerDay = {};
      for (var doc in _taskDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final docCat = data[TaskSchema.category] as String? ?? '';
        if (_selectedCategory != 'All' && docCat != _selectedCategory) continue;

        final ts = data[TaskSchema.completedAt] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          if (dt.isAfter(startDate) || dt.isAtSameMomentAs(startDate)) {
            final dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            final xp = data[TaskSchema.xp] as int? ?? 0;
            xpPerDay[dateKey] = (xpPerDay[dateKey] ?? 0) + xp;
          }
        }
      }
      
      int daysCount = _selectedTabIndex == 0 ? 7 : 30;
      for (int i = 0; i < daysCount; i++) {
        final date = startDate.add(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final val = (xpPerDay[dateKey] ?? 0).toDouble();
        if (val > maxY) maxY = val;
        spots.add(FlSpot(i.toDouble(), val));
      }
      _maxX = daysCount.toDouble() - 1;
    }

    // Add some headroom
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    setState(() {
      _chartData = spots;
      _maxY = maxY;
      _isLoading = false;
    });
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedTabIndex = index;
          });
          _processData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final l = context.lw;
    final style = GoogleFonts.nunito(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text = '';
    
    final now = DateTime.now();
    
    if (_selectedTabIndex == 0) {
      // 1W: show day names like Mon, Tue
      if (value.toInt() >= 0 && value.toInt() < 7) {
        final date = now.subtract(Duration(days: 6 - value.toInt()));
        final days = l.dayShort;
        text = days[date.weekday - 1];
      }
    } else if (_selectedTabIndex == 1) {
      // 1M: show 4 evenly spaced dates
      if (value.toInt() % 7 == 0 || value == _maxX) {
        final date = now.subtract(Duration(days: 29 - value.toInt()));
        text = '${date.day}/${date.month}';
      }
    } else if (_selectedTabIndex == 2) {
      // 1Y: show months
      int month = now.month - 11 + value.toInt();
      if (month <= 0) month += 12;
      final months = l.monthShort;
      if (value.toInt() >= 0 && value.toInt() < 12) {
        text = months[month - 1];
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10.0,
      child: Text(text, style: style),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    final style = GoogleFonts.nunito(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    // Don't show fractional XP
    if (value % 1 != 0) return const SizedBox.shrink();
    
    String text;
    if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      text = value.toInt().toString();
    }
    
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: Text(text, style: style, textAlign: TextAlign.right),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get translations for tabs
    final l = context.lw;
    
    // We can use localized strings or standard ones
    final tab1W = l.statsTab1W;
    final tab1M = l.statsTab1M;
    final tab1Y = l.statsTab1Y;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: AppColors.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 12,
            children: [
              Text(
                l.statsPerformanceXp,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTab(tab1W, 0),
                    _buildTab(tab1M, 1),
                    _buildTab(tab1Y, 2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat == 'All' ? l.statsCatAll : cat,
                      style: GoogleFonts.nunito(
                        color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected && _selectedCategory != cat) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        _processData();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _chartData.isEmpty
                    ? Center(
                        child: Text(
                          l.statsNoData,
                          style: GoogleFonts.nunito(color: AppColors.textSecondary),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (_maxY / 4) == 0 ? 1 : (_maxY / 4),
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: AppColors.textPrimary.withValues(alpha: 0.05),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: _bottomTitleWidgets,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (_maxY / 4) == 0 ? 1 : (_maxY / 4),
                                getTitlesWidget: _leftTitleWidgets,
                                reservedSize: 36,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: _maxX,
                          minY: 0,
                          maxY: _maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartData,
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: _selectedTabIndex != 1, // Don't show dots for 1M because there are too many (30)
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: AppColors.background,
                                    strokeWidth: 2,
                                    strokeColor: AppColors.primary,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (spot) => AppColors.cardBackground,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((LineBarSpot touchedSpot) {
                                  return LineTooltipItem(
                                    '${touchedSpot.y.toInt()} XP',
                                    GoogleFonts.nunito(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                            handleBuiltInTouches: true,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
