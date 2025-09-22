import React from "react";
import { Box, Sheet, Typography } from "@mui/joy";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  Legend,
} from "recharts";
import { useSpendingTrends, useCategories } from "@/hooks/useApi";
import type { Category } from "@/types";

const SpendingChart: React.FC = () => {
  const { data: spendingData, isLoading, error } = useSpendingTrends();
  const { data: categories = [] } = useCategories();

  if (isLoading) {
    return (
      <Sheet
        sx={{
          p: 3,
          borderRadius: "sm",
          height: 300,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Typography>Loading spending data...</Typography>
      </Sheet>
    );
  }

  if (error) {
    return (
      <Sheet
        sx={{
          p: 3,
          borderRadius: "sm",
          height: 300,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Typography color="danger">Failed to load spending data</Typography>
      </Sheet>
    );
  }

  if (
    !spendingData ||
    !spendingData.monthly_spending_by_category ||
    spendingData.monthly_spending_by_category.length === 0
  ) {
    return (
      <Sheet
        sx={{
          p: 3,
          borderRadius: "sm",
          height: 300,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Typography color="neutral">No spending data available</Typography>
      </Sheet>
    );
  }

  const chartData = spendingData.monthly_spending_by_category.map(
    (monthData: { month: string; [key: string]: string | number }) => {
      const transformedData: {
        month: string;
        displayMonth: string;
        [key: string]: string | number;
      } = {
        month: monthData.month,
        displayMonth: "",
      };

      const date = new Date(monthData.month + "-01");
      transformedData.displayMonth = date.toLocaleDateString("en-US", {
        month: "short",
        year: "numeric",
      });

      Object.keys(monthData).forEach((key) => {
        if (key !== "month") {
          transformedData[key] = Math.abs(Number(monthData[key]));
        }
      });

      return transformedData;
    }
  );

  const categoryColors: { [key: string]: string } = {};
  chartData.forEach(
    (monthData: {
      month: string;
      displayMonth: string;
      [key: string]: string | number;
    }) => {
      Object.keys(monthData).forEach((key) => {
        if (key !== "month" && key !== "displayMonth" && !categoryColors[key]) {
          const category = categories.find((cat: Category) => cat.name === key);
          categoryColors[key] = category?.color || "#8884D8";
        }
      });
    }
  );

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(value);
  };

  const CustomTooltip = ({
    active,
    payload,
    label,
  }: {
    active?: boolean;
    payload?: Array<{
      name: string;
      value: number;
      color: string;
      dataKey: string;
    }>;
    label?: string;
  }) => {
    if (active && payload && payload.length) {
      return (
        <Box
          sx={{
            bgcolor: "background.surface",
            p: 2,
            borderRadius: "sm",
            border: "1px solid",
            borderColor: "divider",
            boxShadow: 2,
          }}
        >
          <Typography level="body-sm" sx={{ mb: 1, fontWeight: "bold" }}>
            {label}
          </Typography>
          {payload.map((entry, index) => (
            <Typography key={index} level="body-sm" sx={{ color: entry.color }}>
              {entry.dataKey}: {formatCurrency(entry.value)}
            </Typography>
          ))}
        </Box>
      );
    }
    return null;
  };

  const allCategories = Object.keys(categoryColors);

  return (
    <Sheet sx={{ p: 3, borderRadius: "sm" }}>
      <ResponsiveContainer width="100%" height={400}>
        <BarChart
          data={chartData}
          margin={{
            top: 20,
            right: 30,
            left: 20,
            bottom: 5,
          }}
        >
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis
            dataKey="displayMonth"
            tick={{ fontSize: 12 }}
            angle={-45}
            textAnchor="end"
            height={80}
          />
          <YAxis
            tickFormatter={(value) => `$${value.toLocaleString()}`}
            tick={{ fontSize: 12 }}
          />
          <Tooltip content={<CustomTooltip />} />
          <Legend />
          {allCategories.map((category) => (
            <Bar
              key={category}
              dataKey={category}
              stackId="spending"
              fill={categoryColors[category]}
              name={category}
            />
          ))}
        </BarChart>
      </ResponsiveContainer>
    </Sheet>
  );
};

export default SpendingChart;
