import React, { useState } from "react";
import { Box, Typography, Stack } from "@mui/joy";
import SpendingChart from "./SpendingChart";
import UncategorizedTransactions from "./UncategorizedTransactions";
import AnomalyTransactions from "./AnomalyTransactions";
import TransactionForm from "../transactions/TransactionForm";
import type { Transaction } from "@/types";

const Dashboard: React.FC = () => {
  const [formOpen, setFormOpen] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<
    Transaction | undefined
  >();
  const [formMode, setFormMode] = useState<"create" | "edit">("create");

  const handleEditTransaction = (transaction: Transaction) => {
    setEditingTransaction(transaction);
    setFormMode("edit");
    setFormOpen(true);
  };
  return (
    <Box sx={{ p: 3 }}>
      <Typography level="h2" sx={{ mb: 3 }}>
        Dashboard
      </Typography>

      <Stack spacing={4}>
        <Box>
          <Typography level="h4" sx={{ mb: 2 }}>
            Spending by Category
          </Typography>
          <SpendingChart />
        </Box>

        <Stack spacing={3}>
          <UncategorizedTransactions onEdit={handleEditTransaction} />

          <AnomalyTransactions onEdit={handleEditTransaction} />
        </Stack>
      </Stack>

      <TransactionForm
        open={formOpen}
        onClose={() => setFormOpen(false)}
        transaction={editingTransaction}
        mode={formMode}
      />
    </Box>
  );
};

export default Dashboard;
