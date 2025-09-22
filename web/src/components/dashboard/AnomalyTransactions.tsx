import React, { useState } from "react";
import {
  Box,
  Table,
  Typography,
  Button,
  Chip,
  IconButton,
  Stack,
  Tooltip,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Checkbox,
  Skeleton,
} from "@mui/joy";
import { alpha } from "@mui/material/styles";
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Error as ErrorIcon,
  CheckCircle as ApproveIcon,
  ExpandMore as ExpandMoreIcon,
} from "@mui/icons-material";
import {
  useTransactions,
  useBulkMarkReviewed,
  useBulkDelete,
} from "@/hooks/useApi";
import type { Transaction } from "@/types";

interface AnomalyTransactionsProps {
  onEdit?: (transaction: Transaction) => void;
}

const AnomalyTransactions: React.FC<AnomalyTransactionsProps> = ({
  onEdit,
}) => {
  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const [currentPage, setCurrentPage] = useState(1);

  const {
    data: transactionsData,
    isLoading,
    error,
  } = useTransactions({
    anomaly_types: [
      "unusual_amount",
      "duplicate",
      "missing_description",
      "suspicious_pattern",
    ],
    per_page: 100,
    page: currentPage,
  });
  const bulkMarkReviewed = useBulkMarkReviewed();
  const bulkDelete = useBulkDelete();

  const transactions = transactionsData?.data || [];
  const pagination = transactionsData?.pagination;

  const formatNumber = (number: number) => {
    return new Intl.NumberFormat("en-US").format(number);
  };

  const handleBulkAction = async (action: string) => {
    if (selectedIds.length === 0) return;

    try {
      switch (action) {
        case "approve":
          await bulkMarkReviewed.mutateAsync({
            transaction_ids: selectedIds,
          });
          break;
        case "delete":
          await bulkDelete.mutateAsync({
            transaction_ids: selectedIds,
          });
          break;
      }
      setSelectedIds([]);
    } catch (error) {
      console.error("Bulk action failed:", error);
    }
  };

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedIds(transactionsWithAnomalies.map((t: Transaction) => t.id));
    } else {
      setSelectedIds([]);
    }
  };

  const handleSingleApprove = async (transactionId: number) => {
    try {
      await bulkMarkReviewed.mutateAsync({
        transaction_ids: [transactionId],
      });
    } catch (error) {
      console.error("Single approve failed:", error);
    }
  };

  const handleSingleDelete = async (transactionId: number) => {
    try {
      await bulkDelete.mutateAsync({
        transaction_ids: [transactionId],
      });
    } catch (error) {
      console.error("Single delete failed:", error);
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

  const transactionsWithAnomalies = transactions.filter(
    (t) => t.anomalies && t.anomalies.length > 0
  );

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
          <Typography level="h4">Anomaly Transactions</Typography>
          <Typography level="body-sm" color="neutral">
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
              `${transactionsWithAnomalies.length} transactions`
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
            <Stack
              direction="row"
              spacing={2}
              alignItems="center"
              flexWrap="wrap"
            >
              <Typography level="body-sm">
                {selectedIds.length} transaction
                {selectedIds.length !== 1 ? "s" : ""} selected
              </Typography>

              <Button
                size="sm"
                variant="outlined"
                color="success"
                onClick={() => handleBulkAction("approve")}
                disabled={bulkMarkReviewed.isPending}
                loading={bulkMarkReviewed.isPending}
                startDecorator={<ApproveIcon />}
              >
                Approve
              </Button>

              <Button
                size="sm"
                variant="outlined"
                color="danger"
                onClick={() => handleBulkAction("delete")}
                disabled={bulkDelete.isPending}
                loading={bulkDelete.isPending}
                startDecorator={<DeleteIcon />}
              >
                Delete
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
                      selectedIds.length === transactionsWithAnomalies.length &&
                      transactionsWithAnomalies.length > 0
                    }
                    indeterminate={
                      selectedIds.length > 0 &&
                      selectedIds.length < transactionsWithAnomalies.length
                    }
                    onChange={(e) => handleSelectAll(e.target.checked)}
                  />
                </th>
                <th>Description</th>
                <th>Amount</th>
                <th>Category</th>
                <th>Date</th>
                <th>Anomalies</th>
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
                      <Skeleton
                        variant="rectangular"
                        width={80}
                        height={24}
                        sx={{ borderRadius: "sm" }}
                      />
                    </td>
                    <td>
                      <Skeleton variant="text" level="body-sm" width="70%" />
                    </td>
                    <td>
                      <Skeleton
                        variant="rectangular"
                        width={60}
                        height={24}
                        sx={{ borderRadius: "sm" }}
                      />
                    </td>
                    <td>
                      <Stack direction="row" spacing={1}>
                        {onEdit && (
                          <IconButton size="sm" variant="outlined" disabled>
                            <EditIcon />
                          </IconButton>
                        )}
                        <IconButton size="sm" variant="outlined" disabled>
                          <ApproveIcon />
                        </IconButton>
                        <IconButton size="sm" variant="outlined" disabled>
                          <DeleteIcon />
                        </IconButton>
                      </Stack>
                    </td>
                  </tr>
                ))
              ) : error ? (
                <tr>
                  <td colSpan={7}>
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
              ) : transactionsWithAnomalies.length === 0 ? (
                <tr>
                  <td colSpan={7}>
                    <Typography
                      level="body-sm"
                      color="neutral"
                      textAlign="center"
                      py={4}
                    >
                      No transactions with anomalies
                    </Typography>
                  </td>
                </tr>
              ) : (
                transactionsWithAnomalies.map((transaction: Transaction) => (
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
                      {transaction.category ? (
                        <Chip
                          size="sm"
                          variant="outlined"
                          sx={{
                            borderColor: transaction.category.color,
                            backgroundColor: alpha(
                              transaction.category.color,
                              0.15
                            ),
                          }}
                        >
                          {transaction.category.name}
                        </Chip>
                      ) : (
                        <Chip size="sm" color="neutral" variant="outlined">
                          Uncategorized
                        </Chip>
                      )}
                    </td>
                    <td>
                      <Typography level="body-sm">
                        {formatDate(transaction.date)}
                      </Typography>
                    </td>
                    <td>
                      <Stack direction="row" spacing={1}>
                        {transaction.anomalies &&
                          transaction.anomalies.length > 0 && (
                            <Tooltip
                              placement="top"
                              variant="outlined"
                              color="danger"
                              arrow
                              title={
                                <Stack direction="column" spacing={1}>
                                  {transaction.anomalies.map((anomaly) => (
                                    <Typography
                                      key={anomaly.id}
                                      level="title-sm"
                                      sx={{ fontSize: 12, maxWidth: 200 }}
                                    >
                                      {anomaly.description ||
                                        "No description available"}
                                    </Typography>
                                  ))}
                                </Stack>
                              }
                            >
                              <Chip
                                size="sm"
                                color="danger"
                                variant="soft"
                                startDecorator={<ErrorIcon />}
                              >
                                {transaction.anomalies.length} Anomaly
                                {transaction.anomalies.length !== 1 ? "s" : ""}
                              </Chip>
                            </Tooltip>
                          )}
                      </Stack>
                    </td>
                    <td>
                      <Stack direction="row" spacing={1}>
                        {onEdit && (
                          <Tooltip title="Edit transaction">
                            <IconButton
                              size="sm"
                              variant="outlined"
                              onClick={() => onEdit(transaction)}
                            >
                              <EditIcon />
                            </IconButton>
                          </Tooltip>
                        )}

                        <Tooltip title="Approve (mark as reviewed)">
                          <IconButton
                            size="sm"
                            variant="outlined"
                            color="success"
                            onClick={() => handleSingleApprove(transaction.id)}
                            disabled={bulkMarkReviewed.isPending}
                          >
                            <ApproveIcon />
                          </IconButton>
                        </Tooltip>

                        <Tooltip title="Delete transaction">
                          <IconButton
                            size="sm"
                            variant="outlined"
                            color="danger"
                            onClick={() => handleSingleDelete(transaction.id)}
                            disabled={bulkDelete.isPending}
                          >
                            <DeleteIcon />
                          </IconButton>
                        </Tooltip>
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

export default AnomalyTransactions;
