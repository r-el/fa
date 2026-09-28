# Specter Dashboard API Documentation

## Overview

This API provides authentication, user management, and Specter integration services for the Specter Dashboard system. 
Camera management and streaming are handled by Specter itself, with this API managing user sessions and permissions.

## Base URLs

### Development

```
http://localhost:12113
```

### Production

```
https://api.specter.live
```

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. After logging in, include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### Authentication

#### Register User

- **POST** `/auth/register`
- **Description**: Create a new user account
- **Body**:

```json
{
  "username": "string (3-30 chars)",
  "password": "string (min 6 chars)",
  "name": "string (required)",
  "email": "string (valid email)",
  "role": "string (admin|operator|viewer) - optional, defaults to viewer"
}
```

- **Response**:

```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "name": "string",
      "email": "string",
      "role": "string"
    },
    "token": "jwt-token"
  }
}
```

#### Login User

- **POST** `/auth/login`
- **Description**: Authenticate user and get JWT token
- **Body**:

```json
{
  "username": "string",
  "password": "string"
}
```

- **Response**:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "name": "string",
      "email": "string",
      "role": "string"
    },
    "token": "jwt-token"
  }
}
```

### Users (Protected Routes)

#### Get User Profile

- **GET** `/users/profile`
- **Description**: Get current authenticated user's profile
- **Headers**: `Authorization: Bearer <token>`
- **Response**:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "name": "string",
      "email": "string",
      "role": "string",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

#### Get User by ID

- **GET** `/users/:id`
- **Description**: Get user information by ID
- **Headers**: `Authorization: Bearer <token>`
- **Parameters**: `id` (user UUID)
- **Response**:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "name": "string",
      "email": "string",
      "role": "string",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

### Health

#### Health Check

- **GET** `/health`
- **Description**: Check server health status
- **Response**:

```json
{
  "success": true,
  "message": "Server is healthy",
  "timestamp": "timestamp",
  "uptime": "number",
  "environment": "string"
}
```

## Error Responses

All endpoints may return error responses in the following format:

```json
{
  "success": false,
  "error": "Error message",
  "stack": "Error stack (in development mode)"
}
```

### Common Error Codes

- **400**: Bad Request - Invalid input data
- **401**: Unauthorized - Invalid or missing token
- **403**: Forbidden - Insufficient permissions
- **404**: Not Found - Resource not found
- **409**: Conflict - Resource already exists
- **500**: Internal Server Error

## Validation Rules

### Username

- Length: 3-30 characters
- Allowed: letters, numbers, underscore
- Must be unique

### Password

- Minimum length: 6 characters
- Must contain at least one letter and one number

### Email

- Must be valid email format
- Must be unique

### Name

- Required field
- Minimum length: 1 character

### Role

- Allowed values: "admin", "operator", "viewer"
- Defaults to "viewer" if not specified
