import 'package:get/get.dart';

class CriteriaController extends GetxController {
  var criteria = <Map<String, String>>[].obs;

  var name = ''.obs;
  var description = ''.obs;

  void addCriterion() {
    if (name.value.isEmpty) return;

    criteria.add({
      'name': name.value,
      'description': description.value,
    });

    name.value = '';
    description.value = '';
  }

  void deleteCriterion(int index) {
    criteria.removeAt(index);
  }

  void loadForEdit(Map<String, String> c) {
    name.value = c['name'] ?? '';
    description.value = c['description'] ?? '';
  }

  void updateCriterion(int index) {
    criteria[index] = {
      'name': name.value,
      'description': description.value,
    };
    criteria.refresh();
  }
}