// User types
export interface User {
  id: number;
  email: string;
  created_at: string;
  updated_at: string;
}

// Category types
export interface Category {
  id: number;
  name: string;
  color: string;
  created_at: string;
  updated_at: string;
}

// Transaction types
export interface Transaction {
  id: number;
  amount: number;
  description: string;
  date: string;
  category_id?: number;
  category?: Category;
  anomalies?: Anomaly[];
  created_at: string;
  updated_at: string;
}

// Anomaly types
export interface Anomaly {
  id: number;
  type: "unusual_amount" | "duplicate" | "missing_description";
  severity: "low" | "medium" | "high" | "critical";
  description: string;
  resolved: boolean;
  transaction: Transaction;
  created_at: string;
  updated_at: string;
}

// Categorization Rule types
export interface RulePredicate {
  type: "STRING" | "NUMBER" | "DATE" | "COMPOUND";
  column?: string;
  operator?: string;
  operand?: any;
  predicates?: RulePredicate[];
}

export interface CategorizationRule {
  id: number;
  name: string;
  rule_predicate: RulePredicate;
  category_id: number;
  category: Category;
  priority: number;
  active: boolean;
  created_at: string;
  updated_at: string;
}

// API Response types
export interface ApiResponse<T> {
  data: T;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    current_page: number;
    total_pages: number;
    total_count: number;
    per_page: number;
    has_next_page: boolean;
    has_prev_page: boolean;
  };
}

// Dashboard types
export interface DashboardSummary {
  total_transactions: number;
  uncategorized_count: number;
  anomaly_count: number;
  recent_transactions: Array<{
    id: number;
    amount: number;
    description: string;
    date: string;
  }>;
}

export interface SpendingTrend {
  date: string;
  amount: number;
  category: string;
}

// Filter types
export interface TransactionFilters {
  category_id?: number;
  uncategorized?: boolean;
  anomaly_types?: ("unusual_amount" | "duplicate" | "missing_description")[];
  start_date?: string;
  end_date?: string;
  search?: string;
  page?: number;
  per_page?: number;
}

export interface AnomalyFilters {
  severity?: string;
  type?: "unusual_amount" | "duplicate" | "missing_description";
  page?: number;
  per_page?: number;
}

// WebSocket types
export interface WebSocketMessage {
  type: string;
  data?: any;
  timestamp: string;
}

export interface ImportProgress {
  type: "progress" | "completed" | "error" | "import_status";
  import_id?: number;
  status?: "processing" | "completed" | "failed";
  progress_percentage?: number;
  processed_rows?: number;
  total_rows?: number;
  error_rows?: number;
  rows_per_second?: number;
  processing_time_seconds?: number;
  success_rate?: number;
  error_message?: string;
  timestamp?: string;
  active_imports?: number;
  cache_cleared?: boolean;
}

// Form types
export interface LoginForm {
  email: string;
  password: string;
}

export interface RegisterForm {
  email: string;
  password: string;
  password_confirmation: string;
}

export interface TransactionForm {
  amount: number;
  description: string;
  date: string;
  category_id?: number;
}

export interface CategoryForm {
  name: string;
  color: string;
}

export interface RuleForm {
  name: string;
  rule_predicate: RulePredicate;
  category_id: number;
  priority: number;
  active: boolean;
}

// Bulk operation types
export interface BulkCategorizeRequest {
  transaction_ids: number[];
  category_id: number;
}

export interface BulkMarkReviewedRequest {
  transaction_ids: number[];
}

export interface BulkDeleteRequest {
  transaction_ids: number[];
}

// CSV Import types
export interface CsvImport {
  id: number;
  filename: string;
  status: "pending" | "processing" | "completed" | "failed";
  progress_percentage: number;
  total_rows: number;
  processed_rows: number;
  error_rows: number;
  file_size_mb: number;
  processing_time_seconds: number;
  rows_per_second: number;
  started_at: string | null;
  completed_at: string | null;
  error_message: string | null;
  metadata: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface CsvImportResponse {
  csv_imports: CsvImport[];
  pagination: {
    current_page: number;
    total_pages: number;
    total_count: number;
    per_page: number;
  };
}

export interface CreateCsvImportRequest {
  file?: File;
  s3_key?: string;
  filename?: string;
}

export interface PresignedUrlResponse {
  presigned_url: string;
  s3_key: string;
  expires_in: number;
}

// Error types
export interface ApiError {
  error: string;
  details?: Record<string, string[]>;
}
