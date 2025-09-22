import React, { useEffect } from "react";
import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as yup from "yup";
import {
  Modal,
  ModalDialog,
  ModalClose,
  DialogTitle,
  DialogContent,
  FormControl,
  FormLabel,
  Input,
  Button,
  Stack,
  Typography,
} from "@mui/joy";
import { useCreateCategory, useUpdateCategory } from "@/hooks/useApi";
import type { Category, CategoryForm as CategoryFormType } from "@/types";

interface CategoryFormProps {
  open: boolean;
  onClose: () => void;
  category?: Category;
  mode: "create" | "edit";
}

const schema = yup.object({
  name: yup.string().required("Name is required"),
  color: yup.string().required("Color is required"),
});

const CategoryForm: React.FC<CategoryFormProps> = ({
  open,
  onClose,
  category,
  mode,
}) => {
  const createCategory = useCreateCategory();
  const updateCategory = useUpdateCategory();

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<CategoryFormType>({
    resolver: yupResolver(schema),
    defaultValues: {
      name: category?.name || "",
      color: category?.color || "#1976d2",
    },
  });

  const watchedColor = watch("color");

  useEffect(() => {
    if (open) {
      reset({
        name: category?.name || "",
        color: category?.color || "#1976d2",
      });
    }
  }, [open, category, reset]);

  const onSubmit = async (data: CategoryFormType) => {
    try {
      if (mode === "create") {
        await createCategory.mutateAsync(data);
      } else if (category) {
        await updateCategory.mutateAsync({
          id: category.id,
          data,
        });
      }
      onClose();
      reset();
    } catch (error) {
      console.error("Category save failed:", error);
    }
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Modal open={open} onClose={handleClose}>
      <ModalDialog sx={{ maxWidth: 400 }}>
        <ModalClose />
        <DialogTitle>
          {mode === "create" ? "Add Category" : "Edit Category"}
        </DialogTitle>
        <DialogContent>
          <form onSubmit={handleSubmit(onSubmit)}>
            <Stack spacing={3}>
              <FormControl error={!!errors.name}>
                <FormLabel>Name *</FormLabel>
                <Input
                  {...register("name")}
                  placeholder="Enter category name"
                />
                {errors.name && (
                  <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                    {errors.name.message}
                  </Typography>
                )}
              </FormControl>

              <FormControl error={!!errors.color}>
                <FormLabel>Color *</FormLabel>
                <Stack direction="row" spacing={2} alignItems="center">
                  <Input
                    type="color"
                    value={watchedColor}
                    onChange={(e) => setValue("color", e.target.value)}
                    sx={{ width: 60, height: 40 }}
                  />
                  <Input
                    {...register("color")}
                    placeholder="#1976d2"
                    sx={{ flex: 1 }}
                  />
                </Stack>
                {errors.color && (
                  <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                    {errors.color.message}
                  </Typography>
                )}
              </FormControl>

              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button
                  variant="outlined"
                  onClick={handleClose}
                  disabled={
                    createCategory.isPending || updateCategory.isPending
                  }
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  loading={createCategory.isPending || updateCategory.isPending}
                >
                  {mode === "create" ? "Add Category" : "Update Category"}
                </Button>
              </Stack>
            </Stack>
          </form>
        </DialogContent>
      </ModalDialog>
    </Modal>
  );
};

export default CategoryForm;
