# IntelliDent - Internship Tasks Portfolio

## Project Overview
This project is part of the IntelliDent Internship, focusing on creating a professional, medical-grade mobile application using Flutter. The application maintains a consistent high-fidelity UI that aligns with the brand's identity across all features.

---

## Project Organization & Directory Structure

To ensure scalability and maintainability, the project follows a **Feature-First Architecture**. Each task is isolated within its own module, allowing for independent development while maintaining global consistency.

```text
lib/
├── features/
│   ├── onboarding/      # Task 1: Onboarding Flow
│   ├── auth/            # Task 2: Login & Authentication
│   └── dental_tips/     # Task 3: Knowledge Base (JSON Data)
├── main.dart            # Application Entry Point
assets/
├── images/              # Branded Image Assets
└── data/                # Local JSON Data (dental_tips.json)
```

By organizing the project this way, all three tasks are seamlessly integrated into a single application yet remain perfectly organized and easy to navigate for any developer or instructor.

---

## Task 1: Onboarding Screens (UI + Navigation)

### Objective
Evaluate UI layout, navigation basics, and brand consistency by creating a professional 3-screen onboarding flow.

### Implementation Details
I implemented a high-fidelity 3-screen onboarding process that guides users through the app's core value propositions.
* **Navigation Logic**: Includes "Skip", "Next", "Back", and "Get Started" functionality.
* **Visual Identity**: Circular brand imagery clipped from square assets for a polished look.
* **Animated Indicators**: Expanding pill-shaped dots to track user progress.

#### Files Associated:
* **`onboarding_screen.dart`**: The main navigation controller.
* **`onboarding_page.dart`**: Defines the visual layout of individual pages.
* **`onboarding_list.dart` & `onboarding_data.dart`**: Manages the data layer.

---

## Task 2: Login Screen with Form Validation

### Objective
Test form handling, sophisticated validation logic, and professional entry-point UI/UX.

### Implementation Details
A secure login interface featuring a centered "floating card" design with the following enhancements:
* **Strict Validation**: Email format verification (Regex) and an exact 6-character alphanumeric password requirement.
* **User Feedback**: Specific, clear error messages for individual validation failures.
* **Success State**: A dedicated success page to provide positive reinforcement after authentication.

#### Files Associated:
* **`login.dart`**: The primary login interface with integrated validation logic.
* **`login_sucessful_page.dart`**: High-fidelity success screen.

---

## Task 3: Dental Tips List (Local JSON Data)

### Objective
Assess data parsing, local asset management, and master-detail navigation.

### Implementation Details
This feature serves as a repository of knowledge for users, utilizing local data parsing for high performance.
* **Local Data Storage**: A `dental_tips.json` file containing 8 professionally written dental care tips.
* **Data Modeling**: A dedicated `DentalTip` model with factory constructors for robust JSON-to-Object parsing.
* **Master-Detail Flow**: A scrollable list of tips that navigates to a rich detail view upon selection.

#### ✨ Beyond the Requirements (Extra Features):
* **Dental Tips Landing Screen**: I added a dedicated landing page with a call-to-action ("Get Tips") to create a more immersive user journey.
* **Professional List Tiles**: Instead of basic list items, I designed custom-elevated cards with branded icon containers.
* **Detail Sectioning**: The detail screen includes a "Recommendation" card and a high-end "Got it, Thanks!" button for better UX.

#### Files Associated:
* **`dental_tips.json`**: The source of truth for the tips.
* **`dental_tip_model.dart`**: The data model for type-safe parsing.
* **`dental_tips_landing_screen.dart`**: The entry point for the feature.
* **`dental_tips_list_screen.dart`**: The scrollable master list.
* **`dental_tip_detail_screen.dart`**: The immersive information view.

---

### Technical Excellence & UI Highlights

* **Brand Integrity**: Every screen strictly adheres to the IntelliDent palette: **Deep Blue (#0077B6)**, **Light Blue (#48CAE4)**, and **Accent Blue (#90E0EF)**.
* **Zero Overflow Architecture**: Uses `LayoutBuilder`, `SingleChildScrollView`, and `ConstrainedBox` to ensure a perfect fit on all device sizes.
* **Premium Styling**: Multi-layered shadows, custom gradients, and immersive typography (Weights: 900) used for a high-end medical app feel.
* **Clean Code**: Adherence to DRY (Don't Repeat Yourself) principles and proper separation of concerns.

---

**Developed by: Areesha Soomro**
**IntelliDent Internship - All Tasks (1, 2, & 3) Completed.**
