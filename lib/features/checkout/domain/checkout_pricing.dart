abstract final class CheckoutPricing {
  static const estimatedDeliveryTime = Duration(minutes: 45);

  static double grandTotal(double itemsTotal, double deliveryFee) =>
      itemsTotal + deliveryFee;

  static DateTime estimatedArrival(DateTime now) =>
      now.add(estimatedDeliveryTime);
}
