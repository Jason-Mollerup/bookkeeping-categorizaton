import axios, { type AxiosInstance } from "axios";
import type {
  User,
  Transaction,
  Category,
  Anomaly,
  CategorizationRule,
  DashboardSummary,
  TransactionFilters,
  AnomalyFilters,
  LoginForm,
  RegisterForm,
  TransactionForm,
  CategoryForm,
  RuleForm,
  BulkCategorizeRequest,
  BulkMarkReviewedRequest,
  BulkDeleteRequest,
  PaginatedResponse,
  CsvImport,
  CsvImportResponse,
  CreateCsvImportRequest,
  PresignedUrlResponse,
} from "@/types";

class ApiService {
  private api: AxiosInstance;

  constructor() {
    this.api = axios.create({
      baseURL: "/api/v1",
      headers: {
        "Content-Type": "application/json",
      },
    });

    this.api.interceptors.request.use((config) => {
      const token = localStorage.getItem("auth_token");
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    });

    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem("auth_token");
          window.location.href = "/login";
        }
        return Promise.reject(error);
      }
    );
  }

  async login(credentials: LoginForm): Promise<{ user: User; token: string }> {
    const response = await this.api.post("/auth/login", credentials);
    return response.data;
  }

  async register(
    userData: RegisterForm
  ): Promise<{ user: User; token: string }> {
    const response = await this.api.post("/auth/register", { user: userData });
    return response.data;
  }

  async getCurrentUser(): Promise<User> {
    const response = await this.api.get("/auth/me");
    return response.data.user;
  }

  async getTransactions(
    filters: TransactionFilters = {}
  ): Promise<PaginatedResponse<Transaction>> {
    const response = await this.api.get("/transactions", { params: filters });
    return response.data;
  }

  async getTransaction(id: number): Promise<Transaction> {
    const response = await this.api.get(`/transactions/${id}`);
    return response.data.transaction;
  }

  async createTransaction(data: TransactionForm): Promise<Transaction> {
    const response = await this.api.post("/transactions", {
      transaction: data,
    });
    return response.data.transaction;
  }

  async updateTransaction(
    id: number,
    data: Partial<TransactionForm>
  ): Promise<Transaction> {
    const response = await this.api.put(`/transactions/${id}`, {
      transaction: data,
    });
    return response.data.transaction;
  }

  async deleteTransaction(id: number): Promise<void> {
    await this.api.delete(`/transactions/${id}`);
  }

  async bulkCategorize(
    data: BulkCategorizeRequest
  ): Promise<{ updated_count: number }> {
    const response = await this.api.post("/transactions/bulk_categorize", data);
    return response.data;
  }

  async bulkMarkReviewed(
    data: BulkMarkReviewedRequest
  ): Promise<{ deleted_anomalies: number; transaction_count: number }> {
    const response = await this.api.post(
      "/transactions/bulk_mark_reviewed",
      data
    );
    return response.data;
  }

  async bulkDelete(
    data: BulkDeleteRequest
  ): Promise<{ deleted_count: number }> {
    const response = await this.api.delete("/transactions/bulk_delete", {
      data,
    });
    return response.data;
  }

  async bulkApplyRules(
    transactionIds?: number[]
  ): Promise<{ updated_count: number }> {
    const response = await this.api.post("/transactions/bulk_apply_rules", {
      transaction_ids: transactionIds,
    });
    return response.data;
  }

  async bulkDetectAnomalies(
    transactionIds?: number[]
  ): Promise<{ detected_count: number }> {
    const response = await this.api.post(
      "/transactions/bulk_detect_anomalies",
      { transaction_ids: transactionIds }
    );
    return response.data;
  }

  async importCSV(file: File): Promise<{ message: string }> {
    const formData = new FormData();
    formData.append("file", file);

    const response = await this.api.post("/transactions/import_csv", formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });
    return response.data;
  }

  async getCategories(): Promise<Category[]> {
    const response = await this.api.get("/categories");
    return response.data.categories;
  }

  async getCategory(id: number): Promise<Category> {
    const response = await this.api.get(`/categories/${id}`);
    return response.data.category;
  }

  async getCategorizationRules(): Promise<CategorizationRule[]> {
    const response = await this.api.get("/categorization_rules");
    return response.data.rules;
  }

  async createCategory(data: CategoryForm): Promise<Category> {
    const response = await this.api.post("/categories", { category: data });
    return response.data.category;
  }

  async updateCategory(
    id: number,
    data: Partial<CategoryForm>
  ): Promise<Category> {
    const response = await this.api.put(`/categories/${id}`, {
      category: data,
    });
    return response.data.category;
  }

  async deleteCategory(id: number): Promise<void> {
    await this.api.delete(`/categories/${id}`);
  }

  async getCategoryStats(id: number): Promise<any> {
    const response = await this.api.get(`/categories/${id}/stats`);
    return response.data;
  }

  async getRules(): Promise<CategorizationRule[]> {
    const response = await this.api.get("/categorization_rules");
    return response.data.rules;
  }

  async getRule(id: number): Promise<CategorizationRule> {
    const response = await this.api.get(`/categorization_rules/${id}`);
    return response.data.rule;
  }

  async createRule(data: RuleForm): Promise<CategorizationRule> {
    const response = await this.api.post("/categorization_rules", {
      rule: data,
    });
    return response.data.rule;
  }

  async updateRule(
    id: number,
    data: Partial<RuleForm>
  ): Promise<CategorizationRule> {
    const response = await this.api.put(`/categorization_rules/${id}`, {
      rule: data,
    });
    return response.data.rule;
  }

  async deleteRule(id: number): Promise<void> {
    await this.api.delete(`/categorization_rules/${id}`);
  }

  async bulkActivateRules(
    ruleIds: number[]
  ): Promise<{ updated_count: number }> {
    const response = await this.api.post(
      "/categorization_rules/bulk_activate",
      { rule_ids: ruleIds }
    );
    return response.data;
  }

  async bulkDeactivateRules(
    ruleIds: number[]
  ): Promise<{ updated_count: number }> {
    const response = await this.api.post(
      "/categorization_rules/bulk_deactivate",
      { rule_ids: ruleIds }
    );
    return response.data;
  }

  async bulkDeleteRules(ruleIds: number[]): Promise<{ deleted_count: number }> {
    const response = await this.api.delete(
      "/categorization_rules/bulk_delete",
      { data: { rule_ids: ruleIds } }
    );
    return response.data;
  }

  async getAnomalies(
    filters: AnomalyFilters = {}
  ): Promise<PaginatedResponse<Anomaly>> {
    const response = await this.api.get("/anomalies", { params: filters });
    return response.data;
  }

  async getAnomaly(id: number): Promise<Anomaly> {
    const response = await this.api.get(`/anomalies/${id}`);
    return response.data.anomaly;
  }

  async resolveAnomaly(id: number): Promise<Anomaly> {
    const response = await this.api.patch(`/anomalies/${id}/resolve`);
    return response.data.anomaly;
  }

  async bulkResolveAnomalies(
    anomalyIds: number[]
  ): Promise<{ resolved_count: number }> {
    const response = await this.api.post("/anomalies/bulk_resolve", {
      anomaly_ids: anomalyIds,
    });
    return response.data;
  }

  async getAnomalyStats(): Promise<any> {
    const response = await this.api.get("/anomalies/stats");
    return response.data;
  }

  async getDashboardSummary(): Promise<DashboardSummary> {
    const response = await this.api.get("/dashboard/summary");
    return response.data;
  }

  async getSpendingTrends(): Promise<any> {
    const response = await this.api.get("/dashboard/spending_trends");
    return response.data.trends;
  }

  async getRecentActivity(): Promise<Transaction[]> {
    const response = await this.api.get("/dashboard/recent_activity");
    return response.data;
  }

  async getCsvImports(params?: {
    page?: number;
    per_page?: number;
  }): Promise<CsvImportResponse> {
    const response = await this.api.get("/csv_imports", { params });
    return response.data;
  }

  async getCsvImport(id: number): Promise<CsvImport> {
    const response = await this.api.get(`/csv_imports/${id}`);
    return response.data.csv_import;
  }

  async createCsvImport(data: CreateCsvImportRequest): Promise<CsvImport> {
    const formData = new FormData();

    if (data.file) {
      formData.append("file", data.file);
    }
    if (data.s3_key) {
      formData.append("s3_key", data.s3_key);
    }
    if (data.filename) {
      formData.append("filename", data.filename);
    }

    const response = await this.api.post("/csv_imports", formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });
    return response.data.csv_import;
  }

  async deleteCsvImport(id: number): Promise<void> {
    await this.api.delete(`/csv_imports/${id}`);
  }

  async getCsvImportProgress(id: number): Promise<any> {
    const response = await this.api.get(`/csv_imports/${id}/progress`);
    return response.data;
  }

  async getPresignedUrl(data: {
    filename: string;
    content_type?: string;
  }): Promise<PresignedUrlResponse> {
    const response = await this.api.post("/csv_imports/presigned_url", data);
    return response.data;
  }
}

export const apiService = new ApiService();
