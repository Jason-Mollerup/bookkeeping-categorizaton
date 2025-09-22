import React, { useState } from "react";
import CategoryList from "./CategoryList";
import CategoryForm from "./CategoryForm";
import type { Category } from "@/types";

const Categories: React.FC = () => {
  const [formOpen, setFormOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<
    Category | undefined
  >();
  const [formMode, setFormMode] = useState<"create" | "edit">("create");

  const handleAddCategory = () => {
    setEditingCategory(undefined);
    setFormMode("create");
    setFormOpen(true);
  };

  const handleEditCategory = (category: Category) => {
    setEditingCategory(category);
    setFormMode("edit");
    setFormOpen(true);
  };

  return (
    <>
      <CategoryList onAdd={handleAddCategory} onEdit={handleEditCategory} />

      <CategoryForm
        open={formOpen}
        onClose={() => setFormOpen(false)}
        category={editingCategory}
        mode={formMode}
      />
    </>
  );
};

export default Categories;
