package KinoVector {

    import ScalarValues::*;
    import ISQ::*;
    import SI::*;

    /* ============================================================
     * 1. Общие типы предметной области
     * ============================================================ */

    attribute def Email;
    attribute def Url;
    attribute def RatingValue : Integer;
    attribute def DurationMinutes : Integer;
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
     * 2. Участники и внешние системы
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

    /* ============================================================
     * 3. Основные сущности
     * ============================================================ */

    part def Movie {
        attribute movieId : String;
        attribute tmdbId : Integer;
        attribute title : String;
        attribute releaseYear : Integer;
        attribute duration : DurationMinutes;
        attribute description : String;
        attribute posterUrl : Url;
        attribute averageRating : Real;
        attribute ratingsCount : Integer;
        attribute ageRating : String;
        attribute isArchived : Boolean = false;
    }

    part def Genre {
        attribute genreId : String;
        attribute name : String;
    }

    part def Rating {
        attribute ratingId : String;
        attribute value : RatingValue;
        attribute createdAt : Timestamp;
        attribute updatedAt : Timestamp;
    }

    part def Review {
        attribute reviewId : String;
        attribute text : String;
        attribute containsSpoiler : Boolean;
        attribute status : ReviewStatus = ReviewStatus::published;
        attribute createdAt : Timestamp;
        attribute updatedAt : Timestamp;
    }

    part def WatchHistoryEntry {
        attribute entryId : String;
        attribute watchedAt : Timestamp;
    }

    part def Recommendation {
        attribute recommendationId : String;
        attribute score : Real;
        attribute explanation : String;
        attribute source : String;
        attribute modelVersion : String;
    }

    part def RecommendationFeedbackRecord {
        attribute feedback : RecommendationFeedback;
        attribute createdAt : Timestamp;
    }

    part def ModerationCase {
        attribute caseId : String;
        attribute reason : String;
        attribute createdAt : Timestamp;
        attribute resolvedAt : Timestamp;
    }

    /* ============================================================
     * 4. Порты и сервисы
     * ============================================================ */

    port def WebApiPort {
        in request : String;
        out response : String;
    }

    port def TmdbPort {
        in searchQuery : String;
        out movieMetadata : String;
    }

    port def RecommendationPort {
        in userSignals : String;
        out recommendations : Recommendation[0..*];
    }

    port def ModerationPort {
        in report : String;
        out decision : String;
    }

    part def CatalogService {
        attribute catalogSize : Integer;
        port api : WebApiPort;
    }

    part def RatingService {
        port api : WebApiPort;
    }

    part def ReviewService {
        port api : WebApiPort;
        port moderation : ModerationPort;
    }

    part def HistoryService {
        port api : WebApiPort;
    }

    part def RecommendationService {
        attribute algorithm : String = "hybrid: content-based + item-item CF + popularity";
        attribute modelVersion : String;
        attribute fallbackEnabled : Boolean = true;
        port api : RecommendationPort;
    }

    part def AdminService {
        port api : WebApiPort;
        port tmdb : TmdbPort;
    }

    part def AuthService {
        port api : WebApiPort;
    }

    /* ============================================================
     * 5. Система «КиноВектор»
     * ============================================================ */

    part def KinoVectorSystem {
        part catalog : CatalogService;
        part ratings : RatingService;
        part reviews : ReviewService;
        part history : HistoryService;
        part recommender : RecommendationService;
        part admin : AdminService;
        part auth : AuthService;

        part tmdb : TmdbService;
        part email : EmailService;
        part storage : ObjectStorage;

        connect admin.tmdb to tmdb;
        connect auth.api to email;
        connect catalog.api to storage;
    }

    /* ============================================================
     * 6. Варианты использования
     * ============================================================ */

    use case def BrowseCatalog {
        subject system : KinoVectorSystem;
        actor guest : Guest;
        actor viewer : Viewer;
    }

    use case def SearchMovies {
        subject system : KinoVectorSystem;
        actor viewer : Viewer;
    }

    use case def RateMovie {
        subject system : KinoVectorSystem;
        actor viewer : Viewer;
    }

    use case def WriteReview {
        subject system : KinoVectorSystem;
        actor viewer : Viewer;
    }

    use case def ModerateReview {
        subject system : KinoVectorSystem;
        actor moderator : Moderator;
    }

    use case def GetRecommendations {
        subject system : KinoVectorSystem;
        actor viewer : Viewer;
    }

    use case def ManageCatalog {
        subject system : KinoVectorSystem;
        actor admin : CatalogAdmin;
    }

    use case def ExportPersonalData {
        subject system : KinoVectorSystem;
        actor viewer : Viewer;
    }

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
     * 8. Модель пользовательского интерфейса для мокапов
     * ============================================================ */

    part def Header {
        attribute logoText : String = "КиноВектор";
        attribute searchPlaceholder : String = "Найти фильм";
        part navigation : String[0..*];
    }

    part def MovieCard {
        attribute title : String;
        attribute year : Integer;
        attribute averageRating : Real;
        attribute posterUrl : Url;
        attribute explanation : String;
    }

    part def RecommendationsPage {
        attribute title : String = "Рекомендации для вас";
        part header : Header;
        part hero : MovieCard;
        part recommendations : MovieCard[0..20];
        port openMovie : WebApiPort;
        port likeRecommendation : WebApiPort;
        port dislikeRecommendation : WebApiPort;
    }

    part def CatalogPage {
        attribute title : String = "Каталог фильмов";
        part header : Header;
        part filters : String[0..*];
        part movies : MovieCard[0..20];
        port applyFilters : WebApiPort;
        port openMovie : WebApiPort;
    }

    part def MovieCardPage {
        attribute title : String;
        part header : Header;
        part movie : MovieCard;
        part reviews : String[0..*];
        part similarMovies : MovieCard[0..10];
        port rateMovie : WebApiPort;
        port writeReview : WebApiPort;
        port addToHistory : WebApiPort;
    }

    part def ProfilePage {
        attribute title : String = "Профиль и история";
        part header : Header;
        part preferences : String[0..*];
        part watchHistory : MovieCard[0..*];
        part myReviews : String[0..*];
        port exportData : WebApiPort;
        port deleteAccount : WebApiPort;
    }

    part def AdminPage {
        attribute title : String = "Управление каталогом";
        part header : Header;
        part movieTable : String[0..*];
        part moderationQueue : String[0..*];
        port createMovie : WebApiPort;
        port importFromTmdb : TmdbPort;
        port moderateReview : ModerationPort;
    }
}
