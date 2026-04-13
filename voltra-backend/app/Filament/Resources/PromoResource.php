<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PromoResource\Pages;
use App\Models\Promo;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class PromoResource extends Resource
{
    protected static ?string $model = Promo::class;

    protected static ?string $navigationIcon = 'heroicon-o-ticket';

    protected static ?string $navigationGroup = 'Operations';

    protected static ?string $navigationLabel = 'Promos';

    protected static ?int $navigationSort = 3;

    protected static ?string $recordTitleAttribute = 'promo_code';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Promo Details')
                    ->schema([
                        Forms\Components\TextInput::make('promo_code')
                            ->label('Promo Code')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(50)
                            ->alphaDash()
                            ->helperText('Use uppercase letters and numbers only (e.g., VOLTRA10)'),

                        Forms\Components\TextInput::make('discount_amount')
                            ->label('Discount Amount')
                            ->numeric()
                            ->prefix('Rp')
                            ->required()
                            ->default(0),

                        Forms\Components\TextInput::make('min_transaction')
                            ->label('Minimum Transaction')
                            ->numeric()
                            ->prefix('Rp')
                            ->required()
                            ->default(0)
                            ->helperText('Minimum transaction amount to apply this promo'),

                        Forms\Components\TextInput::make('max_usage')
                            ->label('Max Usage')
                            ->numeric()
                            ->required()
                            ->default(0)
                            ->helperText('Set 0 for unlimited'),
                    ])->columns(2),

                Forms\Components\Section::make('Validity')
                    ->schema([
                        Forms\Components\DateTimePicker::make('expired_at')
                            ->label('Expiry Date')
                            ->nullable()
                            ->helperText('Leave empty for no expiry'),

                        Forms\Components\Toggle::make('is_active')
                            ->label('Active')
                            ->default(true),

                        Forms\Components\Placeholder::make('current_usage')
                            ->label('Current Usage')
                            ->content(fn ($record) => $record?->current_usage ?? 0)
                            ->visibleOn('edit'),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('promo_code')
                    ->label('Code')
                    ->searchable()
                    ->copyable()
                    ->fontFamily('mono')
                    ->weight('bold'),

                Tables\Columns\TextColumn::make('discount_amount')
                    ->label('Discount')
                    ->money('IDR', locale: 'id')
                    ->sortable()
                    ->color('success'),

                Tables\Columns\TextColumn::make('min_transaction')
                    ->label('Min Transaction')
                    ->money('IDR', locale: 'id')
                    ->sortable(),

                Tables\Columns\TextColumn::make('usage_display')
                    ->label('Usage')
                    ->getStateUsing(function ($record) {
                        $max = $record->max_usage > 0 ? $record->max_usage : '∞';
                        return "{$record->current_usage} / {$max}";
                    })
                    ->badge()
                    ->color(function ($record) {
                        if ($record->max_usage > 0 && $record->current_usage >= $record->max_usage) {
                            return 'danger';
                        }
                        if ($record->max_usage > 0 && $record->current_usage >= ($record->max_usage * 0.8)) {
                            return 'warning';
                        }
                        return 'success';
                    }),

                Tables\Columns\TextColumn::make('expired_at')
                    ->label('Expires')
                    ->dateTime('d M Y')
                    ->sortable()
                    ->color(fn ($record) => $record->expired_at?->isPast() ? 'danger' : 'gray')
                    ->placeholder('No expiry'),

                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean(),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime('d M Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Status')
                    ->trueLabel('Active')
                    ->falseLabel('Inactive'),

                Tables\Filters\Filter::make('expired')
                    ->label('Expired')
                    ->query(fn (Builder $query) => $query->where('expired_at', '<', now()))
                    ->toggle(),

                Tables\Filters\TrashedFilter::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
                Tables\Actions\RestoreAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                    Tables\Actions\RestoreBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListPromos::route('/'),
            'create' => Pages\CreatePromo::route('/create'),
            'edit'   => Pages\EditPromo::route('/{record}/edit'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->withoutGlobalScopes();
    }
}
