package KinoVector {

    private import ScalarValues::*;
    private import Views::*;
    private import DiagramLayout::*;

    /* ============================================================
     * 1. Общие типы предметной области
     * ============================================================ */

    attribute def Email;
    attribute def Url;
    attribute def RatingValue;
    attribute def DurationMinutes;
    attribute def Timestamp;

    enum def UserRole {
        viewer;
        moderator;
        catalogAdmin;
        analyst;
    }

    enum def ReviewStatus {
        published;
        hidden;
        pendingModeration;
    }

    enum def RecommendationFeedback {
        like;
        dislike;
        notInterested;
    }

    /* ============================================================
     * 2. Участники (акторы)
     * ============================================================ */

    part def Guest {
        attribute sessionId : String;
    }

    part def Viewer {
        attribute userId : String;
        attribute email : Email;
        attribute displayName : String;
        attribute role : UserRole = UserRole::viewer;
    }

    part def Moderator {
        attribute userId : String;
        attribute role : UserRole = UserRole::moderator;
    }

    part def CatalogAdmin {
        attribute userId : String;
        attribute role : UserRole = UserRole::catalogAdmin;
    }

    part def Analyst {
        attribute userId : String;
        attribute role : UserRole = UserRole::analyst;
    }

    part 'Гость' : Guest;
    part 'Зритель' : Viewer;
    part 'Модератор' : Moderator;
    part 'Администратор каталога' : CatalogAdmin;
    part 'Аналитик' : Analyst;

    /* ============================================================
     * 3. Внешние системы
     * ============================================================ */

    part def TmdbService {
        attribute baseUrl : Url;
        attribute timeoutSeconds : Real = 3.0;
    }

    part def EmailService {
        attribute senderAddress : Email;
    }

    part def ObjectStorage {
        attribute bucketName : String;
    }

    part def PostgresDatabase {
        attribute schemaVersion : String;
    }

    part def RedisCache {
        attribute ttlSeconds : Integer = 900;
    }

    part 'TMDB API' : TmdbService;
    part 'SMTP-сервис' : EmailService;
    part 'Объектное хранилище' : ObjectStorage;
    part 'PostgreSQL' : PostgresDatabase;
    part 'Redis' : RedisCache;

    /* ============================================================
     * 4. Интерфейсы системы
     * ============================================================ */

    port def UserPort {
        in request : String;
        out response : String;
    }

    port def TmdbPort {
        in query : String;
        out movieMetadata : String;
    }

    port def MailPort {
        in mailMessage : String;
    }

    port def StoragePort {
        in object : String;
        out url : Url;
    }

    port def DbPort {
        in query : String;
        out rows : String;
    }

    port def CachePort {
        in key : String;
        out value : String;
    }

    /* ============================================================
     * 5. Внутренние сервисы и система «КиноВектор»
     * ============================================================ */

    part def WebUi;
    part def RestApi;
    part def CatalogService {
        port storage : StoragePort;
        port db : DbPort;
    }
    part def RatingService;
    part def ReviewService;
    part def HistoryService;
    part def RecommendationService {
        port db : DbPort;
        port cache : CachePort;
    }
    part def AdminService {
        port tmdb : TmdbPort;
    }
    part def AuthService {
        port mail : MailPort;
    }

    part def KinoVectorSystem {
        part web : WebUi;
        part api : RestApi;
        part catalog : CatalogService;
        part ratings : RatingService;
        part reviews : ReviewService;
        part history : HistoryService;
        part recommender : RecommendationService;
        part admin : AdminService;
        part auth : AuthService;

        port users : UserPort;
        port tmdb : TmdbPort;
        port mail : MailPort;
        port storage : StoragePort;
        port db : DbPort;
        port cache : CachePort;

        connect web to api;
        connect api to catalog;
        connect api to ratings;
        connect api to reviews;
        connect api to history;
        connect api to recommender;
        connect api to admin;
        connect api to auth;
        connect admin.tmdb to tmdb;
        connect auth.mail to mail;
        connect catalog.storage to storage;
        connect catalog.db to db;
        connect recommender.db to db;
        connect recommender.cache to cache;
    }

    part 'КиноВектор' : KinoVectorSystem;

    connection 'Гость → КиноВектор' connect 'Гость' to 'КиноВектор'.users;
    connection 'Зритель → КиноВектор' connect 'Зритель' to 'КиноВектор'.users;
    connection 'Модератор → КиноВектор' connect 'Модератор' to 'КиноВектор'.users;
    connection 'Администратор → КиноВектор' connect 'Администратор каталога' to 'КиноВектор'.users;
    connection 'Аналитик → КиноВектор' connect 'Аналитик' to 'КиноВектор'.users;
    connection 'КиноВектор → TMDB' connect 'КиноВектор'.tmdb to 'TMDB API';
    connection 'КиноВектор → SMTP' connect 'КиноВектор'.mail to 'SMTP-сервис';
    connection 'КиноВектор → хранилище' connect 'КиноВектор'.storage to 'Объектное хранилище';
    connection 'КиноВектор → PostgreSQL' connect 'КиноВектор'.db to 'PostgreSQL';
    connection 'КиноВектор → Redis' connect 'КиноВектор'.cache to 'Redis';

    /* ============================================================
     * 6. Варианты использования
     * ============================================================ */

    use case 'Просматривать каталог';
    use case 'Искать и фильтровать фильмы';
    use case 'Открывать карточку фильма';
    use case 'Ставить оценку';
    use case 'Писать рецензию';
    use case 'Вести историю просмотров';
    use case 'Получать персональные рекомендации';
    use case 'Указывать предпочтения';
    use case 'Отправлять жалобу на рецензию';
    use case 'Модерировать рецензии';
    use case 'Управлять каталогом и импортировать TMDB';
    use case 'Выгружать и удалять персональные данные';
    use case 'Смотреть аналитику';

    connection 'Гость → каталог' connect 'Гость' to 'Просматривать каталог';
    connection 'Гость → поиск' connect 'Гость' to 'Искать и фильтровать фильмы';
    connection 'Гость → карточка' connect 'Гость' to 'Открывать карточку фильма';
    connection 'Зритель → каталог' connect 'Зритель' to 'Просматривать каталог';
    connection 'Зритель → поиск' connect 'Зритель' to 'Искать и фильтровать фильмы';
    connection 'Зритель → карточка' connect 'Зритель' to 'Открывать карточку фильма';
    connection 'Зритель → оценка' connect 'Зритель' to 'Ставить оценку';
    connection 'Зритель → рецензия' connect 'Зритель' to 'Писать рецензию';
    connection 'Зритель → история' connect 'Зритель' to 'Вести историю просмотров';
    connection 'Зритель → рекомендации' connect 'Зритель' to 'Получать персональные рекомендации';
    connection 'Зритель → предпочтения' connect 'Зритель' to 'Указывать предпочтения';
    connection 'Зритель → жалоба' connect 'Зритель' to 'Отправлять жалобу на рецензию';
    connection 'Зритель → данные' connect 'Зритель' to 'Выгружать и удалять персональные данные';
    connection 'Модератор → модерация' connect 'Модератор' to 'Модерировать рецензии';
    connection 'Администратор → каталог' connect 'Администратор каталога' to 'Управлять каталогом и импортировать TMDB';
    connection 'Аналитик → аналитика' connect 'Аналитик' to 'Смотреть аналитику';

    connection 'include: история' connect 'Получать персональные рекомендации' to 'Вести историю просмотров';
    connection 'include: оценки' connect 'Получать персональные рекомендации' to 'Ставить оценку';
    connection 'include: предпочтения' connect 'Получать персональные рекомендации' to 'Указывать предпочтения';
    connection 'extend: модерация' connect 'Модерировать рецензии' to 'Отправлять жалобу на рецензию';

    /* ============================================================
     * 7. Ключевые требования (полный перечень — в docs/srs.md)
     * ============================================================ */

    requirement def PersonalizedRecommendations {
        id = "REQ-FUNC-007";
        doc /* Система должна формировать персональную ленту не менее чем из 10 фильмов
               и сопровождать каждую рекомендацию кратким объяснением. */
        attribute minItems : Integer = 10;
        attribute maxLatencyMs : Integer = 800;
    }

    requirement def RecommendationQuality {
        id = "REQ-ML-001";
        doc /* Система должна использовать гибридный рекомендательный алгоритм
               с NDCG@10 >= 0.35, coverage >= 0.60 и diversity >= 0.40. */
        attribute minNdcgAt10 : Real = 0.35;
        attribute minCoverage : Real = 0.60;
        attribute minDiversity : Real = 0.40;
    }

    requirement def AccessibleWebInterface {
        id = "REQ-INT-001";
        doc /* Интерфейс должен быть адаптивным для экранов 360–1920 px
               и соответствовать WCAG 2.1 AA. */
        attribute minWidthPx : Integer = 360;
        attribute maxWidthPx : Integer = 1920;
    }

    requirement def SecureAccounts {
        id = "REQ-SEC-001";
        doc /* Система должна использовать TLS 1.3, Argon2id для паролей,
               RBAC и защиту от CSRF, XSS, SQL-инъекций и подбора паролей. */
    }

    requirement def PersonalDataControl {
        id = "REQ-FUNC-010";
        doc /* Пользователь должен иметь возможность выгрузить и удалить
               свои персональные данные. */
        attribute deletionDeadlineDays : Integer = 30;
    }
    /* ============================================================
     * 8. Модель пользовательского интерфейса
     *    Экраны описаны как структуры частей; DiagramLayout
     *    задаёт положение элементов на canvas 1440 × 1200 px.
     * ============================================================ */

    part 'RecommendationsPage' {
        part 'КиноВектор' {
            part 'Каталог';
            part 'Рекомендации';
            part 'История';
            part 'Профиль';
            part 'Поиск фильма';
            part 'АП';
        }
        part 'Рекомендации для вас';
        part 'Подобрано по вашим оценкам\nи истории просмотров';
        part 'Главная рекомендация' {
            part 'Постер\n2:3';
            part 'Дюна: Часть вторая';
            part '2024 · фантастика · 166 мин';
            part '8.5 / 10';
            part '16+';
            part 'Пол Атрейдес объединяется с фременами,\nчтобы отомстить за семью.';
            part 'Буду смотреть';
            part 'Не интересно';
        }
        part 'Почему это вам' {
            part 'Вы высоко оценили\n«Дюну» (2021)';
            part 'Любите фантастику\nи эпическое кино';
            part 'Похожие фильмы:\n«Прибытие», «Интерстеллар»';
            part 'Объяснение полезно?';
            part 'Да';
            part 'Нет';
        }
        part 'Ещё для вас' {
            part 'Прибытие' {
                part 'Постер';
                part '2016 · фантастика';
                part '8.0';
            }
            part 'Интерстеллар' {
                part 'Постер';
                part '2014 · фантастика';
                part '8.7';
            }
            part 'Бегущий по лезвию 2049' {
                part 'Постер';
                part '2017 · фантастика';
                part '8.0';
            }
        }
        part 'Показать ещё';
    }

    part 'CatalogPage' {
        part 'КиноВектор' {
            part 'Каталог';
            part 'Рекомендации';
            part 'История';
            part 'Профиль';
            part 'Поиск фильма';
            part 'АП';
        }
        part 'Каталог фильмов';
        part '1 248 фильмов · обновлено сегодня';
        part 'Фильтры' {
            part 'Жанр: все';
            part 'Год: 2015–2026';
            part 'Рейтинг: от 7.0';
            part 'Сортировка: по популярности';
            part 'Применить';
        }
        part 'Сетка фильмов' {
            part 'Дюна: Часть вторая' {
                part 'Постер';
                part '2024 · фантастика';
                part '8.5';
            }
            part 'Прибытие' {
                part 'Постер';
                part '2016 · фантастика';
                part '8.0';
            }
            part 'Интерстеллар' {
                part 'Постер';
                part '2014 · фантастика';
                part '8.7';
            }
            part 'Оппенгеймер' {
                part 'Постер';
                part '2023 · биография';
                part '8.4';
            }
            part 'Барби' {
                part 'Постер';
                part '2023 · комедия';
                part '7.2';
            }
            part 'Бегущий по лезвию 2049' {
                part 'Постер';
                part '2017 · фантастика';
                part '8.0';
            }
        }
        part 'Страница 1 из 12';
        part 'Далее →';
    }

    part 'MovieCardPage' {
        part 'КиноВектор' {
            part 'Каталог';
            part 'Рекомендации';
            part 'История';
            part 'Профиль';
            part 'Поиск фильма';
            part 'АП';
        }
        part 'Постер\n2:3';
        part 'Дюна: Часть вторая';
        part '2024 · фантастика, приключения · 166 мин';
        part '8.5 / 10';
        part '12 480 оценок';
        part '16+';
        part 'Пол Атрейдес объединяется с фременами, чтобы\nотомстить за семью и предотвратить ужасное\nбудущее, которое он предвидит.';
        part 'Оценить';
        part 'В историю';
        part 'Написать рецензию';
        part 'Рецензии' {
            part 'Алексей П.' {
                part 'Сильный визуальный ряд и редкий для блокбастера\nмасштаб. Вторая часть держит напряжение.';
                part 'Полезно (24)';
            }
            part 'Мария К.' {
                part 'Музыка и пустыня создают уникальную атмосферу.\nСюжет местами провисает.';
                part 'Полезно (11)';
            }
        }
        part 'Похожие фильмы' {
            part 'Прибытие' {
                part 'Постер';
                part 'Прибытие';
                part '2016 · фантастика · 8.0';
            }
            part 'Интерстеллар' {
                part 'Постер';
                part 'Интерстеллар';
                part '2014 · фантастика · 8.7';
            }
            part 'Бегущий по лезвию 2049' {
                part 'Постер';
                part 'Бегущий по лезвию 2049';
                part '2017 · фантастика · 8.0';
            }
        }
    }

    part 'ProfilePage' {
        part 'КиноВектор' {
            part 'Каталог';
            part 'Рекомендации';
            part 'История';
            part 'Профиль';
            part 'Поиск фильма';
            part 'АП';
        }
        part 'Профиль' {
            part 'АП';
            part 'Алексей Петров';
            part 'alexey@example.com';
            part 'Выйти';
        }
        part 'Статистика' {
            part '128\nпросмотрено';
            part '64\nоценки';
            part '7\nрецензий';
        }
        part 'Предпочтения' {
            part 'Фантастика';
            part 'Драма';
            part 'Триллер';
            part 'Добавить жанр';
        }
        part 'История просмотров' {
            part 'Фильм 1' {
                part 'Постер';
                part 'Дюна: Часть вторая';
                part '2 ноября 2026 · оценка 9';
                part '9 / 10';
            }
            part 'Фильм 2' {
                part 'Постер';
                part 'Прибытие';
                part '28 октября 2026 · оценка 8';
                part '8 / 10';
            }
            part 'Фильм 3' {
                part 'Постер';
                part 'Интерстеллар';
                part '19 октября 2026 · оценка 10';
                part '10 / 10';
            }
            part 'Фильм 4' {
                part 'Постер';
                part 'Оппенгеймер';
                part '5 октября 2026 · оценка 8';
                part '8 / 10';
            }
        }
        part 'Персональные данные' {
            part 'Выгрузка и удаление учётной записи.\nДанные удаляются в течение 30 дней.';
            part 'Выгрузить данные';
            part 'Удалить аккаунт';
        }
    }


    /* ============================================================
     * 9. Стили отрисовки представлений
     * ============================================================ */

    rendering plain :> asInterconnectionDiagram {
        attribute showKeywords : Boolean default = false;
        attribute showCompartments : Boolean default = false;
        attribute showTypings : Boolean default = false;
        attribute showMultiplicities : Boolean default = false;
        attribute showPortSymbols : Boolean default = false;
    }

    /* ============================================================
     * 10. Представления
     * ============================================================ */

    view ContextView {
        expose 'КиноВектор';
        expose 'Гость';
        expose 'Зритель';
        expose 'Модератор';
        expose 'Администратор каталога';
        expose 'Аналитик';
        expose 'TMDB API';
        expose 'SMTP-сервис';
        expose 'Объектное хранилище';
        expose 'PostgreSQL';
        expose 'Redis';
        expose 'Гость → КиноВектор';
        expose 'Зритель → КиноВектор';
        expose 'Модератор → КиноВектор';
        expose 'Администратор → КиноВектор';
        expose 'Аналитик → КиноВектор';
        expose 'КиноВектор → TMDB';
        expose 'КиноВектор → SMTP';
        expose 'КиноВектор → хранилище';
        expose 'КиноВектор → PostgreSQL';
        expose 'КиноВектор → Redis';
        render plain;
        metadata Layout about 'КиноВектор' { collapsed = true; }
        metadata Layout about 'Гость' { collapsed = true; }
        metadata Layout about 'Зритель' { collapsed = true; }
        metadata Layout about 'Модератор' { collapsed = true; }
        metadata Layout about 'Администратор каталога' { collapsed = true; }
        metadata Layout about 'Аналитик' { collapsed = true; }
        metadata Layout about 'TMDB API' { collapsed = true; }
        metadata Layout about 'SMTP-сервис' { collapsed = true; }
        metadata Layout about 'Объектное хранилище' { collapsed = true; }
        metadata Layout about 'PostgreSQL' { collapsed = true; }
        metadata Layout about 'Redis' { collapsed = true; }
    }

    view UseCaseView {
        expose 'Гость';
        expose 'Зритель';
        expose 'Модератор';
        expose 'Администратор каталога';
        expose 'Аналитик';
        expose 'Просматривать каталог';
        expose 'Искать и фильтровать фильмы';
        expose 'Открывать карточку фильма';
        expose 'Ставить оценку';
        expose 'Писать рецензию';
        expose 'Вести историю просмотров';
        expose 'Получать персональные рекомендации';
        expose 'Указывать предпочтения';
        expose 'Отправлять жалобу на рецензию';
        expose 'Модерировать рецензии';
        expose 'Управлять каталогом и импортировать TMDB';
        expose 'Выгружать и удалять персональные данные';
        expose 'Смотреть аналитику';
        expose 'Гость → каталог';
        expose 'Гость → поиск';
        expose 'Гость → карточка';
        expose 'Зритель → каталог';
        expose 'Зритель → поиск';
        expose 'Зритель → карточка';
        expose 'Зритель → оценка';
        expose 'Зритель → рецензия';
        expose 'Зритель → история';
        expose 'Зритель → рекомендации';
        expose 'Зритель → предпочтения';
        expose 'Зритель → жалоба';
        expose 'Зритель → данные';
        expose 'Модератор → модерация';
        expose 'Администратор → каталог';
        expose 'Аналитик → аналитика';
        expose 'include: история';
        expose 'include: оценки';
        expose 'include: предпочтения';
        expose 'extend: модерация';
        render plain;
        metadata Layout about 'Гость' { collapsed = true; }
        metadata Layout about 'Зритель' { collapsed = true; }
        metadata Layout about 'Модератор' { collapsed = true; }
        metadata Layout about 'Администратор каталога' { collapsed = true; }
        metadata Layout about 'Аналитик' { collapsed = true; }
    }

    view RecommendationsView {
        expose 'RecommendationsPage'::'КиноВектор';
        expose 'RecommendationsPage'::'Рекомендации для вас';
        expose 'RecommendationsPage'::'Подобрано по вашим оценкам\nи истории просмотров';
        expose 'RecommendationsPage'::'Главная рекомендация';
        expose 'RecommendationsPage'::'Почему это вам';
        expose 'RecommendationsPage'::'Ещё для вас';
        expose 'RecommendationsPage'::'Показать ещё';
        render plain;
        @Canvas { unit = "px"; width = 1440; height = 1200; }

        metadata Layout about 'RecommendationsPage'::'КиноВектор' { x = 0; y = 0; width = 1440; height = 84; }
        metadata Layout about 'RecommendationsPage'::'КиноВектор'::'Каталог' { x = 320; y = 24; width = 120; height = 36; }
        metadata Layout about 'RecommendationsPage'::'КиноВектор'::'Рекомендации' { x = 456; y = 24; width = 170; height = 36; }
        metadata Layout about 'RecommendationsPage'::'КиноВектор'::'История' { x = 642; y = 24; width = 120; height = 36; }
        metadata Layout about 'RecommendationsPage'::'КиноВектор'::'Профиль' { x = 778; y = 24; width = 120; height = 36; }
        metadata Layout about 'RecommendationsPage'::'КиноВектор'::'Поиск фильма' { x = 1040; y = 22; width = 280; height = 40; }
        metadata Layout about 'RecommendationsPage'::'КиноВектор'::'АП' { x = 1344; y = 22; width = 64; height = 40; }
        metadata Layout about 'RecommendationsPage'::'Рекомендации для вас' { x = 64; y = 116; width = 760; height = 48; }
        metadata Layout about 'RecommendationsPage'::'Подобрано по вашим оценкам\nи истории просмотров' { x = 64; y = 172; width = 900; height = 28; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация' { x = 64; y = 220; width = 820; height = 440; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация'::'Постер\n2:3' { x = 88; y = 262; width = 240; height = 360; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация'::'Дюна: Часть вторая' { x = 352; y = 262; width = 500; height = 40; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация'::'2024 · фантастика · 166 мин' { x = 352; y = 312; width = 500; height = 26; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация'::'8.5 / 10' { x = 352; y = 352; width = 180; height = 44; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация'::'16+' { x = 548; y = 352; width = 80; height = 44; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация'::'Пол Атрейдес объединяется с фременами,\nчтобы отомстить за семью.' { x = 352; y = 412; width = 500; height = 64; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация'::'Буду смотреть' { x = 352; y = 500; width = 240; height = 48; }
        metadata Layout about 'RecommendationsPage'::'Главная рекомендация'::'Не интересно' { x = 608; y = 500; width = 200; height = 48; }
        metadata Layout about 'RecommendationsPage'::'Почему это вам' { x = 912; y = 220; width = 464; height = 440; }
        metadata Layout about 'RecommendationsPage'::'Почему это вам'::'Вы высоко оценили\n«Дюну» (2021)' { x = 936; y = 264; width = 416; height = 44; }
        metadata Layout about 'RecommendationsPage'::'Почему это вам'::'Любите фантастику\nи эпическое кино' { x = 936; y = 318; width = 416; height = 44; }
        metadata Layout about 'RecommendationsPage'::'Почему это вам'::'Похожие фильмы:\n«Прибытие», «Интерстеллар»' { x = 936; y = 372; width = 416; height = 66; }
        metadata Layout about 'RecommendationsPage'::'Почему это вам'::'Объяснение полезно?' { x = 936; y = 470; width = 416; height = 30; }
        metadata Layout about 'RecommendationsPage'::'Почему это вам'::'Да' { x = 936; y = 510; width = 90; height = 40; }
        metadata Layout about 'RecommendationsPage'::'Почему это вам'::'Нет' { x = 1040; y = 510; width = 90; height = 40; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас' { x = 64; y = 700; width = 1312; height = 420; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Прибытие' { x = 88; y = 748; width = 400; height = 340; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Прибытие'::'Постер' { x = 104; y = 790; width = 368; height = 170; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Прибытие'::'2016 · фантастика' { x = 104; y = 978; width = 368; height = 24; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Прибытие'::'8.0' { x = 104; y = 1010; width = 90; height = 30; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Интерстеллар' { x = 520; y = 748; width = 400; height = 340; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Интерстеллар'::'Постер' { x = 536; y = 790; width = 368; height = 170; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Интерстеллар'::'2014 · фантастика' { x = 536; y = 978; width = 368; height = 24; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Интерстеллар'::'8.7' { x = 536; y = 1010; width = 90; height = 30; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Бегущий по лезвию 2049' { x = 952; y = 748; width = 400; height = 340; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Бегущий по лезвию 2049'::'Постер' { x = 968; y = 790; width = 368; height = 170; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Бегущий по лезвию 2049'::'2017 · фантастика' { x = 968; y = 978; width = 368; height = 24; }
        metadata Layout about 'RecommendationsPage'::'Ещё для вас'::'Бегущий по лезвию 2049'::'8.0' { x = 968; y = 1010; width = 90; height = 30; }
        metadata Layout about 'RecommendationsPage'::'Показать ещё' { x = 620; y = 1140; width = 200; height = 44; }

        metadata Style about 'RecommendationsPage'::'КиноВектор' { fill = "#111827"; line = "#111827"; text = "#FFFFFF"; fontSize = 24; }
        metadata Style about 'RecommendationsPage'::'КиноВектор'::'Каталог' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'КиноВектор'::'Рекомендации' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'КиноВектор'::'История' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'КиноВектор'::'Профиль' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'КиноВектор'::'Поиск фильма' { fill = "#1F2937"; line = "#374151"; text = "#9CA3AF"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'КиноВектор'::'АП' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Рекомендации для вас' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#111827"; fontSize = 30; }
        metadata Style about 'RecommendationsPage'::'Подобрано по вашим оценкам\nи истории просмотров' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 15; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация' { fill = "#F9FAFB"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация'::'Постер\n2:3' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация'::'Дюна: Часть вторая' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#111827"; fontSize = 26; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация'::'2024 · фантастика · 166 мин' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#6B7280"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация'::'8.5 / 10' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 22; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация'::'16+' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#374151"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация'::'Пол Атрейдес объединяется с фременами,\nчтобы отомстить за семью.' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#4B5563"; fontSize = 13; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация'::'Буду смотреть' { fill = "#111827"; line = "#111827"; text = "#FFFFFF"; fontSize = 15; }
        metadata Style about 'RecommendationsPage'::'Главная рекомендация'::'Не интересно' { fill = "#FFFFFF"; line = "#111827"; text = "#111827"; fontSize = 15; }
        metadata Style about 'RecommendationsPage'::'Почему это вам' { fill = "#ECFEFF"; line = "#67E8F9"; text = "#0E7490"; fontSize = 16; }
        metadata Style about 'RecommendationsPage'::'Почему это вам'::'Вы высоко оценили\n«Дюну» (2021)' { fill = "#ECFEFF"; line = "#ECFEFF"; text = "#0E7490"; fontSize = 13; }
        metadata Style about 'RecommendationsPage'::'Почему это вам'::'Любите фантастику\nи эпическое кино' { fill = "#ECFEFF"; line = "#ECFEFF"; text = "#0E7490"; fontSize = 13; }
        metadata Style about 'RecommendationsPage'::'Почему это вам'::'Похожие фильмы:\n«Прибытие», «Интерстеллар»' { fill = "#ECFEFF"; line = "#ECFEFF"; text = "#0E7490"; fontSize = 13; }
        metadata Style about 'RecommendationsPage'::'Почему это вам'::'Объяснение полезно?' { fill = "#ECFEFF"; line = "#ECFEFF"; text = "#0E7490"; fontSize = 13; }
        metadata Style about 'RecommendationsPage'::'Почему это вам'::'Да' { fill = "#FFFFFF"; line = "#67E8F9"; text = "#0E7490"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Почему это вам'::'Нет' { fill = "#FFFFFF"; line = "#67E8F9"; text = "#0E7490"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 20; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Прибытие' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Прибытие'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Прибытие'::'2016 · фантастика' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Прибытие'::'8.0' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Интерстеллар' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Интерстеллар'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Интерстеллар'::'2014 · фантастика' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Интерстеллар'::'8.7' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Бегущий по лезвию 2049' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Бегущий по лезвию 2049'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Бегущий по лезвию 2049'::'2017 · фантастика' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'RecommendationsPage'::'Ещё для вас'::'Бегущий по лезвию 2049'::'8.0' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'RecommendationsPage'::'Показать ещё' { fill = "#111827"; line = "#111827"; text = "#FFFFFF"; fontSize = 15; }
    }

    view CatalogView {
        expose 'CatalogPage'::'КиноВектор';
        expose 'CatalogPage'::'Каталог фильмов';
        expose 'CatalogPage'::'1 248 фильмов · обновлено сегодня';
        expose 'CatalogPage'::'Фильтры';
        expose 'CatalogPage'::'Сетка фильмов';
        expose 'CatalogPage'::'Страница 1 из 12';
        expose 'CatalogPage'::'Далее →';
        render plain;
        @Canvas { unit = "px"; width = 1440; height = 1200; }

        metadata Layout about 'CatalogPage'::'КиноВектор' { x = 0; y = 0; width = 1440; height = 84; }
        metadata Layout about 'CatalogPage'::'КиноВектор'::'Каталог' { x = 320; y = 24; width = 120; height = 36; }
        metadata Layout about 'CatalogPage'::'КиноВектор'::'Рекомендации' { x = 456; y = 24; width = 170; height = 36; }
        metadata Layout about 'CatalogPage'::'КиноВектор'::'История' { x = 642; y = 24; width = 120; height = 36; }
        metadata Layout about 'CatalogPage'::'КиноВектор'::'Профиль' { x = 778; y = 24; width = 120; height = 36; }
        metadata Layout about 'CatalogPage'::'КиноВектор'::'Поиск фильма' { x = 1040; y = 22; width = 280; height = 40; }
        metadata Layout about 'CatalogPage'::'КиноВектор'::'АП' { x = 1344; y = 22; width = 64; height = 40; }
        metadata Layout about 'CatalogPage'::'Каталог фильмов' { x = 64; y = 116; width = 760; height = 48; }
        metadata Layout about 'CatalogPage'::'1 248 фильмов · обновлено сегодня' { x = 64; y = 172; width = 900; height = 28; }
        metadata Layout about 'CatalogPage'::'Фильтры' { x = 64; y = 220; width = 1312; height = 120; }
        metadata Layout about 'CatalogPage'::'Фильтры'::'Жанр: все' { x = 88; y = 262; width = 220; height = 44; }
        metadata Layout about 'CatalogPage'::'Фильтры'::'Год: 2015–2026' { x = 324; y = 262; width = 220; height = 44; }
        metadata Layout about 'CatalogPage'::'Фильтры'::'Рейтинг: от 7.0' { x = 560; y = 262; width = 220; height = 44; }
        metadata Layout about 'CatalogPage'::'Фильтры'::'Сортировка: по популярности' { x = 796; y = 262; width = 300; height = 44; }
        metadata Layout about 'CatalogPage'::'Фильтры'::'Применить' { x = 1112; y = 262; width = 240; height = 44; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов' { x = 64; y = 360; width = 1312; height = 690; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Дюна: Часть вторая' { x = 88; y = 408; width = 400; height = 290; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Дюна: Часть вторая'::'Постер' { x = 104; y = 450; width = 368; height = 160; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Дюна: Часть вторая'::'2024 · фантастика' { x = 104; y = 626; width = 368; height = 24; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Дюна: Часть вторая'::'8.5' { x = 104; y = 658; width = 90; height = 30; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Прибытие' { x = 520; y = 408; width = 400; height = 290; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Прибытие'::'Постер' { x = 536; y = 450; width = 368; height = 160; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Прибытие'::'2016 · фантастика' { x = 536; y = 626; width = 368; height = 24; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Прибытие'::'8.0' { x = 536; y = 658; width = 90; height = 30; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Интерстеллар' { x = 952; y = 408; width = 400; height = 290; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Интерстеллар'::'Постер' { x = 968; y = 450; width = 368; height = 160; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Интерстеллар'::'2014 · фантастика' { x = 968; y = 626; width = 368; height = 24; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Интерстеллар'::'8.7' { x = 968; y = 658; width = 90; height = 30; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Оппенгеймер' { x = 88; y = 718; width = 400; height = 290; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Оппенгеймер'::'Постер' { x = 104; y = 760; width = 368; height = 160; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Оппенгеймер'::'2023 · биография' { x = 104; y = 936; width = 368; height = 24; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Оппенгеймер'::'8.4' { x = 104; y = 968; width = 90; height = 30; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Барби' { x = 520; y = 718; width = 400; height = 290; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Барби'::'Постер' { x = 536; y = 760; width = 368; height = 160; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Барби'::'2023 · комедия' { x = 536; y = 936; width = 368; height = 24; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Барби'::'7.2' { x = 536; y = 968; width = 90; height = 30; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Бегущий по лезвию 2049' { x = 952; y = 718; width = 400; height = 290; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Бегущий по лезвию 2049'::'Постер' { x = 968; y = 760; width = 368; height = 160; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Бегущий по лезвию 2049'::'2017 · фантастика' { x = 968; y = 936; width = 368; height = 24; }
        metadata Layout about 'CatalogPage'::'Сетка фильмов'::'Бегущий по лезвию 2049'::'8.0' { x = 968; y = 968; width = 90; height = 30; }
        metadata Layout about 'CatalogPage'::'Страница 1 из 12' { x = 64; y = 1090; width = 300; height = 40; }
        metadata Layout about 'CatalogPage'::'Далее →' { x = 1240; y = 1084; width = 136; height = 44; }

        metadata Style about 'CatalogPage'::'КиноВектор' { fill = "#111827"; line = "#111827"; text = "#FFFFFF"; fontSize = 24; }
        metadata Style about 'CatalogPage'::'КиноВектор'::'Каталог' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'КиноВектор'::'Рекомендации' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'КиноВектор'::'История' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'КиноВектор'::'Профиль' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'КиноВектор'::'Поиск фильма' { fill = "#1F2937"; line = "#374151"; text = "#9CA3AF"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'КиноВектор'::'АП' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Каталог фильмов' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#111827"; fontSize = 30; }
        metadata Style about 'CatalogPage'::'1 248 фильмов · обновлено сегодня' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 15; }
        metadata Style about 'CatalogPage'::'Фильтры' { fill = "#F3F4F6"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'CatalogPage'::'Фильтры'::'Жанр: все' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#374151"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Фильтры'::'Год: 2015–2026' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#374151"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Фильтры'::'Рейтинг: от 7.0' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#374151"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Фильтры'::'Сортировка: по популярности' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#374151"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Фильтры'::'Применить' { fill = "#111827"; line = "#111827"; text = "#FFFFFF"; fontSize = 15; }
        metadata Style about 'CatalogPage'::'Сетка фильмов' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 20; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Дюна: Часть вторая' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Дюна: Часть вторая'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Дюна: Часть вторая'::'2024 · фантастика' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Дюна: Часть вторая'::'8.5' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Прибытие' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Прибытие'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Прибытие'::'2016 · фантастика' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Прибытие'::'8.0' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Интерстеллар' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Интерстеллар'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Интерстеллар'::'2014 · фантастика' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Интерстеллар'::'8.7' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Оппенгеймер' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Оппенгеймер'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Оппенгеймер'::'2023 · биография' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Оппенгеймер'::'8.4' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Барби' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Барби'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Барби'::'2023 · комедия' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Барби'::'7.2' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Бегущий по лезвию 2049' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Бегущий по лезвию 2049'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Бегущий по лезвию 2049'::'2017 · фантастика' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'CatalogPage'::'Сетка фильмов'::'Бегущий по лезвию 2049'::'8.0' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'CatalogPage'::'Страница 1 из 12' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#374151"; fontSize = 14; }
        metadata Style about 'CatalogPage'::'Далее →' { fill = "#FFFFFF"; line = "#111827"; text = "#111827"; fontSize = 15; }
    }

    view MovieCardView {
        expose 'MovieCardPage'::'КиноВектор';
        expose 'MovieCardPage'::'Постер\n2:3';
        expose 'MovieCardPage'::'Дюна: Часть вторая';
        expose 'MovieCardPage'::'2024 · фантастика, приключения · 166 мин';
        expose 'MovieCardPage'::'8.5 / 10';
        expose 'MovieCardPage'::'12 480 оценок';
        expose 'MovieCardPage'::'16+';
        expose 'MovieCardPage'::'Пол Атрейдес объединяется с фременами, чтобы\nотомстить за семью и предотвратить ужасное\nбудущее, которое он предвидит.';
        expose 'MovieCardPage'::'Оценить';
        expose 'MovieCardPage'::'В историю';
        expose 'MovieCardPage'::'Написать рецензию';
        expose 'MovieCardPage'::'Рецензии';
        expose 'MovieCardPage'::'Похожие фильмы';
        render plain;
        @Canvas { unit = "px"; width = 1440; height = 1200; }

        metadata Layout about 'MovieCardPage'::'КиноВектор' { x = 0; y = 0; width = 1440; height = 84; }
        metadata Layout about 'MovieCardPage'::'КиноВектор'::'Каталог' { x = 320; y = 24; width = 120; height = 36; }
        metadata Layout about 'MovieCardPage'::'КиноВектор'::'Рекомендации' { x = 456; y = 24; width = 170; height = 36; }
        metadata Layout about 'MovieCardPage'::'КиноВектор'::'История' { x = 642; y = 24; width = 120; height = 36; }
        metadata Layout about 'MovieCardPage'::'КиноВектор'::'Профиль' { x = 778; y = 24; width = 120; height = 36; }
        metadata Layout about 'MovieCardPage'::'КиноВектор'::'Поиск фильма' { x = 1040; y = 22; width = 280; height = 40; }
        metadata Layout about 'MovieCardPage'::'КиноВектор'::'АП' { x = 1344; y = 22; width = 64; height = 40; }
        metadata Layout about 'MovieCardPage'::'Постер\n2:3' { x = 64; y = 130; width = 320; height = 440; }
        metadata Layout about 'MovieCardPage'::'Дюна: Часть вторая' { x = 416; y = 130; width = 700; height = 50; }
        metadata Layout about 'MovieCardPage'::'2024 · фантастика, приключения · 166 мин' { x = 416; y = 192; width = 700; height = 28; }
        metadata Layout about 'MovieCardPage'::'8.5 / 10' { x = 416; y = 240; width = 160; height = 48; }
        metadata Layout about 'MovieCardPage'::'12 480 оценок' { x = 592; y = 248; width = 300; height = 32; }
        metadata Layout about 'MovieCardPage'::'16+' { x = 416; y = 304; width = 80; height = 36; }
        metadata Layout about 'MovieCardPage'::'Пол Атрейдес объединяется с фременами, чтобы\nотомстить за семью и предотвратить ужасное\nбудущее, которое он предвидит.' { x = 416; y = 356; width = 600; height = 100; }
        metadata Layout about 'MovieCardPage'::'Оценить' { x = 416; y = 480; width = 180; height = 48; }
        metadata Layout about 'MovieCardPage'::'В историю' { x = 612; y = 480; width = 200; height = 48; }
        metadata Layout about 'MovieCardPage'::'Написать рецензию' { x = 828; y = 480; width = 240; height = 48; }
        metadata Layout about 'MovieCardPage'::'Рецензии' { x = 64; y = 610; width = 700; height = 470; }
        metadata Layout about 'MovieCardPage'::'Рецензии'::'Алексей П.' { x = 88; y = 660; width = 652; height = 150; }
        metadata Layout about 'MovieCardPage'::'Рецензии'::'Алексей П.'::'Сильный визуальный ряд и редкий для блокбастера\nмасштаб. Вторая часть держит напряжение.' { x = 104; y = 700; width = 620; height = 60; }
        metadata Layout about 'MovieCardPage'::'Рецензии'::'Алексей П.'::'Полезно (24)' { x = 104; y = 768; width = 160; height = 30; }
        metadata Layout about 'MovieCardPage'::'Рецензии'::'Мария К.' { x = 88; y = 830; width = 652; height = 150; }
        metadata Layout about 'MovieCardPage'::'Рецензии'::'Мария К.'::'Музыка и пустыня создают уникальную атмосферу.\nСюжет местами провисает.' { x = 104; y = 870; width = 620; height = 60; }
        metadata Layout about 'MovieCardPage'::'Рецензии'::'Мария К.'::'Полезно (11)' { x = 104; y = 938; width = 160; height = 30; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы' { x = 800; y = 610; width = 576; height = 470; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Прибытие' { x = 824; y = 660; width = 528; height = 120; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Прибытие'::'Постер' { x = 836; y = 672; width = 70; height = 96; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Прибытие'::'Прибытие' { x = 920; y = 680; width = 410; height = 26; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Прибытие'::'2016 · фантастика · 8.0' { x = 920; y = 714; width = 410; height = 24; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Интерстеллар' { x = 824; y = 790; width = 528; height = 120; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Интерстеллар'::'Постер' { x = 836; y = 802; width = 70; height = 96; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Интерстеллар'::'Интерстеллар' { x = 920; y = 810; width = 410; height = 26; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Интерстеллар'::'2014 · фантастика · 8.7' { x = 920; y = 844; width = 410; height = 24; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Бегущий по лезвию 2049' { x = 824; y = 920; width = 528; height = 120; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Бегущий по лезвию 2049'::'Постер' { x = 836; y = 932; width = 70; height = 96; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Бегущий по лезвию 2049'::'Бегущий по лезвию 2049' { x = 920; y = 940; width = 410; height = 26; }
        metadata Layout about 'MovieCardPage'::'Похожие фильмы'::'Бегущий по лезвию 2049'::'2017 · фантастика · 8.0' { x = 920; y = 974; width = 410; height = 24; }

        metadata Style about 'MovieCardPage'::'КиноВектор' { fill = "#111827"; line = "#111827"; text = "#FFFFFF"; fontSize = 24; }
        metadata Style about 'MovieCardPage'::'КиноВектор'::'Каталог' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'КиноВектор'::'Рекомендации' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'КиноВектор'::'История' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'КиноВектор'::'Профиль' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'КиноВектор'::'Поиск фильма' { fill = "#1F2937"; line = "#374151"; text = "#9CA3AF"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'КиноВектор'::'АП' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'Постер\n2:3' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'Дюна: Часть вторая' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#111827"; fontSize = 30; }
        metadata Style about 'MovieCardPage'::'2024 · фантастика, приключения · 166 мин' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'8.5 / 10' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 22; }
        metadata Style about 'MovieCardPage'::'12 480 оценок' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'16+' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#374151"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'Пол Атрейдес объединяется с фременами, чтобы\nотомстить за семью и предотвратить ужасное\nбудущее, которое он предвидит.' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#4B5563"; fontSize = 13; }
        metadata Style about 'MovieCardPage'::'Оценить' { fill = "#111827"; line = "#111827"; text = "#FFFFFF"; fontSize = 15; }
        metadata Style about 'MovieCardPage'::'В историю' { fill = "#FFFFFF"; line = "#111827"; text = "#111827"; fontSize = 15; }
        metadata Style about 'MovieCardPage'::'Написать рецензию' { fill = "#FFFFFF"; line = "#111827"; text = "#111827"; fontSize = 15; }
        metadata Style about 'MovieCardPage'::'Рецензии' { fill = "#F9FAFB"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'MovieCardPage'::'Рецензии'::'Алексей П.' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'MovieCardPage'::'Рецензии'::'Алексей П.'::'Сильный визуальный ряд и редкий для блокбастера\nмасштаб. Вторая часть держит напряжение.' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#4B5563"; fontSize = 13; }
        metadata Style about 'MovieCardPage'::'Рецензии'::'Алексей П.'::'Полезно (24)' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#374151"; fontSize = 13; }
        metadata Style about 'MovieCardPage'::'Рецензии'::'Мария К.' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'MovieCardPage'::'Рецензии'::'Мария К.'::'Музыка и пустыня создают уникальную атмосферу.\nСюжет местами провисает.' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#4B5563"; fontSize = 13; }
        metadata Style about 'MovieCardPage'::'Рецензии'::'Мария К.'::'Полезно (11)' { fill = "#FFFFFF"; line = "#D1D5DB"; text = "#374151"; fontSize = 13; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Прибытие' { fill = "#F9FAFB"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Прибытие'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 11; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Прибытие'::'Прибытие' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#111827"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Прибытие'::'2016 · фантастика · 8.0' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Интерстеллар' { fill = "#F9FAFB"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Интерстеллар'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 11; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Интерстеллар'::'Интерстеллар' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#111827"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Интерстеллар'::'2014 · фантастика · 8.7' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Бегущий по лезвию 2049' { fill = "#F9FAFB"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Бегущий по лезвию 2049'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 11; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Бегущий по лезвию 2049'::'Бегущий по лезвию 2049' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#111827"; fontSize = 14; }
        metadata Style about 'MovieCardPage'::'Похожие фильмы'::'Бегущий по лезвию 2049'::'2017 · фантастика · 8.0' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#6B7280"; fontSize = 13; }
    }

    view ProfileView {
        expose 'ProfilePage'::'КиноВектор';
        expose 'ProfilePage'::'Профиль';
        expose 'ProfilePage'::'Статистика';
        expose 'ProfilePage'::'Предпочтения';
        expose 'ProfilePage'::'История просмотров';
        expose 'ProfilePage'::'Персональные данные';
        render plain;
        @Canvas { unit = "px"; width = 1440; height = 1200; }

        metadata Layout about 'ProfilePage'::'КиноВектор' { x = 0; y = 0; width = 1440; height = 84; }
        metadata Layout about 'ProfilePage'::'КиноВектор'::'Каталог' { x = 320; y = 24; width = 120; height = 36; }
        metadata Layout about 'ProfilePage'::'КиноВектор'::'Рекомендации' { x = 456; y = 24; width = 170; height = 36; }
        metadata Layout about 'ProfilePage'::'КиноВектор'::'История' { x = 642; y = 24; width = 120; height = 36; }
        metadata Layout about 'ProfilePage'::'КиноВектор'::'Профиль' { x = 778; y = 24; width = 120; height = 36; }
        metadata Layout about 'ProfilePage'::'КиноВектор'::'Поиск фильма' { x = 1040; y = 22; width = 280; height = 40; }
        metadata Layout about 'ProfilePage'::'КиноВектор'::'АП' { x = 1344; y = 22; width = 64; height = 40; }
        metadata Layout about 'ProfilePage'::'Профиль' { x = 64; y = 120; width = 520; height = 220; }
        metadata Layout about 'ProfilePage'::'Профиль'::'АП' { x = 88; y = 160; width = 96; height = 96; }
        metadata Layout about 'ProfilePage'::'Профиль'::'Алексей Петров' { x = 208; y = 160; width = 340; height = 36; }
        metadata Layout about 'ProfilePage'::'Профиль'::'alexey@example.com' { x = 208; y = 204; width = 340; height = 26; }
        metadata Layout about 'ProfilePage'::'Профиль'::'Выйти' { x = 208; y = 246; width = 140; height = 40; }
        metadata Layout about 'ProfilePage'::'Статистика' { x = 608; y = 120; width = 768; height = 220; }
        metadata Layout about 'ProfilePage'::'Статистика'::'128\nпросмотрено' { x = 632; y = 170; width = 220; height = 120; }
        metadata Layout about 'ProfilePage'::'Статистика'::'64\nоценки' { x = 876; y = 170; width = 220; height = 120; }
        metadata Layout about 'ProfilePage'::'Статистика'::'7\nрецензий' { x = 1120; y = 170; width = 220; height = 120; }
        metadata Layout about 'ProfilePage'::'Предпочтения' { x = 64; y = 370; width = 1312; height = 150; }
        metadata Layout about 'ProfilePage'::'Предпочтения'::'Фантастика' { x = 88; y = 420; width = 180; height = 44; }
        metadata Layout about 'ProfilePage'::'Предпочтения'::'Драма' { x = 284; y = 420; width = 140; height = 44; }
        metadata Layout about 'ProfilePage'::'Предпочтения'::'Триллер' { x = 440; y = 420; width = 160; height = 44; }
        metadata Layout about 'ProfilePage'::'Предпочтения'::'Добавить жанр' { x = 616; y = 420; width = 200; height = 44; }
        metadata Layout about 'ProfilePage'::'История просмотров' { x = 64; y = 550; width = 1312; height = 430; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 1' { x = 88; y = 600; width = 1264; height = 80; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 1'::'Постер' { x = 96; y = 606; width = 64; height = 68; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 1'::'Дюна: Часть вторая' { x = 176; y = 610; width = 600; height = 26; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 1'::'2 ноября 2026 · оценка 9' { x = 176; y = 644; width = 600; height = 24; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 1'::'9 / 10' { x = 1200; y = 614; width = 120; height = 36; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 2' { x = 88; y = 690; width = 1264; height = 80; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 2'::'Постер' { x = 96; y = 696; width = 64; height = 68; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 2'::'Прибытие' { x = 176; y = 700; width = 600; height = 26; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 2'::'28 октября 2026 · оценка 8' { x = 176; y = 734; width = 600; height = 24; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 2'::'8 / 10' { x = 1200; y = 704; width = 120; height = 36; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 3' { x = 88; y = 780; width = 1264; height = 80; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 3'::'Постер' { x = 96; y = 786; width = 64; height = 68; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 3'::'Интерстеллар' { x = 176; y = 790; width = 600; height = 26; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 3'::'19 октября 2026 · оценка 10' { x = 176; y = 824; width = 600; height = 24; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 3'::'10 / 10' { x = 1200; y = 794; width = 120; height = 36; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 4' { x = 88; y = 870; width = 1264; height = 80; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 4'::'Постер' { x = 96; y = 876; width = 64; height = 68; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 4'::'Оппенгеймер' { x = 176; y = 880; width = 600; height = 26; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 4'::'5 октября 2026 · оценка 8' { x = 176; y = 914; width = 600; height = 24; }
        metadata Layout about 'ProfilePage'::'История просмотров'::'Фильм 4'::'8 / 10' { x = 1200; y = 884; width = 120; height = 36; }
        metadata Layout about 'ProfilePage'::'Персональные данные' { x = 64; y = 1000; width = 1312; height = 170; }
        metadata Layout about 'ProfilePage'::'Персональные данные'::'Выгрузка и удаление учётной записи.\nДанные удаляются в течение 30 дней.' { x = 88; y = 1046; width = 900; height = 50; }
        metadata Layout about 'ProfilePage'::'Персональные данные'::'Выгрузить данные' { x = 88; y = 1104; width = 240; height = 44; }
        metadata Layout about 'ProfilePage'::'Персональные данные'::'Удалить аккаунт' { x = 348; y = 1104; width = 220; height = 44; }

        metadata Style about 'ProfilePage'::'КиноВектор' { fill = "#111827"; line = "#111827"; text = "#FFFFFF"; fontSize = 24; }
        metadata Style about 'ProfilePage'::'КиноВектор'::'Каталог' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'КиноВектор'::'Рекомендации' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'КиноВектор'::'История' { fill = "#111827"; line = "#111827"; text = "#E5E7EB"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'КиноВектор'::'Профиль' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'КиноВектор'::'Поиск фильма' { fill = "#1F2937"; line = "#374151"; text = "#9CA3AF"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'КиноВектор'::'АП' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'Профиль' { fill = "#F9FAFB"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'ProfilePage'::'Профиль'::'АП' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 28; }
        metadata Style about 'ProfilePage'::'Профиль'::'Алексей Петров' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#111827"; fontSize = 24; }
        metadata Style about 'ProfilePage'::'Профиль'::'alexey@example.com' { fill = "#F9FAFB"; line = "#F9FAFB"; text = "#6B7280"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'Профиль'::'Выйти' { fill = "#FFFFFF"; line = "#111827"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'Статистика' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'ProfilePage'::'Статистика'::'128\nпросмотрено' { fill = "#F3F4F6"; line = "#D1D5DB"; text = "#111827"; fontSize = 20; }
        metadata Style about 'ProfilePage'::'Статистика'::'64\nоценки' { fill = "#F3F4F6"; line = "#D1D5DB"; text = "#111827"; fontSize = 20; }
        metadata Style about 'ProfilePage'::'Статистика'::'7\nрецензий' { fill = "#F3F4F6"; line = "#D1D5DB"; text = "#111827"; fontSize = 20; }
        metadata Style about 'ProfilePage'::'Предпочтения' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'ProfilePage'::'Предпочтения'::'Фантастика' { fill = "#E0F2FE"; line = "#7DD3FC"; text = "#0C4A6E"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'Предпочтения'::'Драма' { fill = "#E0F2FE"; line = "#7DD3FC"; text = "#0C4A6E"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'Предпочтения'::'Триллер' { fill = "#E0F2FE"; line = "#7DD3FC"; text = "#0C4A6E"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'Предпочтения'::'Добавить жанр' { fill = "#FFFFFF"; line = "#7DD3FC"; text = "#0C4A6E"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'История просмотров' { fill = "#F9FAFB"; line = "#D1D5DB"; text = "#111827"; fontSize = 16; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 1' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 1'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 11; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 1'::'Дюна: Часть вторая' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 1'::'2 ноября 2026 · оценка 9' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 1'::'9 / 10' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 2' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 2'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 11; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 2'::'Прибытие' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 2'::'28 октября 2026 · оценка 8' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 2'::'8 / 10' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 3' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 3'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 11; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 3'::'Интерстеллар' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 3'::'19 октября 2026 · оценка 10' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 3'::'10 / 10' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 4' { fill = "#FFFFFF"; line = "#E5E7EB"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 4'::'Постер' { fill = "#D1D5DB"; line = "#9CA3AF"; text = "#4B5563"; fontSize = 11; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 4'::'Оппенгеймер' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 4'::'5 октября 2026 · оценка 8' { fill = "#FFFFFF"; line = "#FFFFFF"; text = "#6B7280"; fontSize = 13; }
        metadata Style about 'ProfilePage'::'История просмотров'::'Фильм 4'::'8 / 10' { fill = "#F59E0B"; line = "#F59E0B"; text = "#111827"; fontSize = 15; }
        metadata Style about 'ProfilePage'::'Персональные данные' { fill = "#FEF2F2"; line = "#FCA5A5"; text = "#991B1B"; fontSize = 16; }
        metadata Style about 'ProfilePage'::'Персональные данные'::'Выгрузка и удаление учётной записи.\nДанные удаляются в течение 30 дней.' { fill = "#FEF2F2"; line = "#FEF2F2"; text = "#991B1B"; fontSize = 13; }
        metadata Style about 'ProfilePage'::'Персональные данные'::'Выгрузить данные' { fill = "#FFFFFF"; line = "#991B1B"; text = "#991B1B"; fontSize = 14; }
        metadata Style about 'ProfilePage'::'Персональные данные'::'Удалить аккаунт' { fill = "#DC2626"; line = "#DC2626"; text = "#FFFFFF"; fontSize = 14; }
    }
}

