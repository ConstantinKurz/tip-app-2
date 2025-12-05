# GitHub Copilot Instructions

## Project Context
This is a Flutter web application for sports betting/tipping called "Meins". The app displays match information, team data with flags, and allows users to make predictions.

## Architecture & Structure
- Follow Clean Architecture principles with domain/presentation layers
- Use StatelessWidget for UI components when possible
- Organize widgets in dedicated folders under `lib/presentation/`
- Entities are located in `lib/domain/entities/`

## Coding Standards

### Dart/Flutter Conventions
- Use `const` constructors wherever possible
- Prefer named parameters for widget constructors
- Use `Key? key` parameter and call `super(key: key)`
- Follow Dart naming conventions (camelCase for variables/methods, PascalCase for classes)
- Add `required` keyword for mandatory parameters

### UI Guidelines
- Use `Theme.of(context)` for consistent styling
- Implement responsive design with `Expanded` and `Flexible` widgets
- Handle text overflow with `TextOverflow.ellipsis`
- Use `SizedBox` for spacing instead of `Padding` when appropriate
- Apply `BorderRadius.circular()` for rounded corners

### Widget Structure
- Keep widgets small and focused on single responsibility
- Extract reusable components into separate widget classes
- Use meaningful widget names that describe their purpose
- Pass data through constructor parameters rather than accessing global state

### Code Organization
- Group related imports (Flutter, packages, local files)
- Use relative imports for local files
- Prefer composition over inheritance for widget customization

## Domain Models
- `CustomMatch`: Contains match data including scores and team references
- `Team`: Contains team information including name and flag code
- Use `Flag.fromString()` for country flag display

## Common Patterns
- Conditional rendering based on `hasResult` or similar boolean flags
- Row/Column layouts with proper spacing and alignment
- Container widgets for custom styling and backgrounds
- ClipOval for circular flag displays

## Avoid
- Hardcoded colors (use theme instead)
- Magic numbers (define constants)
- Deeply nested widget trees
- Mutable state in StatelessWidgets
