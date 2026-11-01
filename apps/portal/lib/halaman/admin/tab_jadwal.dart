import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/waktu.dart';
import '../../widget/umum.dart';

/// Jadwal pertemuan bimbel. Peserta yang diterima melihat jadwal untuk kelasnya di portal.
class TabJadwal extends ConsumerWidget {
  const TabJadwal({super.key, required this.program});

  final Program program;

  Future<void> _edit(BuildContext context, WidgetRef ref, [Jadwal? lama]) async {
    final hasil = await showDialog<Jadwal>(
      context: context,
      builder: (_) => _DialogJadwal(program: program, lama: lama),
    );
    if (hasil == null) return;
    try {
      await ref.read(repoProvider).simpanJadwal(program.id, hasil);
    } catch (e) {
      if (context.mounted) tampilkanPesan(context, 'Gagal menyimpan jadwal: $e', galat: true);
    }
  }

  Future<void> _hapus(BuildContext context, WidgetRef ref, Jadwal j) async {
    final ya = await konfirmasi(
      context,
      judul: 'Hapus jadwal?',
      isi: '"${j.judul}" (${formatTanggalJam(j.mulai)}) akan dihapus.',
      ya: 'Hapus',
      bahaya: true,
    );
    if (ya) await ref.read(repoProvider).hapusJadwal(program.id, j.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jadwal = ref.watch(jadwalProvider(program.id));
    final sekarang = ref.watch(detakProvider).value ?? DateTime.now();
    final tema = Theme.of(context);
    return jadwal.when(
      loading: () => const Memuat(),
      error: (e, _) => PesanGalat('Gagal memuat jadwal: $e'),
      data: (daftar) {
        final perTanggal = <String, List<Jadwal>>{};
        for (final j in daftar) {
          perTanggal.putIfAbsent(DateFormat('EEEE, d MMMM y', 'id_ID').format(keWib(j.mulai)), () => []).add(j);
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(onPressed: () => _edit(context, ref), icon: const Icon(Icons.add), label: const Text('Tambah jadwal')),
                Text('${daftar.length} pertemuan · terlihat oleh peserta yang diterima, sesuai kelasnya.'),
              ],
            ),
            const SizedBox(height: 16),
            if (daftar.isEmpty)
              const Kosong(
                ikon: Icons.calendar_month,
                judul: 'Belum ada jadwal',
                pesan: 'Tambahkan pertemuan per materi, misalnya "PU minggu 1", lengkap dengan jam dan tautan Zoom.',
              ),
            for (final e in perTanggal.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(e.key, style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              for (final j in e.value)
                Opacity(
                  opacity: j.selesai.isBefore(sekarang) ? 0.55 : 1,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _edit(context, ref, j),
                      leading: CircleAvatar(
                        backgroundColor: Warna.tintaMuda,
                        child: Text(
                          j.kelas.isEmpty ? 'All' : j.kelas.join(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Warna.tintaTua),
                        ),
                      ),
                      title: Text(j.judul),
                      subtitle: Text(
                        [
                          '${formatJam(j.mulai).replaceAll(' WIB', '')}-${formatJam(j.selesai)}',
                          j.kelas.isEmpty ? 'Semua kelas' : 'Kelas ${j.kelas.join(', ')}',
                          if (j.tautan.isNotEmpty) j.tautan,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _hapus(context, ref, j),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _DialogJadwal extends StatefulWidget {
  const _DialogJadwal({required this.program, this.lama});

  final Program program;
  final Jadwal? lama;

  @override
  State<_DialogJadwal> createState() => _DialogJadwalState();
}

class _DialogJadwalState extends State<_DialogJadwal> {
  late final _judul = TextEditingController(text: widget.lama?.judul ?? '');
  late final _tautan = TextEditingController(text: widget.lama?.tautan ?? '');
  late final _catatan = TextEditingController(text: widget.lama?.catatan ?? '');
  late DateTime _tanggal = () {
    final w = keWib(widget.lama?.mulai ?? DateTime.now().add(const Duration(days: 1)));
    return DateTime(w.year, w.month, w.day);
  }();
  late TimeOfDay _mulai = () {
    final w = keWib(widget.lama?.mulai ?? DateTime.now());
    return widget.lama == null ? const TimeOfDay(hour: 19, minute: 0) : TimeOfDay(hour: w.hour, minute: w.minute);
  }();
  late TimeOfDay _selesai = () {
    final w = keWib(widget.lama?.selesai ?? DateTime.now());
    return widget.lama == null ? const TimeOfDay(hour: 20, minute: 30) : TimeOfDay(hour: w.hour, minute: w.minute);
  }();
  late final Set<String> _kelas = {...?widget.lama?.kelas};

  @override
  void dispose() {
    for (final c in [_judul, _tautan, _catatan]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pilihJam(bool mulai) async {
    final t = await showTimePicker(
      context: context,
      initialTime: mulai ? _mulai : _selesai,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t != null) setState(() => mulai ? _mulai = t : _selesai = t);
  }

  String _jam(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.lama == null ? 'Tambah jadwal' : 'Ubah jadwal'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _judul,
              decoration: const InputDecoration(labelText: 'Materi atau judul pertemuan', hintText: 'Penalaran Umum - minggu 1'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(DateFormat('EEEE, d MMMM y', 'id_ID').format(_tanggal)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final t = await showDatePicker(
                  context: context,
                  initialDate: _tanggal,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2035),
                );
                if (t != null) setState(() => _tanggal = t);
              },
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pilihJam(true),
                    icon: const Icon(Icons.schedule),
                    label: Text('Mulai ${_jam(_mulai)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pilihJam(false),
                    icon: const Icon(Icons.schedule),
                    label: Text('Selesai ${_jam(_selesai)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Jam dalam WIB.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            const Text('Kelas', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Semua kelas'), selected: _kelas.isEmpty, onSelected: (_) => setState(_kelas.clear)),
                for (final k in widget.program.kelas)
                  FilterChip(
                    label: Text('Kelas $k'),
                    selected: _kelas.contains(k),
                    onSelected: (v) => setState(() => v ? _kelas.add(k) : _kelas.remove(k)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tautan,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Tautan kelas daring (opsional)', hintText: 'https://zoom.us/j/...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _catatan,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)', hintText: 'Tentor, passcode, atau persiapan'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
      FilledButton(
        onPressed: () {
          final mulai = dariWib(_tanggal, _mulai);
          final selesai = dariWib(_tanggal, _selesai);
          final tautan = _tautan.text.trim();
          if (_judul.text.trim().isEmpty) {
            tampilkanPesan(context, 'Isi materi atau judul pertemuan.', galat: true);
            return;
          }
          if (!selesai.isAfter(mulai)) {
            tampilkanPesan(context, 'Jam selesai harus setelah jam mulai.', galat: true);
            return;
          }
          if (tautan.isNotEmpty && !(Uri.tryParse(tautan)?.hasScheme ?? false)) {
            tampilkanPesan(context, 'Tautan harus diawali https://', galat: true);
            return;
          }
          Navigator.pop(
            context,
            Jadwal(
              id: widget.lama?.id ?? '',
              judul: _judul.text.trim(),
              mulai: mulai,
              selesai: selesai,
              kelas: widget.program.kelas.where(_kelas.contains).toList(),
              tautan: tautan,
              catatan: _catatan.text.trim(),
            ),
          );
        },
        child: const Text('Simpan'),
      ),
    ],
  );
}
