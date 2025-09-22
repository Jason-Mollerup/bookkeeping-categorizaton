import React, { useState } from "react";
import TransactionTable from "./TransactionTable";
import TransactionForm from "./TransactionForm";
import type { Transaction } from "@/types";

const Transactions: React.FC = () => {
  const [formOpen, setFormOpen] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<
    Transaction | undefined
  >();
  const [formMode, setFormMode] = useState<"create" | "edit">("create");

  const handleAddTransaction = () => {
    setEditingTransaction(undefined);
    setFormMode("create");
    setFormOpen(true);
  };

  const handleEditTransaction = (transaction: Transaction) => {
    setEditingTransaction(transaction);
    setFormMode("edit");
    setFormOpen(true);
  };

  return (
    <>
      <TransactionTable
        onAdd={handleAddTransaction}
        onEdit={handleEditTransaction}
      />

      <TransactionForm
        open={formOpen}
        onClose={() => setFormOpen(false)}
        transaction={editingTransaction}
        mode={formMode}
      />
    </>
  );
};

export default Transactions;
