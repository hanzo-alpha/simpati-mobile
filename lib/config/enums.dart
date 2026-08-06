enum AttendanceType {
  masuk,
  istirahat,
  kembali,
  pulang,
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
      case AttendanceType.dinasLuar:
        return 'Dinas Luar';
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
  alpha;

  String get label {
    switch (this) {
      case AttendanceStatus.tepatWaktu:
        return 'Tepat Waktu';
      case AttendanceStatus.terlambat:
        return 'Terlambat';
      case AttendanceStatus.pulangCepat:
        return 'Pulang Cepat';
      case AttendanceStatus.alpha:
        return 'Alpha';
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
        return 'Sakit';
      case LeaveType.dinasDalam:
        return 'Dinas Dalam';
      case LeaveType.dinasLuar:
        return 'Dinas Luar';
      case LeaveType.izinLain:
        return 'Izin Lain';
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
