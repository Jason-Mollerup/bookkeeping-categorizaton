import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import { QueryClientProvider } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { CssVarsProvider } from "@mui/joy/styles";
import CssBaseline from "@mui/joy/CssBaseline";
import { queryClient } from "@/services/queryClient";
import { AuthProvider } from "@/contexts/AuthContext";
import Layout from "@/components/layout/Layout";
import Login from "@/components/auth/Login";
import Register from "@/components/auth/Register";
import Dashboard from "@/components/dashboard/Dashboard";
import Transactions from "@/components/transactions/Transactions";
import Categories from "@/components/categories/Categories";
import Rules from "@/components/rules/Rules";
import CsvImport from "@/components/imports/CsvImport";
import ProtectedRoute from "@/components/common/ProtectedRoute";

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <CssVarsProvider>
        <CssBaseline />
        <AuthProvider>
          <Router>
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route path="/register" element={<Register />} />
              <Route
                path="/*"
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Routes>
                        <Route
                          path="/"
                          element={<Navigate to="/dashboard" replace />}
                        />
                        <Route path="/dashboard" element={<Dashboard />} />
                        <Route
                          path="/transactions"
                          element={<Transactions />}
                        />
                        <Route path="/categories" element={<Categories />} />
                        <Route path="/rules" element={<Rules />} />
                        <Route path="/import" element={<CsvImport />} />
                      </Routes>
                    </Layout>
                  </ProtectedRoute>
                }
              />
            </Routes>
          </Router>
        </AuthProvider>
      </CssVarsProvider>
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}

export default App;
