# Dashboard Components

This directory contains the dashboard components for the bookkeeping application.

## Components

### Dashboard.tsx

The main dashboard component that brings together all dashboard sections:

- Spending by category chart
- Uncategorized transactions section
- Anomaly transactions section
- Transaction form modal for editing

### SpendingChart.tsx

A pie chart component that displays spending breakdown by category using Recharts library.

- Fetches spending trends data from the API
- Displays category breakdown with colors and percentages
- Shows tooltips with currency formatting

### UncategorizedTransactions.tsx

Displays transactions that don't have a category assigned:

- Shows up to 10 uncategorized transactions
- Allows bulk categorization with category selection
- Individual transaction categorization
- Edit functionality for individual transactions
- Bulk selection and actions

### AnomalyTransactions.tsx

Displays transactions that have anomalies detected:

- Shows transactions with various anomaly types (unusual amount, duplicate, missing description, suspicious pattern)
- Bulk actions: categorize, approve, delete
- Individual actions: categorize, approve, delete, edit
- Displays anomaly severity with color coding
- Tooltips showing anomaly descriptions

## Features

- **Responsive Design**: Uses Material-UI Joy Grid system for responsive layout
- **Real-time Data**: Uses React Query for data fetching and caching
- **Bulk Operations**: Support for bulk categorization, approval, and deletion
- **Interactive Charts**: Pie chart with tooltips and legends
- **Consistent Styling**: Follows the same design patterns as the main transactions page
- **Error Handling**: Proper loading states and error messages
- **Accessibility**: Tooltips and proper ARIA labels

## API Integration

The dashboard components integrate with the following API endpoints:

- `/api/v1/dashboard/spending_trends` - For spending chart data
- `/api/v1/transactions?uncategorized=true` - For uncategorized transactions
- `/api/v1/transactions?anomaly_types=...` - For anomaly transactions
- `/api/v1/transactions/bulk_categorize` - For bulk categorization
- `/api/v1/transactions/bulk_mark_reviewed` - For bulk approval
- `/api/v1/transactions/bulk_delete` - For bulk deletion

## Usage

The dashboard is accessible at `/dashboard` route and is set as the default landing page for authenticated users.
