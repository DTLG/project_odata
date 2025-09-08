import 'label_brand.dart';

abstract class LabelRepository {
  Future<String> buildZpl(LabelBrand brand);
}
