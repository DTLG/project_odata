/// Configuration for order creation
class OrderConfig {
  // Organization key - should be moved to settings
  //"Іванусик Б ФОП",
  static const String organizationKey = '37d2c458-4161-11ec-a432-40167eadd5f2';

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
