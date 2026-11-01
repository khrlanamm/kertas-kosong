import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/unduh.dart';
import '../../util/waktu.dart';
import '../../widget/umum.dart';

const _labelSnbp = {'ya': 'Eligible', 'tidak': 'Tidak eligible', 'belumTahu': 'Belum tahu'};

/// Daftar pendaftar program: verifikasi, pembagian kelas, dan ekspor CSV.
class TabPendaftar extends ConsumerStatefulWidget {
  const TabPendaftar({super.key, required this.program});

  final Program program;

  @override
  ConsumerState<TabPendaftar> createState() => _TabPendaftarState();
}

class _TabPendaftarState extends ConsumerState<TabPendaftar> {
  StatusPendaftar? _status;
  String _kelas = 'semua';
  String _cari = '';
  bool _sibuk = false;

  Program get _p => widget.program;
  bool get _bimbel => _p.jenis == JenisProgram.bimbel;

  Future<void> _atur(Pendaftar d, {required StatusPendaftar status, String? kelas, String? catatan}) async {
    try {
      await ref
          .read(repoProvider)
          .aturPendaftar(_p.id, d.uid, status: status, kelas: status == StatusPendaftar.ditolak ? null : kelas, catatanAdmin: catatan);
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal menyimpan: $e', galat: true);
    }
  }

  Future<void> _terimaSemua(List<Pendaftar> semua) async {
    final menunggu = semua.where((d) => d.status == StatusPendaftar.menunggu).toList();
    final ya = await konfirmasi(
      context,
      judul: 'Terima ${menunggu.length} pendaftar?',
      isi: 'Semua pendaftar yang menunggu akan diterima.',
      ya: 'Terima',
    );
    if (!ya) return;
    await _massal({for (final d in menunggu) d.uid: (status: StatusPendaftar.diterima, kelas: d.kelas)});
  }

  /// Pendaftar diterima yang belum punya kelas dibagi ke kelas yang paling sedikit anggotanya.
  Future<void> _bagiKelas(List<Pendaftar> semua) async {
    if (_p.kelas.isEmpty) {
      tampilkanPesan(context, 'Tambahkan kelas di tab Pengaturan terlebih dahulu.', galat: true);
      return;
    }
    final belum = semua.where((d) => d.status == StatusPendaftar.diterima && d.kelas == null).toList()
      ..sort((a, b) => (a.dibuat ?? DateTime(0)).compareTo(b.dibuat ?? DateTime(0)));
    if (belum.isEmpty) {
      tampilkanPesan(context, 'Semua pendaftar yang diterima sudah punya kelas.');
      return;
    }
    final ya = await konfirmasi(
      context,
      judul: 'Bagi ${belum.length} peserta ke kelas?',
      isi:
          'Peserta diterima yang belum punya kelas dibagi rata ke Kelas ${_p.kelas.join(', ')} sesuai urutan mendaftar. '
          'Setelah itu kelas tiap peserta tetap bisa diubah satu per satu.',
      ya: 'Bagi kelas',
    );
    if (!ya) return;
    final isi = {for (final k in _p.kelas) k: semua.where((d) => d.kelas == k).length};
    final perubahan = <String, ({StatusPendaftar status, String? kelas})>{};
    for (final d in belum) {
      final k = isi.entries.reduce((a, b) => b.value < a.value ? b : a).key;
      isi[k] = isi[k]! + 1;
      perubahan[d.uid] = (status: StatusPendaftar.diterima, kelas: k);
    }
    await _massal(perubahan);
  }

  Future<void> _massal(Map<String, ({StatusPendaftar status, String? kelas})> perubahan) async {
    setState(() => _sibuk = true);
    try {
      await ref.read(repoProvider).aturBanyakPendaftar(_p.id, perubahan);
      if (mounted) tampilkanPesan(context, '${perubahan.length} pendaftar diperbarui.');
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal: $e', galat: true);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  String _csv(List<Pendaftar> daftar) {
    String sel(Object? v) {
      final t = '${v ?? ''}';
      return t.contains(RegExp('[";\n]')) ? '"${t.replaceAll('"', '""')}"' : t;
    }

    final kepala = [
      'Nama',
      'Email',
      'No HP',
      'Sekolah',
      'Kelas',
      'Kota',
      'Alamat',
      'Minat 1',
      'Minat 2',
      'Minat 3',
      if (_bimbel) ...['Tanggal lahir', 'SNBP', 'Nomor SNBP'],
      'Status',
      if (_bimbel) 'Kelas bimbel',
      'Tanggal daftar',
      'Catatan panitia',
    ];
    final baris = [
      for (final d in daftar)
        [
          d.data.nama,
          d.email,
          d.data.noHp,
          d.data.sekolah,
          d.data.kelas,
          d.data.kota,
          d.data.alamat,
          for (var i = 0; i < 3; i++) i < d.data.minat.length ? '${d.data.minat[i]}' : '',
          if (_bimbel) ...[d.data.tanggalLahir, _labelSnbp[d.data.eligibleSnbp] ?? '', d.data.nomorSnbp],
          d.status.label,
          if (_bimbel) d.kelas ?? '',
          d.dibuat == null ? '' : formatTanggalSingkat(d.dibuat!),
          d.catatanAdmin,
        ],
    ];
    return [kepala, ...baris].map((r) => r.map(sel).join(';')).join('\n');
  }

  Future<void> _detail(Pendaftar d) async {
    final catatan = TextEditingController(text: d.catatanAdmin);
    final data = d.data;
    String tanggal(String s) => s.isEmpty ? '-' : DateFormat('d MMMM y', 'id_ID').format(DateTime.parse(s));
    final simpan = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data.nama),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (label, isi) in [
                  ('Email', d.email),
                  ('Nomor HP', data.noHp),
                  ('Sekolah', data.sekolah),
                  ('Kelas', data.kelas),
                  ('Kota', data.kota),
                  ('Alamat', data.alamat),
                  ('Minat', data.minat.isEmpty ? '-' : data.minat.map((m) => '• $m').join('\n')),
                  if (_bimbel) ...[
                    ('Tanggal lahir', tanggal(data.tanggalLahir)),
                    ('SNBP', _labelSnbp[data.eligibleSnbp] ?? '-'),
                    if (data.eligibleSnbp == 'ya') ('Nomor SNBP', data.nomorSnbp),
                  ],
                  ('Mendaftar', d.dibuat == null ? '-' : formatTanggalJam(d.dibuat!)),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Warna.tinta),
                          ),
                        ),
                        Expanded(child: SelectableText(isi.isEmpty ? '-' : isi)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: catatan,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan panitia (terlihat oleh peserta)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tutup')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan catatan')),
        ],
      ),
    );
    if (simpan == true) await _atur(d, status: d.status, kelas: d.kelas, catatan: catatan.text.trim());
    catatan.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendaftar = ref.watch(pendaftarProvider(_p.id));
    return pendaftar.when(
      loading: () => const Memuat(),
      error: (e, _) => PesanGalat('Gagal memuat pendaftar: $e'),
      data: (semua) {
        final q = _cari.toLowerCase();
        final daftar =
            semua
                .where((d) => _status == null || d.status == _status)
                .where((d) => _kelas == 'semua' || (_kelas == '-' ? d.kelas == null : d.kelas == _kelas))
                .where((d) => q.isEmpty || '${d.data.nama} ${d.email} ${d.data.sekolah} ${d.data.kota}'.toLowerCase().contains(q))
                .toList()
              ..sort((a, b) => a.data.nama.toLowerCase().compareTo(b.data.nama.toLowerCase()));
        int jumlah(StatusPendaftar s) => semua.where((d) => d.status == s).length;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Label('${semua.length} pendaftar', warna: Warna.tinta),
                Label('${jumlah(StatusPendaftar.menunggu)} menunggu', warna: Warna.ragu),
                Label('${jumlah(StatusPendaftar.diterima)} diterima', warna: Warna.benar),
                Label('${jumlah(StatusPendaftar.ditolak)} tidak diterima', warna: Warna.salah),
                if (_bimbel)
                  for (final k in _p.kelas) Label('Kelas $k: ${semua.where((d) => d.kelas == k).length}', warna: Colors.deepPurple),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (jumlah(StatusPendaftar.menunggu) > 0)
                  FilledButton.icon(
                    onPressed: _sibuk ? null : () => _terimaSemua(semua),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Terima semua yang menunggu'),
                  ),
                if (_bimbel)
                  OutlinedButton.icon(
                    onPressed: _sibuk ? null : () => _bagiKelas(semua),
                    icon: const Icon(Icons.call_split),
                    label: const Text('Bagi kelas otomatis'),
                  ),
                OutlinedButton.icon(
                  onPressed: semua.isEmpty
                      ? null
                      : () => unduhTeks(
                          'pendaftar-${_p.judul.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.csv',
                          _csv(daftar),
                          mime: 'text/csv',
                        ),
                  icon: const Icon(Icons.download),
                  label: const Text('Unduh CSV'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari nama, email, sekolah, kota',
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _cari = v.trim()),
                  ),
                ),
                DropdownButton<StatusPendaftar?>(
                  value: _status,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua status')),
                    for (final s in StatusPendaftar.values) DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() => _status = v),
                ),
                if (_bimbel)
                  DropdownButton<String>(
                    value: _kelas,
                    items: [
                      const DropdownMenuItem(value: 'semua', child: Text('Semua kelas')),
                      const DropdownMenuItem(value: '-', child: Text('Belum dibagi')),
                      for (final k in _p.kelas) DropdownMenuItem(value: k, child: Text('Kelas $k')),
                    ],
                    onChanged: (v) => setState(() => _kelas = v ?? 'semua'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (daftar.isEmpty)
              const Kosong(
                ikon: Icons.groups_outlined,
                judul: 'Tidak ada pendaftar',
                pesan: 'Pendaftar muncul di sini setelah siswa mendaftar lewat portal.',
              ),
            for (final d in daftar)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => _detail(d),
                  title: Text(d.data.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [
                      d.data.sekolah,
                      d.data.kelas,
                      d.data.kota,
                      d.data.noHp,
                      if (_bimbel && d.data.eligibleSnbp.isNotEmpty) 'SNBP: ${_labelSnbp[d.data.eligibleSnbp]}',
                    ].where((x) => x.isNotEmpty).join(' · '),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<StatusPendaftar>(
                        value: d.status,
                        underline: const SizedBox.shrink(),
                        items: [for (final s in StatusPendaftar.values) DropdownMenuItem(value: s, child: Text(s.label))],
                        onChanged: (v) => v == null ? null : _atur(d, status: v, kelas: d.kelas),
                      ),
                      if (_bimbel)
                        DropdownButton<String?>(
                          value: _p.kelas.contains(d.kelas) ? d.kelas : null,
                          hint: const Text('Kelas'),
                          underline: const SizedBox.shrink(),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Tanpa kelas')),
                            for (final k in _p.kelas) DropdownMenuItem<String?>(value: k, child: Text('Kelas $k')),
                          ],
                          onChanged: d.status == StatusPendaftar.ditolak
                              ? null
                              : (v) => _atur(d, status: v == null ? d.status : StatusPendaftar.diterima, kelas: v),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
