import React, { useState, useEffect } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  IconButton,
  Stack,
  Grid,
  Menu,
  MenuItem,
  ListItemDecorator,
  Alert,
  CircularProgress,
} from "@mui/joy";
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  MoreVert as MoreVertIcon,
  Palette as PaletteIcon,
} from "@mui/icons-material";
import { useCategories, useDeleteCategory } from "@/hooks/useApi";
import type { Category } from "@/types";

interface CategoryListProps {
  onEdit: (category: Category) => void;
  onAdd: () => void;
}

const CategoryList: React.FC<CategoryListProps> = ({ onEdit, onAdd }) => {
  const { data: categories = [], isLoading, error } = useCategories();
  const deleteCategory = useDeleteCategory();
  const [menuAnchor, setMenuAnchor] = useState<{
    [key: number]: HTMLElement | null;
  }>({});

  const handleMenuOpen = (
    event: React.MouseEvent<HTMLElement>,
    categoryId: number
  ) => {
    setMenuAnchor((prev) => ({
      ...prev,
      [categoryId]: event.currentTarget,
    }));
  };

  const handleMenuClose = (categoryId: number) => {
    setMenuAnchor((prev) => ({
      ...prev,
      [categoryId]: null,
    }));
  };

  const closeAllMenus = () => {
    setMenuAnchor({});
  };

  useEffect(() => {
    const handleGlobalClick = (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      const isMenuButton = target.closest("[data-menu-button]");
      const isInsideMenu = target.closest('[role="menu"]');

      if (!isMenuButton && !isInsideMenu) {
        closeAllMenus();
      }
    };

    document.addEventListener("mousedown", handleGlobalClick);

    return () => {
      document.removeEventListener("mousedown", handleGlobalClick);
    };
  }, []);

  const handleDelete = async (category: Category) => {
    if (window.confirm(`Are you sure you want to delete "${category.name}"?`)) {
      try {
        await deleteCategory.mutateAsync(category.id);
      } catch (error) {
        console.error("Delete failed:", error);
      }
    }
    handleMenuClose(category.id);
  };

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert color="danger">Failed to load categories. Please try again.</Alert>
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
        <Typography level="h3">Categories</Typography>
        <Button variant="solid" startDecorator={<AddIcon />} onClick={onAdd}>
          Add Category
        </Button>
      </Box>

      {categories.length === 0 ? (
        <Card>
          <CardContent sx={{ textAlign: "center", py: 4 }}>
            <PaletteIcon
              sx={{ fontSize: 48, color: "text.secondary", mb: 2 }}
            />
            <Typography level="h4" sx={{ mb: 1 }}>
              No categories yet
            </Typography>
            <Typography level="body-md" color="neutral" sx={{ mb: 3 }}>
              Create your first category to start organizing transactions
            </Typography>
            <Button
              variant="solid"
              startDecorator={<AddIcon />}
              onClick={onAdd}
            >
              Create Category
            </Button>
          </CardContent>
        </Card>
      ) : (
        <Grid container spacing={2}>
          {categories.map((category) => (
            <Grid xs={12} sm={6} md={4} lg={3} key={category.id}>
              <Card>
                <CardContent>
                  <Box
                    sx={{
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "flex-start",
                    }}
                  >
                    <Box sx={{ flex: 1 }}>
                      <Stack
                        direction="row"
                        spacing={1}
                        alignItems="center"
                        sx={{ mb: 1 }}
                      >
                        <Box
                          sx={{
                            width: 16,
                            height: 16,
                            borderRadius: "50%",
                            bgcolor: category.color,
                            border: "1px solid",
                            borderColor: "divider",
                          }}
                        />
                        <Typography level="title-md">
                          {category.name}
                        </Typography>
                      </Stack>
                      <Typography level="body-sm" color="neutral">
                        Created{" "}
                        {new Date(category.created_at).toLocaleDateString()}
                      </Typography>
                    </Box>
                    <IconButton
                      size="sm"
                      variant="plain"
                      onClick={(e) => handleMenuOpen(e, category.id)}
                      data-menu-button
                    >
                      <MoreVertIcon />
                    </IconButton>
                  </Box>
                </CardContent>
              </Card>

              <Menu
                anchorEl={menuAnchor[category.id]}
                open={Boolean(menuAnchor[category.id])}
                onClose={() => handleMenuClose(category.id)}
                placement="bottom-end"
              >
                <MenuItem
                  onClick={() => {
                    onEdit(category);
                    handleMenuClose(category.id);
                  }}
                >
                  <ListItemDecorator>
                    <EditIcon />
                  </ListItemDecorator>
                  Edit
                </MenuItem>
                <MenuItem color="danger" onClick={() => handleDelete(category)}>
                  <ListItemDecorator>
                    <DeleteIcon />
                  </ListItemDecorator>
                  Delete
                </MenuItem>
              </Menu>
            </Grid>
          ))}
        </Grid>
      )}
    </Box>
  );
};

export default CategoryList;
