import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";
import * as yup from "yup";
import {
  Box,
  Typography,
  FormControl,
  FormLabel,
  Input,
  Button,
  Alert,
  Divider,
  Link as JoyLink,
  Checkbox,
  IconButton,
  Stack,
} from "@mui/joy";
import { Visibility, VisibilityOff } from "@mui/icons-material";
import { useAuth } from "@/contexts/AuthContext";
import type { LoginForm } from "@/types";

const schema = yup.object({
  email: yup.string().email("Invalid email").required("Email is required"),
  password: yup
    .string()
    .min(6, "Password must be at least 6 characters")
    .required("Password is required"),
});

const Login: React.FC = () => {
  const [error, setError] = useState<string>("");
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginForm>({
    resolver: yupResolver(schema),
  });

  const onSubmit = async (data: LoginForm) => {
    try {
      setIsLoading(true);
      setError("");
      await login(data);
      navigate("/transactions");
    } catch (err: any) {
      setError(err.response?.data?.error || "Login failed");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Box
      sx={{
        display: "flex",
        minHeight: "100vh",
        minWidth: "100vw",
        bgcolor: "background.body",
      }}
    >
      <Box
        sx={{
          flex: "0 0 50%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          bgcolor: "background.surface",
          px: 4,
          position: "relative",
        }}
      >
        <Box
          sx={{
            position: "absolute",
            top: 32,
            left: 32,
            display: "flex",
            alignItems: "center",
            gap: 1,
          }}
        >
          <Box
            sx={{
              width: 32,
              height: 32,
              borderRadius: 1,
              bgcolor: "primary.500",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Typography
              level="title-sm"
              sx={{ color: "white", fontWeight: "bold" }}
            >
              B
            </Typography>
          </Box>
          <Typography level="title-md" sx={{ fontWeight: "bold" }}>
            Bookkeeping
          </Typography>
        </Box>

        <IconButton
          sx={{
            position: "absolute",
            top: 32,
            right: 32,
          }}
        >
          <Box
            sx={{
              width: 20,
              height: 20,
              borderRadius: "50%",
              bgcolor: "text.primary",
            }}
          />
        </IconButton>

        <Box
          sx={{
            width: "100%",
            maxWidth: 400,
            flexGrow: 1,
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
          }}
        >
          <Typography
            level="h1"
            sx={{ mb: 1, textAlign: "center", width: "100%" }}
          >
            Sign in
          </Typography>
          <Typography
            level="body-md"
            sx={{ mb: 4, textAlign: "center", color: "text.secondary" }}
          >
            New to Bookkeeping?{" "}
            <JoyLink component={Link} to="/register" sx={{ fontWeight: "lg" }}>
              Sign up!
            </JoyLink>
          </Typography>

          <Box
            sx={{ display: "flex", alignItems: "center", my: 3, width: "100%" }}
          >
            <Divider sx={{ flex: 1 }}>or</Divider>
          </Box>

          {error && (
            <Alert color="danger" sx={{ mb: 3 }}>
              {error}
            </Alert>
          )}

          <form onSubmit={handleSubmit(onSubmit)} style={{ width: "100%" }}>
            <FormControl sx={{ mb: 3, width: "100%" }}>
              <FormLabel>Email</FormLabel>
              <Input
                {...register("email")}
                type="email"
                placeholder="Enter your email"
                error={!!errors.email}
                sx={{ py: 1.5 }}
              />
              {errors.email && (
                <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                  {errors.email.message}
                </Typography>
              )}
            </FormControl>

            <FormControl sx={{ mb: 3, width: "100%" }}>
              <FormLabel>Password</FormLabel>
              <Input
                {...register("password")}
                type={showPassword ? "text" : "password"}
                placeholder="Enter your password"
                error={!!errors.password}
                sx={{ py: 1.5 }}
                endDecorator={
                  <IconButton onClick={() => setShowPassword(!showPassword)}>
                    {showPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                }
              />
              {errors.password && (
                <Typography level="body-sm" color="danger" sx={{ mt: 1 }}>
                  {errors.password.message}
                </Typography>
              )}
            </FormControl>

            <Stack
              direction="row"
              justifyContent="space-between"
              alignItems="center"
              sx={{ mb: 3 }}
            >
              <Checkbox
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
                label="Remember me"
                size="sm"
              />
              <JoyLink level="body-sm" sx={{ fontWeight: "lg" }}>
                Forgot your password?
              </JoyLink>
            </Stack>

            <Button
              type="submit"
              fullWidth
              loading={isLoading}
              sx={{ py: 1.5, mb: 4 }}
            >
              Sign in
            </Button>
          </form>
        </Box>

        <Typography
          level="body-sm"
          sx={{ color: "text.secondary", mt: "auto", mb: 4 }}
        >
          © Bookkeeping 2025
        </Typography>
      </Box>

      <Box
        sx={{
          flex: "0 0 50%",
          position: "relative",
          backgroundImage:
            "url('https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80')",
          backgroundSize: "cover",
          backgroundPosition: "center",
          backgroundRepeat: "no-repeat",
          "&::before": {
            content: '""',
            position: "absolute",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background:
              "linear-gradient(135deg, rgba(0,0,0,0.3) 0%, rgba(0,0,0,0.1) 100%)",
          },
        }}
      />
    </Box>
  );
};

export default Login;
