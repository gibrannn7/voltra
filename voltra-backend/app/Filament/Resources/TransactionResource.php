<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TransactionResource\Pages;
use App\Models\ApiLog;
use App\Models\Transaction;
use App\Services\DigiflazzService;
use App\Services\MidtransService;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use pxlrbt\FilamentExcel\Actions\Tables\ExportBulkAction;

class TransactionResource extends Resource
{
    protected static ?string $model = Transaction::class;

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';

    protected static ?string $navigationGroup = 'Operations';

    protected static ?string $navigationLabel = 'Transactions';

    protected static ?int $navigationSort = 2;

    protected static ?string $recordTitleAttribute = 'midtrans_order_id';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Transaction Details')
                    ->schema([
                        Forms\Components\TextInput::make('midtrans_order_id')
                            ->label('Order ID')
                            ->disabled(),
                        Forms\Components\TextInput::make('digiflazz_ref_id')
                            ->label('Digiflazz Ref')
                            ->disabled(),
                        Forms\Components\TextInput::make('customer_number')
                            ->disabled(),
                        Forms\Components\TextInput::make('customer_name')
                            ->disabled(),
                        Forms\Components\TextInput::make('status')
                            ->disabled(),
                        Forms\Components\TextInput::make('payment_method')
                            ->disabled(),
                        Forms\Components\TextInput::make('sn_token')
                            ->label('SN / Token')
                            ->disabled(),
                    ])->columns(2),

                Forms\Components\Section::make('Financial Breakdown')
                    ->schema([
                        Forms\Components\TextInput::make('base_price')
                            ->prefix('Rp')
                            ->disabled(),
                        Forms\Components\TextInput::make('admin_fee')
                            ->prefix('Rp')
                            ->disabled(),
                        Forms\Components\TextInput::make('discount')
                            ->prefix('Rp')
                            ->disabled(),
                        Forms\Components\TextInput::make('pg_fee')
                            ->label('PG Fee')
                            ->prefix('Rp')
                            ->disabled(),
                        Forms\Components\TextInput::make('total_amount')
                            ->prefix('Rp')
                            ->disabled(),
                        Forms\Components\TextInput::make('profit_margin')
                            ->prefix('Rp')
                            ->disabled(),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime('d/m/Y H:i')
                    ->sortable(),

                Tables\Columns\TextColumn::make('user.name')
                    ->label('User')
                    ->searchable()
                    ->limit(15),

                Tables\Columns\TextColumn::make('product.name')
                    ->label('Product')
                    ->searchable()
                    ->limit(20)
                    ->tooltip(fn ($record) => $record->product?->name),

                Tables\Columns\TextColumn::make('customer_number')
                    ->label('Customer No')
                    ->searchable()
                    ->fontFamily('mono')
                    ->size('sm'),

                Tables\Columns\TextColumn::make('total_amount')
                    ->label('Total')
                    ->money('IDR', locale: 'id')
                    ->sortable()
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('profit_margin')
                    ->label('Profit')
                    ->money('IDR', locale: 'id')
                    ->sortable()
                    ->color(fn ($record) => bccomp($record->profit_margin, '0', 2) > 0 ? 'success' : 'danger'),

                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'success'    => 'success',
                        'processing' => 'warning',
                        'pending'    => 'gray',
                        'failed'     => 'danger',
                        default      => 'gray',
                    })
                    ->icon(fn (string $state): string => match ($state) {
                        'success'    => 'heroicon-m-check-circle',
                        'processing' => 'heroicon-m-arrow-path',
                        'pending'    => 'heroicon-m-clock',
                        'failed'     => 'heroicon-m-x-circle',
                        default      => 'heroicon-m-question-mark-circle',
                    }),

                Tables\Columns\TextColumn::make('payment_method')
                    ->label('Payment')
                    ->badge()
                    ->color('info'),

                Tables\Columns\TextColumn::make('sn_token')
                    ->label('SN/Token')
                    ->fontFamily('mono')
                    ->size('sm')
                    ->copyable()
                    ->placeholder('-')
                    ->toggleable(),

                Tables\Columns\TextColumn::make('midtrans_order_id')
                    ->label('Order ID')
                    ->fontFamily('mono')
                    ->size('sm')
                    ->copyable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending'    => 'Pending',
                        'processing' => 'Processing',
                        'success'    => 'Success',
                        'failed'     => 'Failed',
                    ]),

                Tables\Filters\SelectFilter::make('payment_method')
                    ->label('Payment Method')
                    ->options([
                        'wallet'        => 'Wallet',
                        'bank_transfer' => 'Bank Transfer',
                        'gopay'         => 'GoPay',
                        'shopeepay'     => 'ShopeePay',
                        'qris'          => 'QRIS',
                    ]),

                Tables\Filters\Filter::make('date_range')
                    ->form([
                        Forms\Components\DatePicker::make('from')
                            ->label('From Date'),
                        Forms\Components\DatePicker::make('until')
                            ->label('Until Date'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['from'], fn (Builder $q, $date) => $q->whereDate('created_at', '>=', $date))
                            ->when($data['until'], fn (Builder $q, $date) => $q->whereDate('created_at', '<=', $date));
                    })
                    ->indicateUsing(function (array $data): array {
                        $indicators = [];
                        if ($data['from'] ?? null) {
                            $indicators['from'] = 'From: ' . \Carbon\Carbon::parse($data['from'])->format('d M Y');
                        }
                        if ($data['until'] ?? null) {
                            $indicators['until'] = 'Until: ' . \Carbon\Carbon::parse($data['until'])->format('d M Y');
                        }
                        return $indicators;
                    }),
            ])
            ->actions([
                // View full transaction detail
                Tables\Actions\ViewAction::make(),

                // View API Logs Modal
                Tables\Actions\Action::make('viewLogs')
                    ->label('API Logs')
                    ->icon('heroicon-o-document-magnifying-glass')
                    ->color('gray')
                    ->modalHeading('API Request/Response Logs')
                    ->modalContent(function (Transaction $record) {
                        $logs = ApiLog::where(function ($q) use ($record) {
                            $q->where('endpoint', 'like', "%{$record->midtrans_order_id}%")
                              ->orWhere('endpoint', 'like', "%{$record->digiflazz_ref_id}%");
                        })
                        ->orWhere(function ($q) use ($record) {
                            // Also check payload JSON for ref_id/order_id
                            $q->whereJsonContains('payload->ref_id', $record->digiflazz_ref_id)
                              ->orWhereJsonContains('payload->order_id', $record->midtrans_order_id);
                        })
                        ->orderByDesc('created_at')
                        ->get();

                        $html = '<div class="space-y-4 max-h-[60vh] overflow-y-auto">';

                        if ($logs->isEmpty()) {
                            $html .= '<p class="text-gray-500 text-sm">No API logs found for this transaction.</p>';
                        }

                        foreach ($logs as $log) {
                            $providerColor = $log->provider === 'midtrans' ? 'blue' : 'green';
                            $html .= '<div class="border border-gray-200 dark:border-gray-700 rounded-lg p-4">';
                            $html .= '<div class="flex justify-between items-center mb-2">';
                            $html .= '<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-' . $providerColor . '-100 text-' . $providerColor . '-800 dark:bg-' . $providerColor . '-900 dark:text-' . $providerColor . '-200">'
                                . strtoupper($log->provider) . ' / ' . strtoupper($log->type) . '</span>';
                            $html .= '<span class="text-xs text-gray-500">' . $log->created_at->format('d/m/Y H:i:s') . '</span>';
                            $html .= '<span class="text-xs font-mono">HTTP ' . $log->http_status . '</span>';
                            $html .= '</div>';
                            $html .= '<div class="mt-2"><p class="text-xs text-gray-500 mb-1 font-semibold">PAYLOAD:</p>';
                            $html .= '<pre class="text-xs bg-gray-50 dark:bg-gray-900 p-2 rounded overflow-x-auto max-h-32">'
                                . htmlspecialchars(json_encode($log->payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)) . '</pre></div>';
                            $html .= '<div class="mt-2"><p class="text-xs text-gray-500 mb-1 font-semibold">RESPONSE:</p>';
                            $html .= '<pre class="text-xs bg-gray-50 dark:bg-gray-900 p-2 rounded overflow-x-auto max-h-32">'
                                . htmlspecialchars(json_encode($log->response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)) . '</pre></div>';
                            $html .= '</div>';
                        }

                        $html .= '</div>';

                        return new \Illuminate\Support\HtmlString($html);
                    })
                    ->modalWidth('3xl')
                    ->modalSubmitAction(false),

                // Manual Re-check Status
                Tables\Actions\Action::make('checkStatus')
                    ->label('Check Status')
                    ->icon('heroicon-o-arrow-path')
                    ->color('warning')
                    ->visible(fn (Transaction $record) => in_array($record->status, ['pending', 'processing']))
                    ->action(function (Transaction $record) {
                        $statusInfo = [];

                        // Check Midtrans
                        if ($record->midtrans_order_id) {
                            $midtrans    = app(MidtransService::class);
                            $mtResult    = $midtrans->checkTransactionStatus($record->midtrans_order_id);
                            $statusInfo['midtrans'] = $mtResult;
                        }

                        // Check Digiflazz
                        if ($record->digiflazz_ref_id) {
                            $digiflazz   = app(DigiflazzService::class);
                            $dgResult    = $digiflazz->checkStatus($record->digiflazz_ref_id);
                            $statusInfo['digiflazz'] = $dgResult;
                        }

                        Notification::make()
                            ->title('Status Check Complete')
                            ->body('Midtrans: ' . ($statusInfo['midtrans']['transaction_status'] ?? 'N/A') .
                                   ' | Digiflazz: ' . ($statusInfo['digiflazz']['data']['status'] ?? 'N/A'))
                            ->info()
                            ->persistent()
                            ->send();
                    })
                    ->requiresConfirmation()
                    ->modalHeading('Manual Status Re-check')
                    ->modalDescription('This will query Midtrans and Digiflazz APIs to get the latest transaction status.'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    ExportBulkAction::make()
                        ->label('Export to Excel'),
                ]),
            ])
            ->headerActions([
                // PDF Export Action
                Tables\Actions\Action::make('exportPdf')
                    ->label('Export PDF')
                    ->icon('heroicon-o-document-arrow-down')
                    ->color('danger')
                    ->form([
                        Forms\Components\DatePicker::make('from')
                            ->label('From Date')
                            ->required(),
                        Forms\Components\DatePicker::make('until')
                            ->label('Until Date')
                            ->required(),
                    ])
                    ->action(function (array $data) {
                        $transactions = Transaction::with(['user', 'product'])
                            ->whereDate('created_at', '>=', $data['from'])
                            ->whereDate('created_at', '<=', $data['until'])
                            ->orderByDesc('created_at')
                            ->get();

                        $totalRevenue = $transactions->where('status', 'success')->sum('total_amount');
                        $totalProfit  = $transactions->where('status', 'success')->sum('profit_margin');

                        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('exports.transactions-pdf', [
                            'transactions' => $transactions,
                            'from'         => $data['from'],
                            'until'        => $data['until'],
                            'totalRevenue' => $totalRevenue,
                            'totalProfit'  => $totalProfit,
                        ]);

                        $filename = 'voltra-transactions-' . $data['from'] . '-to-' . $data['until'] . '.pdf';

                        return response()->streamDownload(function () use ($pdf) {
                            echo $pdf->output();
                        }, $filename);
                    }),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListTransactions::route('/'),
            'view'  => Pages\ViewTransaction::route('/{record}'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->with(['user', 'product', 'promo']);
    }

    public static function getNavigationBadge(): ?string
    {
        $pending = static::getModel()::whereIn('status', ['pending', 'processing'])->count();
        return $pending > 0 ? (string) $pending : null;
    }

    public static function getNavigationBadgeColor(): string|array|null
    {
        return 'warning';
    }
}
