# 07 - Frontend Specification

## Overview

The frontend is a Next.js 14 application providing:
- Natural language Q&A interface with streaming
- Company browsing and financial dashboards
- Document explorer
- Admin panel for HITL reviews

---

## Technology Stack

| Technology | Purpose |
|------------|---------|
| **Next.js 14** | React framework with App Router |
| **TypeScript** | Type safety |
| **Tailwind CSS** | Utility-first styling |
| **shadcn/ui** | Component library |
| **React Query** | Server state management |
| **Recharts** | Data visualization |
| **Zustand** | Client state management |

---

## Project Structure

```
frontend/
├── app/
│   ├── (auth)/
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── layout.tsx
│   ├── (dashboard)/
│   │   ├── page.tsx                    # Dashboard home
│   │   ├── query/
│   │   │   └── page.tsx                # Q&A interface
│   │   ├── companies/
│   │   │   ├── page.tsx                # Company list
│   │   │   └── [symbol]/
│   │   │       └── page.tsx            # Company detail
│   │   ├── compare/
│   │   │   └── page.tsx                # Company comparison
│   │   ├── documents/
│   │   │   └── page.tsx                # Document explorer
│   │   └── layout.tsx                  # Dashboard layout
│   ├── admin/
│   │   ├── hitl/
│   │   │   └── page.tsx                # HITL review queue
│   │   └── layout.tsx
│   ├── api/
│   │   └── [...proxy]/
│   │       └── route.ts                # API proxy (optional)
│   ├── layout.tsx                      # Root layout
│   └── globals.css
├── components/
│   ├── ui/                             # shadcn/ui components
│   ├── query/
│   │   ├── QueryInput.tsx
│   │   ├── QueryResponse.tsx
│   │   ├── StreamingResponse.tsx
│   │   └── CitationCard.tsx
│   ├── company/
│   │   ├── CompanyCard.tsx
│   │   ├── CompanyHeader.tsx
│   │   ├── FundamentalsTable.tsx
│   │   └── PriceChart.tsx
│   ├── dashboard/
│   │   ├── Sidebar.tsx
│   │   ├── Header.tsx
│   │   └── StatsCard.tsx
│   └── shared/
│       ├── LoadingSpinner.tsx
│       ├── ErrorBoundary.tsx
│       └── DataTable.tsx
├── lib/
│   ├── api/
│   │   ├── client.ts                   # API client
│   │   ├── queries.ts                  # React Query hooks
│   │   └── types.ts                    # API types
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   └── useStream.ts
│   ├── stores/
│   │   └── authStore.ts
│   └── utils/
│       ├── formatters.ts
│       └── constants.ts
├── public/
│   └── ...
├── tailwind.config.ts
├── next.config.js
└── package.json
```

---

## Page Specifications

### 1. Dashboard (Home)

**Route**: `/`

**Purpose**: Overview of market and recent activity

**Layout**:
```
┌─────────────────────────────────────────────────────────────┐
│  Header (Logo, Search, User Menu)                           │
├──────────┬──────────────────────────────────────────────────┤
│          │                                                   │
│  Sidebar │   Market Overview Cards                          │
│          │   ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐   │
│  - Home  │   │NIFTY50 │ │Top Gain│ │Top Loss│ │ Volume │   │
│  - Query │   │18,500  │ │TCS +3% │ │HDFC -2%│ │ 1.2B   │   │
│  - Cos   │   └────────┘ └────────┘ └────────┘ └────────┘   │
│  - Docs  │                                                   │
│  - Admin │   Recent Queries                                  │
│          │   ┌─────────────────────────────────────────┐    │
│          │   │ "What was TCS revenue..." - 2 min ago   │    │
│          │   │ "Compare HDFC and ICICI..." - 5 min ago │    │
│          │   └─────────────────────────────────────────┘    │
│          │                                                   │
│          │   Trending News                                   │
│          │   ┌─────────────────────────────────────────┐    │
│          │   │ Reliance Q2 results beat estimates...   │    │
│          │   │ TCS announces dividend of ₹10...        │    │
│          │   └─────────────────────────────────────────┘    │
│          │                                                   │
└──────────┴──────────────────────────────────────────────────┘
```

**Components**:
- `MarketOverviewCard` - NIFTY 50 index value
- `TopMoversCard` - Top gainers/losers
- `RecentQueriesCard` - User's recent queries
- `TrendingNewsCard` - Latest news headlines

---

### 2. Query Page (Q&A Interface)

**Route**: `/query`

**Purpose**: Main RAG query interface

**Layout**:
```
┌─────────────────────────────────────────────────────────────┐
│  Header                                                      │
├──────────┬──────────────────────────────────────────────────┤
│          │                                                   │
│  Sidebar │   Query Input                                     │
│          │   ┌─────────────────────────────────────────┐    │
│          │   │ Ask anything about NIFTY 50 companies...│    │
│          │   │                                    [Ask]│    │
│          │   └─────────────────────────────────────────┘    │
│          │                                                   │
│          │   Filters (collapsible)                          │
│          │   ┌─────────────────────────────────────────┐    │
│          │   │ Company: [All ▼] Period: [All ▼]        │    │
│          │   │ Doc Type: [All ▼]                       │    │
│          │   └─────────────────────────────────────────┘    │
│          │                                                   │
│          │   Response                                        │
│          │   ┌─────────────────────────────────────────┐    │
│          │   │ Based on Reliance's FY2024 Annual       │    │
│          │   │ Report, the company reported revenue    │    │
│          │   │ of ₹9,74,864 crore [1]...               │    │
│          │   │                                         │    │
│          │   │ ─────────────────────────────────────   │    │
│          │   │ Citations:                              │    │
│          │   │ [1] Annual Report FY2024, Page 45       │    │
│          │   └─────────────────────────────────────────┘    │
│          │                                                   │
│          │   Query History (sidebar)                        │
│          │                                                   │
└──────────┴──────────────────────────────────────────────────┘
```

**Components**:

```tsx
// components/query/QueryInput.tsx
interface QueryInputProps {
  onSubmit: (query: string, filters?: QueryFilters) => void;
  isLoading: boolean;
  suggestions?: string[];
}

export function QueryInput({ onSubmit, isLoading, suggestions }: QueryInputProps) {
  const [query, setQuery] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [filters, setFilters] = useState<QueryFilters>({});
  
  return (
    <div className="space-y-4">
      <div className="relative">
        <Textarea
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Ask anything about NIFTY 50 companies..."
          className="min-h-[100px] pr-20"
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              onSubmit(query, filters);
            }
          }}
        />
        <Button
          onClick={() => onSubmit(query, filters)}
          disabled={isLoading || !query.trim()}
          className="absolute bottom-3 right-3"
        >
          {isLoading ? <Loader2 className="animate-spin" /> : 'Ask'}
        </Button>
      </div>
      
      {/* Suggestions */}
      {suggestions && (
        <div className="flex gap-2 flex-wrap">
          {suggestions.map((s) => (
            <Badge
              key={s}
              variant="outline"
              className="cursor-pointer hover:bg-accent"
              onClick={() => setQuery(s)}
            >
              {s}
            </Badge>
          ))}
        </div>
      )}
      
      {/* Filters */}
      <Collapsible open={showFilters} onOpenChange={setShowFilters}>
        <CollapsibleTrigger asChild>
          <Button variant="ghost" size="sm">
            <Filter className="h-4 w-4 mr-2" />
            Filters
          </Button>
        </CollapsibleTrigger>
        <CollapsibleContent>
          <QueryFilters filters={filters} onChange={setFilters} />
        </CollapsibleContent>
      </Collapsible>
    </div>
  );
}
```

```tsx
// components/query/StreamingResponse.tsx
interface StreamingResponseProps {
  queryId: string;
  onComplete: (response: QueryResponse) => void;
}

export function StreamingResponse({ queryId, onComplete }: StreamingResponseProps) {
  const [content, setContent] = useState('');
  const [citations, setCitations] = useState<Citation[]>([]);
  const [status, setStatus] = useState<'streaming' | 'complete' | 'error'>('streaming');
  const [currentNode, setCurrentNode] = useState<string>('');
  
  useEffect(() => {
    const eventSource = new EventSource(`/api/v1/query/${queryId}/stream`);
    
    eventSource.addEventListener('token', (e) => {
      const data = JSON.parse(e.data);
      setContent((prev) => prev + data.content);
    });
    
    eventSource.addEventListener('node', (e) => {
      const data = JSON.parse(e.data);
      setCurrentNode(data.node);
    });
    
    eventSource.addEventListener('citation', (e) => {
      const data = JSON.parse(e.data);
      setCitations((prev) => [...prev, data]);
    });
    
    eventSource.addEventListener('done', (e) => {
      const data = JSON.parse(e.data);
      setStatus('complete');
      onComplete(data);
      eventSource.close();
    });
    
    eventSource.addEventListener('error', () => {
      setStatus('error');
      eventSource.close();
    });
    
    return () => eventSource.close();
  }, [queryId]);
  
  return (
    <div className="space-y-4">
      {/* Progress indicator */}
      {status === 'streaming' && (
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Loader2 className="h-4 w-4 animate-spin" />
          {currentNode && `Processing: ${currentNode}`}
        </div>
      )}
      
      {/* Response content */}
      <div className="prose prose-sm max-w-none">
        <ReactMarkdown>{content}</ReactMarkdown>
        {status === 'streaming' && (
          <span className="inline-block w-2 h-4 bg-primary animate-pulse" />
        )}
      </div>
      
      {/* Citations */}
      {citations.length > 0 && (
        <div className="border-t pt-4">
          <h4 className="text-sm font-medium mb-2">Sources</h4>
          <div className="space-y-2">
            {citations.map((citation, i) => (
              <CitationCard key={i} citation={citation} index={i + 1} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
```

---

### 3. Company List Page

**Route**: `/companies`

**Purpose**: Browse and search NIFTY 50 companies

**Layout**:
```
┌─────────────────────────────────────────────────────────────┐
│  Search: [_______________] Sector: [All ▼] Sort: [Rank ▼]  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐ ┌──────────────────┐ ┌─────────────┐ │
│  │ RELIANCE         │ │ HDFCBANK         │ │ TCS         │ │
│  │ Reliance Ind.    │ │ HDFC Bank        │ │ Tata Consul.│ │
│  │ Energy           │ │ Banking          │ │ IT          │ │
│  │ ₹2,850 (+1.2%)   │ │ ₹1,650 (-0.5%)   │ │ ₹3,920(+2.1)│ │
│  │ MC: ₹19.5L Cr    │ │ MC: ₹12.5L Cr    │ │ MC: ₹14.2LCr│ │
│  └──────────────────┘ └──────────────────┘ └─────────────┘ │
│                                                              │
│  ┌──────────────────┐ ┌──────────────────┐ ┌─────────────┐ │
│  │ INFY             │ │ ICICIBANK        │ │ ...         │ │
│  │ ...              │ │ ...              │ │             │ │
│  └──────────────────┘ └──────────────────┘ └─────────────┘ │
│                                                              │
│  Showing 1-12 of 50                         [1] [2] [3] [>] │
└─────────────────────────────────────────────────────────────┘
```

**Component**:

```tsx
// components/company/CompanyCard.tsx
interface CompanyCardProps {
  company: Company;
  onClick: () => void;
}

export function CompanyCard({ company, onClick }: CompanyCardProps) {
  const priceChange = company.latest_price?.change_percent || 0;
  const isPositive = priceChange >= 0;
  
  return (
    <Card
      className="cursor-pointer hover:shadow-lg transition-shadow"
      onClick={onClick}
    >
      <CardHeader className="pb-2">
        <div className="flex justify-between items-start">
          <div>
            <CardTitle className="text-lg">{company.nse_symbol}</CardTitle>
            <CardDescription className="line-clamp-1">
              {company.name}
            </CardDescription>
          </div>
          <Badge variant="outline">{company.sector}</Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex justify-between items-end">
          <div>
            <p className="text-2xl font-bold">
              ₹{company.latest_price?.close.toLocaleString()}
            </p>
            <p className={cn(
              "text-sm",
              isPositive ? "text-green-600" : "text-red-600"
            )}>
              {isPositive ? '+' : ''}{priceChange.toFixed(2)}%
            </p>
          </div>
          <div className="text-right text-sm text-muted-foreground">
            <p>Market Cap</p>
            <p className="font-medium">
              ₹{formatLargeNumber(company.latest_fundamentals?.market_cap)}
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
```

---

### 4. Company Detail Page

**Route**: `/companies/[symbol]`

**Purpose**: Detailed company information and financials

**Layout**:
```
┌─────────────────────────────────────────────────────────────┐
│  ← Back to Companies                                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  RELIANCE.NS                                    [Ask AI]    │
│  Reliance Industries Ltd                                    │
│  Energy • Oil & Gas Refining • Rank #1                      │
│                                                              │
│  ₹2,850.50  +35.20 (+1.25%)  Today                         │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  [Overview] [Financials] [Documents] [News]                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Price Chart (1D | 1W | 1M | 3M | 1Y | 3Y)                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    📈                                │   │
│  │              ╱╲    ╱╲                               │   │
│  │            ╱    ╲╱    ╲                             │   │
│  │          ╱              ╲╱╲                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  Key Metrics                                                 │
│  ┌────────────┬────────────┬────────────┬────────────┐     │
│  │ Market Cap │ P/E Ratio  │ ROE        │ Debt/Equity│     │
│  │ ₹19.5L Cr  │ 25.3x      │ 8.9%       │ 0.42       │     │
│  └────────────┴────────────┴────────────┴────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Components**:

```tsx
// components/company/PriceChart.tsx
interface PriceChartProps {
  symbol: string;
  period: '1D' | '1W' | '1M' | '3M' | '1Y' | '3Y';
}

export function PriceChart({ symbol, period }: PriceChartProps) {
  const { data, isLoading } = useCompanyPrices(symbol, period);
  
  if (isLoading) return <Skeleton className="h-[300px]" />;
  
  return (
    <ResponsiveContainer width="100%" height={300}>
      <AreaChart data={data}>
        <defs>
          <linearGradient id="colorPrice" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
            <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
          </linearGradient>
        </defs>
        <XAxis
          dataKey="date"
          tickFormatter={(d) => formatDate(d, period)}
        />
        <YAxis
          domain={['auto', 'auto']}
          tickFormatter={(v) => `₹${v}`}
        />
        <Tooltip
          content={<CustomTooltip />}
        />
        <Area
          type="monotone"
          dataKey="close"
          stroke="#3b82f6"
          fillOpacity={1}
          fill="url(#colorPrice)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
```

```tsx
// components/company/FundamentalsTable.tsx
interface FundamentalsTableProps {
  symbol: string;
  periodType: 'quarterly' | 'annual';
}

export function FundamentalsTable({ symbol, periodType }: FundamentalsTableProps) {
  const { data, isLoading } = useCompanyFundamentals(symbol, periodType);
  
  const columns = [
    { key: 'period', label: 'Period' },
    { key: 'revenue', label: 'Revenue', format: formatCurrency },
    { key: 'net_income', label: 'Net Income', format: formatCurrency },
    { key: 'eps', label: 'EPS', format: (v) => `₹${v?.toFixed(2)}` },
    { key: 'pe_ratio', label: 'P/E', format: (v) => v?.toFixed(1) },
    { key: 'roe', label: 'ROE', format: formatPercent },
  ];
  
  return (
    <DataTable
      data={data}
      columns={columns}
      isLoading={isLoading}
    />
  );
}
```

---

### 5. Compare Page

**Route**: `/compare`

**Purpose**: Side-by-side company comparison

**Layout**:
```
┌─────────────────────────────────────────────────────────────┐
│  Compare Companies                                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Select companies to compare (up to 4):                     │
│  [RELIANCE ▼] [TCS ▼] [INFY ▼] [+ Add]                     │
│                                                              │
├──────────────────┬──────────────────┬──────────────────────┤
│                  │ RELIANCE         │ TCS        │ INFY    │
├──────────────────┼──────────────────┼────────────┼─────────┤
│ Price            │ ₹2,850           │ ₹3,920     │ ₹1,850  │
│ Market Cap       │ ₹19.5L Cr        │ ₹14.2L Cr  │ ₹7.6LCr │
│ P/E Ratio        │ 25.3             │ 32.1       │ 28.5    │
│ Revenue (FY24)   │ ₹9.74L Cr        │ ₹2.41L Cr  │ ₹1.53LCr│
│ Net Income       │ ₹73,670 Cr       │ ₹46,099 Cr │ ₹26,233 │
│ ROE              │ 8.9%             │ 52.3%      │ 31.2%   │
│ Debt/Equity      │ 0.42             │ 0.04       │ 0.08    │
├──────────────────┴──────────────────┴────────────┴─────────┤
│                                                              │
│  Price Comparison Chart                                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  --- RELIANCE  --- TCS  --- INFY                    │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

### 6. Admin HITL Page

**Route**: `/admin/hitl`

**Purpose**: Review and approve/reject flagged queries

**Layout**:
```
┌─────────────────────────────────────────────────────────────┐
│  Human Review Queue                              3 Pending   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ⚠️ Sensitive Topic                    2 min ago     │   │
│  │                                                      │   │
│  │ Q: "What is the fraud investigation at XYZ?"        │   │
│  │                                                      │   │
│  │ Generated Response:                                  │   │
│  │ "Based on the documents, there have been reports... │   │
│  │                                                      │   │
│  │ Confidence: 65%                                      │   │
│  │ Sources: 3 documents                                 │   │
│  │                                                      │   │
│  │ [View Details] [Approve] [Edit] [Reject]            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ⚠️ Low Confidence                     15 min ago    │   │
│  │ ...                                                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## API Client

```typescript
// lib/api/client.ts
import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth interceptor
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Add refresh token interceptor
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Try to refresh token
      const refreshToken = localStorage.getItem('refresh_token');
      if (refreshToken) {
        try {
          const { data } = await axios.post(`${API_BASE_URL}/auth/refresh`, {
            refresh_token: refreshToken,
          });
          localStorage.setItem('access_token', data.access_token);
          error.config.headers.Authorization = `Bearer ${data.access_token}`;
          return apiClient.request(error.config);
        } catch {
          // Refresh failed, redirect to login
          window.location.href = '/login';
        }
      }
    }
    return Promise.reject(error);
  }
);
```

## React Query Hooks

```typescript
// lib/api/queries.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './client';

// Companies
export function useCompanies(params?: { sector?: string; limit?: number }) {
  return useQuery({
    queryKey: ['companies', params],
    queryFn: () => apiClient.get('/companies', { params }).then((r) => r.data),
  });
}

export function useCompany(symbol: string) {
  return useQuery({
    queryKey: ['company', symbol],
    queryFn: () => apiClient.get(`/companies/${symbol}`).then((r) => r.data),
    enabled: !!symbol,
  });
}

export function useCompanyFundamentals(symbol: string, periodType: string) {
  return useQuery({
    queryKey: ['fundamentals', symbol, periodType],
    queryFn: () =>
      apiClient
        .get(`/companies/${symbol}/fundamentals`, { params: { period_type: periodType } })
        .then((r) => r.data),
    enabled: !!symbol,
  });
}

// Queries
export function useSubmitQuery() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (data: { question: string; filters?: QueryFilters }) =>
      apiClient.post('/query', data).then((r) => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['query-history'] });
    },
  });
}

export function useQueryHistory(params?: { limit?: number; offset?: number }) {
  return useQuery({
    queryKey: ['query-history', params],
    queryFn: () => apiClient.get('/query/history', { params }).then((r) => r.data),
  });
}

// HITL
export function useHITLPending() {
  return useQuery({
    queryKey: ['hitl-pending'],
    queryFn: () => apiClient.get('/hitl/pending').then((r) => r.data),
    refetchInterval: 30000, // Refetch every 30 seconds
  });
}

export function useApproveHITL() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ id, notes }: { id: string; notes?: string }) =>
      apiClient.post(`/hitl/${id}/approve`, { notes }).then((r) => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['hitl-pending'] });
    },
  });
}
```

---

## Styling

### Tailwind Configuration

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: ['class'],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        // ... other colors
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};

export default config;
```

---

## Next Document

Continue to [08-INFRASTRUCTURE.md](./08-INFRASTRUCTURE.md) for deployment and infrastructure.

