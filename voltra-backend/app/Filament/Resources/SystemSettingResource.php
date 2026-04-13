<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SystemSettingResource\Pages;
use App\Models\SystemSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class SystemSettingResource extends Resource
{
    protected static ?string $model = SystemSetting::class;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';

    protected static ?string $navigationGroup = 'System';

    protected static ?string $navigationLabel = 'Settings';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'key';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Setting')
                    ->schema([
                        Forms\Components\TextInput::make('key')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(100)
                            ->helperText('Unique identifier (e.g., min_app_version, is_maintenance_mode)')
                            ->disabledOn('edit'),

                        Forms\Components\Textarea::make('value')
                            ->required()
                            ->rows(2)
                            ->helperText('The value for this setting'),

                        Forms\Components\TextInput::make('description')
                            ->maxLength(255)
                            ->helperText('Human-readable description of this setting'),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('key')
                    ->searchable()
                    ->fontFamily('mono')
                    ->weight('bold')
                    ->copyable(),

                Tables\Columns\TextColumn::make('value')
                    ->searchable()
                    ->limit(50)
                    ->tooltip(fn ($record) => $record->value)
                    ->badge()
                    ->color(function ($record) {
                        // Special coloring for boolean-like values
                        if (in_array($record->value, ['true', '1'])) {
                            return 'success';
                        }
                        if (in_array($record->value, ['false', '0'])) {
                            return 'gray';
                        }
                        return 'info';
                    }),

                Tables\Columns\TextColumn::make('description')
                    ->limit(40)
                    ->tooltip(fn ($record) => $record->description)
                    ->color('gray'),

                Tables\Columns\TextColumn::make('updated_at')
                    ->label('Last Modified')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->defaultSort('key')
            ->filters([])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([]);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListSystemSettings::route('/'),
            'create' => Pages\CreateSystemSetting::route('/create'),
            'edit'   => Pages\EditSystemSetting::route('/{record}/edit'),
        ];
    }
}
