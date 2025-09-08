import '../../labels/domain/label_brand.dart';
import '../../labels/domain/label_repository.dart';
import 'zpl_templates.dart';

class LabelRepositoryImpl implements LabelRepository {
  @override
  Future<String> buildZpl(LabelBrand brand) async {
    return ZplTemplates.build(brand);
  }
}
