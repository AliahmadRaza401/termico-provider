import 'package:mobx/mobx.dart';

part 'filter_store.g.dart';

class FilterStore = FilterStoreBase with _$FilterStore;

abstract class FilterStoreBase with Store {
  @observable
  List<int> serviceId = ObservableList();

  @observable
  List<int> customerId = ObservableList();

  @observable
  List<int> providerId = ObservableList();

  @observable
  List<String> bookingStatus = ObservableList();

  @observable
  List<String> paymentStatus = ObservableList();

  @observable
  List<String> paymentType = ObservableList();

  @observable
  String startDate = '';

  @observable
  String endDate = '';

  @observable
  List<int> categoryId = ObservableList();

  @observable
  double minPrice = 0.0;

  @observable
  double maxPrice = 10000.0;

  @observable
  bool isPriceFilterApplied = false;

  @observable
  List<String> requestTypeList = ObservableList();

  @observable
  bool isAnyFilterApplied = false;

  @action
  void setStartDate(String val) {
    startDate = val;
  }

  @action
  void setEndDate(String val) {
    endDate = val;
  }

  @action
  Future<void> addToServiceList({required int serId}) async {
    serviceId.add(serId);
    updateFilterFlag();
  }

  @action
  Future<void> removeFromServiceList({required int serId}) async {
    serviceId.removeWhere((element) => element == serId);
  }

  @action
  Future<void> addToCustomerList({required int cusId}) async {
    customerId.add(cusId);
    updateFilterFlag();
  }

  @action
  Future<void> removeFromCustomerList({required int cusId}) async {
    customerId.removeWhere((element) => element == cusId);
  }

  @action
  Future<void> addToProviderList({required int prodId}) async {
    providerId.add(prodId);
    updateFilterFlag();
  }

  @action
  Future<void> removeFromProviderList({required int prodId}) async {
    providerId.removeWhere((element) => element == prodId);
  }

  @action
  Future<void> addToBookingStatusList(
      {required String bookingStatusList}) async {
    bookingStatus.add(bookingStatusList);
    updateFilterFlag();
  }

  @action
  Future<void> removeFromBookingStatusList(
      {required String bookingStatusList}) async {
    bookingStatus.removeWhere((element) => element == bookingStatusList);
  }

  @action
  Future<void> addToPaymentStatusList(
      {required String paymentStatusList}) async {
    paymentStatus.add(paymentStatusList);
    updateFilterFlag();
  }

  @action
  Future<void> removeFromPaymentStatusList(
      {required String paymentStatusList}) async {
    paymentStatus.removeWhere((element) => element == paymentStatusList);
  }

  @action
  Future<void> addToPaymentTypeList({required String paymentTypeList}) async {
    paymentType.add(paymentTypeList);
    updateFilterFlag();
  }

  @action
  Future<void> removeFromPaymentTypeList(
      {required String paymentTypeList}) async {
    paymentType.removeWhere((element) => element == paymentTypeList);
  }

  @action
  Future<void> addToCategoryList({required int catId}) async {
    categoryId.add(catId);
    updateFilterFlag();
  }

  @action
  Future<void> removeFromCategoryList({required int catId}) async {
    categoryId.removeWhere((element) => element == catId);
    updateFilterFlag();
  }

  @action
  void addToRequestTypeList(String requestType) {
    if (!requestTypeList.contains(requestType)) {
      requestTypeList.add(requestType);
      updateFilterFlag();
    }
  }

  @action
  void removeFromRequestTypeList(String requestType) {
    requestTypeList.removeWhere((element) => element == requestType);
    updateFilterFlag();
  }

  @action
  void setPriceRange({required double min, required double max}) {
    minPrice = min;
    maxPrice = max;
    isPriceFilterApplied = (min > 0.0 || max < 10000.0);
    updateFilterFlag();
  }

  @action
  void resetPriceFilter() {
    minPrice = 0.0;
    maxPrice = 10000.0;
    isPriceFilterApplied = false;
    updateFilterFlag();
  }

  @action
  Future<void> clearFilters() async {
    customerId.clear();
    serviceId.clear();
    providerId.clear();
    bookingStatus.clear();
    paymentType.clear();
    paymentStatus.clear();
    categoryId.clear();
    requestTypeList.clear();
    startDate = '';
    endDate = '';
    minPrice = 0.0;
    maxPrice = 10000.0;
    isPriceFilterApplied = false;
    updateFilterFlag();
  }

  @action
  void updateFilterFlag() {
    isAnyFilterApplied = serviceId.isNotEmpty ||
        customerId.isNotEmpty ||
        providerId.isNotEmpty ||
        bookingStatus.isNotEmpty ||
        paymentStatus.isNotEmpty ||
        paymentType.isNotEmpty ||
        categoryId.isNotEmpty ||
        requestTypeList.isNotEmpty ||
        isPriceFilterApplied ||
        startDate.isNotEmpty ||
        endDate.isNotEmpty;
  }

  int getActiveFilterCount() {
    int count = 0;

    if (startDate.isNotEmpty) count++;
    if (endDate.isNotEmpty) count++;
    if (isPriceFilterApplied) count++;
    count += serviceId.length;
    count += providerId.length;
    count += bookingStatus.length;
    count += paymentStatus.length;
    count += paymentType.length;
    count += categoryId.length;
    count += requestTypeList.length;

    return count;
  }
}
