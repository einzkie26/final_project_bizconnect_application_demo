import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          FirebaseFirestore.instance.collection('users').get(),
          FirebaseFirestore.instance.collection('companies').get(),
          FirebaseFirestore.instance.collection('chats').get(),
          FirebaseFirestore.instance.collection('follows').get(),
          FirebaseFirestore.instance.collection('company_follows').get(),
          FirebaseFirestore.instance.collection('company_members').get(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final users = snapshot.data![0].docs.length;
          final companies = snapshot.data![1].docs.length;
          final chats = snapshot.data![2].docs.length;
          final follows = snapshot.data![3].docs.length;
          final companyFollows = snapshot.data![4].docs.length;
          final companyMembers = snapshot.data![5].docs.length;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform Distribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPieChart(users, companies, chats),
                const SizedBox(height: 30),
                const Text('Activity Comparison', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildBarChart(users, companies, chats, follows),
                const SizedBox(height: 30),
                const Text('Growth Trend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLineChart(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieChart(int users, int companies, int chats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: users.toDouble(),
                  title: 'Users\n$users',
                  color: Colors.blue,
                  radius: 100,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: companies.toDouble(),
                  title: 'Companies\n$companies',
                  color: Colors.green,
                  radius: 100,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: chats.toDouble(),
                  title: 'Chats\n$chats',
                  color: Colors.purple,
                  radius: 100,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(int users, int companies, int chats, int follows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: [users, companies, chats, follows].reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: users.toDouble(), color: Colors.blue, width: 20)]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: companies.toDouble(), color: Colors.green, width: 20)]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: chats.toDouble(), color: Colors.purple, width: 20)]),
                BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: follows.toDouble(), color: Colors.orange, width: 20)]),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const titles = ['Users', 'Companies', 'Chats', 'Follows'];
                      return Text(titles[value.toInt()], style: const TextStyle(fontSize: 12));
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                      return Text(months[value.toInt() % 6], style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: [FlSpot(0, 10), FlSpot(1, 25), FlSpot(2, 40), FlSpot(3, 55), FlSpot(4, 70), FlSpot(5, 90)],
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: [FlSpot(0, 5), FlSpot(1, 15), FlSpot(2, 30), FlSpot(3, 45), FlSpot(4, 60), FlSpot(5, 80)],
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
