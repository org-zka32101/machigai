import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/viewmodels/analytics_provider.dart';

/// Analytics dashboard widget
class AnalyticsDashboard extends ConsumerWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final syncPerf = ref.watch(syncPerformanceProvider);
    final offlineUsage = ref.watch(offlineUsageProvider);
    final networkMetrics = ref.watch(networkMetricsProvider);
    final healthScore = ref.watch(healthScoreProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Score Card
          _buildHealthScoreCard(context, analytics),
          const SizedBox(height: 16),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Success Rate',
                  '${syncPerf.successRate.toStringAsFixed(1)}%',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Syncs',
                  syncPerf.totalSyncOperations.toString(),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Failed',
                  syncPerf.failedSyncs.toString(),
                  syncPerf.failedSyncs > 0 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sync Performance Section
          _buildSectionTitle('Sync Performance', context),
          _buildSyncPerformanceCard(context, syncPerf),
          const SizedBox(height: 16),

          // Offline Usage Section
          _buildSectionTitle('Offline Usage', context),
          _buildOfflineUsageCard(context, offlineUsage),
          const SizedBox(height: 16),

          // Network Section
          _buildSectionTitle('Network Conditions', context),
          _buildNetworkMetricsCard(context, networkMetrics),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, AnalyticsData analytics) {
    return Card(
      color: Color(int.parse('0xFF${analytics.healthStatusColor.substring(1)}')),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Health',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${analytics.healthScore}/100',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      analytics.healthStatus,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: analytics.healthScore / 100,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSyncPerformanceCard(BuildContext context, SyncPerformanceMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow(
              context,
              'Average Duration',
              '${metrics.averageSyncDuration.inMilliseconds}ms',
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Min Duration',
              '${metrics.minSyncDuration.inMilliseconds}ms',
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Max Duration',
              '${metrics.maxSyncDuration.inMilliseconds}ms',
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Total Retries',
              metrics.totalRetries.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineUsageCard(BuildContext context, OfflineUsageMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow(
              context,
              'Offline Events',
              metrics.totalOfflineEvents.toString(),
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Total Offline Time',
              '${metrics.totalOfflineTime.inMinutes}m',
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Operations Queued',
              metrics.operationsQueuedOffline.toString(),
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Successfully Synced',
              metrics.operationsSyncedAfterOffline.toString(),
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Offline Success Rate',
              '${metrics.offlineSuccessRate.toStringAsFixed(1)}%',
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Drafts Created Offline',
              metrics.draftsCreatedOffline.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkMetricsCard(BuildContext context, NetworkMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow(
              context,
              'Current Status',
              metrics.isOnline ? 'Online' : 'Offline',
              metrics.isOnline ? Colors.green : Colors.orange,
            ),
            const Divider(height: 16),
            _buildMetricRow(
              context,
              'Disconnections',
              metrics.disconnectionCount.toString(),
            ),
            if (metrics.longestDisconnectionDuration != null) ...[
              const Divider(height: 16),
              _buildMetricRow(
                context,
                'Longest Disconnection',
                '${metrics.longestDisconnectionDuration!.inMinutes}m',
              ),
            ],
            if (metrics.lastDisconnectionTime != null) ...[
              const Divider(height: 16),
              _buildMetricRow(
                context,
                'Last Disconnection',
                _formatTime(metrics.lastDisconnectionTime!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value, [
    Color? valueColor,
  ]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            ref.read(analyticsRefreshProvider)();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            final json = ref.read(analyticsProvider.notifier).exportAsJson();
            _showExportDialog(context, json);
          },
          icon: const Icon(Icons.download),
          label: const Text('Export'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            _showClearConfirmDialog(context, ref);
          },
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Clear'),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showExportDialog(BuildContext context, String json) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics'),
        content: SingleChildScrollView(
          child: SelectableText(json),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Analytics'),
        content: const Text('Are you sure you want to clear all analytics data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(analyticsProvider.notifier).clearAnalytics();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analytics cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
