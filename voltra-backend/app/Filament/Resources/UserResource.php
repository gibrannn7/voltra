<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';

    protected static ?string $navigationGroup = 'Users & Security';

    protected static ?string $navigationLabel = 'Users';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('User Information')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255),

                        Forms\Components\TextInput::make('phone_number')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->tel(),

                        Forms\Components\TextInput::make('email')
                            ->email()
                            ->unique(ignoreRecord: true),

                        Forms\Components\Select::make('role')
                            ->options([
                                'superadmin' => 'Super Admin',
                                'user'       => 'User',
                            ])
                            ->required()
                            ->default('user'),

                        Forms\Components\Select::make('kyc_status')
                            ->options([
                                'unverified' => 'Unverified',
                                'pending'    => 'Pending',
                                'verified'   => 'Verified',
                            ])
                            ->default('unverified'),
                    ])->columns(2),

                Forms\Components\Section::make('Security')
                    ->schema([
                        Forms\Components\Toggle::make('is_suspended')
                            ->label('Suspended')
                            ->helperText('Block this user from accessing the app'),

                        Forms\Components\Textarea::make('suspend_reason')
                            ->label('Suspend Reason')
                            ->rows(2)
                            ->visible(fn (Forms\Get $get) => $get('is_suspended')),

                        Forms\Components\Placeholder::make('failed_pin_count')
                            ->label('Failed PIN Attempts')
                            ->content(fn ($record) => $record?->failed_pin_count ?? 0)
                            ->visibleOn('edit'),

                        Forms\Components\TextInput::make('voltra_points')
                            ->numeric()
                            ->default(0),
                    ])->columns(2),

                Forms\Components\Section::make('Wallet')
                    ->schema([
                        Forms\Components\Placeholder::make('wallet_balance')
                            ->label('Wallet Balance')
                            ->content(function ($record) {
                                if (! $record || ! $record->wallet) {
                                    return 'Rp 0';
                                }
                                return 'Rp ' . number_format((float) $record->wallet->balance, 0, ',', '.');
                            }),
                    ])
                    ->visibleOn('edit'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('#')
                    ->sortable(),

                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('phone_number')
                    ->label('Phone')
                    ->searchable()
                    ->copyable()
                    ->fontFamily('mono'),

                Tables\Columns\TextColumn::make('email')
                    ->searchable()
                    ->limit(20)
                    ->toggleable(),

                Tables\Columns\TextColumn::make('role')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'superadmin' => 'danger',
                        'user'       => 'info',
                        default      => 'gray',
                    }),

                Tables\Columns\TextColumn::make('wallet.balance')
                    ->label('Wallet')
                    ->money('IDR', locale: 'id')
                    ->sortable()
                    ->default('0'),

                Tables\Columns\TextColumn::make('voltra_points')
                    ->label('Points')
                    ->sortable()
                    ->badge()
                    ->color('success'),

                Tables\Columns\TextColumn::make('kyc_status')
                    ->label('KYC')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'verified'   => 'success',
                        'pending'    => 'warning',
                        'unverified' => 'gray',
                        default      => 'gray',
                    }),

                Tables\Columns\IconColumn::make('is_suspended')
                    ->label('Suspended')
                    ->boolean()
                    ->trueIcon('heroicon-o-lock-closed')
                    ->falseIcon('heroicon-o-lock-open')
                    ->trueColor('danger')
                    ->falseColor('success'),

                Tables\Columns\TextColumn::make('transactions_count')
                    ->label('Txns')
                    ->counts('transactions')
                    ->sortable(),

                Tables\Columns\TextColumn::make('created_at')
                    ->label('Registered')
                    ->dateTime('d M Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->options([
                        'superadmin' => 'Super Admin',
                        'user'       => 'User',
                    ]),

                Tables\Filters\TernaryFilter::make('is_suspended')
                    ->label('Suspension Status')
                    ->trueLabel('Suspended')
                    ->falseLabel('Active'),

                Tables\Filters\SelectFilter::make('kyc_status')
                    ->options([
                        'unverified' => 'Unverified',
                        'pending'    => 'Pending',
                        'verified'   => 'Verified',
                    ]),

                Tables\Filters\TrashedFilter::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),

                // Unsuspend action
                Tables\Actions\Action::make('unsuspend')
                    ->label('Unsuspend')
                    ->icon('heroicon-o-lock-open')
                    ->color('success')
                    ->visible(fn (User $record) => $record->is_suspended)
                    ->action(function (User $record) {
                        $record->update([
                            'is_suspended'    => false,
                            'suspend_reason'  => null,
                            'failed_pin_count' => 0,
                        ]);

                        Notification::make()
                            ->title("User {$record->name} has been unsuspended")
                            ->success()
                            ->send();
                    })
                    ->requiresConfirmation()
                    ->modalHeading('Unsuspend User')
                    ->modalDescription('This will unlock the user account and reset their PIN attempts.'),

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
            'index'  => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit'   => Pages\EditUser::route('/{record}/edit'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->withoutGlobalScopes()
            ->with(['wallet']);
    }
}
