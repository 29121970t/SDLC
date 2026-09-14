# Диаграммы

- `cake_calculator.sysml` — структурная модель SysML v2: части приложения и порты взаимодействия.
- `mvc_class.puml` — UML-диаграмма классов реализованного MVC.
- `calculation_sequence.puml` — UML-диаграмма последовательности успешного расчёта и обработки ошибки.

Для повторной генерации изображений PlantUML выполните из этого каталога:

```sh
plantuml -tsvg mvc_class.puml calculation_sequence.puml
```
