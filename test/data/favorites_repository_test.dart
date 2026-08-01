import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/favorites_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toggle adiciona e remove favorito', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = FavoritesRepository();
    expect(await repo.isFavorite('luz'), isFalse);
    await repo.toggle('luz');
    expect(await repo.isFavorite('luz'), isTrue);
    expect(await repo.getFavorites(), ['luz']);
    await repo.toggle('luz');
    expect(await repo.isFavorite('luz'), isFalse);
  });

  test('persiste favoritos entre instâncias', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = FavoritesRepository();
    await repo.toggle('se');
    final repo2 = FavoritesRepository();
    expect(await repo2.isFavorite('se'), isTrue);
  });
}
