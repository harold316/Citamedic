enum DoctorReviewStatus {
  draft,
  pending,
  approved,
  rejected;

  String get id => name;

  String get label {
    switch (this) {
      case DoctorReviewStatus.draft:
        return 'Borrador';
      case DoctorReviewStatus.pending:
        return 'En revisión';
      case DoctorReviewStatus.approved:
        return 'Publicado';
      case DoctorReviewStatus.rejected:
        return 'Rechazado';
    }
  }

  static DoctorReviewStatus fromId(Object? value, {required bool published}) {
    switch (value) {
      case 'draft':
        return DoctorReviewStatus.draft;
      case 'pending':
        return DoctorReviewStatus.pending;
      case 'approved':
        return DoctorReviewStatus.approved;
      case 'rejected':
        return DoctorReviewStatus.rejected;
      default:
        return published
            ? DoctorReviewStatus.approved
            : DoctorReviewStatus.pending;
    }
  }
}
