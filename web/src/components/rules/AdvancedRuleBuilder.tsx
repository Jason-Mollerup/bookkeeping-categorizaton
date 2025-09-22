import React, { useState, useEffect, useCallback } from "react";
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
  Select,
  Option,
  Divider,
  Box,
  Tabs,
  TabList,
  Tab,
  TabPanel,
  Textarea,
  Card,
  CardContent,
  Table,
  type ColorPaletteProp,
} from "@mui/joy";
import { useCreateRule, useUpdateRule, useCategories } from "@/hooks/useApi";
import type { CategorizationRule, RulePredicate } from "@/types";

interface AdvancedRuleBuilderProps {
  open: boolean;
  onClose: () => void;
  rule?: CategorizationRule;
  mode: "create" | "edit";
}

const VALID_STATUS = {
  exact: {
    color: "success",
    message: "Expression is valid",
  },
  partial: {
    color: "warning",
    message: "Part of your expression is invalid. Please check the syntax.",
  },
  invalid: {
    color: "danger",
    message: "Unable to parse expression. Please check the syntax.",
  },
};

const columns = [
  { value: "description", label: "Description", type: "STRING" },
  { value: "amount", label: "Amount", type: "NUMBER" },
  { value: "date", label: "Date", type: "DATE" },
];

const stringOperators = [
  { value: "CONTAINS", label: "Contains" },
  { value: "EQUALS", label: "Equals" },
  { value: "STARTS_WITH", label: "Starts with" },
  { value: "ENDS_WITH", label: "Ends with" },
  { value: "MATCHES", label: "Matches regex" },
];

const numberOperators = [
  { value: "GREATER_THAN", label: "Greater than" },
  { value: "LESS_THAN", label: "Less than" },
  { value: "GREATER_THAN_OR_EQUAL", label: "Greater than or equal" },
  { value: "LESS_THAN_OR_EQUAL", label: "Less than or equal" },
  { value: "EQUALS", label: "Equals" },
];

const dateOperators = [
  { value: "AFTER", label: "After" },
  { value: "BEFORE", label: "Before" },
  { value: "ON", label: "On" },
  { value: "DAY_OF_WEEK", label: "Day of week" },
];

const daysOfWeek = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

const schema = yup.object({
  name: yup.string().required("Rule name is required"),
  category_id: yup.number().required("Category is required"),
  priority: yup
    .number()
    .min(1, "Priority must be at least 1")
    .required("Priority is required"),
  active: yup.boolean(),
});

const AdvancedRuleBuilder: React.FC<AdvancedRuleBuilderProps> = ({
  open,
  onClose,
  rule,
  mode,
}) => {
  const { data: categories = [] } = useCategories();
  const createRule = useCreateRule();
  const updateRule = useUpdateRule();

  const [ruleType, setRuleType] = useState<"simple" | "complex">("simple");
  const [simplePredicate, setSimplePredicate] = useState<RulePredicate>({
    type: "STRING",
    column: "description",
    operator: "CONTAINS",
    operand: "",
  });
  const [complexExpression, setComplexExpression] = useState("");
  const [parsedPredicate, setParsedPredicate] = useState<RulePredicate | null>(
    null
  );
  const [selectedCategoryId, setSelectedCategoryId] = useState<
    number | undefined
  >(undefined);

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
  } = useForm({
    resolver: yupResolver(schema),
    defaultValues: {
      name: rule?.name || "",
      category_id: rule?.category_id || undefined,
      priority: rule?.priority || 1,
      active: rule?.active ?? true,
    },
  });

  const getOperatorSymbol = (operator: string): string => {
    const symbolMap: Record<string, string> = {
      CONTAINS: "contains",
      EQUALS: "=",
      STARTS_WITH: "starts with",
      ENDS_WITH: "ends with",
      MATCHES: "~",
      GREATER_THAN: ">",
      LESS_THAN: "<",
      GREATER_THAN_OR_EQUAL: ">=",
      LESS_THAN_OR_EQUAL: "<=",
      AFTER: "after",
      BEFORE: "before",
      ON: "on",
      DAY_OF_WEEK: "is",
    };
    return symbolMap[operator] || operator;
  };

  const formatOperand = (operand: any, type: string): string => {
    if (type === "STRING") {
      return `'${operand}'`;
    }
    return operand.toString();
  };

  const ruleToExpression = useCallback((predicate: RulePredicate): string => {
    if (predicate.type === "COMPOUND") {
      const subExpressions = predicate.predicates?.map(ruleToExpression) || [];
      const operator = predicate.operator === "AND" ? " and " : " or ";
      return `(${subExpressions.join(operator)})`;
    } else {
      const column = predicate.column || "";
      const operator = getOperatorSymbol(predicate.operator || "");
      const operand = formatOperand(predicate.operand, predicate.type);
      return `${column} ${operator} ${operand}`;
    }
  }, []);

  useEffect(() => {
    if (open && rule) {
      reset({
        name: rule.name,
        category_id: rule.category_id,
        priority: rule.priority,
        active: rule.active,
      });
      setSelectedCategoryId(rule.category_id);

      if (rule.rule_predicate.type === "COMPOUND") {
        setRuleType("complex");
        setComplexExpression(ruleToExpression(rule.rule_predicate));
        setParsedPredicate(rule.rule_predicate);
      } else {
        setRuleType("simple");
        setSimplePredicate(rule.rule_predicate);
      }
    } else if (open) {
      reset({
        name: "",
        category_id: undefined,
        priority: 1,
        active: true,
      });
      setSelectedCategoryId(undefined);
      setRuleType("simple");
      setSimplePredicate({
        type: "STRING",
        column: "description",
        operator: "CONTAINS",
        operand: "",
      });
      setComplexExpression("");
      setParsedPredicate(null);
    } else {
      reset();
      setSelectedCategoryId(undefined);
      setRuleType("simple");
      setSimplePredicate({
        type: "STRING",
        column: "description",
        operator: "CONTAINS",
        operand: "",
      });
      setComplexExpression("");
      setParsedPredicate(null);
    }
  }, [open, rule, reset, ruleToExpression]);

  const parseExpression = (expression: string): RulePredicate | null => {
    try {
      const trimmed = expression.trim();

      if (trimmed.includes(" and ") || trimmed.includes(" or ")) {
        const operator = trimmed.includes(" and ") ? "AND" : "OR";
        const parts = trimmed.split(operator === "AND" ? " and " : " or ");

        const predicates = parts
          .map((part) => {
            const cleanPart = part.trim().replace(/^\(|\)$/g, "");
            return parseSimpleExpression(cleanPart);
          })
          .filter(Boolean) as RulePredicate[];

        return {
          type: "COMPOUND",
          operator,
          predicates,
        };
      } else {
        return parseSimpleExpression(trimmed);
      }
    } catch (error) {
      console.error("Error parsing expression:", error);
      return null;
    }
  };

  const parseSimpleExpression = (expression: string): RulePredicate | null => {
    const patterns = [
      /^(\w+)\s+(contains|starts with|ends with|~)\s+['"]([^'"]+)['"]$/i,
      /^(\w+)\s+(=)\s+['"]([^'"]+)['"]$/i,
      /^(\w+)\s+(contains|starts with|ends with|~)\s+(\S+)$/i,
      /^(\w+)\s+(=)\s+(\S+)$/i,
      /^(\w+)\s+(>|>=|<|<=|=)\s+(-?\d+(?:\.\d+)?)$/,
      /^(\w+)\s+(after|before|on)\s+['"]([^'"]+)['"]$/i,
      /^(\w+)\s+(is)\s+(\w+)$/i,
    ];

    for (const pattern of patterns) {
      const match = expression.match(pattern);
      if (match) {
        const [, column, operator, operand] = match;

        const columnType =
          columns.find((c) => c.value === column)?.type || "STRING";

        const operatorMap: Record<string, string> = {
          contains: "CONTAINS",
          "starts with": "STARTS_WITH",
          "ends with": "ENDS_WITH",
          "~": "MATCHES",
          "=": "EQUALS",
          ">": "GREATER_THAN",
          ">=": "GREATER_THAN_OR_EQUAL",
          "<": "LESS_THAN",
          "<=": "LESS_THAN_OR_EQUAL",
          after: "AFTER",
          before: "BEFORE",
          on: "ON",
          is: "DAY_OF_WEEK",
        };

        return {
          type: columnType as "STRING" | "NUMBER" | "DATE",
          column,
          operator: operatorMap[operator] || operator,
          operand: columnType === "NUMBER" ? parseFloat(operand) : operand,
        };
      }
    }

    return null;
  };

  const handleComplexExpressionChange = (value: string) => {
    setComplexExpression(value);
    const parsed = parseExpression(value);
    setParsedPredicate(parsed);
  };

  const onSubmit = async (data: any) => {
    try {
      if (!data.name?.trim()) {
        alert("Rule name is required");
        return;
      }
      if (!data.category_id) {
        alert("Category is required");
        return;
      }
      if (!data.priority || data.priority < 1) {
        alert("Priority must be at least 1");
        return;
      }

      let rulePredicate: RulePredicate;

      if (ruleType === "simple") {
        if (!simplePredicate.column || !simplePredicate.operator) {
          alert("Please select column and operator for simple rule");
          return;
        }
        if (
          simplePredicate.operand === "" ||
          (simplePredicate.operand == null && simplePredicate.operand !== 0)
        ) {
          alert("Please enter a value for the rule condition");
          return;
        }
        rulePredicate = simplePredicate;
      } else {
        if (!parsedPredicate) {
          alert("Please enter a valid expression");
          return;
        }
        rulePredicate = parsedPredicate;
      }

      const ruleData = {
        ...data,
        rule_predicate: rulePredicate,
      };

      if (mode === "create") {
        await createRule.mutateAsync(ruleData);
      } else if (rule) {
        await updateRule.mutateAsync({ id: rule.id, data: ruleData });
      }
      onClose();
    } catch (error) {
      console.error("Failed to save rule:", error);
      alert(
        `Failed to save rule: ${
          error instanceof Error ? error.message : "Unknown error"
        }`
      );
    }
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  const getOperatorsForType = (type: string) => {
    switch (type) {
      case "STRING":
        return stringOperators;
      case "NUMBER":
        return numberOperators;
      case "DATE":
        return dateOperators;
      default:
        return [];
    }
  };

  const valid =
    complexExpression && !parsedPredicate
      ? "invalid"
      : parsedPredicate
      ? ruleToExpression(parsedPredicate)
          .replace(/['"]/g, "")
          .replace(/\(/g, "")
          .replace(/\)/g, "") ===
        complexExpression
          .replace(/['"]/g, "")
          .replace(/\(/g, "")
          .replace(/\)/g, "")
        ? "exact"
        : "partial"
      : null;

  const renderSimpleBuilder = () => (
    <Stack spacing={3}>
      <FormControl>
        <FormLabel>Column</FormLabel>
        <Select
          value={simplePredicate.column}
          onChange={(_, value) =>
            setSimplePredicate((prev) => ({
              ...prev,
              column: value || "description",
              type:
                (columns.find((c) => c.value === value)?.type as
                  | "STRING"
                  | "NUMBER"
                  | "DATE") || "STRING",
              operator: "CONTAINS",
            }))
          }
        >
          {columns.map((column) => (
            <Option key={column.value} value={column.value}>
              {column.label}
            </Option>
          ))}
        </Select>
      </FormControl>

      <FormControl>
        <FormLabel>Operator</FormLabel>
        <Select
          value={simplePredicate.operator}
          onChange={(_, value) =>
            setSimplePredicate((prev) => ({
              ...prev,
              operator: value || "CONTAINS",
            }))
          }
        >
          {getOperatorsForType(simplePredicate.type).map((op) => (
            <Option key={op.value} value={op.value}>
              {op.label}
            </Option>
          ))}
        </Select>
      </FormControl>

      <FormControl>
        <FormLabel>Value</FormLabel>
        {simplePredicate.operator === "DAY_OF_WEEK" ? (
          <Select
            value={simplePredicate.operand}
            onChange={(_, value) =>
              setSimplePredicate((prev) => ({
                ...prev,
                operand: value || "",
              }))
            }
          >
            {daysOfWeek.map((day) => (
              <Option key={day} value={day.toLowerCase()}>
                {day}
              </Option>
            ))}
          </Select>
        ) : (
          <Input
            value={simplePredicate.operand}
            onChange={(e) =>
              setSimplePredicate((prev) => ({
                ...prev,
                operand:
                  simplePredicate.type === "NUMBER"
                    ? e.target.value === ""
                      ? ""
                      : parseFloat(e.target.value)
                    : e.target.value,
              }))
            }
            placeholder={
              simplePredicate.type === "NUMBER"
                ? "-100 or 100"
                : simplePredicate.type === "DATE"
                ? "2024-01-01"
                : "Enter value"
            }
            type={simplePredicate.type === "NUMBER" ? "number" : "text"}
          />
        )}
      </FormControl>
    </Stack>
  );

  const renderComplexBuilder = () => (
    <Stack spacing={3}>
      <FormControl>
        <FormLabel>Expression</FormLabel>
        <Textarea
          value={complexExpression}
          onChange={(e) => handleComplexExpressionChange(e.target.value)}
          placeholder="(amount < -100) or (description contains 'starbucks')"
          minRows={3}
        />
        {valid !== null && (
          <Card
            variant="soft"
            color={VALID_STATUS[valid].color as ColorPaletteProp}
            sx={{ mt: 3 }}
          >
            <CardContent>
              <Typography level="title-sm">
                {VALID_STATUS[valid].message}
              </Typography>
              {parsedPredicate && (
                <Typography level="title-sm" fontFamily="mono">
                  {ruleToExpression(parsedPredicate)}
                </Typography>
              )}
            </CardContent>
          </Card>
        )}
        <Table variant="outlined" size="sm" sx={{ mt: 3 }}>
          <thead>
            <tr>
              <th>Column</th>
              <th>Valid Operators</th>
              <th>Example</th>
            </tr>
          </thead>
          <caption>
            See below for valid columns, operators, and examples
          </caption>
          <tbody>
            {columns.map((column) => (
              <tr key={column.value}>
                <td>{column.label}</td>
                <td>
                  {getOperatorsForType(column.type)
                    .map((op) => op.label)
                    .join(", ")}
                </td>
                <td>
                  {column.type === "STRING" &&
                    "description contains 'starbucks'"}
                  {column.type === "NUMBER" && "amount > 100"}
                  {column.type === "DATE" && "date after '2024-01-01'"}
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
      </FormControl>
    </Stack>
  );

  return (
    <Modal open={open} onClose={handleClose}>
      <ModalDialog sx={{ maxWidth: 700, width: "90vw" }}>
        <ModalClose />
        <DialogTitle>
          {mode === "create" ? "Create New Rule" : "Edit Rule"}
        </DialogTitle>
        <DialogContent>
          <form onSubmit={handleSubmit(onSubmit)}>
            <Stack spacing={3}>
              <FormControl error={!!errors.name}>
                <FormLabel>Rule Name *</FormLabel>
                <Input
                  {...register("name")}
                  placeholder="e.g., Starbucks Purchases"
                />
                {errors.name && (
                  <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                    {errors.name.message}
                  </Typography>
                )}
              </FormControl>

              <Tabs
                value={ruleType}
                onChange={(_, value) =>
                  setRuleType(value as "simple" | "complex")
                }
              >
                <TabList>
                  <Tab
                    value="simple"
                    sx={{
                      borderTopLeftRadius: 5,
                      borderTopRightRadius: 5,
                    }}
                  >
                    Simple Rule
                  </Tab>
                  <Tab
                    value="complex"
                    sx={{
                      borderTopLeftRadius: 5,
                      borderTopRightRadius: 5,
                    }}
                  >
                    Complex Expression
                  </Tab>
                </TabList>
                <TabPanel
                  value="simple"
                  variant="soft"
                  sx={{
                    borderBottomRightRadius: 5,
                    borderBottomLeftRadius: 5,
                  }}
                >
                  {renderSimpleBuilder()}
                </TabPanel>
                <TabPanel
                  value="complex"
                  variant="soft"
                  sx={{
                    borderBottomRightRadius: 5,
                    borderBottomLeftRadius: 5,
                  }}
                >
                  {renderComplexBuilder()}
                </TabPanel>
              </Tabs>

              <FormControl error={!!errors.category_id}>
                <FormLabel>Target Category *</FormLabel>
                <Select
                  value={selectedCategoryId ? String(selectedCategoryId) : ""}
                  onChange={(_, value) => {
                    const categoryId = value ? Number(value) : undefined;
                    setSelectedCategoryId(categoryId);
                    setValue("category_id", categoryId || 0);
                  }}
                  placeholder="Select category"
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
                {errors.category_id && (
                  <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                    {errors.category_id.message}
                  </Typography>
                )}
              </FormControl>

              <FormControl error={!!errors.priority}>
                <FormLabel>Priority *</FormLabel>
                <Input
                  {...register("priority", { valueAsNumber: true })}
                  type="number"
                  placeholder="1"
                />
                <Typography level="body-xs" color="neutral" sx={{ mt: 1 }}>
                  Lower numbers have higher priority (1 is highest)
                </Typography>
                {errors.priority && (
                  <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                    {errors.priority.message}
                  </Typography>
                )}
              </FormControl>

              <Divider />

              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button
                  variant="outlined"
                  onClick={handleClose}
                  disabled={createRule.isPending || updateRule.isPending}
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  loading={createRule.isPending || updateRule.isPending}
                >
                  {mode === "create" ? "Create Rule" : "Update Rule"}
                </Button>
              </Stack>
            </Stack>
          </form>
        </DialogContent>
      </ModalDialog>
    </Modal>
  );
};

export default AdvancedRuleBuilder;
