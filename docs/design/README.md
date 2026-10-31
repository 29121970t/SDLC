# Графические артефакты и модель

В каталоге собраны материалы к SRS сервиса «КиноВектор»:

- `kinovector.sysml` — SysML v2-модель предметной области, участников, сервисов, вариантов использования и ключевых требований;
- `diagrams/` — исходники и PNG-изображения контекстной диаграммы и диаграммы вариантов использования;
- `mockups/` — PNG-мокапы интерфейса и их HTML/CSS-исходники.

## Состав артефактов

| Артефакт | Файл |
|----------|------|
| SysML v2-модель | `kinovector.sysml` |
| Контекстная диаграмма | `diagrams/context.png` |
| Диаграмма вариантов использования | `diagrams/usecase.png` |
| Мокап «Рекомендации» | `mockups/01-recommendations.png` |
| Мокап «Каталог» | `mockups/02-catalog.png` |
| Мокап «Карточка фильма» | `mockups/03-movie-card.png` |
| Мокап «Профиль и история» | `mockups/04-profile.png` |

## Перегенерация диаграмм

Диаграммы описаны в PlantUML. Для сборки PNG нужен установленный `plantuml` (или `java -jar plantuml.jar`):

```bash
cd docs/design/diagrams
plantuml -tpng context.puml usecase.puml
```

## Перегенерация мокапов

Мокапы свёрстаны как статические HTML-страницы с общим стилем `mockups/source/mockups.css`. Ширина макета — 1440 px. Скриншоты снимаются в headless-браузере:

```bash
cd docs/design/mockups
for f in 01-recommendations 02-catalog 03-movie-card 04-profile; do
  chromium --headless --no-sandbox --disable-gpu --hide-scrollbars \
    --window-size=1440,1200 --screenshot="$f.png" "file://$PWD/source/$f.html"
done
```

Допустима замена `chromium` на `google-chrome`, `chromium-browser` или `microsoft-edge`. Для корректного отображения кириллицы в системе должен быть шрифт `DejaVu Sans` (или заменяющий его `Liberation Sans`).

## Связь с требованиями

- контекстная диаграмма и SysML-модель — разделы 2.1, 2.2, 2.4 и 3 SRS;
- диаграмма вариантов использования — REQ-FUNC-001…010;
- мокапы — REQ-INT-001, REQ-FUNC-002, REQ-FUNC-003, REQ-FUNC-007, REQ-FUNC-010.
