abstract class DocumentVerificationState {
  final int uploadedCount;
  const DocumentVerificationState(this.uploadedCount);
}

class DocumentVerificationInitial extends DocumentVerificationState {
  const DocumentVerificationInitial(super.uploadedCount);
}

class DocumentVerificationUploading extends DocumentVerificationState {
  const DocumentVerificationUploading(super.uploadedCount);
}

class DocumentVerificationComplete extends DocumentVerificationState {
  const DocumentVerificationComplete(super.uploadedCount);
}

class DocumentVerificationError extends DocumentVerificationState {
  final String message;
  const DocumentVerificationError(this.message, super.uploadedCount);
}
