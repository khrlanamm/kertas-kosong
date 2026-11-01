import 'package:cloud_firestore/cloud_firestore.dart';

typedef Json = Map<String, dynamic>;

DateTime? _waktu(Object? v) => v is Timestamp ? v.toDate() : null;
List<T> _daftar<T>(Object? v, T Function(Object? e) ubah) => v is List ? v.map(ubah).toList() : <T>[];

enum Peran { siswa, admin }

class Pengguna {
  const Pengguna({
    required this.uid,
    required this.nama,
    required this.email,
    required this.peran,
    this.sekolah = '',
    this.kelas = '',
    this.kota = '',
    this.noHp = '',
  });

  final String uid;
  final String nama;
  final String email;
  final Peran peran;
  final String sekolah;
  final String kelas;
  final String kota;
  final String noHp;

  bool get admin => peran == Peran.admin;

  factory Pengguna.dariDok(DocumentSnapshot<Json> d) {
    final m = d.data() ?? const {};
    return Pengguna(
      uid: d.id,
      nama: m['nama'] as String? ?? '',
      email: m['email'] as String? ?? '',
      peran: m['peran'] == 'admin' ? Peran.admin : Peran.siswa,
      sekolah: m['sekolah'] as String? ?? '',
      kelas: m['kelas'] as String? ?? '',
      kota: m['kota'] as String? ?? '',
      noHp: m['noHp'] as String? ?? '',
    );
  }
}

class Subtes {
  const Subtes({required this.id, required this.nama, this.singkatan = '', required this.durasiDetik, this.targetSoal = 0});

  final String id;
  final String nama;
  final String singkatan;
  final int durasiDetik;

  /// Jumlah soal yang direncanakan (mis. 30 untuk PU), sebagai panduan admin.
  final int targetSoal;

  String get label => singkatan.isEmpty ? nama : '$nama ($singkatan)';

  factory Subtes.dariMap(Object? v) {
    final m = v is Map ? v : const {};
    return Subtes(
      id: m['id'] as String? ?? '',
      nama: m['nama'] as String? ?? '',
      singkatan: m['singkatan'] as String? ?? '',
      durasiDetik: (m['durasiDetik'] as num?)?.round() ?? 0,
      targetSoal: (m['targetSoal'] as num?)?.round() ?? 0,
    );
  }

  Json keMap() => {'id': id, 'nama': nama, 'singkatan': singkatan, 'durasiDetik': durasiDetik, 'targetSoal': targetSoal};

  Subtes salin({String? nama, String? singkatan, int? durasiDetik, int? targetSoal}) => Subtes(
    id: id,
    nama: nama ?? this.nama,
    singkatan: singkatan ?? this.singkatan,
    durasiDetik: durasiDetik ?? this.durasiDetik,
    targetSoal: targetSoal ?? this.targetSoal,
  );
}

class PengaturanUjian {
  const PengaturanUjian({
    this.acakSoal = false,
    this.acakOpsi = false,
    this.urutanBebas = false,
    this.hasilSegera = false,
    this.tampilkanPembahasan = true,
  });

  /// Acak urutan soal per peserta. Soal satu bacaan tetap berdampingan.
  final bool acakSoal;

  /// Acak urutan pilihan jawaban (pilihan ganda dan pilihan ganda kompleks).
  final bool acakOpsi;

  /// Peserta boleh memilih urutan subtes sendiri. UTBK memakai urutan tetap.
  final bool urutanBebas;

  /// Jumlah benar langsung ditampilkan setelah subtes dikumpulkan.
  final bool hasilSegera;

  /// Pembahasan dibuka untuk peserta setelah ujian ditutup.
  final bool tampilkanPembahasan;

  factory PengaturanUjian.dariMap(Object? v) {
    final m = v is Map ? v : const {};
    return PengaturanUjian(
      acakSoal: m['acakSoal'] == true,
      acakOpsi: m['acakOpsi'] == true,
      urutanBebas: m['urutanBebas'] == true,
      hasilSegera: m['tampilkanHasil'] == 'segera',
      tampilkanPembahasan: m['tampilkanPembahasan'] != false,
    );
  }

  Json keMap() => {
    'acakSoal': acakSoal,
    'acakOpsi': acakOpsi,
    'urutanBebas': urutanBebas,
    'tampilkanHasil': hasilSegera ? 'segera' : 'setelahTutup',
    'tampilkanPembahasan': tampilkanPembahasan,
  };

  PengaturanUjian salin({bool? acakSoal, bool? acakOpsi, bool? urutanBebas, bool? hasilSegera, bool? tampilkanPembahasan}) =>
      PengaturanUjian(
        acakSoal: acakSoal ?? this.acakSoal,
        acakOpsi: acakOpsi ?? this.acakOpsi,
        urutanBebas: urutanBebas ?? this.urutanBebas,
        hasilSegera: hasilSegera ?? this.hasilSegera,
        tampilkanPembahasan: tampilkanPembahasan ?? this.tampilkanPembahasan,
      );
}

class Ujian {
  const Ujian({
    required this.id,
    required this.judul,
    this.deskripsi = '',
    required this.terbit,
    required this.buka,
    required this.tutup,
    this.subtes = const [],
    this.pengaturan = const PengaturanUjian(),
    this.jumlahSoal = const {},
    this.skorDihitung,
  });

  final String id;
  final String judul;
  final String deskripsi;
  final bool terbit;
  final DateTime buka;
  final DateTime tutup;
  final List<Subtes> subtes;
  final PengaturanUjian pengaturan;
  final Map<String, int> jumlahSoal;
  final DateTime? skorDihitung;

  int get totalSoal => subtes.fold(0, (s, t) => s + (jumlahSoal[t.id] ?? 0));
  int get totalDetik => subtes.fold(0, (s, t) => s + t.durasiDetik);

  bool belumDibuka(DateTime sekarang) => sekarang.isBefore(buka);
  bool sedangBuka(DateTime sekarang) => !sekarang.isBefore(buka) && sekarang.isBefore(tutup);
  bool sudahTutup(DateTime sekarang) => !sekarang.isBefore(tutup);

  factory Ujian.dariDok(DocumentSnapshot<Json> d) {
    final m = d.data() ?? const {};
    final jumlah = m['jumlahSoal'];
    return Ujian(
      id: d.id,
      judul: m['judul'] as String? ?? '',
      deskripsi: m['deskripsi'] as String? ?? '',
      terbit: m['status'] == 'terbit',
      buka: _waktu(m['buka']) ?? DateTime.now(),
      tutup: _waktu(m['tutup']) ?? DateTime.now(),
      subtes: _daftar(m['subtes'], Subtes.dariMap),
      pengaturan: PengaturanUjian.dariMap(m['pengaturan']),
      jumlahSoal: jumlah is Map ? jumlah.map((k, v) => MapEntry(k as String, (v as num).round())) : const {},
      skorDihitung: _waktu(m['skorDihitung']),
    );
  }
}

enum TipeSoal {
  pg('Pilihan ganda', 'Pilih satu jawaban yang paling tepat.'),
  pgk('Pilihan ganda kompleks', 'Pilih semua jawaban yang benar. Jawaban benar bisa lebih dari satu.'),
  bs('Tabel benar/salah', 'Tentukan pilihan yang sesuai untuk setiap pernyataan.'),
  isian('Isian singkat', 'Ketik jawaban singkat berupa angka, kata, atau frasa.');

  const TipeSoal(this.label, this.petunjuk);

  final String label;
  final String petunjuk;

  static TipeSoal dari(Object? v) => TipeSoal.values.firstWhere((t) => t.name == v, orElse: () => TipeSoal.pg);
}

class Opsi {
  const Opsi(this.id, this.teks);

  final String id;
  final String teks;

  factory Opsi.dariMap(Object? v) {
    final m = v is Map ? v : const {};
    return Opsi(m['id'] as String? ?? '', m['teks'] as String? ?? '');
  }

  Json keMap() => {'id': id, 'teks': teks};
}

/// Pasangan label kolom untuk soal tabel, mengikuti variasi soal UTBK.
const pilihanLabelBs = [
  ['Benar', 'Salah'],
  ['Ya', 'Tidak'],
  ['Sesuai', 'Tidak Sesuai'],
  ['Mendukung', 'Tidak Mendukung'],
  ['Fakta', 'Opini'],
];

class KunciIsian {
  const KunciIsian({this.jawaban = const [], this.numerik = true, this.toleransi = 0});

  final List<String> jawaban;
  final bool numerik;
  final double toleransi;

  factory KunciIsian.dariMap(Object? v) {
    final m = v is Map ? v : const {};
    return KunciIsian(
      jawaban: _daftar(m['jawaban'], (e) => '$e'),
      numerik: m['numerik'] != false,
      toleransi: (m['toleransi'] as num?)?.toDouble() ?? 0,
    );
  }

  Json keMap() => {'jawaban': jawaban, 'numerik': numerik, 'toleransi': toleransi};
}

class Soal {
  const Soal({
    required this.id,
    required this.subtesId,
    required this.urutan,
    required this.tipe,
    this.stimulusId,
    this.teks = '',
    this.opsi = const [],
    this.pernyataan = const [],
    this.labelBs = const ['Benar', 'Salah'],
    this.kunciPg,
    this.kunciPgk = const [],
    this.kunciBs = const {},
    this.kunciIsian = const KunciIsian(),
    this.pembahasan = '',
  });

  final String id;
  final String subtesId;
  final int urutan;
  final TipeSoal tipe;
  final String? stimulusId;
  final String teks;
  final List<Opsi> opsi;
  final List<Opsi> pernyataan;
  final List<String> labelBs;
  final String? kunciPg;
  final List<String> kunciPgk;
  final Map<String, bool> kunciBs;
  final KunciIsian kunciIsian;
  final String pembahasan;

  factory Soal.dariDok(DocumentSnapshot<Json> d) {
    final m = d.data() ?? const {};
    final tipe = TipeSoal.dari(m['tipe']);
    final kunci = m['kunci'];
    return Soal(
      id: d.id,
      subtesId: m['subtesId'] as String? ?? '',
      urutan: (m['urutan'] as num?)?.round() ?? 0,
      tipe: tipe,
      stimulusId: m['stimulusId'] as String?,
      teks: m['teks'] as String? ?? '',
      opsi: _daftar(m['opsi'], Opsi.dariMap),
      pernyataan: _daftar(m['pernyataan'], Opsi.dariMap),
      labelBs: _daftar(m['labelBs'], (e) => '$e').length == 2 ? _daftar(m['labelBs'], (e) => '$e') : const ['Benar', 'Salah'],
      kunciPg: tipe == TipeSoal.pg && kunci is String ? kunci : null,
      kunciPgk: tipe == TipeSoal.pgk ? _daftar(kunci, (e) => '$e') : const [],
      kunciBs: tipe == TipeSoal.bs && kunci is Map ? kunci.map((k, v) => MapEntry('$k', v == true)) : const {},
      kunciIsian: tipe == TipeSoal.isian ? KunciIsian.dariMap(kunci) : const KunciIsian(),
      pembahasan: m['pembahasan'] as String? ?? '',
    );
  }

  Object? get kunci => switch (tipe) {
    TipeSoal.pg => kunciPg,
    TipeSoal.pgk => kunciPgk,
    TipeSoal.bs => kunciBs,
    TipeSoal.isian => kunciIsian.keMap(),
  };

  Json keMap() => {
    'subtesId': subtesId,
    'urutan': urutan,
    'tipe': tipe.name,
    'stimulusId': stimulusId,
    'teks': teks,
    'opsi': tipe == TipeSoal.pg || tipe == TipeSoal.pgk ? opsi.map((o) => o.keMap()).toList() : <Json>[],
    'pernyataan': tipe == TipeSoal.bs ? pernyataan.map((o) => o.keMap()).toList() : <Json>[],
    'labelBs': labelBs,
    'kunci': kunci,
    'pembahasan': pembahasan,
  };

  /// Pesan kesalahan jika soal belum lengkap, atau null jika siap disimpan.
  String? periksa() {
    if (teks.trim().isEmpty) return 'Teks soal masih kosong.';
    switch (tipe) {
      case TipeSoal.pg:
        if (opsi.length < 2) return 'Tambahkan minimal dua pilihan jawaban.';
        if (opsi.any((o) => o.teks.trim().isEmpty)) return 'Ada pilihan jawaban yang masih kosong.';
        if (kunciPg == null || !opsi.any((o) => o.id == kunciPg)) return 'Pilih kunci jawaban.';
      case TipeSoal.pgk:
        if (opsi.length < 2) return 'Tambahkan minimal dua pilihan jawaban.';
        if (opsi.any((o) => o.teks.trim().isEmpty)) return 'Ada pilihan jawaban yang masih kosong.';
        if (kunciPgk.isEmpty) return 'Tandai minimal satu jawaban yang benar.';
      case TipeSoal.bs:
        if (pernyataan.isEmpty) return 'Tambahkan minimal satu pernyataan.';
        if (pernyataan.any((p) => p.teks.trim().isEmpty)) return 'Ada pernyataan yang masih kosong.';
        if (pernyataan.any((p) => !kunciBs.containsKey(p.id))) return 'Tentukan kunci untuk setiap pernyataan.';
      case TipeSoal.isian:
        if (kunciIsian.jawaban.where((j) => j.trim().isNotEmpty).isEmpty) return 'Isi minimal satu jawaban yang diterima.';
    }
    return null;
  }
}

class Stimulus {
  const Stimulus({required this.id, required this.subtesId, this.judul = '', this.teks = ''});

  final String id;
  final String subtesId;
  final String judul;
  final String teks;

  factory Stimulus.dariDok(DocumentSnapshot<Json> d) {
    final m = d.data() ?? const {};
    return Stimulus(
      id: d.id,
      subtesId: m['subtesId'] as String? ?? '',
      judul: m['judul'] as String? ?? '',
      teks: m['teks'] as String? ?? '',
    );
  }

  Json keMap() => {'subtesId': subtesId, 'judul': judul, 'teks': teks};
}

class HasilSubtes {
  const HasilSubtes({required this.benar, required this.jumlah, this.skor});

  final int benar;
  final int jumlah;
  final double? skor;

  factory HasilSubtes.dariMap(Object? v) {
    final m = v is Map ? v : const {};
    return HasilSubtes(
      benar: (m['benar'] as num?)?.round() ?? 0,
      jumlah: (m['jumlah'] as num?)?.round() ?? 0,
      skor: (m['skor'] as num?)?.toDouble(),
    );
  }
}

class Sesi {
  const Sesi({
    required this.id,
    required this.uid,
    required this.ujianId,
    this.nama = '',
    this.sekolah = '',
    this.selesai = false,
    this.subtesAktif,
    this.subtesSelesai = const [],
    this.hasil = const {},
    this.totalBenar = 0,
    this.skorRata,
    this.uji = false,
  });

  final String id;
  final String uid;
  final String ujianId;
  final String nama;
  final String sekolah;
  final bool selesai;
  final String? subtesAktif;
  final List<String> subtesSelesai;
  final Map<String, HasilSubtes> hasil;
  final int totalBenar;
  final double? skorRata;

  /// Percobaan oleh admin; tidak ikut dinilai.
  final bool uji;

  factory Sesi.dariDok(DocumentSnapshot<Json> d) {
    final m = d.data() ?? const {};
    final hasil = m['hasil'];
    return Sesi(
      id: d.id,
      uid: m['uid'] as String? ?? '',
      ujianId: m['ujianId'] as String? ?? '',
      nama: m['nama'] as String? ?? '',
      sekolah: m['sekolah'] as String? ?? '',
      selesai: m['status'] == 'selesai',
      subtesAktif: m['subtesAktif'] as String?,
      subtesSelesai: _daftar(m['subtesSelesai'], (e) => '$e'),
      hasil: hasil is Map ? hasil.map((k, v) => MapEntry('$k', HasilSubtes.dariMap(v))) : const {},
      totalBenar: (m['totalBenar'] as num?)?.round() ?? 0,
      skorRata: (m['skorRata'] as num?)?.toDouble(),
      uji: m['uji'] == true,
    );
  }
}

/// Soal seperti yang diterima peserta dari Cloud Function (tanpa kunci).
class SoalPeserta {
  const SoalPeserta({
    required this.id,
    required this.tipe,
    required this.teks,
    this.stimulusId,
    this.opsi = const [],
    this.pernyataan = const [],
    this.labelBs = const ['Benar', 'Salah'],
    this.isianAngka = false,
  });

  final String id;
  final TipeSoal tipe;
  final String teks;
  final String? stimulusId;
  final List<Opsi> opsi;
  final List<Opsi> pernyataan;
  final List<String> labelBs;
  final bool isianAngka;

  factory SoalPeserta.dariMap(Object? v) {
    final m = v is Map ? v : const {};
    final label = _daftar(m['labelBs'], (e) => '$e');
    return SoalPeserta(
      id: m['id'] as String? ?? '',
      tipe: TipeSoal.dari(m['tipe']),
      teks: m['teks'] as String? ?? '',
      stimulusId: m['stimulusId'] as String?,
      opsi: _daftar(m['opsi'], Opsi.dariMap),
      pernyataan: _daftar(m['pernyataan'], Opsi.dariMap),
      labelBs: label.length == 2 ? label : const ['Benar', 'Salah'],
      isianAngka: m['isianAngka'] == true,
    );
  }
}

class StimulusPeserta {
  const StimulusPeserta(this.judul, this.teks);

  final String judul;
  final String teks;
}

/// Data pengerjaan satu subtes dari Cloud Function mulaiSubtes.
class DataPengerjaan {
  const DataPengerjaan({
    required this.status,
    required this.sekarang,
    required this.batas,
    required this.namaSubtes,
    required this.soal,
    required this.stimulus,
    required this.jawaban,
    required this.ragu,
  });

  /// "baru", "lanjut", atau "waktuHabis".
  final String status;
  final DateTime sekarang;
  final DateTime batas;
  final String namaSubtes;
  final List<SoalPeserta> soal;
  final Map<String, StimulusPeserta> stimulus;
  final Map<String, Object?> jawaban;
  final Map<String, bool> ragu;

  factory DataPengerjaan.dariMap(Map<Object?, Object?> m) {
    DateTime waktu(Object? v) => DateTime.fromMillisecondsSinceEpoch((v as num?)?.round() ?? 0);
    final stimulus = m['stimulus'];
    final jawaban = m['jawaban'];
    final ragu = m['ragu'];
    final subtes = m['subtes'];
    return DataPengerjaan(
      status: m['status'] as String? ?? 'baru',
      sekarang: waktu(m['sekarang']),
      batas: waktu(m['batas']),
      namaSubtes: subtes is Map ? subtes['nama'] as String? ?? '' : '',
      soal: _daftar(m['soal'], SoalPeserta.dariMap),
      stimulus: stimulus is Map
          ? stimulus.map((k, v) => MapEntry('$k', StimulusPeserta((v as Map)['judul'] as String? ?? '', v['teks'] as String? ?? '')))
          : const {},
      jawaban: jawaban is Map ? jawaban.map((k, v) => MapEntry('$k', v)) : {},
      ragu: ragu is Map ? ragu.map((k, v) => MapEntry('$k', v == true)) : {},
    );
  }
}

/// Satu soal di halaman pembahasan.
class SoalPembahasan {
  const SoalPembahasan({
    required this.soal,
    required this.subtesId,
    required this.kunci,
    required this.jawaban,
    required this.benar,
    required this.pembahasan,
  });

  final SoalPeserta soal;
  final String subtesId;
  final Object? kunci;
  final Object? jawaban;
  final bool benar;
  final String pembahasan;

  factory SoalPembahasan.dariMap(Object? v) {
    final m = v is Map ? v : const {};
    return SoalPembahasan(
      soal: SoalPeserta.dariMap(m),
      subtesId: m['subtesId'] as String? ?? '',
      kunci: m['kunci'],
      jawaban: m['jawaban'],
      benar: m['benar'] == true,
      pembahasan: m['pembahasan'] as String? ?? '',
    );
  }
}

/// Apakah jawaban peserta sudah terisi (untuk navigasi soal).
bool jawabanTerisi(TipeSoal tipe, Object? jawaban, {int jumlahPernyataan = 0}) => switch (tipe) {
  TipeSoal.pg => jawaban is String && jawaban.isNotEmpty,
  TipeSoal.pgk => jawaban is List && jawaban.isNotEmpty,
  TipeSoal.bs => jawaban is Map && jawaban.length >= jumlahPernyataan && jumlahPernyataan > 0,
  TipeSoal.isian => jawaban is String && jawaban.trim().isNotEmpty,
};
