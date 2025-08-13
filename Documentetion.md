## ADB Simple Tool – Документация

Минимальный консольный инструмент для повседневной работы с устройствами Android через ADB + (опционально) scrcpy. Теперь включает панель управления пакетами с БД состояний и undo.

### Состав
- `adb_tool_simple.bat` – основной скрипт.
- `adb.exe` (если присутствует локально; иначе используется системный adb из PATH).
- `scrcpy/` (опционально portable scrcpy; fallback на глобальный `scrcpy`).
- `adb_simple.log` – лог операций.
- `Packages_states.txt` – «БД» пакетов: `имя|status|type`.
- `packages_stack.txt` – стек undo (последовательность изменений статусов).
- Папка `screens/` – скриншоты и записи экрана.

### Главное меню (актуально)
1. Refresh / Pick device – выбрать первое доступное устройство.
2. Install ALL APK – установка всех `*.apk` в текущей папке.
3. Install ONE APK – установка одного APK.
4. Package manager – вход в панель управления пакетами.
5. Push / Pull – передача файлов/папок с логом OK/FAIL.
6. Screenshot – снимок экрана.
7. Screenrecord – запись экрана (до 180 сек).
8. Reboot menu – reboot / recovery / bootloader.
9. Grant permission – `pm grant`.
10. Revoke permission – `pm revoke`.
11. Wireless ADB – tcpip 5555 / connect / auto-detect IP / disconnect.
12. Device info – SDK + root check.
13. Cleanup temp – удаляет `/data/local/tmp/shot.png` & `rec.mp4`.
14. Screen stream – scrcpy (с попыткой `--audio`).
0. Exit – выход.

### Панель Package Manager
Вызов пункт 4.
Подменю:
1) Show packages – вывод с фильтрами:
	- Substring filter (по подстроке в имени)
	- Status filter: enabled / disabled / deleted / any
	- Type filter: system / user / other / any (тип формируется по `pm list packages -s` / `-3`)
	Показываются счётчики: total, enabled, disabled, deleted.
2) Disable package – по номеру (из текущего отображения) или точному имени.
3) Enable package – аналогично.
4) Uninstall package – меняет статус в БД на deleted (имя остаётся в списке).
5) Refresh statuses – полное пересканирование; обновляет statuses и types, добавляет новые пакеты, помечает отсутствующие как deleted.
6) Export list – формирует `packages_export_<status>.txt` по выбранному статусу.
7) Mass disable – из файла (1 имя на строку) или inline список (разделители пробел/запятая).
8) Mass enable – аналогично disable.
9) Undo last change – откат последнего действия (enable/disable статус возвращается; uninstall только помечает обратно предыдущий статус без реинсталляции APK).
0) Back – назад в главное меню.

### Формат БД пакетов
`Packages_states.txt` строки вида:
```
package.name|enabled|system
package.name2|disabled|user
package.removed|deleted|other
```
Статусы: enabled / disabled / deleted.
Типы: system / user / other.

### Undo стек
`packages_stack.txt` строки:
```
package.name|previous_status|new_status|action
```
`undo` снимает последнюю строку и пытается обратное действие (enable<->disable). Для uninstall только восстанавливает статус в БД (физическую установку надо выполнить вручную).

### Логирование
Файл: `adb_simple.log`.
Основные токены: script_entry, started, exit, selected=SERIAL, no_device, OK/FAIL install, OK/FAIL uninstall, push_OK / push_FAIL / pull_OK / pull_FAIL, screenshot, screenrecord, cleanup_tmp, scrcpy_exit, packages_refreshed, disable_OK / disable_FAIL, enable_OK / enable_FAIL, uninstall_OK / uninstall_FAIL, export_<status>, undo.
Формат строки:
```
[DD.MM.YYYY HH:MM:SS,ms] token ...
```

### Архитектура
Один .bat файл, функции через метки + `call`. Точка входа `:__start` прыжком через определения. `ADB_CMD` формируется после выбора устройства (или равен `adb`). Работа с пакетами использует временные .tmp файлы и сортировку `sort`.

### Особенности
- Временные файлы на устройстве: `/data/local/tmp/shot.png`, `/data/local/tmp/rec.mp4`.
- При отсутствии устройства большинство операций просто не выполнятся — сначала пункт 1.
- Для массовых списков можно смешивать пробелы и запятые.
- Пайпы в выводе списка экранированы (`^|`).
- Статус deleted не удаляет строку из БД, служит для аудита.

### scrcpy
Поиск: локальный `scrcpy\scrcpy.exe` затем глобальный `scrcpy`. Сначала пробует `--audio`, иначе повтор без аудио. Для кастомизации флагов редактируйте метку `:scrcpy_stream`.

### Типичные сценарии
1. Массовое отключение ненужных системных пакетов: Refresh → Show (filter system) → Export disabled → Mass disable.
2. Анализ новых пакетов после обновления прошивки: Refresh → Show (filter any) → сравнить по добавленным строкам.
3. Быстрая запись и скриншоты: пункты 6–7.
4. Undo ошибочного disable: Undo last change.

### Ограничения
- Нет автоматического восстановления (reinstall) после uninstall (только статус возвращается).
- Не поддерживаются split-APK / .apks архивы.
- Undo хранит только последовательно накопленный стек; после выхода стек не очищается (можно вручную очистить файл).

### Расширение / кастомизация
Добавление новой функции: создать метку `:my_action`, вызвать её из цепочки if в `:main_menu`, добавить лог и (при необходимости) обновить документацию.

### Устранение неполадок
- Пустое окно / мгновенный выход: проверь `goto :__start` после инициализации.
- adb не найден: положите `adb.exe` рядом или добавьте в PATH.
- Нет пакетов / пустой список: проверьте соединение (`adb devices`), затем Refresh statuses.
- scrcpy не запускается: протестируйте `scrcpy --version` в отдельном окне.

### Быстрый старт
1. Подключите устройство и подтвердите RSA.
2. Запустите `adb_tool_simple.bat`.
3. Пункт 1 (Refresh) — увидеть serial.
4. Пункт 4 (Package manager) → 5 (Refresh statuses) для построения БД.
5. Используйте нужные операции.

### Лицензия / использование
Скрипт предоставляется «как есть». Используйте на свой риск. ADB и scrcpy имеют собственные лицензии.

---
Если нужна дополнительная автоматизация (например, пакетный reinstall из каталога или метки для групп), можно расширить архитектуру — напишите запрос.
