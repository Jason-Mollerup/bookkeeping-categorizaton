import React, { useEffect } from "react";
import { useForm } from "react-hook-form";
import {
  Modal,
  ModalDialog,
  ModalClose,
  DialogTitle,
  DialogContent,
  FormControl,
  FormLabel,
  Input,
  Select,
  Option,
  Button,
  Stack,
  Divider,
  Typography,
  Box,
} from "@mui/joy";
import {
  useCreateTransaction,
  useUpdateTransaction,
  useCategories,
} from "@/hooks/useApi";
import type {
  Transaction,
  TransactionForm as TransactionFormType,
} from "@/types";

interface TransactionFormProps {
  open: boolean;
  onClose: () => void;
  transaction?: Transaction;
  mode: "create" | "edit";
}

const TransactionForm: React.FC<TransactionFormProps> = ({
  open,
  onClose,
  transaction,
  mode,
}) => {
  const { data: categories = [] } = useCategories();
  const createTransaction = useCreateTransaction();
  const updateTransaction = useUpdateTransaction();

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<TransactionFormType>({
    defaultValues: {
      amount: transaction?.amount || 0,
      description: transaction?.description || "",
      date: transaction?.date || new Date().toISOString().split("T")[0],
      category_id: transaction?.category_id || undefined,
    },
  });

  const watchedCategoryId = watch("category_id");

  useEffect(() => {
    if (open) {
      reset({
        amount: transaction?.amount || 0,
        description: transaction?.description || "",
        date: transaction?.date || new Date().toISOString().split("T")[0],
        category_id: transaction?.category_id || undefined,
      });
    }
  }, [open, transaction, reset]);

  const onSubmit = async (data: any) => {
    try {
      const transactionData = {
        ...data,
        amount: parseFloat(data.amount),
        category_id: data.category_id || null,
      };

      if (mode === "create") {
        await createTransaction.mutateAsync(transactionData);
      } else if (transaction) {
        await updateTransaction.mutateAsync({
          id: transaction.id,
          data: transactionData,
        });
      }
      onClose();
      reset();
    } catch (error) {
      console.error("Transaction save failed:", error);
    }
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Modal open={open} onClose={handleClose}>
      <ModalDialog sx={{ width: 500 }}>
        <ModalClose />
        <DialogTitle>
          {mode === "create" ? "Add Transaction" : "Edit Transaction"}
        </DialogTitle>
        <DialogContent>
          <form onSubmit={handleSubmit(onSubmit)}>
            <Stack spacing={3}>
              <FormControl error={!!errors.amount}>
                <FormLabel>Amount *</FormLabel>
                <Input
                  {...register("amount", {
                    required: "Amount is required",
                    valueAsNumber: true,
                    validate: (value: number) => {
                      if (isNaN(value)) return "Please enter a valid number";
                      return true;
                    },
                  })}
                  type="text"
                  inputMode="decimal"
                  placeholder="0.00"
                />
                {errors.amount && (
                  <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                    {errors.amount.message}
                  </Typography>
                )}
              </FormControl>

              <FormControl error={!!errors.description}>
                <FormLabel>Description</FormLabel>
                <Input
                  {...register("description")}
                  placeholder="Enter transaction description"
                />
                {errors.description && (
                  <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                    {errors.description.message}
                  </Typography>
                )}
              </FormControl>

              <FormControl error={!!errors.date}>
                <FormLabel>Date *</FormLabel>
                <Input {...register("date")} type="date" />
                {errors.date && (
                  <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                    {errors.date.message}
                  </Typography>
                )}
              </FormControl>

              <FormControl>
                <FormLabel>Category</FormLabel>
                <Select
                  value={watchedCategoryId ? String(watchedCategoryId) : ""}
                  onChange={(_, value) =>
                    setValue("category_id", value ? Number(value) : undefined)
                  }
                  placeholder="Select category"
                >
                  <Option value="">No category</Option>
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

              <Divider />

              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button
                  variant="outlined"
                  onClick={handleClose}
                  disabled={
                    createTransaction.isPending || updateTransaction.isPending
                  }
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  loading={
                    createTransaction.isPending || updateTransaction.isPending
                  }
                >
                  {mode === "create" ? "Add Transaction" : "Update Transaction"}
                </Button>
              </Stack>
            </Stack>
          </form>
        </DialogContent>
      </ModalDialog>
    </Modal>
  );
};

export default TransactionForm;
