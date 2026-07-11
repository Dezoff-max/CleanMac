<p align="center">
  <img src="docs/assets/icon-256.png" width="128" alt="CleanMac icon">
</p>

<h1 align="center">CleanMac</h1>

<p align="center">
  Безопасная локальная очистка macOS с предварительным просмотром,<br>
  Safe Mode и удалением приложений через Корзину.
</p>

<p align="center">
  <a href="https://github.com/Dezoff-max/CleanMac/actions/workflows/ci.yml"><img src="https://github.com/Dezoff-max/CleanMac/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/Dezoff-max/CleanMac/releases/latest"><img src="https://img.shields.io/github/v/release/Dezoff-max/CleanMac?display_name=tag" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift 6.0">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Dezoff-max/CleanMac" alt="MIT License"></a>
</p>

CleanMac — нативное SwiftUI-приложение для macOS, которое сначала сканирует выбранные области, объясняет найденные кандидаты и только после явного подтверждения перемещает разрешённые элементы в Корзину. Приложение работает локально: в коде нет сетевой отправки результатов сканирования, аналитики или облачного аккаунта.

> [!IMPORTANT]
> Текущий публичный релиз не подписан Developer ID и не нотарифицирован Apple. macOS Gatekeeper может заблокировать запуск загруженной сборки. Для разработки можно собрать приложение из исходников; не отключайте системную защиту ради запуска неподписанного файла.

## Интерфейс

<p align="center">
  <img src="docs/screenshots/overview.png" alt="Главный экран CleanMac" width="100%">
</p>

| Выбор областей сканирования | Групповое удаление приложений |
| --- | --- |
| <img src="docs/screenshots/scan-areas.png" alt="Области сканирования CleanMac"> | <img src="docs/screenshots/applications-multiselect.png" alt="Выбор нескольких приложений в CleanMac"> |

## Возможности

- **Безопасное сканирование.** Кэши пользователя и браузеров, логи, временные файлы, Xcode Derived Data, кэши Node/SwiftPM, Загрузки, установщики и Корзина.
- **Понятный просмотр результатов.** Категории, размер, риск, причина рекомендации, точный путь и недоступные для чтения области.
- **Safe Mode.** Включён по умолчанию и блокирует выбор элементов, требующих ручной проверки.
- **Очистка через Корзину.** Разрешённые пути повторно проверяются перед выполнением; постоянное удаление не используется.
- **Восстановление.** Элементы, перемещённые в текущем сеансе, можно вернуть, если исходный путь свободен.
- **Удаление приложений.** Поиск сторонних программ в `/Applications` и `~/Applications`, выбор нескольких приложений и необязательных точных остатков по bundle ID.
- **Меню-бар и автоматическое сканирование.** Статус диска, последний результат, расписание безопасного сканирования и локальные уведомления, пока CleanMac запущен.
- **Контроль разрешений.** Живой статус Full Disk Access и Finder Automation без автоматического запроса доступа.
- **Русский и английский интерфейс.** Переключение языка и светлой/тёмной темы внутри приложения.

## Модель безопасности

1. Сканирование выполняется только для чтения.
2. Каждый кандидат относится к известной категории и допустимому корневому пути.
3. Очистка требует явного выбора и отдельного подтверждения.
4. Перед выполнением пути проверяются повторно.
5. Файлы перемещаются в Корзину, а не удаляются навсегда.
6. При удалении приложения сначала перемещается сам `.app`; связанные остатки не затрагиваются, если этот шаг завершился ошибкой.
7. CleanMac не повышает привилегии и не устанавливает системный helper.

## Установка

Готовые архивы находятся на странице [Releases](https://github.com/Dezoff-max/CleanMac/releases/latest). Вместе с ZIP публикуется файл `.sha256` для проверки загрузки:

```bash
shasum -a 256 CleanMac-*.zip
```

Сравните полученный хеш с первым значением в приложенном файле `.sha256`, затем распакуйте архив и переместите `CleanMac.app` в `/Applications`.

Актуальные ограничения готовой сборки:

- macOS 14 или новее;
- архитектура Apple Silicon (`arm64`);
- релиз пока подписан только ad-hoc и не нотарифицирован Apple.

## Разрешения macOS

CleanMac запрашивает доступ только по действию пользователя:

- **Файлы и папки** — для выбранных пользовательских областей;
- **Полный доступ к диску** — опционально, для более глубокого чтения защищённых метаданных;
- **Автоматизация Finder** — опционально, только чтобы показать выбранный элемент в Finder.

Сканирование и очистка не требуют Finder Automation. Разрешения можно проверить на экране «Доступы» и изменить в системных настройках macOS.

## Сборка из исходников

Требуются macOS 14+ и Xcode 26+.

```bash
git clone https://github.com/Dezoff-max/CleanMac.git
cd CleanMac
./script/build_and_run.sh --verify
```

Тесты ядра:

```bash
swift test --package-path CleanMacCore
```

Локальный Release ZIP и SHA-256:

```bash
./script/package_release.sh
```

Подписание Developer ID и нотарификация описаны в [docs/signing-notarization.md](docs/signing-notarization.md).

## Структура проекта

```text
CleanMac/             SwiftUI-приложение для macOS
CleanMacCore/         Тестируемое ядро сканирования и очистки
script/               Сборка, запуск и упаковка релиза
docs/                 Документация и скриншоты
.github/workflows/    CI и публикация GitHub Releases
```

## Участие в разработке

1. Создайте отдельную ветку от `main`.
2. Сохраняйте модель безопасности: scan → review → confirm → Trash.
3. Добавляйте тесты для изменений путей, сканирования и удаления.
4. Перед Pull Request выполните `swift test --package-path CleanMacCore` и `./script/build_and_run.sh --verify`.

Сообщения об ошибках и предложения можно создавать через [GitHub Issues](https://github.com/Dezoff-max/CleanMac/issues).

## Лицензия

Проект распространяется по лицензии [MIT](LICENSE).
