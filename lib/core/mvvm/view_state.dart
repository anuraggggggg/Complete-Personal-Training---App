enum ViewStatus { idle, loading, success, error }

class ViewState {
  final ViewStatus status;
  final String? message;

  const ViewState._(this.status, [this.message]);

  const ViewState.idle() : this._(ViewStatus.idle);
  const ViewState.loading() : this._(ViewStatus.loading);
  const ViewState.success() : this._(ViewStatus.success);
  const ViewState.error(String message) : this._(ViewStatus.error, message);
}
