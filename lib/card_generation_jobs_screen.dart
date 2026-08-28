import 'package:flutter/material.dart';

import 'database/isar/card_generation_job.dart';
import 'services/card_generation_job_service.dart';
import 'theme/app_theme.dart';

class CardGenerationJobsScreen extends StatefulWidget {
  const CardGenerationJobsScreen({super.key});

  @override
  State<CardGenerationJobsScreen> createState() =>
      _CardGenerationJobsScreenState();
}

class _CardGenerationJobsScreenState extends State<CardGenerationJobsScreen> {
  List<CardGenerationJob> _jobs = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobs = await CardGenerationJobService.loadAll();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل عمليات إنشاء الكروت'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadJobs,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث السجل',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _jobs.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadJobs,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _jobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _buildJobCard(_jobs[index]),
                      ),
                    ),
    );
  }

  Widget _buildJobCard(CardGenerationJob job) {
    final color = _statusColor(job.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.profileName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(_statusLabel(job.status)),
                  backgroundColor: color.withAlpha(35),
                  labelStyle: TextStyle(color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Job: ${job.jobId}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: job.requestedCount == 0
                  ? 0
                  : (job.confirmedCount / job.requestedCount).clamp(0.0, 1.0),
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              'المؤكد: ${job.confirmedCount} · المحجوز: ${job.reservedCount} · الفاشل: ${job.failedCount} من ${job.requestedCount}',
            ),
            Text(
              'آخر تحديث: ${job.updatedAt.toLocal()} · الخدمة: ${job.serviceMode}',
              style: TextStyle(color: context.theme.appColors.textSecondary),
            ),
            if ((job.lastError ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                job.lastError!,
                style: TextStyle(color: context.theme.appColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('لا توجد عمليات توليد محفوظة حتى الآن.'),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تعذر تحميل سجل العمليات.'),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _loadJobs, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final colors = context.theme.appColors;
    return switch (status) {
      CardGenerationJobStatus.completed => colors.success,
      CardGenerationJobStatus.failed => colors.error,
      CardGenerationJobStatus.cancelled => colors.muted,
      CardGenerationJobStatus.partial => colors.warning,
      _ => colors.primary,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      CardGenerationJobStatus.preparing => 'تحضير',
      CardGenerationJobStatus.ready => 'جاهز للاستئناف',
      CardGenerationJobStatus.running => 'قيد التنفيذ',
      CardGenerationJobStatus.partial => 'فشل جزئي',
      CardGenerationJobStatus.completed => 'مكتمل',
      CardGenerationJobStatus.failed => 'فشل',
      CardGenerationJobStatus.cancelled => 'ملغى',
      _ => status,
    };
  }
}
