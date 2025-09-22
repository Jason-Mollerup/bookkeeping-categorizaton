# Bookkeeping API Documentation

## Local

```
http://localhost:3000/api/v1
```

## Authentication

All endpoints (except auth endpoints) require JWT authentication via Authorization header:

```
Authorization: Bearer <jwt_token>
```

## Endpoints

### Authentication

- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user
- `GET /auth/me` - Get current user info

### Transactions

- `GET /transactions` - List transactions (with filtering & pagination)
- `POST /transactions` - Create transaction
- `GET /transactions/:id` - Get transaction
- `PUT/PATCH /transactions/:id` - Update transaction
- `DELETE /transactions/:id` - Delete transaction

**Bulk Operations:**

- `POST /transactions/bulk_categorize` - Categorize multiple transactions
- `POST /transactions/bulk_flag` - Flag/unflag multiple transactions
- `POST /transactions/bulk_mark_reviewed` - Mark multiple as reviewed
- `DELETE /transactions/bulk_delete` - Delete multiple transactions
- `POST /transactions/bulk_apply_rules` - Apply rules to multiple transactions
- `POST /transactions/bulk_detect_anomalies` - Detect anomalies for multiple transactions
- `POST /transactions/import_csv` - Import transactions from CSV

### Categories

- `GET /categories` - List categories
- `POST /categories` - Create category
- `GET /categories/:id` - Get category
- `PUT/PATCH /categories/:id` - Update category
- `DELETE /categories/:id` - Delete category
- `GET /categories/:id/stats` - Get category statistics

### Categorization Rules

- `GET /categorization_rules` - List rules
- `POST /categorization_rules` - Create rule
- `GET /categorization_rules/:id` - Get rule
- `PUT/PATCH /categorization_rules/:id` - Update rule
- `DELETE /categorization_rules/:id` - Delete rule

**Bulk Operations:**

- `POST /categorization_rules/bulk_activate` - Activate multiple rules
- `POST /categorization_rules/bulk_deactivate` - Deactivate multiple rules
- `DELETE /categorization_rules/bulk_delete` - Delete multiple rules
- `POST /categorization_rules/bulk_reorder` - Reorder rule priorities
- `POST /categorization_rules/test_rule` - Test rule against transaction

### Anomalies

- `GET /anomalies` - List anomalies (with filtering & pagination)
- `GET /anomalies/:id` - Get anomaly
- `PATCH /anomalies/:id/resolve` - Resolve anomaly
- `POST /anomalies/bulk_resolve` - Resolve multiple anomalies
- `GET /anomalies/stats` - Get anomaly statistics

### Dashboard

- `GET /dashboard/summary` - Get dashboard summary
- `GET /dashboard/spending_trends` - Get spending trends
- `GET /dashboard/recent_activity` - Get recent activity

## Request/Response Examples

### Register User

```bash
POST /api/v1/auth/register
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

### Create Transaction

```bash
POST /api/v1/transactions
Authorization: Bearer <token>
Content-Type: application/json

{
  "transaction": {
    "amount": 25.99,
    "description": "Coffee at Starbucks",
    "date": "2024-01-15",
    "category_id": 1
  }
}
```

### Bulk Categorize Transactions

```bash
POST /api/v1/transactions/bulk_categorize
Authorization: Bearer <token>
Content-Type: application/json

{
  "transaction_ids": [1, 2, 3, 4, 5],
  "category_id": 2
}
```

### Create Categorization Rule

```bash
POST /api/v1/categorization_rules
Authorization: Bearer <token>
Content-Type: application/json

{
  "rule": {
    "name": "Amazon Shopping",
    "condition_type": "contains",
    "condition_value": "amazon",
    "category_id": 3,
    "priority": 1,
    "active": true
  }
}
```

## Filtering & Pagination

### Transaction Filtering

- `?category_id=1` - Filter by category
- `?flagged=true` - Filter flagged transactions
- `?uncategorized=true` - Filter uncategorized transactions
- `?unreviewed=true` - Filter unreviewed transactions
- `?start_date=2024-01-01&end_date=2024-01-31` - Filter by date range
- `?page=2&per_page=50` - Pagination

### Anomaly Filtering

- `?severity=high` - Filter by severity
- `?type=unusual_amount` - Filter by anomaly type
- `?page=1&per_page=25` - Pagination

## Error Responses

All errors return JSON with error message:

```json
{
  "error": "Error message here"
}
```

Common status codes:

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `422` - Unprocessable Entity
- `500` - Internal Server Error
