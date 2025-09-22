import React, { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import {
  Box,
  Sheet,
  List,
  ListItem,
  ListItemButton,
  ListItemContent,
  ListItemDecorator,
  Typography,
  IconButton,
  Divider,
  Avatar,
  Dropdown,
  Menu,
  MenuItem,
  MenuButton,
} from "@mui/joy";
import {
  DashboardRounded as DashboardIcon,
  ReceiptRounded as ReceiptIcon,
  CategoryRounded as CategoryIcon,
  RuleRounded as RuleIcon,
  CloudUploadRounded as ImportIcon,
  MenuRounded as MenuIcon,
  LogoutRounded as LogoutIcon,
  SettingsRounded as SettingsIcon,
} from "@mui/icons-material";
import { useAuth } from "@/contexts/AuthContext";

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const navigationItems = [
    { path: "/dashboard", label: "Dashboard", icon: DashboardIcon },
    { path: "/transactions", label: "Transactions", icon: ReceiptIcon },
    { path: "/categories", label: "Categories", icon: CategoryIcon },
    { path: "/rules", label: "Rules", icon: RuleIcon },
    { path: "/import", label: "Import CSV", icon: ImportIcon },
  ];

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <Box
      sx={{
        display: "flex",
        minHeight: "100vh",
        minWidth: "100vw",
      }}
    >
      <Sheet
        sx={{
          width: { xs: sidebarOpen ? 256 : 0, md: 256 },
          height: "100vh",
          position: "fixed",
          top: 0,
          left: 0,
          zIndex: 1000,
          transition: "width 0.3s ease",
          overflow: "hidden",
          borderRight: "1px solid",
          borderRightColor: "divider",
        }}
      >
        <Box sx={{ p: 2 }}>
          <Box
            sx={{
              display: "flex",
              justifyContent: "flex-start",
              gap: 2,
              mb: 2,
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
            <Typography level="h4">Bookkeeping</Typography>
          </Box>

          <List>
            {navigationItems.map((item) => (
              <ListItem key={item.path}>
                <ListItemButton
                  sx={{ borderRadius: "sm" }}
                  selected={location.pathname === item.path}
                  onClick={() => {
                    navigate(item.path);
                    setSidebarOpen(false);
                  }}
                >
                  <ListItemDecorator>
                    <item.icon />
                  </ListItemDecorator>
                  <ListItemContent>{item.label}</ListItemContent>
                </ListItemButton>
              </ListItem>
            ))}
          </List>
        </Box>
      </Sheet>

      <Box
        sx={{
          flex: 1,
          ml: { xs: 0, md: "256px" },
          transition: "margin-left 0.3s ease",
        }}
      >
        <Sheet
          sx={{
            p: 2,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            borderBottom: "1px solid",
            borderColor: "divider",
          }}
        >
          <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
            <IconButton
              variant="outlined"
              onClick={() => setSidebarOpen(!sidebarOpen)}
              sx={{ display: { md: "none" } }}
            >
              <MenuIcon />
            </IconButton>
            <Typography level="title-lg">
              {navigationItems.find((item) => item.path === location.pathname)
                ?.label || "Bookkeeping"}
            </Typography>
          </Box>

          <Dropdown>
            <MenuButton
              variant="plain"
              sx={{
                display: "flex",
                alignItems: "center",
                gap: 1,
                p: 1,
                borderRadius: "sm",
              }}
            >
              <Avatar size="sm">{user?.email?.[0]?.toUpperCase()}</Avatar>
              <Typography level="body-sm">{user?.email}</Typography>
            </MenuButton>
            <Menu>
              <MenuItem onClick={() => navigate("/settings")}>
                <ListItemDecorator>
                  <SettingsIcon />
                </ListItemDecorator>
                Settings
              </MenuItem>
              <Divider />
              <MenuItem onClick={handleLogout} color="danger">
                <ListItemDecorator>
                  <LogoutIcon />
                </ListItemDecorator>
                Logout
              </MenuItem>
            </Menu>
          </Dropdown>
        </Sheet>

        <Box sx={{ p: 3 }}>{children}</Box>
      </Box>

      {sidebarOpen && (
        <Box
          sx={{
            position: "fixed",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            bgcolor: "rgba(0, 0, 0, 0.5)",
            zIndex: 999,
            display: { md: "none" },
          }}
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </Box>
  );
};

export default Layout;
