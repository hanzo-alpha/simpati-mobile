enum AttendanceType {
  masuk,
  istirahat,
  kembali,
  pulang,
  dinasDalam,
  dinasLuar,
  wfh;

  String get label {
    switch (this) {
      case AttendanceType.masuk:
        return 'Masuk';
      case AttendanceType.istirahat:
        return 'Istirahat';
      case AttendanceType.kembali:
        return 'Kembali';
      case AttendanceType.pulang:
        return 'Pulang';
      case AttendanceType.dinasDalam:
        return 'Dinas Dalam (DD)';
      case AttendanceType.dinasLuar:
        return 'Dinas Luar (DL)';
      case AttendanceType.wfh:
        return 'WFH';
    }
  }

  String get icon {
    switch (this) {
      case AttendanceType.masuk:
        return '🟢';
      case AttendanceType.istirahat:
        return '🟡';
      case AttendanceType.kembali:
        return '🔵';
      case AttendanceType.pulang:
        return '🟣';
      case AttendanceType.dinasDalam:
        return '🏢';
      case AttendanceType.dinasLuar:
        return '✈️';
      case AttendanceType.wfh:
        return '🏠';
    }
  }
}

enum AttendanceStatus {
  tepatWaktu,
  terlambat,
  pulangCepat,
  alpha,
  dinasDalam,
  dinasLuar,
  sakit,
  cuti;

  String get code {
    switch (this) {
      case AttendanceStatus.tepatWaktu:
        return 'Hadir';
      case AttendanceStatus.terlambat:
        return 'TL';
      case AttendanceStatus.pulangCepat:
        return 'PSW';
      case AttendanceStatus.alpha:
        return 'TK';
      case AttendanceStatus.dinasDalam:
        return 'DD';
      case AttendanceStatus.dinasLuar:
        return 'DL';
      case AttendanceStatus.sakit:
        return 'Sakit';
      case AttendanceStatus.cuti:
        return 'Cuti';
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.tepatWaktu:
        return 'Tepat Waktu';
      case AttendanceStatus.terlambat:
        return 'Terlambat (TL)';
      case AttendanceStatus.pulangCepat:
        return 'Pulang Sebelum Waktu (PSW)';
      case AttendanceStatus.alpha:
        return 'Tanpa Keterangan (TK)';
      case AttendanceStatus.dinasDalam:
        return 'Dinas Dalam (DD)';
      case AttendanceStatus.dinasLuar:
        return 'Dinas Luar (DL)';
      case AttendanceStatus.sakit:
        return 'Izin Sakit';
      case AttendanceStatus.cuti:
        return 'Cuti';
    }
  }
}

enum LeaveType {
  cuti,
  sakit,
  dinasDalam,
  dinasLuar,
  izinLain;

  String get label {
    switch (this) {
      case LeaveType.cuti:
        return 'Cuti';
      case LeaveType.sakit:
        return 'Izin Sakit';
      case LeaveType.dinasDalam:
        return 'Tugas Dinas Dalam (DD)';
      case LeaveType.dinasLuar:
        return 'Tugas Dinas Luar (DL)';
      case LeaveType.izinLain:
        return 'Izin Lainnya';
    }
  }
}

enum LeaveStatus {
  menunggu,
  disetujui,
  ditolak;

  String get label {
    switch (this) {
      case LeaveStatus.menunggu:
        return 'Menunggu';
      case LeaveStatus.disetujui:
        return 'Disetujui';
      case LeaveStatus.ditolak:
        return 'Ditolak';
    }
  }
}
