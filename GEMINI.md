# Thief Sim Watch App

A mission-based "thief simulator" game for Apple Watch, built with SwiftUI and following Clean Architecture and Domain-Driven Design (DDD) principles.

## Project Overview

- **Purpose:** A lightweight, interactive game for Apple Watch where players perform missions in different districts, involving vent crawling, hacking, and safe cracking.
- **Architecture:** Clean Architecture + DDD.
    - **Domain:** Core entities (District, Upgrade, GameState) and services (EconomyService, MissionService, VentCrawlEngine) containing pure business logic.
    - **Infrastructure:** Implementation of device-specific features (HapticFeedbackProvider) and data persistence (StaticGameDataRepository).
    - **Application:** Orchestration layer using `AppRouter` for navigation, `GameSession` for persistent state, and `MissionCoordinator` for mission-specific lifecycles.
    - **Presentation:** Modular SwiftUI Views separated by feature (Map, Shop, Mission).
- **Core Technologies:** Swift, SwiftUI, WatchKit, Combine.

## Project Structure

- `Thief Sim Watch App/`
    - `Domain/`: Core entities, repository interfaces, and pure logic services.
    - `Infrastructure/`: Concrete repository implementations and hardware/device adapters.
    - `Application/`: State management and orchestration.
        - `AppRouter`: Manages top-level navigation (`gameState`).
        - `GameSession`: Holds persistent player data (money, unlocks, customization).
        - `MissionCoordinator`: Manages the lifecycle and shared state of a single active mission.
    - `Presentation/`: SwiftUI Views and per-phase ViewModels.
        - `Common/Components/`: Reusable UI elements (`PlayerFigureView`).
        - `Map/`, `Shop/`, `Mission/`, `Results/`: Feature-specific screens.
- `Thief Sim Watch AppTests/`: Unit tests for domain logic (e.g., `VentCrawlEngineTests`).

## Building and Running

- **Requirements:** Xcode 15+ and an Apple Watch Simulator or Device (running watchOS 10.0+).
- **Opening:** Open `Thief Sim.xcodeproj` in Xcode.
- **Running:** Select the `Thief Sim Watch App` target and a Watch simulator/device, then press `Cmd+R`.
- **Testing:** Press `Cmd+U` to run unit tests in `Thief Sim Watch AppTests`.

## Development Conventions

1. **Separation of Layers:** Do not mix business logic with UI code. UI should react to state provided by ViewModels or Coordinators.
2. **Domain-Driven:** Keep domain services (`EconomyService`, `VentCrawlEngine`) pure and framework-independent where possible.
3. **ViewModel Pattern:** Every feature/screen has its own ViewModel that prepares data for the View and handles user intent.
4. **Single Responsibility:** Each class/struct should have one clear purpose. For example, `MissionCoordinator` handles mission lifecycle, while `VentCrawlViewModel` handles only the vent-crawl minigame state.
5. **Haptics:** Always use `HapticProvider` for feedback to ensure testability and separation from `WatchKit`.
6. **Documentation:** Use short, Apple-style triple-slash (`///`) documentation for public/internal types and methods.
