# Swagger Comparison Tool

A tool to check and validate Swagger/OpenAPI specifications for compatibility between versions. This tool supports migration scenarios described in the [TypeSpec Azure documentation](https://azure.github.io/typespec-azure/docs/migrate-swagger/01-get-started/).

## Overview
This tool simplifies comparing Swagger/OpenAPI specifications by normalizing both documents before comparison, removing non-essential differences to focus on API compatibility issues.

## Installation

### Global Installation

```bash
npm install -g @autorest/swagger-compare
```

### Local Installation

```bash
npm install @autorest/swagger-compare
```

## Usage

### As a Command Line Tool

```bash
# Basic usage
swagger-check --oldPath ./old-swagger --newPath ./new-swagger

# With output folder for detailed reports
swagger-check --oldPath ./old-swagger --newPath ./new-swagger --outputFolder ./results

# Using positional arguments (shorter syntax)
swagger-check ./old-swagger ./new-swagger
```

## Features

- **Document Normalization**: Processes Swagger files to eliminate non-essential differences
- **Smart Comparison**: Identifies meaningful API changes while ignoring formatting differences
- **Enum Handling**: Standardizes enum naming to CamelCase and removes unnecessary details
- **Parameter Normalization**: Removes common parameters like API version, subscription ID, etc.
- **Page Model Detection**: Automatically identifies and standardizes paging patterns
- **Detailed Reporting**: Generates comprehensive comparison reports in the specified output folder
- **PowerShell Integration**: Includes scripts for checking SDK compatibility

## Configuration

The tool can be configured to ignore certain types of differences:

- `ignoreDescription`: Exclude description field differences
- `enumNameToCamelCase`: Standardize enum names to CamelCase format

## Development

```bash
# Build the project
npm run build

# Run the project
npm start

# Development mode with auto-reloading
npm run dev

# Run tests
npm test

# Lint the code
npm run lint
```

## License

MIT
