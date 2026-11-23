import React, { useEffect, useMemo, useState } from "react";
import { Layers, Search, TrendingUp, Users } from "lucide-react";
import {
  KPI_CARDS,
  MONTHLY_REVENUE,
  SEGMENTS,
  TOP_COUNTRIES,
} from "./data/analyticsData.js";

const TABS = [
  { id: "overview", label: "Overview", icon: Layers },
  { id: "trends", label: "Trends & Markets", icon: TrendingUp },
  { id: "customers", label: "Customers", icon: Users },
];

function parseCustomerCsv(text) {
  const lines = text.trim().split(/\r?\n/);
  if (lines.length < 2) return [];
  const headers = lines[0].split(",").map((h) => h.replace(/"/g, "").trim());
  const idxId = headers.indexOf("customer_id");
  const idxR = headers.indexOf("recency");
  const idxF = headers.indexOf("frequency");
  const idxM = headers.indexOf("monetary");
  const idxS = headers.indexOf("segment");
  return lines
    .slice(1)
    .map((line) => {
      const cols = line.split(",").map((c) => c.replace(/"/g, "").trim());
      return {
        customer_id: cols[idxId] || "",
        recency: Number(cols[idxR]),
        frequency: Number(cols[idxF]),
        monetary: Number(cols[idxM]),
        segment: cols[idxS] || "",
      };
    })
    .filter((row) => row.customer_id);
}

function MonthlyChart({ data }) {
  const [hovered, setHovered] = useState(null);
  const w = 900;
  const h = 250;
  const padL = 60;
  const padR = 24;
  const padT = 18;
  const padB = 38;
  const maxV = 1600000;
  const xStep = (w - padL - padR) / (data.length - 1);

  const points = data.map((d, i) => ({
    ...d,
    x: padL + i * xStep,
    y: h - padB - (d.revenue / maxV) * (h - padT - padB),
  }));

  const polyline = points.map((p) => `${p.x},${p.y}`).join(" ");
  const baselineY = h - padB;
  const areaPoints = `${points[0].x},${baselineY} ${polyline} ${points[points.length - 1].x},${baselineY}`;

  return (
    <div>
      <svg viewBox={`0 0 ${w} ${h}`} style={{ width: "100%", height: "auto", display: "block" }}>
        <defs>
          <linearGradient id="blueArea" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#2563eb" stopOpacity="0.16" />
            <stop offset="100%" stopColor="#2563eb" stopOpacity="0.01" />
          </linearGradient>
        </defs>
        {[0, 500000, 1000000, 1500000].map((v) => {
          const y = h - padB - (v / maxV) * (h - padT - padB);
          return (
            <g key={v}>
              <line x1={padL} y1={y} x2={w - padR} y2={y} stroke="#dbeafe" strokeDasharray="3 3" />
              <text x={padL - 10} y={y + 4} textAnchor="end" fontSize="11" fill="#5b6b84">
                £{v / 1000}K
              </text>
            </g>
          );
        })}

        <polygon fill="url(#blueArea)" points={areaPoints} />
        <polyline fill="none" stroke="#1d4ed8" strokeWidth="2.5" points={polyline} />

        {points.map((p) => (
          <g
            key={p.month}
            onMouseEnter={() => setHovered(p)}
            onMouseLeave={() => setHovered(null)}
            style={{ cursor: "pointer" }}
          >
            <circle
              cx={p.x}
              cy={p.y}
              r={hovered?.month === p.month ? 6 : 4.2}
              fill={hovered?.month === p.month ? "#1e3a8a" : "#2563eb"}
              stroke="#ffffff"
              strokeWidth="1.5"
            />
            <text x={p.x} y={h - 12} textAnchor="middle" fontSize="11" fill="#5b6b84">
              {p.month}
            </text>
          </g>
        ))}
      </svg>
      <div className="card-sub" style={{ marginTop: 10, marginBottom: 0 }}>
        {hovered
          ? `${hovered.month}: £${hovered.revenue.toLocaleString()} (${hovered.invoices.toLocaleString()} invoices)`
          : "Hover a point to inspect monthly revenue and invoice count."}
      </div>
    </div>
  );
}

export default function App() {
  const [activeTab, setActiveTab] = useState("overview");
  const [selectedSegId, setSelectedSegId] = useState(3);
  const [customers, setCustomers] = useState([]);
  const [searchId, setSearchId] = useState("");
  const [segFilter, setSegFilter] = useState("ALL");
  const [sortBy, setSortBy] = useState("monetary");
  const [sortDir, setSortDir] = useState("desc");
  const [page, setPage] = useState(1);
  const pageSize = 10;

  useEffect(() => {
    fetch("./data/rfm_segmented.csv")
      .then((res) => (res.ok ? res.text() : ""))
      .then((text) => {
        if (text) setCustomers(parseCustomerCsv(text));
      })
      .catch(() => {});
  }, []);

  const selectedSegment = SEGMENTS.find((s) => s.id === selectedSegId) || SEGMENTS[0];
  const topCountries = TOP_COUNTRIES.slice(0, 5);

  const filteredCustomers = useMemo(() => {
    const q = searchId.trim().toLowerCase();
    return customers
      .filter(
        (c) =>
          (!q || c.customer_id.toLowerCase().includes(q)) &&
          (segFilter === "ALL" || c.segment === segFilter)
      )
      .sort((a, b) => {
        const diff = a[sortBy] - b[sortBy];
        return sortDir === "asc" ? diff : -diff;
      });
  }, [customers, searchId, segFilter, sortBy, sortDir]);

  const totalPages = Math.max(1, Math.ceil(filteredCustomers.length / pageSize));
  const pagedCustomers = filteredCustomers.slice((page - 1) * pageSize, page * pageSize);

  const toggleSort = (col) => {
    if (sortBy === col) {
      setSortDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortBy(col);
      setSortDir("desc");
    }
    setPage(1);
  };

  return (
    <div>
      <header className="topbar">
        <div className="topbar-inner">
          <div>
            <h1>Customer Behavior &amp; RFM Segmentation</h1>
            <p>UCI Online Retail · Dec 2010 – Dec 2011 · K-Means (K = 4)</p>
          </div>
        </div>
      </header>

      <main className="container">
        <section className="kpi-grid">
          {KPI_CARDS.map((kpi) => (
            <div className="kpi-card" key={kpi.label}>
              <div className="kpi-label">{kpi.label}</div>
              <div className="kpi-val">{kpi.value}</div>
              <div className="kpi-sub">{kpi.sub}</div>
            </div>
          ))}
        </section>

        <nav className="tabs">
          {TABS.map((t) => {
            const Icon = t.icon;
            return (
              <button
                key={t.id}
                className={`tab-btn ${activeTab === t.id ? "active" : ""}`}
                onClick={() => setActiveTab(t.id)}
              >
                <Icon size={15} />
                {t.label}
              </button>
            );
          })}
        </nav>

        {activeTab === "overview" && (
          <>
            <div className="card">
              <h2>Customer Segments</h2>
              <p className="card-sub">Select a segment to view its RFM medians and action plan.</p>
              <div className="seg-grid">
                {SEGMENTS.map((seg) => (
                  <button
                    key={seg.id}
                    className={`seg-card ${selectedSegId === seg.id ? "active" : ""}`}
                    onClick={() => setSelectedSegId(seg.id)}
                  >
                    <div className="seg-name">
                      <span className="seg-dot" style={{ background: seg.color }} />
                      {seg.name}
                    </div>
                    <div className="seg-stat">{seg.revShare}% of revenue</div>
                    <div className="seg-meta">
                      {seg.customers.toLocaleString()} customers ({seg.custShare}%)
                    </div>
                  </button>
                ))}
              </div>

              <div className="detail-strip">
                <div className="detail-metrics">
                  <span>
                    Median Recency: <strong>{selectedSegment.medRecency} days</strong>
                  </span>
                  <span>
                    Median Frequency: <strong>{selectedSegment.medFrequency} orders</strong>
                  </span>
                  <span>
                    Median Spend: <strong>£{selectedSegment.medMonetary.toLocaleString()}</strong>
                  </span>
                  <span>
                    Total Revenue: <strong>£{selectedSegment.totalRevenue.toLocaleString()}</strong>
                  </span>
                </div>
                <div>
                  <strong>Action:</strong> {selectedSegment.action}
                </div>
              </div>
            </div>

            <div className="card">
              <h2>Revenue Concentration by Segment</h2>
              <p className="card-sub">Share of customer-identified spend (£8.89M total).</p>
              {SEGMENTS.map((seg) => (
                <div className="bar-group" key={seg.id}>
                  <div className="bar-head">
                    <span>{seg.name}</span>
                    <span>
                      <strong>{seg.revShare}%</strong> revenue · {seg.custShare}% customers
                    </span>
                  </div>
                  <div className="bar-track">
                    <div
                      className="bar-fill"
                      style={{ width: `${seg.revShare}%`, background: seg.color }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {activeTab === "trends" && (
          <>
            <div className="card">
              <h2>Monthly Gross Revenue</h2>
              <p className="card-sub">
                Peak in Nov 2011 (£1,503,867). Dec 2011 is partial (ends Dec 9).
              </p>
              <MonthlyChart data={MONTHLY_REVENUE} />
            </div>

            <div className="card">
              <h2>Top 5 Markets</h2>
              <p className="card-sub">
                Netherlands and EIRE are driven by a few wholesale accounts; Germany and France have
                broader customer bases.
              </p>
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Country</th>
                      <th className="num">Revenue</th>
                      <th className="num">Customers</th>
                      <th className="num">Share</th>
                    </tr>
                  </thead>
                  <tbody>
                    {topCountries.map((c) => (
                      <tr key={c.country}>
                        <td>{c.country}</td>
                        <td className="num">£{c.revenue.toLocaleString()}</td>
                        <td className="num">{c.customers.toLocaleString()}</td>
                        <td className="num">{c.share.toFixed(2)}%</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </>
        )}

        {activeTab === "customers" && (
          <div className="card">
            <h2>Customer Lookup</h2>
            <p className="card-sub">
              {filteredCustomers.length.toLocaleString()} of {customers.length.toLocaleString()}{" "}
              customers shown.
            </p>
            <div className="toolbar">
              <div style={{ position: "relative" }}>
                <Search
                  size={15}
                  style={{ position: "absolute", left: 10, top: 10, color: "#9ca3af" }}
                />
                <input
                  className="input"
                  style={{ paddingLeft: 32 }}
                  type="text"
                  placeholder="Search CustomerID..."
                  value={searchId}
                  onChange={(e) => {
                    setSearchId(e.target.value);
                    setPage(1);
                  }}
                />
              </div>
              <select
                className="select"
                value={segFilter}
                onChange={(e) => {
                  setSegFilter(e.target.value);
                  setPage(1);
                }}
              >
                <option value="ALL">All Segments</option>
                {SEGMENTS.map((s) => (
                  <option key={s.id} value={s.name}>
                    {s.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>CustomerID</th>
                    <th>Segment</th>
                    <th className="num sortable" onClick={() => toggleSort("recency")}>
                      Recency {sortBy === "recency" ? (sortDir === "asc" ? "↑" : "↓") : ""}
                    </th>
                    <th className="num sortable" onClick={() => toggleSort("frequency")}>
                      Frequency {sortBy === "frequency" ? (sortDir === "asc" ? "↑" : "↓") : ""}
                    </th>
                    <th className="num sortable" onClick={() => toggleSort("monetary")}>
                      Spend (£) {sortBy === "monetary" ? (sortDir === "asc" ? "↑" : "↓") : ""}
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {pagedCustomers.map((c) => (
                    <tr key={c.customer_id}>
                      <td>{c.customer_id}</td>
                      <td>{c.segment}</td>
                      <td className="num">{c.recency} d</td>
                      <td className="num">{c.frequency}</td>
                      <td className="num">
                        £{c.monetary.toLocaleString(undefined, { maximumFractionDigits: 2 })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="pagination">
              <span>
                Page {page} of {totalPages}
              </span>
              <div style={{ display: "flex", gap: 8 }}>
                <button className="btn" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
                  Previous
                </button>
                <button
                  className="btn"
                  disabled={page >= totalPages}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Next
                </button>
              </div>
            </div>
          </div>
        )}

        <footer className="footer-note">
          541,909 raw rows → 524,878 valid sales → 4,338 customers · Silhouette 0.335 · Spearman
          F–M ρ = 0.807 · Kruskal-Wallis χ² = 3078.3 (p &lt; 2.2e-16)
        </footer>
      </main>
    </div>
  );
}
