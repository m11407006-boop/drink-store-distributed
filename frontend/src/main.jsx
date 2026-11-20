
import React from "react";
import { createRoot } from "react-dom/client";

function App() {
  const [apiStatus, setApiStatus] = React.useState("checking");

  // 門市資料
  const [stores, setStores] = React.useState([]);
  const [storesLoading, setStoresLoading] = React.useState(true);
  const [storesError, setStoresError] = React.useState("");

  // 目前選擇的門市
  const [selectedStore, setSelectedStore] = React.useState(null);

  // 該門市的菜單
  const [products, setProducts] = React.useState([]);
  const [productsLoading, setProductsLoading] = React.useState(false);
  const [productsError, setProductsError] = React.useState("");

  // 載入 API 狀態與所有門市
  React.useEffect(() => {
    fetch("/api/health")
      .then((response) => {
        if (!response.ok) throw new Error("API error");
        return response.json();
      })
      .then(() => setApiStatus("connected"))
      .catch(() => setApiStatus("disconnected"));

    fetch("/api/stores")
      .then((response) => {
        if (!response.ok) throw new Error("Stores API error");
        return response.json();
      })
      .then((data) => {
        setStores(data);
        setStoresLoading(false);
      })
      .catch(() => {
        setStoresError("無法取得門市資料。");
        setStoresLoading(false);
      });
  }, []);

  // 選擇門市後，取得該門市的菜單
  React.useEffect(() => {
    if (!selectedStore) {
      setProducts([]);
      setProductsError("");
      setProductsLoading(false);
      return;
    }

    const controller = new AbortController();

    setProducts([]);
    setProductsError("");
    setProductsLoading(true);

    fetch(
      `/api/stores/${encodeURIComponent(selectedStore.store_id)}/products`,
      { signal: controller.signal }
    )
      .then((response) => {
        if (!response.ok) throw new Error("Products API error");
        return response.json();
      })
      .then((data) => {
        setProducts(data);
        setProductsLoading(false);
      })
      .catch((error) => {
        if (error.name !== "AbortError") {
          setProductsError("無法取得這間門市的菜單。");
          setProductsLoading(false);
        }
      });

    return () => controller.abort();
  }, [selectedStore]);

  return (
    <main style={{
      fontFamily: "Arial, sans-serif",
      maxWidth: "1100px",
      margin: "40px auto",
      padding: "24px",
      color: "#333"
    }}>
      <h1>好喝飲料連鎖系統</h1>
      <h2>全台門市與菜單</h2>

      <p>
        FastAPI 狀態：
        {apiStatus === "connected"
          ? "正常連線"
          : apiStatus === "disconnected"
            ? "連線失敗"
            : "檢查中"}
      </p>

      <hr />

      <h2>全台門市</h2>

      {storesLoading && <p>門市資料載入中...</p>}

      {storesError && (
        <p style={{ color: "red" }}>{storesError}</p>
      )}

      {!storesLoading && !storesError && (
        <p>目前共有 {stores.length} 間門市，請選擇門市查看菜單。</p>
      )}

      <section style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
        gap: "16px"
      }}>
        {stores.map((store) => (
          <div
            key={store.store_id}
            style={{
              border: selectedStore?.store_id === store.store_id
                ? "2px solid #2563eb"
                : "1px solid #ddd",
              borderRadius: "10px",
              padding: "16px",
              backgroundColor: "#fff"
            }}
          >
            <h3>{store.store_name}</h3>
            <p>所在地：{store.city}</p>
            <p>
              類型：
              {store.store_type === "headquarters"
                ? "總部"
                : store.store_type === "franchise"
                  ? "加盟店"
                  : "直營分店"}
            </p>
            <p>狀態：{store.is_active ? "營業中" : "已停用"}</p>

            <button
              onClick={() => setSelectedStore(store)}
              disabled={!store.is_active}
              style={{
                width: "100%",
                padding: "10px",
                border: "none",
                borderRadius: "6px",
                backgroundColor: "#2563eb",
                color: "white",
                cursor: "pointer"
              }}
            >
              查看菜單
            </button>
          </div>
        ))}
      </section>

      {selectedStore && (
        <>
          <hr style={{ margin: "32px 0" }} />

          <h2>{selectedStore.store_name}－專屬菜單</h2>
          <p>所在地：{selectedStore.city}</p>

          <button
            onClick={() => setSelectedStore(null)}
            style={{
              padding: "9px 16px",
              border: "1px solid #ccc",
              borderRadius: "6px",
              backgroundColor: "#fff",
              cursor: "pointer"
            }}
          >
            返回門市總覽
          </button>

          {productsLoading && <p>菜單載入中...</p>}

          {productsError && (
            <p style={{ color: "red" }}>{productsError}</p>
          )}

          {!productsLoading && !productsError && (
            <p>本店目前供應 {products.length} 款飲品。</p>
          )}

          <section style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
            gap: "16px",
            marginTop: "16px"
          }}>
            {products.map((product) => (
              <div
                key={product.product_id}
                style={{
                  border: product.is_special
                    ? "2px solid #d97706"
                    : "1px solid #ddd",
                  borderRadius: "10px",
                  padding: "18px",
                  backgroundColor: product.is_special
                    ? "#fffbeb"
                    : "#f9fafb"
                }}
              >
                {product.is_special && (
                  <span style={{
                    color: "#b45309",
                    fontWeight: "bold"
                  }}>
                    ★ 門市限定
                  </span>
                )}

                <h3>{product.product_name}</h3>
                <p>{product.description}</p>
                <p style={{
                  fontSize: "20px",
                  fontWeight: "bold",
                  color: "#2563eb"
                }}>
                  NT$ {product.price.toFixed(0)}
                </p>
              </div>
            ))}
          </section>
        </>
      )}
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
