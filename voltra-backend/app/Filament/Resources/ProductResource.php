<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProductResource\Pages;
use App\Models\Category;
use App\Models\Product;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Cache;

class ProductResource extends Resource
{
    protected static ?string $model = Product::class;

    protected static ?string $navigationIcon = 'heroicon-o-cube';

    protected static ?string $navigationGroup = 'Operations';

    protected static ?string $navigationLabel = 'Products';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Product Information')
                    ->schema([
                        Forms\Components\Select::make('category_id')
                            ->label('Category')
                            ->relationship('category', 'name')
                            ->required()
                            ->searchable()
                            ->preload(),

                        Forms\Components\TextInput::make('sku_code')
                            ->label('SKU Code (Digiflazz)')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(100),

                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255),

                        Forms\Components\Select::make('type')
                            ->options([
                                'prepaid'  => 'Prepaid',
                                'postpaid' => 'Postpaid',
                            ])
                            ->required()
                            ->default('prepaid'),
                    ])->columns(2),

                Forms\Components\Section::make('Pricing')
                    ->description('All prices in IDR. Use DECIMAL precision.')
                    ->schema([
                        Forms\Components\TextInput::make('base_price')
                            ->label('Base Price (from Digiflazz)')
                            ->numeric()
                            ->prefix('Rp')
                            ->required()
                            ->default(0),

                        Forms\Components\TextInput::make('admin_markup')
                            ->label('Admin Markup')
                            ->numeric()
                            ->prefix('Rp')
                            ->required()
                            ->default(0)
                            ->helperText('Markup profit per transaction'),

                        Forms\Components\Placeholder::make('selling_price')
                            ->label('Selling Price (Auto-calculated)')
                            ->content(function ($record) {
                                if (! $record) {
                                    return 'Rp 0';
                                }
                                return 'Rp ' . number_format((float) $record->selling_price, 0, ',', '.');
                            }),
                    ])->columns(3),

                Forms\Components\Section::make('Status')
                    ->schema([
                        Forms\Components\Toggle::make('is_active')
                            ->label('Active')
                            ->default(true)
                            ->helperText('Disabled products will not appear in the mobile app'),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('ID')
                    ->sortable()
                    ->searchable(),

                Tables\Columns\TextColumn::make('category.name')
                    ->label('Category')
                    ->badge()
                    ->color('info')
                    ->sortable()
                    ->searchable(),

                Tables\Columns\TextColumn::make('sku_code')
                    ->label('SKU')
                    ->searchable()
                    ->copyable()
                    ->fontFamily('mono')
                    ->size('sm'),

                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->limit(30)
                    ->tooltip(fn ($record) => $record->name),

                Tables\Columns\TextColumn::make('base_price')
                    ->label('Base Price')
                    ->money('IDR', locale: 'id')
                    ->sortable()
                    ->color('gray'),

                Tables\Columns\TextColumn::make('admin_markup')
                    ->label('Markup')
                    ->money('IDR', locale: 'id')
                    ->sortable()
                    ->color('success'),

                Tables\Columns\TextColumn::make('selling_price')
                    ->label('Selling Price')
                    ->getStateUsing(fn ($record) => $record->selling_price)
                    ->money('IDR', locale: 'id')
                    ->sortable(query: function (Builder $query, string $direction): Builder {
                        return $query->orderByRaw("(base_price + admin_markup) {$direction}");
                    })
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('type')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'prepaid'  => 'success',
                        'postpaid' => 'warning',
                        default    => 'gray',
                    }),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-circle')
                    ->falseIcon('heroicon-o-x-circle'),

                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Last Updated')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('category_id')
            ->filters([
                Tables\Filters\SelectFilter::make('category_id')
                    ->label('Category')
                    ->relationship('category', 'name'),

                Tables\Filters\SelectFilter::make('type')
                    ->options([
                        'prepaid'  => 'Prepaid',
                        'postpaid' => 'Postpaid',
                    ]),

                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Status')
                    ->trueLabel('Active Only')
                    ->falseLabel('Inactive Only'),

                Tables\Filters\TrashedFilter::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
                Tables\Actions\RestoreAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    // Mass Update Markup Action
                    Tables\Actions\BulkAction::make('updateMarkup')
                        ->label('Mass Update Markup')
                        ->icon('heroicon-o-currency-dollar')
                        ->color('warning')
                        ->form([
                            Forms\Components\TextInput::make('markup_amount')
                                ->label('New Markup Amount (Rp)')
                                ->numeric()
                                ->required()
                                ->prefix('Rp')
                                ->helperText('This will set the admin_markup for all selected products'),
                        ])
                        ->action(function (Collection $records, array $data): void {
                            $count = $records->count();
                            $records->each(function (Product $product) use ($data) {
                                $product->update([
                                    'admin_markup' => $data['markup_amount'],
                                ]);
                            });

                            // Invalidate product cache
                            $categories = Category::pluck('id');
                            foreach ($categories as $catId) {
                                Cache::forget("products:category:{$catId}");
                            }
                            Cache::forget('products:category:');

                            Notification::make()
                                ->title("Markup updated for {$count} products")
                                ->success()
                                ->send();
                        })
                        ->deselectRecordsAfterCompletion()
                        ->requiresConfirmation(),

                    // Bulk Activate
                    Tables\Actions\BulkAction::make('activate')
                        ->label('Activate Selected')
                        ->icon('heroicon-o-check-circle')
                        ->color('success')
                        ->action(function (Collection $records): void {
                            $records->each->update(['is_active' => true]);

                            Notification::make()
                                ->title($records->count() . ' products activated')
                                ->success()
                                ->send();
                        })
                        ->requiresConfirmation(),

                    // Bulk Deactivate
                    Tables\Actions\BulkAction::make('deactivate')
                        ->label('Deactivate Selected')
                        ->icon('heroicon-o-x-circle')
                        ->color('danger')
                        ->action(function (Collection $records): void {
                            $records->each->update(['is_active' => false]);

                            Notification::make()
                                ->title($records->count() . ' products deactivated')
                                ->warning()
                                ->send();
                        })
                        ->requiresConfirmation(),

                    Tables\Actions\DeleteBulkAction::make(),
                    Tables\Actions\RestoreBulkAction::make(),
                ]),
            ])
            ->headerActions([
                // Sync from Digiflazz action
                Tables\Actions\Action::make('syncDigiflazz')
                    ->label('Sync from Digiflazz')
                    ->icon('heroicon-o-arrow-path')
                    ->color('info')
                    ->action(function () {
                        \App\Jobs\SyncDigiflazzProducts::dispatch();

                        Notification::make()
                            ->title('Product sync job dispatched')
                            ->body('Products will be updated from Digiflazz in the background.')
                            ->info()
                            ->send();
                    })
                    ->requiresConfirmation()
                    ->modalHeading('Sync Products from Digiflazz')
                    ->modalDescription('This will fetch the latest product catalog and prices from Digiflazz. Products with negative margins will be auto-disabled.')
                    ->modalSubmitActionLabel('Start Sync'),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListProducts::route('/'),
            'create' => Pages\CreateProduct::route('/create'),
            'edit'   => Pages\EditProduct::route('/{record}/edit'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->withoutGlobalScopes()
            ->with('category');
    }
}
