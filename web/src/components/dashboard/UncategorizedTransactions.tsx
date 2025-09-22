import React, { useState } from "react";
import {
  Box,
  Table,
  Typography,
  Button,
  IconButton,
  FormControl,
  Select,
  Option,
  Stack,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Checkbox,
  Skeleton,
} from "@mui/joy";
import {
  Edit as EditIcon,
  ExpandMore as ExpandMoreIcon,
} from "@mui/icons-material";
import {
  useTransactions,
  useBulkCategorize,
  useCategories,
} from "@/hooks/useApi";
import type { Transaction } from "@/types";

interface UncategorizedTransactionsProps {
  onEdit?: (transaction: Transaction) => void;
}

const UncategorizedTransactions: React.FC<UncategorizedTransactionsProps> = ({
  onEdit,
}) => {
  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const [bulkCategoryId, setBulkCategoryId] = useState<number | null>(null);
  const [currentPage, setCurrentPage] = useState(1);

  const {
    data: transactionsData,
    isLoading,
    error,
  } = useTransactions({
    uncategorized: true,
    per_page: 100,
    page: currentPage,
  });
  const { data: categories = [] } = useCategories();
  const bulkCategorize = useBulkCategorize();

  const transactions = transactionsData?.data || [];
  const pagination = transactionsData?.pagination;

  const formatNumber = (number: number) => {
    return new Intl.NumberFormat("en-US").format(number);
  };

  const handleBulkCategorize = async () => {
    if (selectedIds.length === 0 || !bulkCategoryId) return;

    try {
      await bulkCategorize.mutateAsync({
        transaction_ids: selectedIds,
        category_id: bulkCategoryId,
      });
      setSelectedIds([]);
      setBulkCategoryId(null);
    } catch (error) {
      console.error("Bulk categorize failed:", error);
    }
  };

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedIds(transactions.map((t: Transaction) => t.id));
    } else {
      setSelectedIds([]);
    }
  };

  const handleSingleCategorize = async (
    transactionId: number,
    categoryId: number
  ) => {
    try {
      await bulkCategorize.mutateAsync({
        transaction_ids: [transactionId],
        category_id: categoryId,
      });
      setSelectedIds((prev) => prev.filter((id) => id !== transactionId));
    } catch (error) {
      console.error("Single categorize failed:", error);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString();
  };

  return (
    <Accordion defaultExpanded>
      <AccordionSummary
        indicator={<ExpandMoreIcon sx={{ mx: 1 }} />}
        variant="plain"
      >
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            width: "100%",
            p: 1,
          }}
        >
          <Typography level="h4">Uncategorized Transactions</Typography>
          <Typography level="body-sm">
            {error ? (
              "Error loading data"
            ) : pagination && pagination.total_count > 0 ? (
              <>
                Showing{" "}
                {formatNumber(
                  (pagination.current_page - 1) * pagination.per_page + 1
                )}{" "}
                to{" "}
                {formatNumber(
                  Math.min(
                    pagination.current_page * pagination.per_page,
                    pagination.total_count
                  )
                )}{" "}
                of {formatNumber(pagination.total_count)}
              </>
            ) : isLoading ? (
              "Loading..."
            ) : (
              `${transactions.length} transactions`
            )}
          </Typography>
        </Box>
      </AccordionSummary>
      <AccordionDetails>
        {selectedIds.length > 0 && (
          <Box
            sx={{
              mb: 2,
              p: 2,
              bgcolor: "background.level1",
              borderRadius: "sm",
            }}
          >
            <Stack direction="row" spacing={2} alignItems="center">
              <Typography level="body-sm">
                {selectedIds.length} transaction
                {selectedIds.length !== 1 ? "s" : ""} selected
              </Typography>
              <FormControl size="sm" sx={{ minWidth: 200 }}>
                <Select
                  placeholder="Assign category..."
                  value={bulkCategoryId ? String(bulkCategoryId) : ""}
                  onChange={(_, value) =>
                    setBulkCategoryId(value ? Number(value) : null)
                  }
                >
                  {categories.map((category) => (
                    <Option key={category.id} value={String(category.id)}>
                      <Box
                        sx={{ display: "flex", alignItems: "center", gap: 1 }}
                      >
                        <Box
                          sx={{
                            width: 12,
                            height: 12,
                            borderRadius: "50%",
                            bgcolor: category.color,
                            border: "1px solid",
                            borderColor: "divider",
                          }}
                        />
                        {category.name}
                      </Box>
                    </Option>
                  ))}
                </Select>
              </FormControl>
              <Button
                size="sm"
                variant="solid"
                onClick={handleBulkCategorize}
                disabled={!bulkCategoryId || bulkCategorize.isPending}
                loading={bulkCategorize.isPending}
              >
                Assign Category
              </Button>
              <Button
                size="sm"
                variant="plain"
                onClick={() => setSelectedIds([])}
              >
                Clear
              </Button>
            </Stack>
          </Box>
        )}

        <Box
          sx={{
            height: 400,
            overflowY: "auto",
            border: "1px solid",
            borderColor: "divider",
            borderRadius: "sm",
          }}
        >
          <Table stickyHeader>
            <thead>
              <tr>
                <th style={{ width: 40 }}>
                  <Checkbox
                    checked={
                      selectedIds.length === transactions.length &&
                      transactions.length > 0
                    }
                    indeterminate={
                      selectedIds.length > 0 &&
                      selectedIds.length < transactions.length
                    }
                    onChange={(e) => handleSelectAll(e.target.checked)}
                  />
                </th>
                <th>Description</th>
                <th>Amount</th>
                <th>Date</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                Array.from({ length: 10 }).map((_, index) => (
                  <tr key={`loading-${index}`}>
                    <td>
                      <Checkbox disabled />
                    </td>
                    <td>
                      <Skeleton variant="text" level="body-sm" width="80%" />
                    </td>
                    <td>
                      <Skeleton variant="text" level="body-sm" width="60%" />
                    </td>
                    <td>
                      <Skeleton variant="text" level="body-sm" width="70%" />
                    </td>
                    <td>
                      <Stack direction="row" spacing={1}>
                        <FormControl size="sm" sx={{ minWidth: 120 }}>
                          <Skeleton
                            variant="rectangular"
                            width="100%"
                            height={32}
                          />
                        </FormControl>
                        {onEdit && (
                          <IconButton size="sm" variant="outlined" disabled>
                            <EditIcon />
                          </IconButton>
                        )}
                      </Stack>
                    </td>
                  </tr>
                ))
              ) : error ? (
                <tr>
                  <td colSpan={5}>
                    <Typography
                      level="body-sm"
                      color="danger"
                      textAlign="center"
                      py={4}
                    >
                      Failed to load transactions
                    </Typography>
                  </td>
                </tr>
              ) : transactions.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    <Typography
                      level="body-sm"
                      color="neutral"
                      textAlign="center"
                      py={4}
                    >
                      No uncategorized transactions
                    </Typography>
                  </td>
                </tr>
              ) : (
                transactions.map((transaction: Transaction) => (
                  <tr key={transaction.id}>
                    <td>
                      <Checkbox
                        checked={selectedIds.includes(transaction.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedIds((prev) => [...prev, transaction.id]);
                          } else {
                            setSelectedIds((prev) =>
                              prev.filter((id) => id !== transaction.id)
                            );
                          }
                        }}
                      />
                    </td>
                    <td>
                      <Typography level="body-sm">
                        {transaction.description || "-- no description --"}
                      </Typography>
                    </td>
                    <td>
                      <Typography
                        level="body-sm"
                        color={transaction.amount < 0 ? "danger" : "success"}
                      >
                        {formatCurrency(transaction.amount)}
                      </Typography>
                    </td>
                    <td>
                      <Typography level="body-sm">
                        {formatDate(transaction.date)}
                      </Typography>
                    </td>
                    <td>
                      <Stack direction="row" spacing={1}>
                        <FormControl size="sm" sx={{ minWidth: 120 }}>
                          <Select
                            placeholder="Category"
                            onChange={(_, value) => {
                              if (value) {
                                handleSingleCategorize(
                                  transaction.id,
                                  Number(value)
                                );
                              }
                            }}
                          >
                            {categories.map((category) => (
                              <Option
                                key={category.id}
                                value={String(category.id)}
                              >
                                <Box
                                  sx={{
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 1,
                                  }}
                                >
                                  <Box
                                    sx={{
                                      width: 12,
                                      height: 12,
                                      borderRadius: "50%",
                                      bgcolor: category.color,
                                      border: "1px solid",
                                      borderColor: "divider",
                                    }}
                                  />
                                  {category.name}
                                </Box>
                              </Option>
                            ))}
                          </Select>
                        </FormControl>
                        {onEdit && (
                          <IconButton
                            size="sm"
                            variant="outlined"
                            onClick={() => onEdit(transaction)}
                          >
                            <EditIcon />
                          </IconButton>
                        )}
                      </Stack>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </Table>
        </Box>

        {((pagination && pagination.total_count > 0) || isLoading) && (
          <Box
            sx={{
              mt: 3,
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
            }}
          >
            <Stack direction="row" spacing={1}>
              <Button
                size="sm"
                variant="outlined"
                disabled={isLoading || !pagination?.has_prev_page}
                onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
              >
                Previous
              </Button>
              <Button
                size="sm"
                variant="outlined"
                disabled={isLoading || !pagination?.has_next_page}
                onClick={() => setCurrentPage((prev) => prev + 1)}
              >
                Next
              </Button>
            </Stack>
          </Box>
        )}
      </AccordionDetails>
    </Accordion>
  );
};

export default UncategorizedTransactions;
