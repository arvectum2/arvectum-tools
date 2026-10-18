# Core

[Principles](CORE_PRINCIPLES.md) · [Core roadmap](ROADMAP.md) · [Portfolio](PORTFOLIO.md) · [Architecture](REPO_ARCHITECTURE.md) · [Brand](BRAND.md) · [Release checklist](RELEASE_CHECKLIST.md) · [Shared packages](packages/README.md).

Global policies only; app-specific delivery and growth experiments belong to their owners.

**Binding:** [Architecture contract](ARCHITECTURE_CONTRACT.md). Run `python3 core/tools/check_architecture.py` before commits.

For concurrent development see the [branch and worktree lifecycle](ARCHITECTURE_CONTRACT.md#branch-and-worktree-lifecycle-binding-decision-2026-10-11).

[Shared dependency catalog](dependencies/README.md) · [Design tokens](packages/ArvectumDesignTokens/README.md).

## Быстрая проверка

Для повторяемой базовой проверки Core на Mac mini из любого каталога:

```bash
bash core/tools/verify_baseline.sh
```

Скрипт последовательно проверяет архитектуру, версии SwiftPM, проекции зависимостей и выполняет Swift-тесты. **Это не физическая приёмка приложений и не разрешение на публикацию**.

**Нулевая точка продолжения:** [проверенная baseline от 18.10.2026](BASELINE_2026-10-18.md) · [актуальная очередь Core](ROADMAP.md) · [политика релизных ворот](RELEASE_CHECKLIST.md).
