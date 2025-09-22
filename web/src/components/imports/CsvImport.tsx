import React, { useCallback, useEffect, useState } from "react";
import {
  Box,
  Typography,
  Card,
  CardContent,
  LinearProgress,
  Alert,
  Chip,
  Stack,
  IconButton,
  Tooltip,
} from "@mui/joy";
import {
  CloudUpload as UploadIcon,
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
  Refresh as RefreshIcon,
  Delete as DeleteIcon,
} from "@mui/icons-material";
import { useDropzone } from "react-dropzone";
import {
  useCsvImports,
  useCreateCsvImport,
  useDeleteCsvImport,
} from "@/hooks/useApi";
import { useQueryClient } from "@tanstack/react-query";
import { queryKeys } from "@/hooks/useApi";
import { websocketService } from "@/services/websocket";
import { useAuth } from "@/contexts/AuthContext";
import type { CsvImport as CsvImportType } from "@/types";

const CsvImport: React.FC = () => {
  const { data: imports = [], refetch } = useCsvImports();
  const createImport = useCreateCsvImport();
  const deleteImport = useDeleteCsvImport();
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const [localImports, setLocalImports] = useState<CsvImportType[]>([]);
  const [isUploadingToS3, setIsUploadingToS3] = useState(false);
  const [uploadingFilename, setUploadingFilename] = useState<string | null>(
    null
  );

  useEffect(() => {
    setLocalImports(imports);
  }, [imports]);

  useEffect(() => {
    if (user?.id) {
      try {
        websocketService.connect(user.id);

        websocketService.onImportProgress((data) => {
          console.log("Received import progress:", data);

          setLocalImports((prev) =>
            prev.map((importItem) =>
              importItem.id === data.import_id
                ? {
                    ...importItem,
                    progress_percentage: data.progress_percentage || 0,
                    processed_rows: data.processed_rows || 0,
                    total_rows: data.total_rows || 0,
                    rows_per_second: data.rows_per_second || 0,
                    status: data.status || importItem.status,
                  }
                : importItem
            )
          );
        });

        websocketService.onImportCompleted((data) => {
          console.log("Received import completed:", data);

          setLocalImports((prev) =>
            prev.map((importItem) =>
              importItem.id === data.import_id
                ? {
                    ...importItem,
                    status: "completed",
                    progress_percentage: 100,
                    processed_rows:
                      data.processed_rows || importItem.processed_rows,
                    total_rows: data.total_rows || importItem.total_rows,
                    completed_at: data.timestamp || new Date().toISOString(),
                  }
                : importItem
            )
          );

          if (data.cache_cleared) {
            console.log(
              "Cache cleared by backend, invalidating frontend queries"
            );
            queryClient.invalidateQueries({ queryKey: ["transactions"] });
            queryClient.invalidateQueries({ queryKey: queryKeys.dashboard });
            queryClient.invalidateQueries({
              queryKey: queryKeys.spendingTrends,
            });
            queryClient.invalidateQueries({
              queryKey: queryKeys.recentActivity,
            });
            queryClient.invalidateQueries({ queryKey: queryKeys.anomalies() });
            queryClient.invalidateQueries({ queryKey: ["csv-imports"] });

            queryClient.invalidateQueries({
              queryKey: ["transactions"],
              predicate: (query) => {
                const filters = query.queryKey[1] as any;
                return filters?.uncategorized === true;
              },
            });
          }
        });

        websocketService.onImportFailed((data) => {
          console.log("Received import failed:", data);

          setLocalImports((prev) =>
            prev.map((importItem) =>
              importItem.id === data.import_id
                ? {
                    ...importItem,
                    status: "failed",
                    error_message:
                      data.error_message || "Unknown error occurred",
                  }
                : importItem
            )
          );
        });
      } catch (error) {
        console.warn(
          "WebSocket connection failed, continuing without real-time updates:",
          error
        );
      }
    }

    return () => {
      try {
        websocketService.disconnect();
      } catch (error) {
        console.warn("WebSocket disconnect error:", error);
      }
    };
  }, [user?.id, queryClient]);

  const onDrop = useCallback(
    (acceptedFiles: File[]) => {
      if (acceptedFiles.length > 0) {
        const file = acceptedFiles[0];

        setIsUploadingToS3(true);
        setUploadingFilename(file.name);

        createImport.mutate(
          { file },
          {
            onSuccess: () => {
              refetch();
              setIsUploadingToS3(false);
              setUploadingFilename(null);
            },
            onError: (error) => {
              console.error("Upload failed:", error);
              setIsUploadingToS3(false);
              setUploadingFilename(null);
            },
          }
        );
      }
    },
    [createImport, refetch]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      "text/csv": [".csv"],
    },
    multiple: false,
    disabled: isUploadingToS3 || createImport.isPending,
  });

  const handleDelete = (importId: number) => {
    deleteImport.mutate(importId, {
      onSuccess: () => {
        refetch();
      },
    });
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "completed":
        return "success";
      case "failed":
        return "danger";
      case "processing":
        return "warning";
      default:
        return "neutral";
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "completed":
        return <CheckIcon />;
      case "failed":
        return <ErrorIcon />;
      case "processing":
        return <RefreshIcon />;
      default:
        return null;
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography level="h2" sx={{ mb: 3 }}>
        CSV Import
      </Typography>

      <div {...getRootProps()}>
        <Card
          sx={{
            mb: 3,
            border: "2px dashed",
            borderColor: isDragActive ? "primary.300" : "neutral.300",
            backgroundColor: isDragActive
              ? "background.level2"
              : "background.surface",
            transition: "all 0.2s ease",
            cursor:
              isUploadingToS3 || createImport.isPending
                ? "not-allowed"
                : "pointer",
            opacity: isUploadingToS3 || createImport.isPending ? 0.6 : 1,
          }}
        >
          <CardContent
            sx={{
              textAlign: "center",
              py: 4,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
            }}
          >
            <input {...getInputProps()} />
            {isUploadingToS3 || createImport.isPending ? (
              <>
                <RefreshIcon
                  sx={{
                    fontSize: 48,
                    mb: 2,
                    color: "primary.500",
                    animation: "spin 1s linear infinite",
                    "@keyframes spin": {
                      "0%": { transform: "rotate(0deg)" },
                      "100%": { transform: "rotate(360deg)" },
                    },
                  }}
                />
                <Typography level="h4" sx={{ mb: 1, color: "primary.600" }}>
                  Uploading...
                </Typography>
                {uploadingFilename && (
                  <Typography
                    level="body-lg"
                    sx={{ mb: 1, color: "primary.700", fontWeight: "bold" }}
                  >
                    {uploadingFilename}
                  </Typography>
                )}
                <Typography
                  level="body-md"
                  sx={{ mb: 2, color: "text.secondary" }}
                >
                  Please wait while your file is being uploaded
                </Typography>
                <LinearProgress
                  sx={{ width: "100%", maxWidth: 300, mt: 2 }}
                  variant="soft"
                />
              </>
            ) : (
              <>
                <UploadIcon
                  color="primary"
                  sx={{
                    fontSize: 48,
                    mb: 2,
                  }}
                />
                <Typography level="h4" sx={{ mb: 1 }}>
                  {isDragActive ? "Drop your CSV file here" : "Upload CSV File"}
                </Typography>
                <Typography
                  level="body-md"
                  sx={{ mb: 2, color: "text.secondary" }}
                >
                  Drag and drop a CSV file, or click to browse
                </Typography>
                <Typography level="body-sm" sx={{ color: "text.tertiary" }}>
                  Supported format: CSV files with columns: amount, description,
                  date, category_id
                </Typography>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      <Typography level="h3" sx={{ mb: 2 }}>
        Import History
      </Typography>

      {localImports.length === 0 ? (
        <Card>
          <CardContent sx={{ textAlign: "center", py: 4 }}>
            <Typography level="body-md" sx={{ color: "text.secondary" }}>
              No imports yet. Upload a CSV file to get started.
            </Typography>
          </CardContent>
        </Card>
      ) : (
        <Stack spacing={2}>
          {localImports.map((importItem: CsvImportType) => (
            <Card key={importItem.id}>
              <CardContent>
                <Stack
                  direction="row"
                  justifyContent="space-between"
                  alignItems="flex-start"
                  sx={{ mb: 2 }}
                >
                  <Box>
                    <Typography level="title-md" sx={{ mb: 1 }}>
                      {importItem.filename}
                    </Typography>
                    <Stack direction="row" spacing={1} sx={{ mb: 1 }}>
                      <Chip
                        size="sm"
                        color={getStatusColor(importItem.status)}
                        startDecorator={getStatusIcon(importItem.status)}
                      >
                        {importItem.status}
                      </Chip>
                      <Chip size="sm" variant="outlined">
                        {importItem.file_size_mb} MB
                      </Chip>
                      <Chip size="sm" variant="outlined">
                        {importItem.total_rows.toLocaleString()} rows
                      </Chip>
                    </Stack>
                  </Box>
                  <Stack direction="row" spacing={1}>
                    <Tooltip
                      title="Refresh"
                      variant="outlined"
                      size="sm"
                      placement="top"
                    >
                      <IconButton
                        size="sm"
                        variant="outlined"
                        onClick={() => refetch()}
                      >
                        <RefreshIcon />
                      </IconButton>
                    </Tooltip>
                    {importItem.status !== "processing" && (
                      <Tooltip
                        title="Delete"
                        variant="outlined"
                        size="sm"
                        placement="top"
                      >
                        <IconButton
                          size="sm"
                          variant="outlined"
                          color="danger"
                          onClick={() => handleDelete(importItem.id)}
                        >
                          <DeleteIcon />
                        </IconButton>
                      </Tooltip>
                    )}
                  </Stack>
                </Stack>

                {importItem.status === "processing" && (
                  <Box sx={{ mb: 2 }}>
                    <Stack
                      direction="row"
                      justifyContent="space-between"
                      alignItems="center"
                      sx={{ mb: 1 }}
                    >
                      <Typography level="body-sm">
                        Processing...{" "}
                        {importItem.processed_rows.toLocaleString()} /{" "}
                        {importItem.total_rows.toLocaleString()} rows
                      </Typography>
                      <Typography
                        level="body-sm"
                        sx={{ color: "text.secondary" }}
                      >
                        {importItem.progress_percentage}%
                      </Typography>
                    </Stack>
                    <LinearProgress
                      determinate
                      value={importItem.progress_percentage}
                    />
                    {importItem.rows_per_second > 0 && (
                      <Typography
                        level="body-xs"
                        sx={{ mt: 1, color: "text.tertiary" }}
                      >
                        {importItem.rows_per_second} rows/second
                      </Typography>
                    )}
                  </Box>
                )}

                {importItem.status === "failed" && importItem.error_message && (
                  <Alert color="danger" sx={{ mb: 2 }}>
                    <Typography level="body-sm">
                      {importItem.error_message}
                    </Typography>
                  </Alert>
                )}

                {importItem.status === "completed" && (
                  <Box sx={{ mb: 2 }}>
                    <Stack direction="row" spacing={2}>
                      <Typography level="body-sm">
                        <strong>Processed:</strong>{" "}
                        {importItem.processed_rows.toLocaleString()} rows
                      </Typography>
                      {importItem.error_rows > 0 && (
                        <Typography
                          level="body-sm"
                          sx={{ color: "warning.600" }}
                        >
                          <strong>Errors:</strong>{" "}
                          {importItem.error_rows.toLocaleString()} rows
                        </Typography>
                      )}
                      <Typography level="body-sm">
                        <strong>Time:</strong>{" "}
                        {importItem.processing_time_seconds}s
                      </Typography>
                    </Stack>
                  </Box>
                )}

                <Typography level="body-xs" sx={{ color: "text.tertiary" }}>
                  Created: {new Date(importItem.created_at).toLocaleString()}
                  {importItem.completed_at && (
                    <>
                      {" "}
                      • Completed:{" "}
                      {new Date(importItem.completed_at).toLocaleString()}
                    </>
                  )}
                </Typography>
              </CardContent>
            </Card>
          ))}
        </Stack>
      )}
    </Box>
  );
};

export default CsvImport;
