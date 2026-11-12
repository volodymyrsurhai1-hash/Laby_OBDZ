# Бази даних і знань — лабораторні роботи

Матеріали розкладені окремо за номерами робіт. Звіт кожної роботи лежить у її папці: для здачі відкрийте `README.md` потрібної лабораторної.

| Робота | Стан | Звіт | Методичні вказівки |
|---|---|---|---|
| №1 — моделювання та схема БД | Звіт підготовлений | [lab-01/README.md](lab-01/README.md) | [lab-01/instructions.pdf](lab-01/instructions.pdf) |
| №2 — див. завдання в методичці | Папка і шаблон звіту підготовлені; результати ще треба додати | [lab-02/README.md](lab-02/README.md) | [lab-02/instructions.pdf](lab-02/instructions.pdf) |
| №3 — аналітичні запити та звітність | Ще не виконана; матеріали залишені окремо | [lab-03/README.md](lab-03/README.md) | [lab-03/instructions.pdf](lab-03/instructions.pdf) |

## Спільне середовище

PostgreSQL запускається з кореня репозиторію:

```powershell
docker compose up -d
docker compose ps
```

Підключення до БД та примітки щодо збереження даних: [compose.yaml](compose.yaml).
