export const KPI_CARDS = [
  {
    label: "Valid Gross Sales",
    value: "£10,642,111",
    sub: "19,960 invoices · 3,922 products",
  },
  {
    label: "Identified Customers",
    value: "4,338",
    sub: "392,692 line items (£8,887,209 spend)",
  },
  {
    label: "Top Segment Revenue",
    value: "65.1%",
    sub: "Driven by 16.8% of customers (728)",
  },
  {
    label: "UK Market Share",
    value: "84.6%",
    sub: "£9,001,744 across 18,019 invoices",
  },
];

export const SEGMENTS = [
  {
    id: 3,
    name: "High-Value Loyalists",
    color: "#1e40af",
    customers: 728,
    custShare: 16.8,
    medRecency: 9,
    medFrequency: 10,
    medMonetary: 3688,
    totalRevenue: 5788710,
    revShare: 65.1,
    action:
      "Protect retention with VIP early access before the Sep–Nov Q4 surge, priority fulfillment, and dedicated account support for wholesale buyers.",
  },
  {
    id: 1,
    name: "Mid-Tier Regulars",
    color: "#2563eb",
    customers: 1163,
    custShare: 26.8,
    medRecency: 54,
    medFrequency: 4,
    medMonetary: 1342,
    totalRevenue: 2095526,
    revShare: 23.6,
    action:
      "Increase order frequency with replenishment reminders and cross-sell bundles featuring broad-demand bestsellers (e.g., Regency Cakestand, Jumbo Bag).",
  },
  {
    id: 4,
    name: "Recent Low-Frequency",
    color: "#60a5fa",
    customers: 876,
    custShare: 20.2,
    medRecency: 19,
    medFrequency: 2,
    medMonetary: 440,
    totalRevenue: 451892,
    revShare: 5.1,
    action:
      "Trigger automated second-order onboarding within 30 days to convert recent buyers into repeat regulars before recency decays.",
  },
  {
    id: 2,
    name: "Inactive / One-Time",
    color: "#93c5fd",
    customers: 1571,
    custShare: 36.2,
    medRecency: 184,
    medFrequency: 1,
    medMonetary: 299,
    totalRevenue: 551081,
    revShare: 6.2,
    action:
      "Use low-cost automated win-back campaigns rather than heavy discounting, since this segment represents 36.2% of accounts but only 6.2% of revenue.",
  },
];

export const MONTHLY_REVENUE = [
  { month: "Dec 10", revenue: 821453, invoices: 1559 },
  { month: "Jan 11", revenue: 689812, invoices: 1086 },
  { month: "Feb 11", revenue: 522546, invoices: 1100 },
  { month: "Mar 11", revenue: 716215, invoices: 1454 },
  { month: "Apr 11", revenue: 536968, invoices: 1246 },
  { month: "May 11", revenue: 769297, invoices: 1681 },
  { month: "Jun 11", revenue: 760547, invoices: 1533 },
  { month: "Jul 11", revenue: 718076, invoices: 1475 },
  { month: "Aug 11", revenue: 757841, invoices: 1361 },
  { month: "Sep 11", revenue: 1056435, invoices: 1837 },
  { month: "Oct 11", revenue: 1151264, invoices: 2040 },
  { month: "Nov 11", revenue: 1503867, invoices: 2769 },
  { month: "Dec 11*", revenue: 637790, invoices: 819 },
];

export const TOP_COUNTRIES = [
  { country: "United Kingdom", revenue: 9001744, invoices: 18019, customers: 3920, share: 84.6 },
  { country: "Netherlands", revenue: 285446, invoices: 94, customers: 9, share: 2.68 },
  { country: "EIRE", revenue: 283141, invoices: 288, customers: 3, share: 2.66 },
  { country: "Germany", revenue: 228678, invoices: 457, customers: 94, share: 2.15 },
  { country: "France", revenue: 209625, invoices: 392, customers: 87, share: 1.97 },
  { country: "Australia", revenue: 138454, invoices: 57, customers: 9, share: 1.3 },
  { country: "Spain", revenue: 61559, invoices: 90, customers: 30, share: 0.58 },
  { country: "Switzerland", revenue: 57068, invoices: 54, customers: 21, share: 0.54 },
  { country: "Belgium", revenue: 41196, invoices: 98, customers: 25, share: 0.39 },
  { country: "Sweden", revenue: 38368, invoices: 36, customers: 8, share: 0.36 },
];

export const CLEANING_AUDIT = [
  { stage: "1. Raw dataset", rows: 541909, removed: 0 },
  { stage: "2. After removing exact duplicates", rows: 536641, removed: 5268 },
  { stage: "3. Valid sales (qty > 0, unit_price > 0, non-C)", rows: 524878, removed: 11763 },
  { stage: "4. Valid sales with known customer_id (RFM base)", rows: 392692, removed: 132186 },
];
