# StudentHub – Student Management System

## Project Documentation

**Project Name:** StudentHub
**Project Type:** Full-Stack Multi-Organization Student Management System
**Frontend:** Flutter
**Backend:** ASP.NET Core Web API (.NET 8)
**Database:** PostgreSQL
**ORM:** Entity Framework Core
**Authentication:** JWT Bearer Authentication
**API Documentation & Testing:** Swagger / OpenAPI
**Frontend Platform:** Flutter Web, with cross-platform Flutter architecture for Android/iOS/Web

---

# 1. Project Overview

StudentHub is a full-stack Student Management System designed for educational organizations.

The main purpose of the system is to provide one platform where organizations can manage:

* Students
* Courses
* Teachers
* Staff
* Assignments
* Assignment PDF files
* Assignment submissions
* Assignment grading
* Academic grades
* Attendance
* Notifications
* Student profiles
* Password management
* Organization users

The system is designed as a **multi-organization application**.

This means multiple organizations can use the same application while their data remains completely separated.

For example:

```text
Organization A
    ├── Admin
    ├── Teachers
    ├── Staff
    ├── Students
    ├── Courses
    ├── Assignments
    └── Grades

Organization B
    ├── Admin
    ├── Teachers
    ├── Staff
    ├── Students
    ├── Courses
    ├── Assignments
    └── Grades
```

Users from Organization A must never be able to access Organization B's private data.

This organization-level security is enforced by the backend and is not dependent only on the Flutter UI.

---

# 2. Main Project Goal

The project was initially started as a Student Management application.

The project was then expanded into a complete full-stack system with:

* Authentication
* Role-based access
* Multi-organization support
* Student management
* Course management
* Assignment management
* PDF attachment support
* Assignment submissions
* Academic grades
* Attendance
* Notifications
* Profile management
* Password management
* Organization management
* Security and authorization

The final goal was to create a project suitable for:

1. Real-world learning
2. Full-stack development practice
3. Flutter development demonstration
4. Backend API development demonstration
5. Database design demonstration
6. Authentication and authorization demonstration
7. Technical interview/demo presentation

---

# 3. Why This Technology Stack Was Chosen

The frontend uses Flutter because Flutter allows the same application architecture to target multiple platforms.

The backend uses ASP.NET Core Web API because it provides a structured and reliable way to build REST APIs.

PostgreSQL was selected as the relational database.

Entity Framework Core is used to communicate with PostgreSQL from the ASP.NET Core backend.

JWT authentication is used so the frontend can securely communicate with protected backend APIs.

The complete architecture is:

```text
Flutter Application
        │
        │ HTTP / REST API
        ▼
ASP.NET Core Web API
        │
        │ Entity Framework Core
        ▼
PostgreSQL Database
```

---

# 4. Technology Stack

## Frontend

* Flutter
* Dart
* Material UI
* HTTP package
* Flutter Secure Storage
* File Picker
* Syncfusion PDF Viewer

## Backend

* ASP.NET Core Web API
* .NET 8
* C#
* Entity Framework Core
* JWT Bearer Authentication
* REST APIs
* Swagger / OpenAPI

## Database

* PostgreSQL
* PostgreSQL database created for the project:
  `StudentManagementDB`

## Development Tools

* Android Studio
* Visual Studio Code
* .NET SDK
* pgAdmin
* Swagger
* Chrome for Flutter Web testing

---

# 5. System Architecture

StudentHub follows a client-server architecture.

The Flutter application is responsible for:

* User interface
* Navigation
* User interaction
* Form validation
* API requests
* Token storage
* Displaying API responses
* Loading states
* Error states
* Empty states

The ASP.NET Core Web API is responsible for:

* Business logic
* Authentication
* Authorization
* Role validation
* Organization isolation
* Database operations
* CRUD operations
* File handling
* Notification creation
* Security checks

PostgreSQL is responsible for persistent storage.

The architecture can be represented as:

```text
                    ┌──────────────────────┐
                    │      Flutter UI      │
                    │   StudentHub App     │
                    └──────────┬───────────┘
                               │
                               │ HTTP
                               ▼
                    ┌──────────────────────┐
                    │ ASP.NET Core Web API │
                    │       .NET 8         │
                    └──────────┬───────────┘
                               │
                         EF Core
                               │
                               ▼
                    ┌──────────────────────┐
                    │      PostgreSQL      │
                    │  StudentManagementDB │
                    └──────────────────────┘
```

---

# 6. Frontend Architecture

The Flutter application is organized around screens, services, storage, assignments, dashboards and other feature areas.

A simplified structure is:

```text
student_management_app/
│
├── lib/
│   │
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── employee_dashboard_screen.dart
│   │   ├── student_dashboard_screen.dart
│   │   ├── super_admin_dashboard_screen.dart
│   │   └── ...
│   │
│   ├── services/
│   │   ├── auth_api_service.dart
│   │   ├── token_storage.dart
│   │   ├── student_api_service.dart
│   │   ├── notification_api_service.dart
│   │   └── ...
│   │
│   ├── assignments/
│   │   ├── assignments_screen.dart
│   │   ├── student_assignments_screen.dart
│   │   └── ...
│   │
│   ├── theme/
│   │   └── app_theme.dart
│   │
│   ├── auth_gate.dart
│   └── main.dart
│
└── ...
```

The exact project folder structure has continued to grow as new modules were added, but the main principle is to keep UI screens and API/service logic separated.

---

# 7. Backend Architecture

The backend is an ASP.NET Core Web API project.

Backend project:

```text
StudentManagement.API
```

Main responsibilities include:

```text
Controllers
    ↓
Business / API Logic
    ↓
Entity Framework Core
    ↓
PostgreSQL
```

Important backend areas include:

* Authentication
* Users
* Organizations
* Students
* Courses
* Assignments
* Student Assignments
* Academic Grades
* Attendance
* Notifications

The API uses controllers to expose REST endpoints.

---

# 8. Database

The application uses PostgreSQL.

Database:

```text
StudentManagementDB
```

The database stores the application's persistent data including users, organizations, students, courses, assignments, grades, attendance and notifications.

Entity Framework Core is used as the ORM.

The basic database communication flow is:

```text
Flutter
   ↓
API Controller
   ↓
Entity Framework Core
   ↓
PostgreSQL
```

---

# 9. Entity Framework Core

Entity Framework Core is used to map C# models to PostgreSQL database tables.

It handles:

* Database access
* Queries
* Inserts
* Updates
* Deletes
* Relationships
* Transactions
* Database migrations

The project also uses EF Core migrations to keep the database structure synchronized with the application models.

---

# 10. Authentication

StudentHub uses JWT-based authentication.

The login process is:

```text
User enters email + password
          ↓
Flutter sends login request
          ↓
ASP.NET Core validates credentials
          ↓
Backend creates JWT
          ↓
Backend returns token + user information
          ↓
Flutter stores JWT securely
          ↓
User enters application
```

The JWT is sent with protected API requests using:

```text
Authorization: Bearer <token>
```

---

# 11. Secure Token Storage

Flutter uses secure storage for authentication information.

Important stored information includes:

```text
jwt_token
user_data
```

The token is stored using Flutter Secure Storage.

User information is also stored so the application can restore the user's session after restarting.

---

# 12. Authentication Service

The Flutter application contains:

```text
AuthApiService
```

This service handles authentication-related API operations.

Important operations include:

* Login
* Get token
* Get saved user
* Check login status
* Check JWT expiry
* Logout
* Register
* Register organization
* Change password

The service communicates with:

```text
http://localhost:5083/api/Auth
```

during development.

---

# 13. JWT Expiry Handling

The application checks the JWT expiration time.

When the application starts:

```text
Get saved token
       ↓
Does token exist?
       ↓
Check JWT expiry
       ↓
If expired → logout
       ↓
If valid → restore session
```

This prevents an expired authentication token from being treated as an active session.

---

# 14. Authentication Gate

The Flutter application uses an `AuthGate`.

Its responsibility is to determine what should appear when the application starts.

The startup flow is:

```text
Application starts
       ↓
AuthGate
       ↓
Check saved JWT
       ↓
Is token valid?
       │
       ├── No → Login Screen
       │
       └── Yes
             ↓
        Read saved user role
             ↓
        Open correct dashboard
```

The application now restores each user's correct dashboard after restart or hot restart.

---

# 15. Role-Based Access

StudentHub has the following roles:

```text
SuperAdmin
Admin
Teacher
Staff
User / Student
```

Each role has a different purpose.

---

# 16. SuperAdmin

There is one global SuperAdmin for the application.

The SuperAdmin is not created separately for every organization.

The SuperAdmin can manage the overall system.

SuperAdmin functionality includes:

* View organizations
* View organization information
* View organization creator information
* View organization users
* View user emails
* View courses
* View students
* Delete individual users
* Delete an organization
* Manage global organization-level information

The SuperAdmin is above individual organizations.

Conceptually:

```text
                 SuperAdmin
                     │
          ┌──────────┴──────────┐
          │                     │
    Organization A        Organization B
```

---

# 17. Organization Admin

Each organization has its own Admin.

The Admin manages their own organization.

Admin responsibilities include:

* Manage students
* Manage courses
* Manage users
* Create Teacher accounts
* Create Staff accounts
* Create normal User accounts
* Manage assignments
* Manage academic information
* Manage organization data

Admin-created users automatically belong to the Admin's organization.

---

# 18. Teacher

Teacher accounts are created by an organization Admin.

Teachers do not publicly register themselves.

Teacher functionality includes access to organization-specific academic features such as:

* Courses
* Assignments
* Assignment PDFs
* Assignment submissions
* Assignment grading
* Notifications
* Academic information

Teacher accounts inherit the Admin's organization.

---

# 19. Staff

Staff accounts are also created by the organization Admin.

Staff accounts inherit the Admin's organization.

Staff use the common Employee Dashboard.

Staff access is limited to the data allowed for their organization and role.

---

# 20. Normal User / Student

Normal users/students use the Student Dashboard.

Students can access their own academic information such as:

* Courses
* Assignments
* Assignment PDFs
* Assignment submissions
* Grades
* Attendance
* Notifications
* Profile
* Password management

Students should only see their own permitted information and organization data.

---

# 21. Role-Based Dashboard Routing

The application uses role-based dashboard routing.

Current behavior:

```text
SuperAdmin
    ↓
SuperAdminDashboardScreen

Admin
    ↓
DashboardScreen

Teacher
    ↓
EmployeeDashboardScreen

Staff
    ↓
EmployeeDashboardScreen

User / Student
    ↓
StudentDashboardScreen
```

This routing works both:

* After login
* After application restart / hot restart

The saved role is read from the saved user information.

---

# 22. Multi-Organization Architecture

One of the most important parts of StudentHub is multi-organization support.

The application can contain multiple organizations.

Each organization has its own:

* Users
* Students
* Courses
* Assignments
* Academic data
* Attendance
* Notifications

Example:

```text
Organization 1
    ├── Admin 1
    ├── Teacher 1
    ├── Staff 1
    ├── Student 1
    └── Course A

Organization 2
    ├── Admin 2
    ├── Teacher 2
    ├── Staff 2
    ├── Student 2
    └── Course B
```

Organization 1 users must not access Organization 2 data.

---

# 23. Organization Isolation

Organization isolation is enforced on the backend.

This is important because hiding data in Flutter alone is not secure.

The backend uses the authenticated user's organization information to restrict database queries and API operations.

The JWT contains organization-related identity information.

The backend reads the user's organization claim and uses it to enforce organization boundaries.

The important JWT claim used by the application is:

```text
OrganizationId
```

The backend then ensures that requests operate only on the user's allowed organization data.

---

# 24. Organization Security Example

Suppose:

```text
Organization A → OrganizationId = 1
Organization B → OrganizationId = 2
```

A user from Organization A sends a request.

The backend identifies:

```text
Current User → OrganizationId = 1
```

The backend must only return:

```text
OrganizationId = 1
```

data.

It must not return:

```text
OrganizationId = 2
```

data.

This security rule applies even if there are many organizations.

The system was specifically tested to verify organization separation.

---

# 25. Registration Architecture

The public registration flow is designed for creating a new organization and its first Admin.

The public registration screen does not allow arbitrary users to select an existing organization.

This prevents users from publicly joining another organization's account system.

The normal flow is:

```text
New Organization Registration
        ↓
Organization Name
        ↓
Admin Full Name
        ↓
Admin Email
        ↓
Password
        ↓
Create Organization
        ↓
Create First Admin
```

Teacher, Staff and normal User accounts are created by the organization's Admin.

---

# 26. Student Management

Student management is one of the core modules.

The system supports student CRUD operations.

CRUD means:

```text
Create
Read
Update
Delete
```

The backend exposes student API operations.

Examples include:

```text
GET    /api/Students
GET    /api/Students/{id}
POST   /api/Students
PUT    /api/Students/{id}
DELETE /api/Students/{id}
```

The exact available endpoints may include additional authenticated operations such as retrieving the current student's own information.

---

# 27. Student Profile

Students can manage their profile information.

Profile functionality includes:

* View profile
* Edit profile
* Change profile picture
* Change password

The profile experience is integrated into the Student Dashboard.

---

# 28. Profile Picture

Student profile picture functionality was added to allow students to change their profile image.

The UI displays the student's profile picture where appropriate.

The existing profile functionality was tested after implementation.

---

# 29. Course Management

Courses are organization-specific.

Admins can manage courses.

Students can see the courses available to them.

Teachers and staff can work with courses according to their role.

Course data is protected by organization isolation.

Course assignment to students can also generate a notification.

---

# 30. Assignments

The assignment system allows teachers/staff to create academic assignments.

Assignment functionality includes:

* Create assignment
* Edit assignment
* View assignment
* Assignment details
* PDF attachment
* Student submission
* Submission review
* Grading
* Feedback
* Notifications

The assignment system is connected with the notification system.

---

# 31. Assignment PDF Attachments

Teachers/staff can attach PDF files to assignments.

The workflow is:

```text
Teacher/Staff
     ↓
Create/Edit Assignment
     ↓
Select PDF
     ↓
Save Assignment
     ↓
Student receives assignment
     ↓
Student opens assignment
     ↓
Student views attached PDF
```

Flutter uses a PDF viewer to display the assignment attachment.

The student can open the PDF from the assignment detail interface.

---

# 32. Assignment Submissions

Students can submit assignments.

The system supports a student submission flow.

The assignment detail area contains a:

```text
Your Submission
```

section.

Students can submit their work and teachers/staff can review the submission.

The submission system also supports submitted PDF viewing where applicable.

---

# 33. Assignment Grading

Teachers/staff can review student submissions and provide:

* Grade
* Feedback

When an assignment is graded, the student can receive a notification.

The student can then open the relevant assignment from the notification.

---

# 34. Academic Grades

StudentHub contains an Academic Grades module.

Academic grades can be added and updated.

Teachers/staff can work with grades according to their permissions.

Students can view their academic grades from the Student Dashboard.

The system calculates and displays academic performance information such as averages.

Example:

```text
Mid-Term: 90/100
Final:    95/100
Average:  92.5/100
```

Academic grade notifications can also be generated when a grade is added or updated.

---

# 35. Course Academic Grades

The project also contains course-level academic grade management.

The course grade screen provides:

* Student list
* Grades
* Average
* Performance information
* Edit grade
* Delete grade

The UI was redesigned to provide a cleaner academic gradebook-style experience while preserving the existing functionality.

The grade table supports vertical and horizontal scrolling for larger student lists.

---

# 36. Attendance

StudentHub includes attendance management.

Attendance is organization-specific.

Students can view their attendance information.

Attendance events can generate notifications.

For example:

```text
Teacher/Staff marks attendance
        ↓
Attendance saved
        ↓
Student notification created
```

Students can open the notification and navigate to the relevant attendance information.

---

# 37. Notification System

StudentHub uses a database-based in-app notification system.

Firebase was not used for this notification system.

Notifications are stored in PostgreSQL through the ASP.NET Core API.

The notification model contains:

```text
Notification
├── Id
├── UserId
├── OrganizationId
├── Title
├── Message
├── Type
├── IsRead
├── CreatedAt
└── RelatedId
```

---

# 38. Notification Fields

## Id

Unique notification identifier.

## UserId

Identifies the user who should receive the notification.

## OrganizationId

Identifies the organization.

This also helps maintain organization isolation.

## Title

Notification title.

## Message

Notification message.

## Type

Identifies what caused the notification.

Examples:

```text
Assignment
Grade
Attendance
Course
Submission
```

## IsRead

Tracks whether the notification has been read.

## CreatedAt

Stores when the notification was created.

## RelatedId

Stores the ID of a related record when needed.

This allows notifications to navigate directly to relevant content.

---

# 39. Notification Events

The system supports notifications for important events.

Current notification events include:

### Assignment Created

```text
Teacher creates assignment
        ↓
Enrolled students receive notification
```

### Assignment Graded

```text
Teacher grades submission
        ↓
Student receives notification
```

### Course Assigned

```text
Course assigned to student
        ↓
Student receives notification
```

### Attendance Marked

```text
Attendance marked
        ↓
Student receives notification
```

### Academic Grade Added/Updated

```text
Grade added/updated
        ↓
Student receives notification
```

### Assignment Submitted

```text
Student submits assignment
        ↓
Relevant Teacher/Staff receives notification
```

---

# 40. Notification Read System

Users can mark notifications as read.

The notification service supports:

```text
Get notifications
Mark notification as read
Mark all notifications as read
```

The Student Dashboard also displays an unread notification count/badge.

---

# 41. Notification Deep Linking

Notifications are not only simple messages.

They can navigate users to the related feature.

Examples:

```text
Academic Grade Notification
        ↓
Academic Grades Screen

Assignment Notification
        ↓
Assignments Screen
        ↓
Related Assignment

Course Notification
        ↓
Course Information

Attendance Notification
        ↓
Attendance Screen
```

This makes notifications more useful and user-friendly.

---

# 42. Employee Notifications

Teacher and Staff users also have a common notification interface.

For example, when a student submits an assignment:

```text
Student
   ↓
Submit Assignment
   ↓
Backend creates notification
   ↓
Teacher/Staff receives notification
```

The Employee Dashboard can display the user's notifications.

---

# 43. Employee Dashboard

Teacher and Staff share a common Employee Dashboard.

The dashboard is designed so that both roles can use the same general employee experience while still respecting their role permissions.

The dashboard includes organization-specific information.

The logged-in user's actual name is displayed instead of a hardcoded account label.

The dashboard reads the saved user data and displays the user's name.

---

# 44. Student Dashboard

The Student Dashboard is designed for normal User/Student accounts.

It provides access to relevant student functionality including:

* Courses
* Assignments
* Grades
* Attendance
* Notifications
* Profile
* Security/password

The dashboard is separate from Admin and Employee dashboards.

---

# 45. Admin Dashboard

The Admin Dashboard is designed for organization administrators.

The Admin can manage organization data and users.

Existing Admin functionality was preserved while new features were added.

The Admin Dashboard is intentionally separate from the Employee Dashboard.

---

# 46. SuperAdmin Dashboard

The SuperAdmin Dashboard provides global system-level visibility.

Unlike organization Admins, the SuperAdmin can work across organizations.

The SuperAdmin can inspect:

* Organizations
* Organization creators
* Users
* User emails
* Courses
* Students

The SuperAdmin can also delete individual users and organizations according to the implemented system functionality.

---

# 47. Organization Deletion

Deleting an organization is a high-level operation.

The system is designed so that deleting an organization also removes the related organization data.

This includes organization-related:

* Users
* Courses
* Students

The relationship/cascade behavior is implemented at the backend/database level where appropriate.

---

# 48. API Architecture

The Flutter application communicates with ASP.NET Core through HTTP APIs.

Examples of API areas include:

```text
/api/Auth
/api/Students
/api/Courses
/api/Users
/api/Notifications
/api/AcademicGrades
/api/StudentAssignments
```

The APIs are protected using authentication and authorization where required.

---

# 49. Authentication API

Important authentication operations include:

```text
POST /api/Auth/login
POST /api/Auth/register
POST /api/Auth/register-organization
POST /api/Auth/change-password
```

The login endpoint returns authentication information including a JWT and user information.

---

# 50. Student API

The Student API supports student management.

Typical operations include:

```text
GET
POST
PUT
DELETE
```

Student APIs also contain authenticated operations for the current student's own data.

---

# 51. Course API

The Course API manages organization-specific courses.

It supports course management and course-related student functionality.

---

# 52. User API

The User API manages organization users.

Admin users can create Teacher, Staff and normal User accounts.

The backend verifies organization ownership and authorization.

A normal User is not allowed to perform Admin-only user management operations.

This was tested using Swagger.

---

# 53. Academic Grades API

The Academic Grades API manages:

* Creating grades
* Reading grades
* Updating grades
* Deleting grades
* Student grade access
* Course-level grade access

Organization and authorization rules are applied to these operations.

---

# 54. Assignment API

The assignment API handles:

* Assignment creation
* Assignment updates
* Assignment retrieval
* Assignment deletion where supported
* PDF attachment
* Student assignment access
* Student submissions
* Submission review
* Grading
* Feedback

---

# 55. Notification API

The Notification API provides:

```text
GET /api/Notifications
PUT /api/Notifications/{id}/read
PUT /api/Notifications/read-all
```

The backend uses the authenticated user's identity and organization to control notification access.

---

# 56. Swagger / OpenAPI

Swagger is used for backend API documentation and testing.

Development Swagger endpoint:

```text
http://localhost:5083/swagger
```

Swagger was used extensively during development to:

* Test authentication
* Test JWT tokens
* Test protected endpoints
* Test CRUD APIs
* Verify authorization
* Verify organization isolation
* Test different user roles

---

# 57. JWT Testing in Swagger

The backend was tested using Swagger authentication.

The workflow is:

```text
Login through Swagger
       ↓
Receive JWT
       ↓
Authorize Swagger with Bearer token
       ↓
Call protected endpoint
       ↓
Backend validates JWT
       ↓
Endpoint executes according to role/organization
```

This made it possible to test backend authorization independently from Flutter.

---

# 58. Backend Security

Security is one of the major parts of the project.

Important security concepts implemented include:

* JWT authentication
* Role-based authorization
* Organization isolation
* Authenticated API access
* Secure token storage
* JWT expiry validation
* Password management
* Organization-aware backend queries
* Restricted Admin operations
* Restricted SuperAdmin operations

---

# 59. Password Management

The application supports password changing.

The Flutter profile/security area contains:

```text
Change Password
```

The backend endpoint is:

```text
POST /api/Auth/change-password
```

The request includes:

```text
Current Password
New Password
Confirm New Password
```

The new password is validated by the backend.

The feature was tested by changing a user's password, logging out, and successfully logging in again using the new password.

---

# 60. Logout

Logout removes the saved authentication information.

The flow is:

```text
User clicks Logout
       ↓
Delete saved JWT
       ↓
Delete saved user data
       ↓
Return to Login Screen
```

This prevents the previous user's session from being restored.

---

# 61. Session Restoration

The application supports session restoration.

If a user closes the application while logged in, the saved JWT can be checked when the application starts again.

The system now restores the correct dashboard based on the saved role.

For example:

```text
Teacher closes application
        ↓
Application starts
        ↓
Valid JWT found
        ↓
Saved role = Teacher
        ↓
Employee Dashboard
```

The same process works for:

* SuperAdmin
* Admin
* Teacher
* Staff
* Student/User

This was specifically tested after implementation.

---

# 62. Flutter API Service Architecture

Instead of placing HTTP requests directly inside every UI widget, the project uses API service classes.

Examples:

```text
AuthApiService
StudentApiService
NotificationApiService
```

This keeps API communication separate from UI code.

A typical flow is:

```text
Screen
  ↓
API Service
  ↓
HTTP Request
  ↓
ASP.NET API
  ↓
Database
```

---

# 63. Error Handling

The Flutter application handles common states such as:

* Loading
* Success
* Error
* Empty data
* Authentication failure

The backend also returns appropriate HTTP status codes for invalid or unauthorized requests.

For example, during testing, a normal User attempting an Admin-only user-management endpoint received:

```text
403 Forbidden
```

This confirmed that backend authorization was working.

---

# 64. Loading States

The UI includes loading indicators where data is being retrieved.

This prevents users from thinking the application is frozen while waiting for API responses.

The AuthGate also displays a loading indicator while checking the saved authentication state.

---

# 65. Empty States

Screens provide appropriate empty-state handling where data is not available.

Examples include:

* No assignments
* No grades
* No notifications
* No students
* No course data

The goal is to provide a clear user experience instead of showing broken or blank UI.

---

# 66. UI / UX Development

The UI was developed with a focus on:

* Clean layouts
* Simple navigation
* User-friendly interactions
* Consistent spacing
* Clear buttons
* Loading states
* Empty states
* Error messages
* Responsive layouts
* Professional dashboards

The application is being polished further as the final step of the project.

The main functionality is already implemented and tested.

---

# 67. Academic Grades UI Improvements

The Academic Grades UI was redesigned to look more professional.

The redesign included:

* Cleaner course header
* Summary cards
* Grade table
* Student avatars
* Grade badges
* Performance badges
* Better spacing
* Better visual hierarchy
* Loading state
* Empty state
* Edit/delete actions

The functionality remained unchanged.

---

# 68. Scrollable Grade Tables

Academic grade tables can contain many students.

The course grade screen uses nested scrolling so that:

* The table can scroll vertically for many students.
* The table can scroll horizontally when the table is wider than the available screen.

A runtime Scrollbar issue was discovered during development.

The unnecessary Scrollbar was removed from the relevant screen.

After this change, the runtime issue was resolved.

This demonstrates an important development principle used throughout the project:

> Fix the smallest isolated part necessary without disturbing working functionality.

---

# 69. Development Approach

The project was developed incrementally.

New functionality was added in small steps.

After each major feature:

```text
Implement
   ↓
Build / Analyze
   ↓
Run application
   ↓
Test feature
   ↓
Fix issues
   ↓
Continue
```

Existing working features were intentionally preserved when adding new functionality.

---

# 70. Testing Strategy

Testing was performed through several methods.

## Flutter Testing

The application was run through Flutter Web using Chrome.

Development command:

```text
flutter run -d chrome --web-port 5000
```

Application URL:

```text
http://localhost:5000
```

## Flutter Analyze

Flutter static analysis was used to detect:

* Compilation errors
* Type errors
* Unused code
* Other Dart issues

The project reached a state where:

```text
No issues found!
```

was reported after relevant changes.

## Backend Build

The ASP.NET Core backend was built using:

```text
dotnet build
```

The backend reached:

```text
0 warnings
0 errors
```

during successful builds.

## Swagger Testing

Swagger was used to test APIs independently.

## Manual UI Testing

Different accounts and roles were used to test real application flows.

---

# 71. Role Testing

The following roles were tested:

```text
SuperAdmin
Admin
Teacher
Staff
Student/User
```

Role-based dashboard routing was verified.

Current behavior after login and restart:

```text
SuperAdmin → SuperAdmin Dashboard
Admin      → Admin Dashboard
Teacher    → Employee Dashboard
Staff      → Employee Dashboard
Student    → Student Dashboard
```

---

# 72. Organization Isolation Testing

Organization isolation was specifically tested.

A user from one organization was not allowed to access another organization's protected data.

The system was tested with multiple organizations and users.

The core requirement was:

> Even if the system contains many organizations and users, each organization must only see its own permitted data.

This requirement was successfully tested.

---

# 73. Authorization Testing

Different roles were tested against protected endpoints.

For example:

```text
Admin token
    ↓
Admin API
    ↓
Allowed
```

while:

```text
Normal User token
    ↓
Admin-only User API
    ↓
403 Forbidden
```

This confirmed that backend authorization is not only implemented in the Flutter interface.

---

# 74. Notification Testing

The notification system was tested for the major notification events.

Tested scenarios included:

* New assignment
* Assignment graded
* Course assigned
* Attendance marked
* Academic grade added/updated
* Student assignment submission

Notification click/deep-link behavior was also tested.

---

# 75. Assignment Testing

The assignment system was tested through the complete workflow:

```text
Teacher/Staff
     ↓
Create Assignment
     ↓
Attach PDF
     ↓
Save
     ↓
Student receives assignment
     ↓
Student opens assignment
     ↓
Student views PDF
     ↓
Student submits assignment
     ↓
Teacher/Staff reviews submission
     ↓
Teacher/Staff grades submission
     ↓
Student receives notification
```

Existing assignment functionality was preserved while PDF and notification features were added.

---

# 76. Profile Testing

The profile system was tested for:

* Edit Profile
* Change Picture
* Change Password

The password-change workflow was also verified by logging out and logging back in using the newly changed password.

---

# 77. Application Startup Testing

The startup/session system was tested for every role.

After login, the correct dashboard appeared.

After hot restart, the same role-specific dashboard remained open.

Final verified behavior:

```text
SuperAdmin → SuperAdmin Dashboard
Admin      → Admin Dashboard
Teacher    → Employee Dashboard
Staff      → Employee Dashboard
Student    → Student Dashboard
```

This fixed an issue where previously Teacher, Staff and Student sessions were incorrectly restored to the Admin Dashboard.

The final solution reads the saved user's role during application startup.

---

# 78. Project Development Timeline

The project started as a simpler Student Management application.

The development then progressed approximately through these stages:

```text
1. Flutter project creation
        ↓
2. ASP.NET Core Web API creation
        ↓
3. PostgreSQL database setup
        ↓
4. Student API
        ↓
5. Flutter ↔ API connection
        ↓
6. Student CRUD
        ↓
7. Authentication
        ↓
8. JWT
        ↓
9. Organizations
        ↓
10. Role-based access
        ↓
11. Admin / Teacher / Staff / Student dashboards
        ↓
12. Courses
        ↓
13. Assignments
        ↓
14. PDF attachments
        ↓
15. Student submissions
        ↓
16. Assignment grading
        ↓
17. Academic grades
        ↓
18. Attendance
        ↓
19. Notifications
        ↓
20. Profile
        ↓
21. Password management
        ↓
22. Security testing
        ↓
23. Organization isolation testing
        ↓
24. UI improvements
        ↓
25. Startup/session restoration
        ↓
26. Final UI polishing
```

---

# 79. Why Firebase Was Not Used

The project intentionally uses a custom backend instead of Firebase.

The selected architecture is:

```text
Flutter
   ↓
ASP.NET Core Web API
   ↓
PostgreSQL
```

This demonstrates backend development skills such as:

* REST API development
* Database design
* Entity Framework Core
* JWT authentication
* Authorization
* Multi-tenant security
* Server-side business logic
* API testing

This makes the project useful as a full-stack development demonstration.

---

# 80. Important Development Decisions

Several important decisions were made during development.

## Decision 1 – Custom Backend

ASP.NET Core Web API was selected instead of Firebase.

## Decision 2 – PostgreSQL

PostgreSQL was selected as the relational database.

## Decision 3 – JWT

JWT was selected for authentication.

## Decision 4 – Multi-Organization

The application was expanded from a single-organization student system into a multi-organization platform.

## Decision 5 – One Global SuperAdmin

The application uses one global SuperAdmin instead of creating a SuperAdmin for every organization.

## Decision 6 – Admin-Created Employees

Teacher and Staff accounts are created by the organization Admin.

## Decision 7 – Backend Organization Isolation

Organization isolation is enforced by the backend rather than relying only on Flutter.

## Decision 8 – Database Notifications

Notifications are stored in PostgreSQL instead of initially using Firebase notifications.

## Decision 9 – Common Employee Dashboard

Teacher and Staff use a common Employee Dashboard.

## Decision 10 – Session Restoration

The application reads the saved role during startup so every user returns to the correct dashboard.

---

# 81. Important Security Principle

A major security principle in this project is:

> The frontend controls the user experience, but the backend controls access to protected data.

For example, even if a user somehow changes the Flutter UI, they should not be able to access another organization's protected API data.

The backend verifies:

```text
Who is the user?
        ↓
What is the user's role?
        ↓
Which organization does the user belong to?
        ↓
Is this operation allowed?
        ↓
Is this data inside the user's organization?
```

Only then should the operation proceed.

---

# 82. Example Secure Request Flow

Example:

```text
Student from Organization 1
        ↓
Flutter sends JWT
        ↓
ASP.NET Core validates JWT
        ↓
Read UserId
        ↓
Read Role
        ↓
Read OrganizationId
        ↓
Apply authorization
        ↓
Query Organization 1 data
        ↓
Return allowed result
```

Another organization cannot simply be accessed by changing an ID in the Flutter request because the backend also validates the user's organization context.

---

# 83. Project URLs During Development

## Flutter

```text
http://localhost:5000
```

Flutter Web is run with:

```text
flutter run -d chrome --web-port 5000
```

## ASP.NET Core API

```text
http://localhost:5083
```

## Swagger

```text
http://localhost:5083/swagger
```

## API Swagger JSON

```text
http://localhost:5083/swagger/v1/swagger.json
```

## PostgreSQL

```text
localhost:5432
```

Database:

```text
StudentManagementDB
```

---

# 84. Development Environment

The project was developed primarily on Windows.

Important tools used include:

* Android Studio
* Visual Studio Code
* PowerShell
* Flutter SDK
* .NET 8 SDK
* PostgreSQL
* pgAdmin
* Chrome
* Swagger

The backend project uses:

```text
.NET 8
```

The Flutter project is:

```text
student_management_app
```

---

# 85. Current Project State

The main functional development of StudentHub is now almost complete.

The following major areas are working:

* Authentication
* Registration
* Login
* Logout
* JWT
* Role-based routing
* Organization management
* Organization isolation
* SuperAdmin
* Admin
* Teacher
* Staff
* Students
* Courses
* Assignments
* Assignment PDFs
* Student submissions
* Assignment grading
* Academic grades
* Attendance
* Notifications
* Profile
* Profile picture
* Password change
* API security
* Session restoration

The remaining work is mainly focused on:

* UI improvements
* User experience improvements
* Final visual polish
* Interview/demo readiness

---

# 86. Final Feature Summary

## Authentication

* Registration
* Login
* Logout
* JWT authentication
* JWT expiry check
* Secure token storage
* Session restoration

## Organizations

* Create organization
* Organization Admin
* Organization users
* Organization-specific data
* Organization isolation
* SuperAdmin organization management

## User Roles

* SuperAdmin
* Admin
* Teacher
* Staff
* User/Student

## Students

* Student CRUD
* Student profile
* Profile editing
* Profile picture

## Courses

* Course management
* Student course assignment
* Organization-specific courses

## Assignments

* Assignment CRUD
* PDF attachment
* Student assignment access
* Student submissions
* Submission review
* Grading
* Feedback

## Academic Grades

* Grade management
* Course grade management
* Student grade viewing
* Average calculation
* Grade editing
* Grade deletion

## Attendance

* Attendance management
* Student attendance viewing
* Attendance notifications

## Notifications

* Database notifications
* Unread count
* Read notification
* Mark all as read
* Related record IDs
* Deep linking

## Security

* JWT
* Role authorization
* Organization isolation
* Protected APIs
* Secure token storage
* Password management

---

# 87. Complete High-Level System Flow

The complete StudentHub architecture can be summarized as:

```text
                         STUDENTHUB
                              │
                              ▼
                    ┌─────────────────┐
                    │  Flutter App    │
                    │     UI/UX       │
                    └────────┬────────┘
                             │
                             │ HTTP + JWT
                             ▼
                    ┌─────────────────┐
                    │ ASP.NET Core    │
                    │    Web API      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        Authentication   Authorization   Business Logic
              │              │              │
              └──────────────┼──────────────┘
                             │
                             ▼
                    Entity Framework Core
                             │
                             ▼
                       PostgreSQL
                             │
                             ▼
                    StudentManagementDB
```

---

# 88. Role Architecture

```text
                         SuperAdmin
                             │
              ┌──────────────┴──────────────┐
              │                             │
       Organization A                Organization B
              │                             │
           Admin                          Admin
              │                             │
       ┌──────┼──────┐               ┌──────┼──────┐
       │      │      │               │      │      │
    Teacher Staff Student         Teacher Staff Student
       │      │      │               │      │      │
       └──────┴──────┘               └──────┴──────┘
```

Every organization remains isolated.

---

# 89. User Request Flow

A normal protected request works like this:

```text
User
 ↓
Flutter Screen
 ↓
API Service
 ↓
HTTP Request
 ↓
JWT Bearer Token
 ↓
ASP.NET Core
 ↓
Authentication
 ↓
Authorization
 ↓
Organization Validation
 ↓
Business Logic
 ↓
Entity Framework Core
 ↓
PostgreSQL
 ↓
Response
 ↓
Flutter UI
```

---

# 90. Example: Student Viewing a Grade

```text
Student opens Academic Grades
        ↓
Flutter requests grades
        ↓
JWT attached to request
        ↓
API validates JWT
        ↓
API identifies student
        ↓
API identifies organization
        ↓
API retrieves allowed grades
        ↓
PostgreSQL returns data
        ↓
API returns JSON
        ↓
Flutter displays grades
```

---

# 91. Example: Teacher Creating Assignment

```text
Teacher opens Assignments
        ↓
Creates assignment
        ↓
Selects PDF
        ↓
Flutter sends request
        ↓
JWT attached
        ↓
Backend validates Teacher
        ↓
Backend validates organization
        ↓
Assignment saved
        ↓
PDF information saved
        ↓
Enrolled students identified
        ↓
Notifications created
        ↓
Student sees assignment
```

---

# 92. Example: Student Submission

```text
Student opens assignment
        ↓
Views assignment/PDF
        ↓
Submits work
        ↓
Backend validates student
        ↓
Backend validates organization
        ↓
Submission saved
        ↓
Assignment creator identified
        ↓
Teacher/Staff notification created
```

---

# 93. Example: Assignment Grading

```text
Teacher/Staff opens submissions
        ↓
Selects student submission
        ↓
Adds grade
        ↓
Adds feedback
        ↓
Backend saves grade/feedback
        ↓
Student notification created
        ↓
Student opens notification
        ↓
Assignment opens
```

---

# 94. Example: Organization Security

```text
Organization A User
        ↓
JWT contains OrganizationId = A
        ↓
Requests Organization B data
        ↓
Backend checks organization
        ↓
Organization mismatch
        ↓
Request rejected / data not returned
```

This is one of the most important security features of StudentHub.

---

# 95. Example: Application Restart

```text
Application starts
        ↓
AuthGate
        ↓
Check saved JWT
        ↓
JWT valid?
        │
        ├── No → Login
        │
        └── Yes
             ↓
       Read saved user
             ↓
        Read role
             ↓
   ┌─────────┼───────────┐
   │         │           │
 Admin    Teacher      Student
   │       /Staff         │
   ▼         ▼            ▼
Admin    Employee      Student
Dashboard Dashboard    Dashboard
```

SuperAdmin is restored to the SuperAdmin Dashboard.

---

# 96. What This Project Demonstrates

StudentHub demonstrates practical knowledge of:

### Flutter

* Flutter UI development
* Stateful widgets
* Navigation
* API integration
* Secure storage
* Forms
* File selection
* PDF viewing
* Dashboard development
* Loading/error/empty states
* Responsive UI concepts

### Backend

* ASP.NET Core Web API
* REST API design
* Controllers
* JWT authentication
* Authorization
* Role-based access
* Organization-level security
* Business logic
* Entity Framework Core
* Database relationships

### Database

* PostgreSQL
* Relational database design
* Entity relationships
* EF Core migrations
* Organization-scoped data

### Security

* JWT
* Bearer authentication
* Role authorization
* Organization isolation
* Password management
* Secure token storage

### Full-Stack Integration

* Flutter → API
* API → EF Core
* EF Core → PostgreSQL
* API → Flutter JSON responses
* Authentication across frontend/backend

---

# 97. Interview Explanation

A short explanation of the project can be:

> StudentHub is a full-stack multi-organization Student Management System built using Flutter, ASP.NET Core Web API, PostgreSQL and Entity Framework Core. The system uses JWT authentication and role-based authorization for SuperAdmin, Admin, Teacher, Staff and Student users. Each organization has isolated users, students, courses and academic data. The system includes student and course management, assignments with PDF attachments, student submissions, grading, academic grades, attendance, notifications and profile management. The backend is responsible for authentication, authorization and organization-level data isolation, while Flutter provides the user interface and communicates with the backend through REST APIs.

---

# 98. Why the Architecture Is Useful

The architecture keeps the frontend and backend separated.

Flutter does not directly communicate with PostgreSQL.

Instead:

```text
Flutter
   ↓
API
   ↓
Database
```

This provides a central place for:

* Security
* Validation
* Authorization
* Business rules
* Organization isolation

This is safer and easier to maintain than allowing the frontend to directly control database access.

---

# 99. Important Project Principle

Throughout development, existing working functionality was preserved whenever new functionality was added.

The development approach was:

```text
Existing Feature
      ↓
Add New Feature
      ↓
Keep Existing API/UI Behavior
      ↓
Test New Feature
      ↓
Fix Only Related Issues
```

This was especially important for:

* Assignments
* Student submissions
* PDF viewing
* Notifications
* Organization security
* Dashboard routing
* Academic grades
* Profile functionality

---

# 100. Current Status

StudentHub has reached the stage where the major functional architecture is complete.

The application has:

```text
Frontend
    Flutter
       ↓
Backend
    ASP.NET Core Web API
       ↓
ORM
    Entity Framework Core
       ↓
Database
    PostgreSQL
```

Authentication and authorization are implemented.

Multi-organization isolation is implemented and tested.

Role-based dashboards are implemented and tested.

Core academic modules are implemented and tested.

Notification flows are implemented and tested.

The current development focus is mainly:

```text
Final UI Improvements
        +
User Experience Improvements
        
```

---

# 101. Final Project Architecture Summary

```text
┌──────────────────────────────────────────────────────┐
│                    STUDENTHUB                        │
├──────────────────────────────────────────────────────┤
│                                                      │
│                  FLUTTER FRONTEND                    │
│                                                      │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │ Admin   │ │Employee │ │ Student  │ │SuperAdmin│ │
│  │Dashboard│ │Dashboard│ │Dashboard │ │Dashboard │ │
│  └─────────┘ └─────────┘ └──────────┘ └──────────┘ │
│                                                      │
│  Students | Courses | Assignments | Grades           │
│  Attendance | Notifications | Profile | Security      │
│                                                      │
└────────────────────────┬─────────────────────────────┘
                         │
                     HTTP + JWT
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│              ASP.NET CORE WEB API                    │
│                       .NET 8                         │
├──────────────────────────────────────────────────────┤
│                                                      │
│ Authentication                                       │
│ Authorization                                        │
│ Role Management                                      │
│ Organization Isolation                               │
│ Student APIs                                         │
│ Course APIs                                          │
│ Assignment APIs                                      │
│ Grade APIs                                           │
│ Attendance APIs                                      │
│ Notification APIs                                    │
│ User APIs                                            │
│                                                      │
└────────────────────────┬─────────────────────────────┘
                         │
                   Entity Framework
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│                    PostgreSQL                        │
│                                                      │
│ Organizations                                        │
│ Users                                                │
│ Students                                             │
│ Courses                                              │
│ Assignments                                          │
│ Submissions                                          │
│ Academic Grades                                      │
│ Attendance                                           │
│ Notifications                                        │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

# 102. Final Conclusion

StudentHub started as a basic Student Management project and was gradually developed into a complete full-stack, role-based, multi-organization educational management system.

The final system combines:

* Flutter
* ASP.NET Core Web API
* PostgreSQL
* Entity Framework Core
* JWT Authentication
* Role-based authorization
* Multi-organization security
* REST APIs
* Swagger
* Secure local token storage
* Academic management
* Assignment management
* PDF files
* Student submissions
* Grading
* Attendance
* Notifications
* Profile management

The most important architectural feature is that **the backend controls security and organization isolation**, while Flutter provides the user-facing experience.

The project is now functionally almost complete, with the remaining work focused mainly on improving the UI, usability and final presentation quality.

---

# 103. Project Development Philosophy

The project was developed with the following principles:

1. Keep existing working features stable.
2. Add new features in small isolated steps.
3. Keep frontend and backend responsibilities separated.
4. Enforce security on the backend.
5. Keep organization data isolated.
6. Use role-based access instead of giving every user the same permissions.
7. Store authentication information securely.
8. Test features manually after implementation.
9. Use Swagger to independently test APIs.
10. Keep the final UI simple, clean and user-friendly.

---

# 104. Final One-Line Description

**StudentHub is a full-stack, multi-organization Student Management System built with Flutter, ASP.NET Core Web API, PostgreSQL, Entity Framework Core and JWT authentication, providing secure role-based management of students, courses, assignments, grades, attendance, notifications and organization data.**
