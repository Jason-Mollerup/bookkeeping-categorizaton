import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiService } from "@/services/api";
import type {
  TransactionFilters,
  AnomalyFilters,
  TransactionForm,
  CategoryForm,
  RuleForm,
  BulkCategorizeRequest,
  BulkMarkReviewedRequest,
  BulkDeleteRequest,
  CreateCsvImportRequest,
} from "@/types";

export const queryKeys = {
  user: ["user"] as const,
  transactions: (filters?: TransactionFilters) =>
    ["transactions", filters] as const,
  transaction: (id: number) => ["transaction", id] as const,
  categories: ["categories"] as const,
  category: (id: number) => ["category", id] as const,
  rules: ["rules"] as const,
  rule: (id: number) => ["rule", id] as const,
  anomalies: (filters?: AnomalyFilters) => ["anomalies", filters] as const,
  anomaly: (id: number) => ["anomaly", id] as const,
  dashboard: ["dashboard"] as const,
  spendingTrends: ["spendingTrends"] as const,
  recentActivity: ["recentActivity"] as const,
};

export const useCurrentUser = () => {
  return useQuery({
    queryKey: queryKeys.user,
    queryFn: () => apiService.getCurrentUser(),
    enabled: !!localStorage.getItem("auth_token"),
  });
};

export const useTransactions = (filters: TransactionFilters = {}) => {
  return useQuery({
    queryKey: queryKeys.transactions(filters),
    queryFn: () => apiService.getTransactions(filters),
  });
};

export const useTransaction = (id: number) => {
  return useQuery({
    queryKey: queryKeys.transaction(id),
    queryFn: () => apiService.getTransaction(id),
    enabled: !!id,
  });
};

export const useCreateTransaction = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: TransactionForm) => apiService.createTransaction(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
      queryClient.invalidateQueries({ queryKey: queryKeys.recentActivity });
    },
  });
};

export const useUpdateTransaction = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: number;
      data: Partial<TransactionForm>;
    }) => apiService.updateTransaction(id, data),

    onMutate: async ({ id, data }) => {
      await queryClient.cancelQueries({ queryKey: ["transactions"] });
      await queryClient.cancelQueries({ queryKey: queryKeys.transaction(id) });

      const previousQueries = new Map();
      queryClient
        .getQueryCache()
        .findAll({ queryKey: ["transactions"] })
        .forEach((query) => {
          previousQueries.set(query.queryKey, query.state.data);
        });
      const previousTransaction = queryClient.getQueryData(
        queryKeys.transaction(id)
      );

      queryClient
        .getQueryCache()
        .findAll({ queryKey: ["transactions"] })
        .forEach((query) => {
          queryClient.setQueryData(query.queryKey, (old: any) => {
            if (!old?.data) return old;

            return {
              ...old,
              data: old.data.map((transaction: any) =>
                transaction.id === id
                  ? { ...transaction, ...data }
                  : transaction
              ),
            };
          });
        });

      queryClient.setQueryData(queryKeys.transaction(id), (old: any) => {
        if (!old) return old;
        return { ...old, ...data };
      });

      return { previousQueries, previousTransaction, id };
    },

    onError: (_err, _variables, context) => {
      if (context?.previousQueries) {
        context.previousQueries.forEach((data, queryKey) => {
          queryClient.setQueryData(queryKey, data);
        });
      }
      if (context?.previousTransaction && context?.id) {
        queryClient.setQueryData(
          queryKeys.transaction(context.id),
          context.previousTransaction
        );
      }
    },

    onSettled: (_, __, { id }) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.transaction(id) });
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
      queryClient.invalidateQueries({ queryKey: queryKeys.recentActivity });
    },
  });
};

export const useDeleteTransaction = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => apiService.deleteTransaction(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
      queryClient.invalidateQueries({ queryKey: queryKeys.recentActivity });
    },
  });
};

export const useBulkCategorize = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: BulkCategorizeRequest) =>
      apiService.bulkCategorize(data),

    onMutate: async ({ transaction_ids, category_id }) => {
      await queryClient.cancelQueries({ queryKey: ["transactions"] });

      const previousQueries = new Map();
      queryClient
        .getQueryCache()
        .findAll({ queryKey: ["transactions"] })
        .forEach((query) => {
          previousQueries.set(query.queryKey, query.state.data);
        });

      const categories = queryClient.getQueryData(
        queryKeys.categories
      ) as any[];
      const category = categories?.find((c) => c.id === category_id);

      queryClient
        .getQueryCache()
        .findAll({ queryKey: ["transactions"] })
        .forEach((query) => {
          queryClient.setQueryData(query.queryKey, (old: any) => {
            if (!old?.data) return old;

            const queryFilters = query.queryKey[1] as TransactionFilters;
            const isUncategorizedQuery = queryFilters?.uncategorized === true;

            if (isUncategorizedQuery) {
              return {
                ...old,
                data: old.data.filter(
                  (transaction: any) =>
                    !transaction_ids.includes(transaction.id)
                ),
              };
            } else {
              return {
                ...old,
                data: old.data.map((transaction: any) =>
                  transaction_ids.includes(transaction.id)
                    ? {
                        ...transaction,
                        category_id,
                        category: category
                          ? {
                              id: category.id,
                              name: category.name,
                              color: category.color,
                            }
                          : null,
                      }
                    : transaction
                ),
              };
            }
          });
        });

      return { previousQueries };
    },

    onError: (_err, _variables, context) => {
      if (context?.previousQueries) {
        context.previousQueries.forEach((data, queryKey) => {
          queryClient.setQueryData(queryKey, data);
        });
      }
    },

    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
    },
  });
};

export const useBulkMarkReviewed = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: BulkMarkReviewedRequest) =>
      apiService.bulkMarkReviewed(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
    },
  });
};

export const useBulkDelete = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: BulkDeleteRequest) => apiService.bulkDelete(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
    },
  });
};

export const useBulkApplyRules = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (transaction_ids?: number[]) =>
      apiService.bulkApplyRules(transaction_ids),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
    },
  });
};

export const useBulkDetectAnomalies = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (transaction_ids?: number[]) =>
      apiService.bulkDetectAnomalies(transaction_ids),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.anomalies() });
    },
  });
};

export const useImportCSV = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: File) => apiService.importCSV(file),
    onSuccess: () => {
      // Clear all cached queries after CSV import to ensure fresh data
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
      queryClient.invalidateQueries({ queryKey: queryKeys.spendingTrends });
      queryClient.invalidateQueries({ queryKey: queryKeys.recentActivity });
      queryClient.invalidateQueries({ queryKey: queryKeys.anomalies() });
      queryClient.invalidateQueries({ queryKey: ["csv-imports"] });
      queryClient.invalidateQueries({ queryKey: ["csv-import"] });

      // Clear any cached uncategorized transactions
      queryClient.invalidateQueries({
        queryKey: ["transactions"],
        predicate: (query) => {
          const filters = query.queryKey[1] as TransactionFilters;
          return filters?.uncategorized === true;
        },
      });
    },
  });
};

export const useCategories = () => {
  return useQuery({
    queryKey: queryKeys.categories,
    queryFn: () => apiService.getCategories(),
  });
};

export const useCategory = (id: number) => {
  return useQuery({
    queryKey: queryKeys.category(id),
    queryFn: () => apiService.getCategory(id),
    enabled: !!id,
  });
};

export const useCategorizationRules = () => {
  return useQuery({
    queryKey: queryKeys.rules,
    queryFn: () => apiService.getCategorizationRules(),
  });
};

export const useCreateCategory = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CategoryForm) => apiService.createCategory(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.categories });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
    },
  });
};

export const useUpdateCategory = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<CategoryForm> }) =>
      apiService.updateCategory(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.category(id) });
      queryClient.invalidateQueries({ queryKey: queryKeys.categories });
    },
  });
};

export const useDeleteCategory = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => apiService.deleteCategory(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.categories });
      queryClient.invalidateQueries({ queryKey: ["transactions"] });
    },
  });
};

export const useRules = () => {
  return useQuery({
    queryKey: queryKeys.rules,
    queryFn: apiService.getRules,
  });
};

export const useRule = (id: number) => {
  return useQuery({
    queryKey: queryKeys.rule(id),
    queryFn: () => apiService.getRule(id),
    enabled: !!id,
  });
};

export const useCreateRule = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: RuleForm) => apiService.createRule(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.rules });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
    },
  });
};

export const useUpdateRule = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<RuleForm> }) =>
      apiService.updateRule(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.rule(id) });
      queryClient.invalidateQueries({ queryKey: queryKeys.rules });
    },
  });
};

export const useDeleteRule = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => apiService.deleteRule(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.rules });
    },
  });
};

export const useAnomalies = (filters: AnomalyFilters = {}) => {
  return useQuery({
    queryKey: queryKeys.anomalies(filters),
    queryFn: () => apiService.getAnomalies(filters),
  });
};

export const useAnomaly = (id: number) => {
  return useQuery({
    queryKey: queryKeys.anomaly(id),
    queryFn: () => apiService.getAnomaly(id),
    enabled: !!id,
  });
};

export const useResolveAnomaly = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => apiService.resolveAnomaly(id),
    onSuccess: (_, anomalyId) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.anomaly(anomalyId) });
      queryClient.invalidateQueries({ queryKey: queryKeys.anomalies() });
      queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
    },
  });
};

export const useDashboardSummary = () => {
  return useQuery({
    queryKey: queryKeys.dashboard,
    queryFn: () => apiService.getDashboardSummary(),
    refetchInterval: 30000,
  });
};

export const useSpendingTrends = () => {
  return useQuery({
    queryKey: queryKeys.spendingTrends,
    queryFn: () => apiService.getSpendingTrends(),
  });
};

export const useRecentActivity = () => {
  return useQuery({
    queryKey: queryKeys.recentActivity,
    queryFn: () => apiService.getRecentActivity(),
  });
};

export const useCsvImports = (params?: {
  page?: number;
  per_page?: number;
}) => {
  return useQuery({
    queryKey: ["csv-imports", params],
    queryFn: () => apiService.getCsvImports(params),
    select: (data) => data.csv_imports,
  });
};

export const useCsvImport = (id: number) => {
  return useQuery({
    queryKey: ["csv-import", id],
    queryFn: () => apiService.getCsvImport(id),
    enabled: !!id,
  });
};

export const useCreateCsvImport = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateCsvImportRequest) =>
      apiService.createCsvImport(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["csv-imports"] });
    },
  });
};

export const useDeleteCsvImport = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => apiService.deleteCsvImport(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["csv-imports"] });
    },
  });
};

export const useCsvImportProgress = (id: number) => {
  return useQuery({
    queryKey: ["csv-import-progress", id],
    queryFn: () => apiService.getCsvImportProgress(id),
    enabled: !!id,
    refetchInterval: (query) => {
      if (
        query.state.data?.status === "completed" ||
        query.state.data?.status === "failed"
      ) {
        return false;
      }
      return 2000;
    },
  });
};

export const usePresignedUrl = () => {
  return useMutation({
    mutationFn: (data: { filename: string; content_type?: string }) =>
      apiService.getPresignedUrl(data),
  });
};
