# System Architecture

## High-Level Architecture Diagram

```
+-------------------+
|     User (Browser)|
+---------+---------+
          | HTTPS
          v
+---------+---------+
|     Frontend      |
|   (Nuxt 3 / Vue)  |
+---------+---------+
          | API (JSON)
          v
+---------+---------+
|     Backend       |
|  (Nitro / H3)     |
+---------+---------+
          | DB Reads/Writes
          v
+---------+---------+
|    SQLite DB      |
+---------+---------+
          | WireGuard Mgmt
          v
+---------+---------+
|  WireGuard Kernel |
|    (wg-quick)     |
+---------+---------+
          | VPN Tunnel
          v
+-------------------+
|  Remote Clients   |
+-------------------+
```

## Frontend Architecture (Nuxt 3, Pinia, Components)

The frontend is built with Nuxt 3, leveraging its full-stack capabilities including server-side rendering (SSR) and automatic routing.

-   **Nuxt 3**: Provides the framework for routing, SSR, and developer experience.
-   **Vue 3**: Reactive UI library for building user interfaces.
-   **Pinia**: A lightweight and intuitive state management library for Vue.js, used to manage global application state (e.g., authentication status, client lists, global settings).
-   **Components**: Organized into reusable UI elements and feature-specific components.
    -   `Base/`: Generic, atomic components (buttons, inputs, dialogs).
    -   `Form/`: Components for building forms (text fields, number fields).
    -   Feature-specific directories (e.g., `Clients/`, `Admin/`, `ClientCard/`) for grouping related components.
-   **Tailwind CSS**: Utility-first CSS framework for styling, enabling rapid UI development and consistent design.
-   **Radix Vue**: Headless UI components providing accessibility and unstyled primitives, which are then styled with Tailwind CSS.
-   **Composables**: Vue 3's Composition API is heavily utilized to encapsulate and reuse reactive logic across components.

## Backend Architecture (Nitro, Drizzle, SQLite)

The backend is powered by Nitro, Nuxt's server engine, which provides a fast and flexible API layer.

-   **Nitro/H3**: Minimalist, high-performance server framework for handling API requests and server-side logic. It allows defining API routes easily (e.g., `api/**/*.ts`).
-   **Drizzle ORM**: A modern TypeScript ORM used for interacting with the SQLite database. It provides a type-safe way to define schemas, perform queries, and manage migrations.
-   **SQLite**: A lightweight, file-based relational database used for storing application data (users, clients, interfaces, settings). It's ideal for self-hosted applications due to its zero-configuration nature.
-   **API Endpoints**: Categorized by resource and functionality (e.g., `/api/admin/*`, `/api/client/*`, `/api/session`).
-   **`wgHelper.ts` / `WireGuard.ts`**: Core utility modules responsible for interacting with the underlying WireGuard system, generating keys, configuring interfaces, and managing client connections.
-   **Session Management**: Handled via secure HTTP-only cookies and managed by backend utilities.

## Database Schema Overview

The database uses SQLite and is managed by Drizzle ORM. Key tables include:

-   `users_table`: Stores user authentication details (username, hashed password, TOTP key), roles, and personal information.
-   `interfaces_table`: Holds configuration for WireGuard server interfaces (name, device, port, keys, CIDR, MTU).
-   `clients_table`: Stores details for each WireGuard client (user association, interface association, name, IPs, keys, allowed IPs, DNS).
-   `one_time_links_table`: Manages secure, temporary links for client configuration downloads.
-   `general_table`: Stores general application settings, setup step, session settings, metrics settings, and bandwidth limiting configurations (`bandwidthEnabled`, `downloadLimitMbps`, `uploadLimitMbps`).
-   `hooks_table`: Defines pre-up/post-up/pre-down/post-down scripts for the WireGuard interface.
-   `user_configs_table`: Stores default client settings per interface.

## API Design Patterns

-   **RESTful Principles**: APIs generally follow RESTful conventions, using standard HTTP methods (GET, POST, PUT, DELETE) for resource manipulation.
-   **JSON Payloads**: Request and response bodies are typically JSON.
-   **Authentication**: Session-based authentication with secure cookie management. Admin and user roles enforce access control.
-   **Error Handling**: Consistent error response structures with appropriate HTTP status codes.
-   **Versioning**: Implicitly handled by the current single API version; explicit versioning can be introduced if needed.

## Security Architecture

-   **Password Hashing**: User passwords are securely hashed using Argon2 (via `argon2id`).
-   **Two-Factor Authentication (TOTP)**: Integration of Time-based One-Time Passwords for enhanced login security.
-   **Role-Based Access Control (RBAC)**: Different user roles (e.g., `admin`, `user`) have varying permissions to access API endpoints and functionalities.
-   **Session Management**: Secure, HTTP-only cookies are used for session tokens, reducing the risk of XSS attacks.
-   **Input Validation**: Strict validation of all incoming API request data to prevent injection attacks and ensure data integrity.
-   **Environment Variables**: Sensitive configuration is managed through environment variables, not hardcoded.
-   **WireGuard Security**: Leverages the inherent cryptographic strength of the WireGuard protocol itself.
-   **Containerization**: Running in Docker provides process isolation and a more controlled environment.
