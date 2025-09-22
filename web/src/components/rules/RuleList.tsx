import React, { useState, useEffect } from "react";
import {
  Box,
  Typography,
  Button,
  Card,
  CardContent,
  IconButton,
  Stack,
  Chip,
  Menu,
  MenuItem,
  ListItemDecorator,
  Alert,
  CircularProgress,
  Switch,
  Tooltip,
  Grid,
} from "@mui/joy";
import { alpha } from "@mui/system";
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  MoreVert as MoreVertIcon,
  Rule as RuleIcon,
} from "@mui/icons-material";
import {
  useCategorizationRules,
  useDeleteRule,
  useUpdateRule,
} from "@/hooks/useApi";
import type { CategorizationRule } from "@/types";

interface RuleListProps {
  onAdd: () => void;
  onEdit: (rule: CategorizationRule) => void;
}

const RuleList: React.FC<RuleListProps> = ({ onAdd, onEdit }) => {
  const { data: rules = [], isLoading, error } = useCategorizationRules();
  const deleteRule = useDeleteRule();
  const updateRule = useUpdateRule();
  const [menuAnchor, setMenuAnchor] = useState<{
    [key: number]: HTMLElement | null;
  }>({});

  const handleMenuOpen = (
    event: React.MouseEvent<HTMLElement>,
    ruleId: number
  ) => {
    setMenuAnchor((prev) => ({
      ...prev,
      [ruleId]: event.currentTarget,
    }));
  };

  const handleMenuClose = (ruleId: number) => {
    setMenuAnchor((prev) => ({
      ...prev,
      [ruleId]: null,
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

  const handleDelete = async (rule: CategorizationRule) => {
    try {
      await deleteRule.mutateAsync(rule.id);
      handleMenuClose(rule.id);
    } catch (err) {
      console.error("Failed to delete rule:", err);
    }
  };

  const handleToggleActive = async (rule: CategorizationRule) => {
    try {
      await updateRule.mutateAsync({
        id: rule.id,
        data: {
          active: !rule.active,
        },
      });
    } catch (err) {
      console.error("Failed to update rule:", err);
    }
  };

  const getConditionDisplay = (rule: CategorizationRule) => {
    return formatPredicate(rule.rule_predicate);
  };

  const formatPredicate = (predicate: any): string => {
    if (!predicate) return "Invalid rule";

    switch (predicate.type) {
      case "STRING":
        return `${predicate.column} ${getOperatorLabel(predicate.operator)} "${
          predicate.operand
        }"`;
      case "NUMBER":
        return `${predicate.column} ${getOperatorLabel(predicate.operator)} ${
          predicate.operand
        }`;
      case "DATE":
        if (predicate.operator === "DAY_OF_WEEK") {
          return `${predicate.column} is ${predicate.operand}`;
        }
        return `${predicate.column} ${getOperatorLabel(predicate.operator)} ${
          predicate.operand
        }`;
      case "COMPOUND":
        const subConditions = predicate.predicates?.map(formatPredicate) || [];
        const operator = predicate.operator === "AND" ? " AND " : " OR ";
        return `(${subConditions.join(operator)})`;
      default:
        return "Unknown condition type";
    }
  };

  const getOperatorLabel = (operator: string): string => {
    const operatorMap: Record<string, string> = {
      CONTAINS: "contains",
      EQUALS: "equals",
      STARTS_WITH: "starts with",
      ENDS_WITH: "ends with",
      MATCHES: "matches",
      GREATER_THAN: ">",
      LESS_THAN: "<",
      GREATER_THAN_OR_EQUAL: ">=",
      LESS_THAN_OR_EQUAL: "<=",
      AFTER: "after",
      BEFORE: "before",
      ON: "on",
      DAY_OF_WEEK: "is",
    };
    return operatorMap[operator] || operator;
  };

  if (isLoading) {
    return (
      <Box
        sx={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          height: "80vh",
        }}
      >
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert color="danger">Failed to load rules. Please try again.</Alert>
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
        <Typography level="h3">Categorization Rules</Typography>
        <Button variant="solid" startDecorator={<AddIcon />} onClick={onAdd}>
          Add Rule
        </Button>
      </Box>

      {rules.length === 0 ? (
        <Card>
          <CardContent sx={{ textAlign: "center", py: 4 }}>
            <RuleIcon sx={{ fontSize: 48, color: "text.secondary", mb: 2 }} />
            <Typography level="h4" sx={{ mb: 1 }}>
              No rules yet
            </Typography>
            <Typography level="body-md" color="neutral">
              Create your first categorization rule to automatically organize
              your transactions.
            </Typography>
          </CardContent>
        </Card>
      ) : (
        <Grid container spacing={2}>
          {rules
            .sort((a, b) => a.priority - b.priority)
            .map((rule) => (
              <Grid xs={12} lg={6} key={rule.id}>
                <Card key={rule.id}>
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
                          spacing={2}
                          alignItems="center"
                          sx={{ mb: 1 }}
                        >
                          <Typography level="title-lg">{rule.name}</Typography>
                        </Stack>

                        <Typography level="body-sm" sx={{ mb: 1 }}>
                          <strong>If:</strong> {getConditionDisplay(rule)}
                        </Typography>

                        <Box
                          sx={{ display: "flex", alignItems: "center", gap: 1 }}
                        >
                          <Typography level="body-sm">
                            <strong>Then:</strong> Categorize as
                          </Typography>
                          <Chip
                            size="sm"
                            color="primary"
                            variant="outlined"
                            sx={{
                              borderColor: rule.category?.color,
                              backgroundColor: alpha(
                                rule.category?.color,
                                0.15
                              ),
                            }}
                          >
                            {rule.category?.name || "Unknown Category"}
                          </Chip>
                        </Box>
                      </Box>

                      <Stack direction="row" spacing={1} alignItems="center">
                        <Tooltip
                          title={
                            rule.active ? "Deactivate rule" : "Activate rule"
                          }
                          variant="outlined"
                          placement="top"
                          size="sm"
                        >
                          <Switch
                            checked={rule.active}
                            onChange={() => handleToggleActive(rule)}
                            color={rule.active ? "success" : "neutral"}
                          />
                        </Tooltip>

                        <IconButton
                          variant="plain"
                          color="neutral"
                          size="sm"
                          data-menu-button
                          onClick={(event) => handleMenuOpen(event, rule.id)}
                        >
                          <MoreVertIcon />
                        </IconButton>

                        <Menu
                          anchorEl={menuAnchor[rule.id]}
                          open={Boolean(menuAnchor[rule.id])}
                          onClose={() => handleMenuClose(rule.id)}
                          placement="bottom-end"
                        >
                          <MenuItem
                            onClick={() => {
                              onEdit(rule);
                              handleMenuClose(rule.id);
                            }}
                          >
                            <ListItemDecorator>
                              <EditIcon />
                            </ListItemDecorator>
                            Edit
                          </MenuItem>
                          <MenuItem
                            color="danger"
                            onClick={() => handleDelete(rule)}
                          >
                            <ListItemDecorator>
                              <DeleteIcon />
                            </ListItemDecorator>
                            Delete
                          </MenuItem>
                        </Menu>
                      </Stack>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
        </Grid>
      )}
    </Box>
  );
};

export default RuleList;
