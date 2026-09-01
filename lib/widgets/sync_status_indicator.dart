import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:machigai/viewmodels/sync_status_provider.dart';

/// Compact sync status indicator widget
/// Shows current sync state with icon and optional label
class CompactSyncStatusIndicator extends ConsumerWidget {
  final bool showLabel;
  final double size;

  const CompactSyncStatusIndicator({
    Key? key,
    this.showLabel = false,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return Tooltip(
      message: syncStatus.statusMessage,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicatorIcon(syncStatus.indicator, size),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Text(
              syncStatus.statusMessage,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicatorIcon(SyncStatusIndicator indicator, double size) {
    switch (indicator) {
      case SyncStatusIndicator.offline:
        return Icon(
          Icons.cloud_off,
          size: size,
          color: Colors.orange,
        );
      case SyncStatusIndicator.syncing:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue.shade400,
            ),
          ),
        );
      case SyncStatusIndicator.pending:
        return Icon(
          Icons.cloud_upload,
          size: size,
          color: Colors.amber,
        );
      case SyncStatusIndicator.error:
        return Icon(
          Icons.cloud_off,
          size: size,
          color: Colors.red,
        );
      case SyncStatusIndicator.synced:
        return Icon(
          Icons.cloud_done,
          size: size,
          color: Colors.green,
        );
    }
  }
}

/// Expanded sync status widget with detailed information
/// Shows full sync status with buttons for manual refresh/clear
class ExpandedSyncStatusWidget extends ConsumerWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onClear;

  const ExpandedSyncStatusWidget({
    Key? key,
    this.onRefresh,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with status indicator
            Row(
              children: [
                _buildStatusIcon(syncStatus.indicator),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        syncStatus.statusMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getStatusColor(syncStatus.indicator),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status details
            _buildStatusDetail(
              context,
              'Connection',
              syncStatus.isOnline ? 'Online' : 'Offline',
              syncStatus.isOnline ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildStatusDetail(
              context,
              'Pending',
              syncStatus.pendingOperations.toString(),
              syncStatus.pendingOperations > 0 ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildStatusDetail(
              context,
              'Synced',
              syncStatus.totalSynced.toString(),
              Colors.green,
            ),
            if (syncStatus.totalFailed > 0) ...[
              const SizedBox(height: 8),
              _buildStatusDetail(
                context,
                'Failed',
                syncStatus.totalFailed.toString(),
                Colors.red,
              ),
            ],
            if (syncStatus.lastSyncTime != null) ...[
              const SizedBox(height: 8),
              _buildStatusDetail(
                context,
                'Last Sync',
                '${syncStatus.timeSinceLastSyncMinutes}m ago',
                Colors.grey,
              ),
            ],

            // Action buttons
            if (syncStatus.requiresAttention) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onRefresh != null)
                    TextButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  const SizedBox(width: 8),
                  if (syncStatus.totalFailed > 0 && onClear != null)
                    TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatusIndicator indicator) {
    IconData iconData;
    Color color;

    switch (indicator) {
      case SyncStatusIndicator.offline:
        iconData = Icons.cloud_off;
        color = Colors.orange;
      case SyncStatusIndicator.syncing:
        return SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
          ),
        );
      case SyncStatusIndicator.pending:
        iconData = Icons.cloud_upload;
        color = Colors.amber;
      case SyncStatusIndicator.error:
        iconData = Icons.error_outline;
        color = Colors.red;
      case SyncStatusIndicator.synced:
        iconData = Icons.cloud_done;
        color = Colors.green;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(iconData, color: color),
    );
  }

  Widget _buildStatusDetail(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(SyncStatusIndicator indicator) {
    switch (indicator) {
      case SyncStatusIndicator.offline:
      case SyncStatusIndicator.error:
        return Colors.red;
      case SyncStatusIndicator.syncing:
      case SyncStatusIndicator.pending:
        return Colors.amber;
      case SyncStatusIndicator.synced:
        return Colors.green;
    }
  }
}

/// Snackbar for sync notifications
void showSyncNotification(BuildContext context, SyncStatus status) {
  if (!status.requiresAttention) return;

  final messenger = ScaffoldMessenger.of(context);

  String message;
  Color backgroundColor;
  IconData icon;

  switch (status.indicator) {
    case SyncStatusIndicator.offline:
      message = 'You are offline - changes will sync when online';
      backgroundColor = Colors.orange;
      icon = Icons.cloud_off;
    case SyncStatusIndicator.syncing:
      message = 'Syncing...';
      backgroundColor = Colors.blue;
      icon = Icons.cloud_upload;
    case SyncStatusIndicator.pending:
      message = '${status.pendingOperations} operations pending sync';
      backgroundColor = Colors.amber;
      icon = Icons.cloud_upload;
    case SyncStatusIndicator.error:
      message = 'Sync failed - ${status.totalFailed} operations need retry';
      backgroundColor = Colors.red;
      icon = Icons.error_outline;
    case SyncStatusIndicator.synced:
      message = 'All changes synced!';
      backgroundColor = Colors.green;
      icon = Icons.cloud_done;
  }

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
    ),
  );
}
