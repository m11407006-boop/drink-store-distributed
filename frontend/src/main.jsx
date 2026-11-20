import React from "react";
import { createRoot } from "react-dom/client";

function App() {
  const [apiStatus, setApiStatus] = React.useState("checking");

  React.useEffect(() => {
    fetch("/api/health")
      .then((response) => {
        if (!response.ok) throw new Error("API error");
        return response.json();
      })
      .then(() => setApiStatus("connected"))
      .catch(() => setApiStatus("disconnected"));
  }, []);

  return (
    <main style={{
      fontFamily: "Arial, sans-serif",
      maxWidth: "720px",
      margin: "60px auto",
      padding: "24px"
    }}>
      <h1>好喝飲料連鎖系統</h1>
      <h2>Docker Lab 開發環境</h2>
      <hr />
      <p>React Frontend Container 正常運作。</p>
      <p>
        FastAPI 狀態：
        {apiStatus === "connected"
          ? "正常連線"
          : apiStatus === "disconnected"
            ? "連線失敗"
            : "檢查中"}
      </p>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
