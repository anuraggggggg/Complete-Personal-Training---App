import 'package:get/get.dart';
import 'view_state.dart';

abstract class BaseViewModel extends GetxController {
  final Rx<ViewState> state = const ViewState.idle().obs;

  bool get isBusy => state.value.status == ViewStatus.loading;
  bool get hasViewError => state.value.status == ViewStatus.error;
  String get viewErrorMessage => state.value.message ?? '';

  void setLoading() => state.value = const ViewState.loading();
  void setSuccess() => state.value = const ViewState.success();
  void setError(String message) => state.value = ViewState.error(message);
  void setIdle() => state.value = const ViewState.idle();
}
