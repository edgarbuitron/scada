import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const CloudSyncApp());
}

class CloudSyncApp extends StatelessWidget {
  const CloudSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CloudSyncDashboard(),
    );
  }
}

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
const Color _bg        = Color(0xFF0D1117);
const Color _card      = Color(0xFF161B22);
const Color _border    = Color(0xFF21262D);
const Color _blue      = Color(0xFF1F6FEB);
const Color _green     = Color(0xFF3FB950);
const Color _textPri   = Color(0xFFE6EDF3);
const Color _textSec   = Color(0xFF8B949E);
const Color _orange    = Color(0xFFD29922);

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class CloudSyncDashboard extends StatelessWidget {
  const CloudSyncDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              const SizedBox(height: 20),
              _TopCards(),
              const SizedBox(height: 16),
              _BottomCards(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Cloud Sync',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textPri,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sincronización y respaldo en la nube',
                style: TextStyle(fontSize: 13, color: _textSec),
              ),
            ],
          ),
        ),
        // Status badge + icon
        Row(
          children: [
            const Text(
              'Conectado',
              style: TextStyle(fontSize: 13, color: _textPri),
            ),
            const SizedBox(width: 6),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _green.withOpacity(0.5), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: _textPri, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// TOP ROW  (3 stat cards)
// ─────────────────────────────────────────────
class _TopCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final isNarrow = w < 600;

      Widget syncCard   = _SyncCard();
      Widget storageCard = _StorageCard();
      //Widget serverCard  = _ServerCard();

      if (isNarrow) {
        return Column(children: [
          syncCard,
          const SizedBox(height: 12),
          storageCard,
          const SizedBox(height: 12),
          //serverCard,
        ]);
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: syncCard),
          const SizedBox(width: 12),
          Expanded(child: storageCard),
          const SizedBox(width: 12),
          //Expanded(child: serverCard),
        ],
      );
    });
  }
}

// ── Última sincronización ──
class _SyncCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DashCard(
      label: 'Última sincronización',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sync, color: _blue, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '20/05/2025 10:42:30 AM',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPri,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Hace 5 minutos',
                style: TextStyle(fontSize: 12, color: _textSec),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Espacio usado ──
class _StorageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DashCard(
      label: 'Espacio usado',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(painter: _DonutPainter(0.62)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '62%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _textPri,
                ),
              ),
              Text(
                '6.2 GB / 10 GB',
                style: TextStyle(fontSize: 12, color: _textSec),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  const _DonutPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 6;
    const strokeW = 10.0;

    final bgPaint = Paint()
      ..color  = _border
      ..style  = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color  = _blue
      ..style  = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}



/* 



// ── Estado del servidor ──
class _ServerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DashCard(
      label: 'Estado del servidor',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cloud_outlined, color: _blue, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Activo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPri,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Todos los servicios funcionando',
                style: TextStyle(fontSize: 11, color: _textSec),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 */







// ─────────────────────────────────────────────
// BOTTOM ROW  (DB card + Sync info card)
// ─────────────────────────────────────────────
class _BottomCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isNarrow = constraints.maxWidth < 600;

      Widget dbCard   = _DatabaseCard();
      Widget syncInfo = _SyncInfoCard();

      if (isNarrow) {
        return Column(children: [
          dbCard,
          const SizedBox(height: 12),
          syncInfo,
        ]);
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: dbCard),
          const SizedBox(width: 12),
          Expanded(child: syncInfo),
        ],
      );
    });
  }
}

// ── Base de datos ──
class _DatabaseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DashCard(
      label: 'Base de datos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DB name row
          Row(
            children: [
              const Icon(Icons.storage, color: _textSec, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'industrial_control_db',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPri,
                      ),
                    ),
                    Text(
                      'PostgreSQL 14.2',
                      style: TextStyle(fontSize: 12, color: _textSec),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: 'Conectada', color: _green),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 14),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DbStat(label: 'Tamaño',    value: '2.45 GB'),
              _DbStat(label: 'Tablas',    value: '38'),
              _DbStat(label: 'Registros', value: '125,430'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado',
                      style: TextStyle(fontSize: 11, color: _textSec)),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: _green, size: 14),
                      SizedBox(width: 4),
                      Text('Óptimo',
                          style: TextStyle(
                              fontSize: 13,
                              color: _green,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DbStat extends StatelessWidget {
  final String label;
  final String value;
  const _DbStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _textSec)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPri)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Información de sincronización ──
class _SyncInfoCard extends StatelessWidget {
  static const _rows = [
    _SyncRow(Icons.insert_drive_file_outlined, 'Archivos sincronizados', '1,245', null),
    _SyncRow(Icons.pending_outlined,           'Archivos pendientes',    '0',     null),
    _SyncRow(Icons.warning_amber_outlined,     'Conflictos detectados',  '0',     null),
    _SyncRow(Icons.upload_outlined,            'Velocidad de subida',    '12.5 MB/s', null),
    _SyncRow(Icons.download_outlined,          'Velocidad de descarga',  '18.3 MB/s', null),
  ];

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      label: 'Información de sincronización',
      child: Column(
        children: _rows
            .map((r) => _SyncInfoRow(row: r))
            .toList(),
      ),
    );
  }
}

class _SyncRow {
  final IconData icon;
  final String  label;
  final String  value;
  final Color?  valueColor;
  const _SyncRow(this.icon, this.label, this.value, this.valueColor);
}

class _SyncInfoRow extends StatelessWidget {
  final _SyncRow row;
  const _SyncInfoRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(row.icon, color: _textSec, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(row.label,
                style: const TextStyle(fontSize: 13, color: _textSec)),
          ),
          Text(
            row.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: row.valueColor ?? _textPri,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE CARD WRAPPER
// ─────────────────────────────────────────────
class _DashCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _DashCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _textSec),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}