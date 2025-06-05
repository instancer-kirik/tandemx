# Contributing to ScanPrint

Thank you for your interest in contributing to ScanPrint! This document provides guidelines and instructions for contributing to the project.

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/scanprint.git
   cd scanprint
   ```

2. Install dependencies:
   ```bash
   # With UV (recommended)
   ./install.sh
   # Or with standard pip
   pip install -e ".[dev]"
   ```

3. Verify your setup:
   ```bash
   # Run the application in demo mode
   ./run_demo.py
   ```

## Project Structure

The project follows this structure:
- `scanprint/` - Main package directory
  - `__init__.py` - Package initialization
  - `main.py` - Application entry point with UI components
- `utils/` - Utility modules
  - `inventory.py` - Inventory management functions
  - `labelgen.py` - Label generation functionality
- `run.py` - Application runner script
- `run_demo.py` - Demo mode runner script

## Code Style

We follow PEP 8 and use Black for code formatting:

```bash
# Format code
black scanprint utils
```

## Testing

Run tests with pytest:

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_inventory.py
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests to ensure they pass
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Commit Guidelines

- Use clear, descriptive commit messages
- Reference issue numbers in commit messages when applicable
- Keep commits focused on a single change

## Feature Requests and Bug Reports

Please use the GitHub issue tracker to:
- Report bugs
- Request new features
- Suggest improvements

When reporting bugs, please include:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots if applicable
- Environment details (OS, Python version, etc.)

## UI Development

The application uses PyQt6. When making UI changes:
- Keep the interface simple and intuitive
- Test on different screen sizes
- Consider accessibility

## Label Templates

When adding or modifying label templates:
- Place templates in the `labels/templates` directory
- Use consistent formatting
- Document available fields

## License

By contributing to ScanPrint, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).