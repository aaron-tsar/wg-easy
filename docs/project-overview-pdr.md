# Project Overview & Product Development Requirements (PDR)

## Project Overview
`wg-easy` is an all-in-one, self-hosted solution for managing WireGuard VPN servers with ease through a user-friendly web interface. It simplifies the setup, configuration, and management of WireGuard clients, making VPN administration accessible to users without deep technical expertise.

**Goals:**
- Provide a simple, intuitive web interface for WireGuard management.
- Automate common WireGuard configuration tasks.
- Ensure a secure and robust VPN solution.
- Offer multi-language support for global accessibility.
- Support various deployment methods, primarily Docker.

**Target Users:**
- System administrators looking for an easy way to manage WireGuard VPNs.
- Individuals and small businesses needing a secure, self-hosted VPN solution.
- Developers seeking a convenient tool for secure remote access.

## Product Development Requirements (PDR)

### Functional Requirements
- **Client Management:**
    - Create, read, update, and delete WireGuard clients.
    - Generate QR codes for client configuration.
    - Generate one-time links for client configuration download.
    - Configure client bandwidth limits (enable/disable, download, upload).
- **Server Configuration:**
    - Configure WireGuard interface settings (e.g., CIDR, MTU, DNS).
    - Manage pre/post-up/down hooks.
- **Authentication:**
    - User registration and login.
    - Two-Factor Authentication (TOTP) support.
- **Internationalization:**
    - Support for 16 locales (i18n).
- **Monitoring:**
    - Display VPN client metrics (data transfer, last handshake).
    - Prometheus and JSON metrics endpoints.
- **Setup Wizard:**
    - Guided initial setup process for new installations.
- **AmneziaWG Support:**
    - Integration with AmneziaWG for enhanced features.

### Non-Functional Requirements
- **Performance:**
    - Responsive web UI.
    - Efficient WireGuard configuration application.
- **Security:**
    - Secure password hashing (Argon2).
    - Role-Based Access Control (RBAC).
    - Protection against common web vulnerabilities.
- **Usability:**
    - Intuitive and clean user interface.
    - Clear error messages and feedback.
- **Maintainability:**
    - Clean codebase with clear separation of concerns.
    - Comprehensive documentation.
- **Scalability:**
    - Designed to manage a moderate number of VPN clients.
- **Compatibility:**
    - Runs effectively within Docker environments.
    - Compatible with modern web browsers.

## Key Features List
- WireGuard client CRUD operations.
- QR code generation for quick client setup.
- One-time links for secure configuration sharing.
- 2FA/TOTP for enhanced security.
- Multi-language support (16 locales).
- Real-time client metrics dashboard.
- Prometheus and JSON metric endpoints.
- Integrated setup wizard.
- Docker-first deployment.
- AmneziaWG support.

## Tech Stack Summary
- **Frontend**: Nuxt 3, Vue 3, Pinia (state management), Tailwind CSS (styling), Radix Vue (UI components).
- **Backend**: Nitro/H3 (server framework), Drizzle ORM (database abstraction), SQLite (database).
- **Containerization**: Docker.
- **Version Control**: Git.
- **CI/CD**: GitHub Actions.
- **VPN Core**: WireGuard, AmneziaWG.
