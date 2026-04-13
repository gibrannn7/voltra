<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Voltra - Transaction Report</title>
    <style>
        body {
            font-family: 'Helvetica', 'Arial', sans-serif;
            font-size: 11px;
            color: #1a1a1a;
            margin: 0;
            padding: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 24px;
            border-bottom: 3px solid #2563EB;
            padding-bottom: 16px;
        }
        .header h1 {
            margin: 0;
            font-size: 22px;
            color: #2563EB;
            letter-spacing: 1px;
        }
        .header p {
            margin: 4px 0;
            color: #6B7280;
            font-size: 12px;
        }
        .summary {
            display: flex;
            margin-bottom: 20px;
        }
        .summary-box {
            border: 1px solid #E5E7EB;
            border-radius: 6px;
            padding: 12px 16px;
            margin-right: 12px;
            flex: 1;
        }
        .summary-box .label {
            font-size: 10px;
            color: #6B7280;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .summary-box .value {
            font-size: 16px;
            font-weight: bold;
            color: #111827;
            margin-top: 4px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 12px;
        }
        thead th {
            background-color: #2563EB;
            color: white;
            padding: 8px 6px;
            text-align: left;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        tbody td {
            padding: 7px 6px;
            border-bottom: 1px solid #E5E7EB;
            font-size: 10px;
        }
        tbody tr:nth-child(even) {
            background-color: #F9FAFB;
        }
        .status-success { color: #10B981; font-weight: bold; }
        .status-failed { color: #EF4444; font-weight: bold; }
        .status-processing { color: #F59E0B; font-weight: bold; }
        .status-pending { color: #6B7280; font-weight: bold; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .footer {
            margin-top: 24px;
            text-align: center;
            font-size: 9px;
            color: #9CA3AF;
            border-top: 1px solid #E5E7EB;
            padding-top: 12px;
        }
        .total-row td {
            font-weight: bold;
            border-top: 2px solid #2563EB;
            background-color: #EFF6FF;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>VOLTRA APP</h1>
        <p>Transaction Report</p>
        <p>Period: {{ \Carbon\Carbon::parse($from)->format('d M Y') }} - {{ \Carbon\Carbon::parse($until)->format('d M Y') }}</p>
        <p>Generated: {{ now()->format('d M Y H:i') }} WIB</p>
    </div>

    <table style="width: 100%; margin-bottom: 20px;">
        <tr>
            <td style="width: 33%; padding: 10px; border: 1px solid #E5E7EB; border-radius: 4px;">
                <div style="font-size: 10px; color: #6B7280; text-transform: uppercase;">Total Revenue</div>
                <div style="font-size: 16px; font-weight: bold; color: #10B981;">Rp {{ number_format((float) $totalRevenue, 0, ',', '.') }}</div>
            </td>
            <td style="width: 33%; padding: 10px; border: 1px solid #E5E7EB; border-radius: 4px;">
                <div style="font-size: 10px; color: #6B7280; text-transform: uppercase;">Total Profit</div>
                <div style="font-size: 16px; font-weight: bold; color: #2563EB;">Rp {{ number_format((float) $totalProfit, 0, ',', '.') }}</div>
            </td>
            <td style="width: 33%; padding: 10px; border: 1px solid #E5E7EB; border-radius: 4px;">
                <div style="font-size: 10px; color: #6B7280; text-transform: uppercase;">Total Transactions</div>
                <div style="font-size: 16px; font-weight: bold; color: #111827;">{{ $transactions->count() }}</div>
            </td>
        </tr>
    </table>

    <table>
        <thead>
            <tr>
                <th>#</th>
                <th>Date</th>
                <th>User</th>
                <th>Product</th>
                <th>Customer No</th>
                <th>Status</th>
                <th class="text-right">Amount</th>
                <th class="text-right">Profit</th>
                <th>Payment</th>
            </tr>
        </thead>
        <tbody>
            @forelse($transactions as $tx)
            <tr>
                <td>{{ $tx->id }}</td>
                <td>{{ $tx->created_at->format('d/m/Y H:i') }}</td>
                <td>{{ $tx->user?->name ?? '-' }}</td>
                <td>{{ \Illuminate\Support\Str::limit($tx->product?->name ?? '-', 20) }}</td>
                <td style="font-family: monospace;">{{ $tx->customer_number }}</td>
                <td>
                    <span class="status-{{ $tx->status }}">
                        {{ strtoupper($tx->status) }}
                    </span>
                </td>
                <td class="text-right">Rp {{ number_format((float) $tx->total_amount, 0, ',', '.') }}</td>
                <td class="text-right">Rp {{ number_format((float) $tx->profit_margin, 0, ',', '.') }}</td>
                <td>{{ $tx->payment_method ?? '-' }}</td>
            </tr>
            @empty
            <tr>
                <td colspan="9" class="text-center" style="padding: 20px; color: #9CA3AF;">
                    No transactions found for this period.
                </td>
            </tr>
            @endforelse

            @if($transactions->isNotEmpty())
            <tr class="total-row">
                <td colspan="6" class="text-right" style="font-weight: bold;">TOTAL (Success only):</td>
                <td class="text-right">Rp {{ number_format((float) $totalRevenue, 0, ',', '.') }}</td>
                <td class="text-right">Rp {{ number_format((float) $totalProfit, 0, ',', '.') }}</td>
                <td></td>
            </tr>
            @endif
        </tbody>
    </table>

    <div class="footer">
        <p>This report was auto-generated by Voltra Admin Panel. For questions, contact your system administrator.</p>
        <p>Voltra App &copy; {{ date('Y') }} - Smart PPOB & Bill Payment System</p>
    </div>
</body>
</html>
