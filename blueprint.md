# Ezer Fresh MVP Blueprint

## 1. Overview

Ezer Fresh is a Flutter-based mobile application for a fresh produce delivery service. This MVP (Minimum Viable Product) will provide core functionalities for three user roles: customers, drivers, and administrators. The application will be built using Flutter and Firebase, with a focus on a clean, scalable, and production-ready architecture.

**Business Goal:** To provide a seamless and efficient platform for ordering fresh fruits, vegetables, herbs, and spices.

**Target Audience:**
-   **Customers:** Individuals and families looking for a convenient way to purchase fresh produce.
-   **Drivers:** Delivery personnel responsible for transporting orders.
-   **Admins:** Business owners or managers who oversee the entire operation.

## 2. Core Technologies

-   **UI Framework:** Flutter
-   **Backend & Database:** Firebase (Authentication, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging)
-   **State Management:** Riverpod
-   **Routing:** GoRouter

## 3. Features & Implementation Plan

### 3.1. Authentication
-   [x] Single registration and login page.
-   [x] Firebase Authentication for user management.
-   [x] Store user roles and additional information in a `users` collection in Cloud Firestore.
-   [x] Role-based routing after login using GoRouter.

### 3.2. Customer Features
-   [x] **Home Screen:**
    -   Greeting section
    -   Search bar
    -   Featured products
    -   Categories section
    -   Popular products
    -   Cart icon with item count
-   [x] **Product System:**
    -   View products by category.
    -   Search and filter products.
    -   Detailed product page with image, description, price, and unit.
    -   Add to cart with a quantity selector.
-   [x] **Cart System:**
    -   View and manage items in the cart.
    -   Update item quantities.
    -   Calculate and display the total price.
    -   "Checkout" button.
-   [x] **Checkout:**
    -   Enter delivery address and phone number.
    -   "Cash on Delivery" as the only payment method for the MVP.
-   [x] **Orders:**
    -   Place an order.
    -   View order history with status tracking.
-   [x] **Bottom Navigation:**
    -   Home, Categories, Cart, Orders, Profile.

### 3.3. Driver Features
-   [x] **Driver Dashboard:**
    -   View a list of assigned orders.
    -   Accept or reject orders.
    -   Update delivery status (e.g., "Picked Up," "On the Way," "Delivered").
    -   View completed deliveries.

### 3.4. Admin Features
-   [x] **Admin Dashboard:**
    -   Overview of key metrics (e.g., total orders, pending orders).
-   [x] **Product Management:**
    -   CRUD (Create, Read, Update, Delete) operations for products.
    -   Upload product images to Firebase Storage.
    -   Update stock and price.
-   [x] **Order Management:**
    -   View all orders.
    -   Update order status.
    -   Assign drivers to orders.
    -   Cancel orders.

## 4. Project Structure

```
lib/
  core/
    constants/
    models/
    providers/
    services/
    utils/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    customer/
      presentation/
    driver/
      presentation/
    admin/
      presentation/
    products/
      data/
      domain/
      presentation/
    orders/
      data/
      domain/
      presentation/
    cart/
      data/
      domain/
      presentation/
    categories/
      data/
      domain/
      presentation/
  main.dart
```

## 5. Data Models

-   **User:** `uid`, `name`, `phone`, `email`, `role`
-   **Product:** `id`, `name`, `category`, `price`, `unit`, `description`, `image`, `stock`, `isAvailable`
-   **Order:** `orderId`, `customerId`, `driverId`, `items`, `totalPrice`, `status`, `paymentMethod`, `deliveryAddress`, `createdAt`
-   **Category:** `id`, `name`
-   **CartItem:** `productId`, `quantity`

## 6. UI/UX Design

-   **Theme:** Clean, modern, and fresh, with a green and organic color palette.
-   **Layout:** Responsive and intuitive layouts for all user roles.
-   **Components:** A library of reusable widgets for consistency.
-   **Feedback:** Loading indicators, empty states, and error messages.

## 7. Current Task

The current task is to set up the initial project structure, including creating the necessary folders and files for the Ezer Fresh application. I will then proceed with adding the required dependencies to the `pubspec.yaml` file.
