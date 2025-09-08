/// Configuration for order creation
class OrderConfig {
  // Organization key - should be moved to settings
  static const String organizationKey = '49b22f0e-2258-11e1-b864-002354e1ef1c';

  // Default order settings
  static const bool defaultPosted = false;
  static const bool defaultDeletionMark = false;
  static const bool defaultPriceIncludesVAT = true;
  static const bool defaultAutoCalculateVAT = true;
  static const String defaultStatus = 'КОбеспечению';
  static const String defaultBusinessOperation = 'РеализацияКлиенту';
  static const String defaultDocumentBaseType = 'StandardODATA.Undefined';
  static const bool defaultAgreed = false;

  // OData path for orders
  static const String odataPath = '/odata/standard.odata/';

  // Database table names
  static const String ordersTable = 'orders';
}
