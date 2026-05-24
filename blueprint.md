# Ezer Fresh - Application Blueprint

## Overview

Ezer Fresh is a modern, clean, and intuitive mobile application for ordering fresh groceries online. It provides a seamless user experience, from browsing products to placing orders and managing user profiles. The application is built with Flutter and leverages Firebase for backend services, ensuring a scalable and reliable platform.

## Project Documentation

This section outlines the style, design, and features implemented in the application from the initial version to the current version.

### Core Technologies & Architecture

- **Framework:** Flutter
- **Backend:** Firebase (Authentication, Firestore)
- **State Management:** Riverpod
- **Routing:** `go_router` for declarative navigation.
- **Architecture:** The project follows a feature-first structure, with a clear separation of concerns between the presentation, domain, and data layers.

### Key Features Implemented

1.  **User Authentication:**
    -   A simple login screen allows users to sign in.
    -   Firebase Authentication is used to manage user sessions.

2.  **Navigation:**
    -   A modern, animated bottom navigation bar (`google_nav_bar`) provides easy access to the main screens: Home, Cart, Orders, and Profile.
    -   The navigation is managed by `go_router` which supports deep linking and nested navigation.

3.  **Home Screen:**
    -   Displays a list of product categories.
    -   Serves as the main entry point of the application.

4.  **Product & Category Views:**
    -   Users can tap a category on the home screen to view a list of products within that category.

5.  **Profile Management (Onboarding Flow):**
    -   **Profile Screen:** A dedicated screen for users to view their profile information.
    -   **Onboarding for New Users:** If a user has not created a profile, they are presented with an onboarding screen (`CreateProfileScreen`) to enter their name, contact information, and address.
    -   **Profile Editing:** Existing users can edit their profile information.
    -   **Data Persistence:** User profile data is securely stored in Firestore.

6.  **Orders Screen:**
    -   A placeholder screen for users to view their past and current orders.

7.  **Cart Screen:**
    -   A placeholder screen for the user's shopping cart.

### Design & UI/UX

- **Visual Style:** The app aims for a clean, modern aesthetic with a focus on usability.
- **Component Library:** Utilizes Material Design components, enhanced with custom styling and animations.
- **Navigation:** The use of `google_nav_bar` provides a visually appealing and interactive navigation experience.

## Current Task

**Task:** Complete the profile and onboarding features.

**Status:** **Completed.**

- **Steps Taken:**
    1.  Created the `CreateProfileScreen` for user onboarding.
    2.  Updated the `ProfileScreen` to check for existing profiles and display either the user's data or a prompt to create a profile.
    3.  Added an "Edit" functionality for existing profiles.
    4.  Integrated with Firestore to save and retrieve user profile data.
    5.  Updated the `go_router` configuration to include the new `CreateProfileScreen` route.
