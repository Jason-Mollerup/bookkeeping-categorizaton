import React, { useState } from "react";
import {
  Box,
  Table,
  Sheet,
  Checkbox,
  Typography,
  Button,
  IconButton,
  Chip,
  Input,
  Select,
  Option,
  FormControl,
  FormLabel,
  Stack,
  Divider,
  Tooltip,
} from "@mui/joy";
import { alpha } from "@mui/material/styles";
import {
  Edit as EditIcon,
  FilterList as FilterIcon,
  Search as SearchIcon,
  Add as AddIcon,
  FileUpload as UploadIcon,
  Error as ErrorIcon,
  CloseRounded as CloseRoundedIcon,
} from "@mui/icons-material";
import {
  useTransactions,
  useBulkCategorize,
  useBulkMarkReviewed,
  useBulkDelete,
  useCategories,
} from "@/hooks/useApi";
import type { Transaction, TransactionFilters } from "@/types";
import { useNavigate } from "react-router-dom";

interface TransactionTableProps {
  onEdit?: (transaction: Transaction) => void;
  onAdd?: () => void;
  onImport?: () => void;
}

const formatNumber = (number: number) => {
  return new Intl.NumberFormat("en-US").format(number);
};

const TransactionTable: React.FC<TransactionTableProps> = ({
  onEdit,
  onAdd,
}) => {
  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const [filters, setFilters] = useState<TransactionFilters>({
    page: 1,
    per_page: 250,
  });
  const [searchInput, setSearchInput] = useState("");
  const [showFilters, setShowFilters] = useState(false);
  const navigate = useNavigate();
  const { data: transactionsData, isLoading, error } = useTransactions(filters);
  const { data: categories = [] } = useCategories();
  const bulkCategorize = useBulkCategorize();
  const bulkMarkReviewed = useBulkMarkReviewed();
  const bulkDelete = useBulkDelete();

  const transactions = transactionsData?.data || [];
  const pagination = transactionsData?.pagination;

  const handleSearch = () => {
    setFilters((prev) => ({
      ...prev,
      search: searchInput.trim() || undefined,
      page: 1,
    }));
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

  const handleClearSearch = () => {
    setSearchInput("");
    setFilters((prev) => ({
      ...prev,
      search: undefined,
      page: 1,
    }));
  };

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedIds(transactions.map((t: Transaction) => t.id));
    } else {
      setSelectedIds([]);
    }
  };

  const handleSelectTransaction = (id: number, checked: boolean) => {
    if (checked) {
      setSelectedIds((prev) => [...prev, id]);
    } else {
      setSelectedIds((prev) => prev.filter((selectedId) => selectedId !== id));
    }
  };

  const handleBulkAction = async (action: string, data?: any) => {
    if (selectedIds.length === 0) return;

    try {
      switch (action) {
        case "categorize":
          await bulkCategorize.mutateAsync({
            transaction_ids: selectedIds,
            category_id: data.categoryId,
          });
          break;
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

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString();
  };

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
        <Typography>Loading transactions...</Typography>
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 2 }}>
        <Typography color="danger">Failed to load transactions</Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Box
        sx={{
          mb: 3,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <Typography level="h3">Transactions</Typography>
        <Stack direction="row" spacing={2}>
          <Button
            variant="outlined"
            startDecorator={<UploadIcon />}
            onClick={() => navigate("/import")}
          >
            Import CSV
          </Button>
          <Button variant="solid" startDecorator={<AddIcon />} onClick={onAdd}>
            Add Transaction
          </Button>
        </Stack>
      </Box>

      <Sheet sx={{ p: 2, mb: 3, borderRadius: "sm" }}>
        <Stack direction="row" spacing={2} alignItems="center">
          <FormControl sx={{ flex: 1 }}>
            <Input
              placeholder="Search transactions... (press Enter to search)"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              onKeyPress={handleKeyPress}
              startDecorator={<SearchIcon />}
              endDecorator={
                searchInput && (
                  <IconButton
                    size="sm"
                    variant="plain"
                    onClick={handleClearSearch}
                  >
                    <CloseRoundedIcon fontSize="small" />
                  </IconButton>
                )
              }
            />
          </FormControl>
          <Button
            variant="outlined"
            onClick={handleSearch}
            startDecorator={<SearchIcon />}
          >
            Search
          </Button>

          <IconButton
            variant={showFilters ? "solid" : "outlined"}
            onClick={() => setShowFilters(!showFilters)}
          >
            <FilterIcon />
          </IconButton>
        </Stack>

        {showFilters && (
          <Box sx={{ mt: 2 }}>
            <Divider sx={{ mb: 2 }} />
            <Stack direction="row" spacing={2} alignItems="center">
              <FormControl size="sm">
                <FormLabel>Category</FormLabel>
                <Select
                  placeholder="All categories"
                  value={filters.category_id ? String(filters.category_id) : ""}
                  onChange={(_, value) =>
                    setFilters((prev) => ({
                      ...prev,
                      category_id: value ? Number(value) : undefined,
                    }))
                  }
                >
                  <Option value="">All categories</Option>
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
              <FormControl size="sm">
                <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                  <FormLabel>Anomaly Types</FormLabel>
                  {filters.anomaly_types &&
                    filters.anomaly_types.length > 0 && (
                      <Typography
                        level="body-xs"
                        color="primary"
                        sx={{
                          textDecoration: "underline",
                          cursor: "pointer",
                          justifySelf: "center",
                          mb: "4px",
                        }}
                        onClick={() => {
                          setFilters((prev) => ({
                            ...prev,
                            anomaly_types: undefined,
                          }));
                        }}
                      >
                        clear
                      </Typography>
                    )}
                </Box>
                <Select
                  multiple
                  placeholder="Select anomaly types"
                  value={filters.anomaly_types || []}
                  onChange={(_, value) => {
                    const selectedValues = Array.isArray(value)
                      ? value
                      : value
                      ? [value]
                      : [];
                    setFilters((prev) => ({
                      ...prev,
                      anomaly_types:
                        selectedValues.length > 0 ? selectedValues : undefined,
                    }));
                  }}
                  renderValue={(selected) => (
                    <Box
                      sx={{ display: "flex", gap: "0.25rem", flexWrap: "wrap" }}
                    >
                      {selected.length > 0 && (
                        <Chip
                          key={selected[0].value}
                          variant="soft"
                          color="primary"
                          size="sm"
                        >
                          {selected[0].label}
                        </Chip>
                      )}
                      {selected.length > 1 && (
                        <Chip variant="soft" color="primary" size="sm">
                          +{selected.length - 1} more
                        </Chip>
                      )}
                    </Box>
                  )}
                  sx={{ minWidth: "15rem" }}
                  slotProps={{
                    listbox: {
                      sx: {
                        width: "100%",
                      },
                    },
                  }}
                >
                  <Option value="unusual_amount">Unusual Amount</Option>
                  <Option value="duplicate">Potential Duplicate</Option>
                  <Option value="missing_description">
                    Missing Description
                  </Option>
                  <Option value="uncategorized">Uncategorized</Option>
                </Select>
              </FormControl>
            </Stack>
          </Box>
        )}
      </Sheet>

      {selectedIds.length > 0 && (
        <Sheet
          sx={{ p: 2, mb: 2, borderRadius: "sm", bgcolor: "background.level1" }}
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

            <FormControl size="sm" sx={{ minWidth: 200 }}>
              <Select
                placeholder="Categorize as..."
                onChange={(_, value) => {
                  if (value) {
                    handleBulkAction("categorize", {
                      categoryId: Number(value),
                    });
                  }
                }}
              >
                {categories.map((category) => (
                  <Option key={category.id} value={String(category.id)}>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
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
              variant="outlined"
              onClick={() => handleBulkAction("approve", {})}
            >
              Approve
            </Button>
            <Button
              size="sm"
              variant="outlined"
              color="danger"
              onClick={() => handleBulkAction("delete")}
            >
              Delete
            </Button>
            <Button
              size="sm"
              variant="plain"
              onClick={() => setSelectedIds([])}
            >
              Clear Selection
            </Button>
          </Stack>
        </Sheet>
      )}

      {pagination && pagination.total_count > 0 && (
        <Typography level="body-sm" color="neutral" mb={2}>
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
          of {formatNumber(pagination.total_count)} transactions
          {filters.search && <span> matching "{filters.search}"</span>}
        </Typography>
      )}

      <Sheet sx={{ borderRadius: "sm", overflow: "hidden" }}>
        <Table>
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
              <th>Category</th>
              <th>Date</th>
              <th>Anomalies</th>
              <th style={{ width: 70 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {transactions.map((transaction: Transaction) => (
              <tr key={transaction.id}>
                <td>
                  <Checkbox
                    checked={selectedIds.includes(transaction.id)}
                    onChange={(e) =>
                      handleSelectTransaction(transaction.id, e.target.checked)
                    }
                  />
                </td>
                <td>
                  <Typography
                    level="body-sm"
                    sx={{
                      ...(transaction.description
                        ? {}
                        : { fontStyle: "italic" }),
                    }}
                  >
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
                                  {anomaly.description}
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
                <td style={{ textAlign: "center" }}>
                  <IconButton
                    size="sm"
                    variant="plain"
                    onClick={() => onEdit?.(transaction)}
                  >
                    <EditIcon />
                  </IconButton>
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
      </Sheet>

      {pagination && pagination.total_count > 0 && (
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
              disabled={!pagination.has_prev_page}
              onClick={() =>
                setFilters((prev) => ({
                  ...prev,
                  page: (prev.page || 1) - 1,
                }))
              }
            >
              Previous
            </Button>
            <Button
              size="sm"
              variant="outlined"
              disabled={!pagination.has_next_page}
              onClick={() =>
                setFilters((prev) => ({
                  ...prev,
                  page: (prev.page || 1) + 1,
                }))
              }
            >
              Next
            </Button>
          </Stack>
        </Box>
      )}

      {pagination && pagination.total_count === 0 && (
        <Typography level="body-sm" color="neutral" mt={2} textAlign="center">
          No transactions found
        </Typography>
      )}
    </Box>
  );
};

export default TransactionTable;
