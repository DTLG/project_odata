# Architecture Documentation

## 🏗️ Clean Architecture Overview

Цей проект побудований за принципами Clean Architecture, що забезпечує:

- **Separation of Concerns**: Розділення відповідальностей між шарами
- **Dependency Rule**: Залежності спрямовані всередину, до domain layer
- **Testability**: Легке тестування кожного шару окремо
- **Maintainability**: Простота підтримки та розширення
- **Scalability**: Можливість масштабування проекту

## 📁 Project Structure

```
lib/
├── core/                           # Core Layer
│   ├── constants/                  # Константи додатку
│   │   └── app_constants.dart
│   ├── di/                        # Dependency Injection
│   │   └── injection_container.dart
│   ├── errors/                    # Обробка помилок
│   │   └── failures.dart
│   ├── theme/                     # Теми додатку
│   │   └── app_theme.dart
│   ├── usecases/                  # Базові use case класи
│   │   └── usecase.dart
│   ├── services/                  # Базові сервіси
│   │   └── theme_service.dart
│   └── examples/                  # Приклади архітектури
│       ├── clean_architecture_examples.dart
│       └── solid_examples.dart
├── domain/                        # Domain Layer
│   ├── entities/                  # Бізнес-об'єкти
│   │   └── user.dart
│   ├── repositories/              # Repository інтерфейси
│   │   └── user_repository.dart
│   └── usecases/                  # Use cases
│       └── get_current_user.dart
├── data/                          # Data Layer
│   ├── datasources/               # Data sources
│   │   └── user_remote_data_source.dart
│   ├── models/                    # Data models
│   │   └── user_model.dart
│   └── repositories/              # Repository реалізації
│       └── user_repository_impl.dart
└── presentation/                  # Presentation Layer
    ├── blocs/                     # Business Logic Components
    │   └── user_bloc.dart
    ├── pages/                     # UI сторінки
    │   └── home_page.dart
    └── widgets/                   # Перевикористовувані віджети
        ├── api_demo_card.dart
        └── theme_switcher.dart
```

## 🔄 Data Flow

```
UI (Presentation) → BLoC → Use Case → Repository → Data Source → API/Database
     ↑                                                              ↓
     ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

## 🎯 Layer Responsibilities

### Core Layer
- **Constants**: Глобальні константи додатку
- **DI**: Налаштування залежностей
- **Errors**: Централізована обробка помилок
- **Theme**: UI теми та стилі
- **Services**: Базові сервіси (theme, storage, etc.)

### Domain Layer
- **Entities**: Бізнес-об'єкти без залежностей
- **Repositories**: Інтерфейси для доступу до даних
- **Use Cases**: Бізнес-логіка додатку

### Data Layer
- **Models**: Моделі даних з JSON серіалізацією
- **Data Sources**: Конкретні реалізації для отримання даних
- **Repository Impl**: Реалізації repository інтерфейсів

### Presentation Layer
- **BLoCs**: Управління станом та бізнес-логікою UI
- **Pages**: UI сторінки
- **Widgets**: Перевикористовувані UI компоненти

## 🔧 SOLID Principles Implementation

### 1. Single Responsibility Principle (SRP)
- Кожен клас має одну відповідальність
- `UserValidator` - тільки валідація
- `UserRepository` - тільки доступ до даних

### 2. Open/Closed Principle (OCP)
- Відкритий для розширення через наслідування
- Закритий для модифікації існуючого коду

### 3. Liskov Substitution Principle (LSP)
- Підкласи можуть замінювати базові класи
- Repository implementations замінюють repository interfaces

### 4. Interface Segregation Principle (ISP)
- Розділення великих інтерфейсів на менші
- `UserRepository` має тільки необхідні методи

### 5. Dependency Inversion Principle (DIP)
- Залежності від абстракцій, а не від конкретних класів
- Use cases залежать від repository interfaces

## 🎨 Theme System

### Color Palette
- **Primary**: Dark Red (#8B0000)
- **Secondary**: Sea Green (#2E8B57)
- **Accent**: Gold (#FFD700)

### Theme Features
- Світла та темна теми
- Автоматичне збереження налаштувань
- Material 3 дизайн
- Консистентні стилі для всіх компонентів

## 🚀 Getting Started

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Explore the Code**
   - Start with `main.dart`
   - Check `core/theme/app_theme.dart` for theming
   - Review `presentation/pages/home_page.dart` for UI
   - Examine `core/examples/` for architecture examples

## 🧪 Testing Strategy

- **Unit Tests**: Для use cases та repositories
- **Widget Tests**: Для UI компонентів
- **Integration Tests**: Для повного flow додатку

## 📚 Best Practices

1. **Always use interfaces** для repositories та data sources
2. **Implement proper error handling** з custom failure classes
3. **Use dependency injection** для loose coupling
4. **Follow naming conventions** для консистентності
5. **Write tests** для критичної бізнес-логіки

## 🔮 Future Enhancements

- Local storage з Hive або SQLite
- State management з Riverpod або Bloc
- Network layer з Retrofit або Dio
- Code generation з build_runner
- Internationalization (i18n) підтримка
