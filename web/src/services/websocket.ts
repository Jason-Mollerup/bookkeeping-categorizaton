import type { WebSocketMessage, ImportProgress } from "@/types";
import actioncable from "actioncable";

class WebSocketService {
  private cable: any = null;
  private subscriptions: any = {};
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;

  connect(userId: number): void {
    if (this.cable) {
      return;
    }

    try {
      const token = localStorage.getItem("auth_token");
      if (!token) {
        console.warn(
          "No authentication token found, WebSocket connection skipped"
        );
        return;
      }

      this.cable = actioncable.createConsumer(
        `ws://localhost:3000/cable?token=${encodeURIComponent(token)}`
      );
      this.setupEventListeners(userId);
      console.log("WebSocket connected successfully");
    } catch (error) {
      console.warn("Failed to connect WebSocket:", error);
    }
  }

  disconnect(): void {
    if (this.cable) {
      Object.values(this.subscriptions).forEach((subscription: any) => {
        if (subscription && typeof subscription.unsubscribe === "function") {
          subscription.unsubscribe();
        }
      });
      this.subscriptions = {};
      this.cable = null;
    }
  }

  private setupEventListeners(userId: number): void {
    if (!this.cable) return;

    this.subscriptions.imports = this.cable.subscriptions.create(
      { channel: "ImportChannel", user_id: userId },
      {
        received: (data: any) => {
          console.log("Import update received:", data);
          this.handleImportUpdate(data);
        },
      }
    );

    this.subscriptions.transactions = this.cable.subscriptions.create(
      { channel: "TransactionChannel", user_id: userId },
      {
        received: (data: any) => {
          console.log("Transaction update received:", data);
          this.handleTransactionUpdate(data);
        },
      }
    );

    this.subscriptions.anomalies = this.cable.subscriptions.create(
      { channel: "AnomalyChannel", user_id: userId },
      {
        received: (data: any) => {
          console.log("Anomaly update received:", data);
          this.handleAnomalyUpdate(data);
        },
      }
    );
  }

  onAnomalyDetected(_callback: (data: any) => void): void {
    // TODO: Implement ActionCable subscription
    console.log("Anomaly detected subscription would be set up here");
  }

  onAnomalyResolved(_callback: (data: any) => void): void {
    // TODO: Implement ActionCable subscription
    console.log("Anomaly resolved subscription would be set up here");
  }

  onTransactionCreated(_callback: (data: any) => void): void {
    console.log("Transaction created subscription would be set up here");
  }

  onTransactionUpdated(_callback: (data: any) => void): void {
    console.log("Transaction updated subscription would be set up here");
  }

  onTransactionDeleted(_callback: (data: any) => void): void {
    console.log("Transaction deleted subscription would be set up here");
  }

  onBulkCategorizationComplete(_callback: (data: any) => void): void {
    console.log(
      "Bulk categorization complete subscription would be set up here"
    );
  }

  onBulkCategorizationFailed(_callback: (data: any) => void): void {
    console.log("Bulk categorization failed subscription would be set up here");
  }

  onBulkRuleApplicationComplete(_callback: (data: any) => void): void {
    console.log(
      "Bulk rule application complete subscription would be set up here"
    );
  }

  onBulkRuleApplicationFailed(_callback: (data: any) => void): void {
    console.log(
      "Bulk rule application failed subscription would be set up here"
    );
  }

  private handleImportUpdate(data: any): void {
    const event = new CustomEvent("importUpdate", { detail: data });
    window.dispatchEvent(event);
  }

  private handleTransactionUpdate(data: any): void {
    const event = new CustomEvent("transactionUpdate", { detail: data });
    window.dispatchEvent(event);
  }

  private handleAnomalyUpdate(data: any): void {
    const event = new CustomEvent("anomalyUpdate", { detail: data });
    window.dispatchEvent(event);
  }

  onImportStarted(callback: (data: ImportProgress) => void): void {
    window.addEventListener("importUpdate", (event: any) => {
      if (
        event.detail.type === "progress" &&
        event.detail.progress_percentage === 0
      ) {
        callback(event.detail);
      }
    });
  }

  onImportProgress(callback: (data: ImportProgress) => void): void {
    window.addEventListener("importUpdate", (event: any) => {
      if (event.detail.type === "progress") {
        callback(event.detail);
      }
    });
  }

  onImportCompleted(callback: (data: ImportProgress) => void): void {
    window.addEventListener("importUpdate", (event: any) => {
      if (event.detail.type === "completed") {
        callback(event.detail);
      }
    });
  }

  onImportFailed(callback: (data: ImportProgress) => void): void {
    window.addEventListener("importUpdate", (event: any) => {
      if (event.detail.type === "error") {
        callback(event.detail);
      }
    });
  }

  onMessage(_callback: (message: WebSocketMessage) => void): void {
    console.log("Message subscription would be set up here");
  }

  off(event: string, _callback?: (...args: any[]) => void): void {
    console.log(`Event listener removal for ${event} would be called here`);
  }

  isConnected(): boolean {
    return (
      this.cable && this.cable.connection && this.cable.connection.isOpen()
    );
  }

  getConnectionState(): string {
    if (!this.cable) return "disconnected";
    if (!this.cable.connection) return "connecting";
    return this.cable.connection.isOpen() ? "connected" : "disconnected";
  }
}

export const websocketService = new WebSocketService();
