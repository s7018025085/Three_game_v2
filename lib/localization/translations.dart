// Система локализации для Three Game
// Поддержка русского и английского языков

class AppStrings {
  static const String locale = 'ru'; // 'en' или 'ru'

  // Start Screen
  static String startTitle() => locale == 'ru' ? 'Three Game' : 'Three Game';
  static String startPlayButton() => locale == 'ru' ? 'ИГРАТЬ' : 'PLAY';
  static String startContinueButton() =>
      locale == 'ru' ? 'ПРОДОЛЖИТЬ' : 'CONTINUE';
  static String startLevelSelect() =>
      locale == 'ru' ? 'ВЫБОР УРОВНЕЙ' : 'LEVEL SELECT';
  static String startEditor() => locale == 'ru' ? 'РЕДАКТОР' : 'EDITOR';
  static String startHighScore() =>
      locale == 'ru' ? 'Рекорд: ' : 'High Score: ';

  // Game Screen
  static String gameMovesLeft() => locale == 'ru' ? 'Ходы: ' : 'Moves: ';
  static String gameScore() => locale == 'ru' ? 'Очки: ' : 'Score: ';
  static String gameTarget() => locale == 'ru' ? 'Цель: ' : 'Target: ';
  static String gameWon() => locale == 'ru' ? 'ПОБЕДА!' : 'VICTORY!';
  static String gameLost() => locale == 'ru' ? 'ПОРАЖЕНИЕ' : 'DEFEAT';
  static String gameBonus() => locale == 'ru' ? 'Бонусы' : 'Bonuses';
  static String gameMaxCombo() => locale == 'ru' ? 'Макс комбо' : 'Max Combo';
  static String gameNextLevel() => locale == 'ru' ? 'СЛЕДУЮЩИЙ' : 'NEXT LEVEL';
  static String gameMenu() => locale == 'ru' ? 'Меню' : 'Menu';
  static String gameRetry() => locale == 'ru' ? 'Повторить' : 'Retry';
  static String gameShop() => locale == 'ru' ? 'Лавка' : 'Shop';
  static String gameShopComingSoon() =>
      locale == 'ru' ? 'Лавка скоро будет!' : 'Shop coming soon!';
  static String gameNeedMore(int need) => locale == 'ru'
      ? 'Нужно ещё $need для прохода'
      : 'Need $need more to pass';

  static String gameLevelComplete() =>
      locale == 'ru' ? 'Уровень пройден!' : 'Level Complete!';
  static String gameOutOfMoves() =>
      locale == 'ru' ? 'Ходы закончились!' : 'Out of Moves!';

  // Level Select
  static String levelSelectTitle() => locale == 'ru' ? 'УРОВНИ' : 'LEVELS';
  static String levelSelectCampaign() =>
      locale == 'ru' ? 'КАМПАНИЯ' : 'CAMPAIGN';
  static String levelSelectCustom() => locale == 'ru' ? 'СВОИ' : 'CUSTOM';
  static String levelSelectRegenerate() =>
      locale == 'ru' ? 'Новая кампания' : 'Regenerate Campaign';
  static String levelSelectRegenerated() => locale == 'ru'
      ? 'Кампания обновлена!'
      : 'Campaign regenerated successfully!';
  static String levelSelectUnlockAll() =>
      locale == 'ru' ? 'Разблокировать все' : 'Unlock All';
  static String levelSelectLockAll() =>
      locale == 'ru' ? 'Заблокировать все' : 'Lock All';
  static String levelSelectCreate() => locale == 'ru' ? 'Создать' : 'Create';
  static String levelSelectEdit() => locale == 'ru' ? 'Редактировать' : 'Edit';
  static String levelSelectDelete() => locale == 'ru' ? 'Удалить' : 'Delete';
  static String levelSelectBack() => locale == 'ru' ? 'Назад' : 'Back';

  // Level Editor
  static String editorTitle() => locale == 'ru' ? 'РЕДАКТОР' : 'LEVEL EDITOR';
  static String editorName() => locale == 'ru' ? 'Имя:' : 'Name:';
  static String editorMoves() => locale == 'ru' ? 'Ходы:' : 'Moves:';
  static String editorStar1() => locale == 'ru' ? '⭐ 1:' : '⭐ 1:';
  static String editorStar2() => locale == 'ru' ? '⭐ 2:' : '⭐ 2:';
  static String editorStar3() => locale == 'ru' ? '⭐ 3:' : '⭐ 3:';
  static String editorTool() => locale == 'ru' ? 'Инструмент:' : 'Tool:';
  static String editorCell() => locale == 'ru' ? 'Ячейка' : 'Cell';
  static String editorJelly() => locale == 'ru' ? 'Желе' : 'Jelly';
  static String editorRock() => locale == 'ru' ? 'Камень' : 'Rock';
  static String editorSave() => locale == 'ru' ? 'СОХРАНИТЬ' : 'SAVE';
  static String editorCancel() => locale == 'ru' ? 'Отмена' : 'Cancel';
  static String editorBack() => locale == 'ru' ? 'Назад' : 'Back';

  // Level Goals
  static String goalCollectGem() =>
      locale == 'ru' ? 'Собрать камни' : 'Collect Gems';
  static String goalClearJelly() =>
      locale == 'ru' ? 'Очистить желе' : 'Clear Jelly';
  static String goalDestroyRock() =>
      locale == 'ru' ? 'Сломать камни' : 'Destroy Rocks';
  static String goalScore() => locale == 'ru' ? 'Набрать очки' : 'Score';

  // Loading
  static String loading() => locale == 'ru' ? 'Загрузка...' : 'Loading...';
  static String databaseEmpty() => locale == 'ru'
      ? 'БД пуста. Генерируем кампанию...'
      : 'Database empty. Generating campaign...';
  static String databaseLoaded(int count) =>
      locale == 'ru' ? 'Загружено $count уровней' : 'Loaded $count levels';
}
